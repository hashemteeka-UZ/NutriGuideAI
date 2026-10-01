"""Structural checks on Base.metadata (Step C) plus a DDL smoke test on db_test."""

from collections.abc import Iterator
from enum import StrEnum

import pytest
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Column,
    Enum,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    MetaData,
    Numeric,
    PrimaryKeyConstraint,
    String,
    Table,
    UniqueConstraint,
    create_engine,
    inspect,
    text,
)
from sqlalchemy.engine import Engine, make_url
from sqlalchemy.exc import OperationalError

import app.db.models  # noqa: F401  (registers every model on Base.metadata)
from app.core.config import REPO_ROOT, get_settings
from app.db.base import Base
from app.db.models import reference as ref

PG_MAX_IDENTIFIER = 63

REFERENCE_TABLES = {
    "categories",
    "cuisines",
    "allergens",
    "dietary_tags",
    "health_conditions",
    "condition_nutrient_limits",
    "condition_tag_restrictions",
    "foods",
    "nutrients",
    "food_nutrients",
    "portions_food",
    "ingredients",
    "ingredient_aliases",
    "ingredient_allergens",
    "ingredient_tags",
}

EXPECTED_TABLES = REFERENCE_TABLES

# Junction tables and their composite PK (§9.8, §9.12, §9.13).
COMPOSITE_PK = {
    "food_nutrients": ("food_id", "nutrient_id"),
    "ingredient_allergens": ("ingredient_id", "allergen_id"),
    "ingredient_tags": ("ingredient_id", "tag_id"),
}
SURROGATE_PK_TABLES = sorted(EXPECTED_TABLES - COMPOSITE_PK.keys())

# §15.10 audit-column classes.
MUTABLE_TABLES = {
    "categories",
    "cuisines",
    "allergens",
    "dietary_tags",
    "health_conditions",
    "condition_nutrient_limits",
    "condition_tag_restrictions",
    "foods",
    "nutrients",
    "ingredients",
}
NO_AUDIT_TABLES = {
    "food_nutrients",
    "portions_food",
    "ingredient_aliases",
    "ingredient_allergens",
    "ingredient_tags",
}

# §17 enum-like columns: (table, column) -> allowed values.
ENUM_COLUMNS: dict[tuple[str, str], type[StrEnum]] = {
    ("dietary_tags", "tag_group"): ref.TagGroup,
    ("condition_nutrient_limits", "limit_basis"): ref.LimitBasis,
    ("condition_tag_restrictions", "restriction_type"): ref.RestrictionType,
    ("foods", "external_source"): ref.FoodExternalSource,
    ("foods", "state"): ref.FoodState,
    ("nutrients", "unit"): ref.NutrientUnit,
    ("ingredients", "review_status"): ref.ReviewStatus,
}

CONVENTION_PREFIX = {
    PrimaryKeyConstraint: "pk_",
    ForeignKeyConstraint: "fk_",
    UniqueConstraint: "uq_",
    CheckConstraint: "ck_",
}


def _table(name: str) -> Table:
    return Base.metadata.tables[name]


def _fk_columns(table: Table) -> list[Column[object]]:
    return [col for col in table.columns if col.foreign_keys]


def _is_plain_btree(index: Index) -> bool:
    using = index.dialect_options["postgresql"]["using"]
    where = index.dialect_options["postgresql"]["where"]
    return (not using or using == "btree") and where is None


def _leading_columns(table: Table) -> set[str]:
    """Columns usable as the leftmost key of a full (non-partial) B-tree index."""
    leading: set[str] = set()
    if table.primary_key.columns:
        leading.add(next(iter(table.primary_key.columns)).name)
    for constraint in table.constraints:
        if isinstance(constraint, UniqueConstraint) and constraint.columns:
            leading.add(next(iter(constraint.columns)).name)
    for index in table.indexes:
        first = next(iter(index.expressions), None)
        if isinstance(first, Column) and _is_plain_btree(index):
            leading.add(first.name)
    return leading


def _unique_column_sets(table: Table) -> set[tuple[str, ...]]:
    return {
        tuple(col.name for col in c.columns)
        for c in table.constraints
        if isinstance(c, UniqueConstraint)
    }


def test_expected_tables_exist() -> None:
    assert set(Base.metadata.tables) == EXPECTED_TABLES


@pytest.mark.parametrize("table_name", SURROGATE_PK_TABLES)
def test_surrogate_pk_is_bigint_identity_always(table_name: str) -> None:
    pk_cols = list(_table(table_name).primary_key.columns)
    assert len(pk_cols) == 1
    col = pk_cols[0]
    assert isinstance(col.type, BigInteger)
    assert not col.foreign_keys
    assert col.identity is not None
    assert col.identity.always is True


@pytest.mark.parametrize("table_name", sorted(COMPOSITE_PK))
def test_composite_pk(table_name: str) -> None:
    table = _table(table_name)
    assert tuple(c.name for c in table.primary_key.columns) == COMPOSITE_PK[table_name]
    for col in table.primary_key.columns:
        assert col.foreign_keys, f"{table_name}.{col.name} should be an FK"
        assert col.identity is None


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_fk_columns_are_bigint(table_name: str) -> None:
    for col in _fk_columns(_table(table_name)):
        assert isinstance(col.type, BigInteger), f"{table_name}.{col.name}"


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_every_fk_column_is_indexed(table_name: str) -> None:
    table = _table(table_name)
    leading = _leading_columns(table)
    missing = [col.name for col in _fk_columns(table) if col.name not in leading]
    assert not missing, f"{table_name}: FK columns without index: {missing}"


def test_fk_index_check_detects_uncovered_fk() -> None:
    metadata = MetaData()
    Table("parent", metadata, Column("id", BigInteger, primary_key=True))
    child = Table(
        "child",
        metadata,
        Column("id", BigInteger, primary_key=True),
        Column("covered", BigInteger, ForeignKey("parent.id"), index=True),
        Column("partial_only", BigInteger, ForeignKey("parent.id")),
        Column("uncovered", BigInteger, ForeignKey("parent.id")),
        Index("ix_partial", "partial_only", postgresql_where=text("id > 0")),
    )
    leading = _leading_columns(child)
    assert "covered" in leading
    assert "partial_only" not in leading
    assert "uncovered" not in leading


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_every_fk_has_explicit_ondelete(table_name: str) -> None:
    for fk in _table(table_name).foreign_keys:
        assert fk.ondelete is not None, f"{table_name}.{fk.parent.name}"


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_no_native_enum(table_name: str) -> None:
    for col in _table(table_name).columns:
        if isinstance(col.type, Enum):
            assert col.type.native_enum is False, f"{table_name}.{col.name}"


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_numeric_columns_return_float(table_name: str) -> None:
    for col in _table(table_name).columns:
        if isinstance(col.type, Numeric):
            assert col.type.asdecimal is False, f"{table_name}.{col.name}"


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_constraint_and_index_names(table_name: str) -> None:
    table = _table(table_name)
    for constraint in table.constraints:
        name = constraint.name
        assert isinstance(name, str), f"{table_name}: unnamed {constraint!r}"
        assert len(name) <= PG_MAX_IDENTIFIER, f"{name} ({len(name)} chars)"
        assert name.startswith(CONVENTION_PREFIX[type(constraint)]), name
    for index in table.indexes:
        name = index.name
        assert isinstance(name, str), f"{table_name}: unnamed index"
        assert len(name) <= PG_MAX_IDENTIFIER, f"{name} ({len(name)} chars)"
        assert name.startswith("ix_"), name


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_audit_columns_match_table_class(table_name: str) -> None:
    columns = set(_table(table_name).columns.keys())
    if table_name in MUTABLE_TABLES:
        assert {"created_at", "updated_at"} <= columns
    elif table_name in NO_AUDIT_TABLES:
        assert not {"created_at", "updated_at"} & columns
    else:
        pytest.fail(f"{table_name} is not assigned to a §15.10 class in this test")


@pytest.mark.parametrize(("table_name", "column"), sorted(ENUM_COLUMNS))
def test_enum_like_column_has_check(table_name: str, column: str) -> None:
    table = _table(table_name)
    assert isinstance(table.c[column].type, String)
    checks = [
        str(c.sqltext)
        for c in table.constraints
        if isinstance(c, CheckConstraint) and str(c.sqltext).startswith(f"{column} IN (")
    ]
    assert len(checks) == 1, f"{table_name}.{column}: expected one IN (...) CHECK"
    for member in ENUM_COLUMNS[(table_name, column)]:
        assert f"'{member.value}'" in checks[0]


# §15.7, plus the user's decisions for FKs that §15.7 does not list.
EXPECTED_ONDELETE = {
    ("condition_nutrient_limits", "condition_id"): "CASCADE",
    ("condition_nutrient_limits", "nutrient_id"): "RESTRICT",
    ("condition_tag_restrictions", "condition_id"): "CASCADE",
    ("condition_tag_restrictions", "tag_id"): "RESTRICT",
    ("foods", "category_id"): "RESTRICT",
    ("food_nutrients", "food_id"): "CASCADE",
    ("food_nutrients", "nutrient_id"): "RESTRICT",
    ("portions_food", "food_id"): "CASCADE",
    ("ingredients", "default_food_id"): "SET NULL",
    ("ingredient_aliases", "ingredient_id"): "CASCADE",
    ("ingredient_allergens", "ingredient_id"): "CASCADE",
    ("ingredient_allergens", "allergen_id"): "RESTRICT",
    ("ingredient_tags", "ingredient_id"): "CASCADE",
    ("ingredient_tags", "tag_id"): "RESTRICT",
}


def test_ondelete_policy_matches_expected() -> None:
    actual = {
        (table.name, fk.parent.name): fk.ondelete
        for table in Base.metadata.tables.values()
        for fk in table.foreign_keys
    }
    assert actual == EXPECTED_ONDELETE


@pytest.mark.parametrize("table_name", sorted(REFERENCE_TABLES))
def test_reference_depends_only_on_reference(table_name: str) -> None:
    for fk in _table(table_name).foreign_keys:
        assert fk.column.table.name in REFERENCE_TABLES, f"{table_name} -> {fk.target_fullname}"


def test_foods_identity_constraints() -> None:
    foods = _table("foods")
    assert ("external_source", "external_code") in _unique_column_sets(foods)
    assert ("fdc_id",) in _unique_column_sets(foods)
    assert foods.c.fdc_id.nullable is True
    checks = {str(c.sqltext) for c in foods.constraints if isinstance(c, CheckConstraint)}
    assert "basis_grams = 100" in checks


def test_condition_tag_restrictions_checks() -> None:
    checks = {
        c.name: str(c.sqltext)
        for c in _table("condition_tag_restrictions").constraints
        if isinstance(c, CheckConstraint)
    }
    assert checks["ck_condition_tag_restrictions_max_servings_only_for_limit"] == (
        "restriction_type = 'LIMIT' OR max_servings_per_week IS NULL"
    )
    assert checks["ck_condition_tag_restrictions_max_servings_positive"] == (
        "max_servings_per_week IS NULL OR max_servings_per_week > 0"
    )


def test_ingredient_aliases_search_index() -> None:
    aliases = _table("ingredient_aliases")
    assert ("alias_text", "lang") in _unique_column_sets(aliases)
    gin = [ix for ix in aliases.indexes if ix.dialect_options["postgresql"]["using"] == "gin"]
    assert len(gin) == 1
    assert [c.name for c in gin[0].columns] == ["alias_normalized"]
    assert gin[0].dialect_options["postgresql"]["ops"] == {"alias_normalized": "gin_trgm_ops"}


def test_server_defaults() -> None:
    def default_sql(table: str, column: str) -> str:
        default = _table(table).c[column].server_default
        assert default is not None, f"{table}.{column} has no server default"
        return str(default.arg)  # type: ignore[attr-defined]

    assert default_sql("ingredients", "review_status") == "PENDING"
    assert default_sql("health_conditions", "is_supported") == "false"
    assert default_sql("health_conditions", "fluid_goal_requires_clinician") == "false"
    assert default_sql("nutrients", "is_mandatory") == "false"


# --- DDL smoke test (db_test, docker compose profile "test") ------------------


class _TestDbSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=REPO_ROOT / ".env", extra="ignore")

    POSTGRES_TEST_DB: str
    POSTGRES_TEST_PORT: int = 5433


@pytest.fixture
def test_db_engine() -> Iterator[Engine]:
    try:
        test_settings = _TestDbSettings()
    except Exception as exc:
        pytest.skip(f"POSTGRES_TEST_DB is not configured in .env: {exc}")

    dev_url = make_url(get_settings().DATABASE_URL)
    url = dev_url.set(
        port=test_settings.POSTGRES_TEST_PORT, database=test_settings.POSTGRES_TEST_DB
    )
    assert (url.port, url.database) != (dev_url.port, dev_url.database), "refusing to use dev DB"

    engine = create_engine(url, connect_args={"connect_timeout": 3})
    try:
        engine.connect().close()
    except OperationalError:
        engine.dispose()
        pytest.skip(
            f"db_test is not reachable on {url.host}:{url.port}; "
            "start it with `docker compose --profile test up -d db_test`"
        )
    yield engine
    engine.dispose()


def test_ddl_create_all_and_drop_all(test_db_engine: Engine) -> None:
    with test_db_engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
    try:
        Base.metadata.create_all(test_db_engine)
        created = set(inspect(test_db_engine).get_table_names())
        assert created >= EXPECTED_TABLES
    finally:
        Base.metadata.drop_all(test_db_engine)
    assert not set(inspect(test_db_engine).get_table_names()) & EXPECTED_TABLES
