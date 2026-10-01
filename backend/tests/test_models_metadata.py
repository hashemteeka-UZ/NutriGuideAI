"""Structural checks on Base.metadata (Step C) plus a DDL smoke test on db_test."""

from enum import StrEnum

import pytest
from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Integer,
    MetaData,
    Numeric,
    PrimaryKeyConstraint,
    SmallInteger,
    String,
    Table,
    UniqueConstraint,
    Uuid,
    inspect,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.engine import Engine

import app.db.models  # noqa: F401  (registers every model on Base.metadata)
from app.db.base import Base
from app.db.models import catalog as cat
from app.db.models import reference as ref
from app.db.models import user as usr

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

CATALOG_TABLES = {
    "meals",
    "meal_ingredients",
    "meal_nutrients",
    "meal_allergens",
    "meal_tags",
    "meal_translations",
}

USER_TABLES = {
    "users",
    "user_profiles",
    "user_health_conditions",
    "user_allergen_prefs",
    "user_ingredient_prefs",
    "user_interactions",
    "meal_plans",
    "meal_plan_items",
    "consumption_logs",
    "weight_logs",
    "user_targets",
    "refresh_tokens",
    "water_logs",
}

EXPECTED_TABLES = REFERENCE_TABLES | CATALOG_TABLES | USER_TABLES

# §8 dependency direction: tables each domain may reference.
ALLOWED_FK_TARGETS = {
    **dict.fromkeys(REFERENCE_TABLES, REFERENCE_TABLES),
    **dict.fromkeys(CATALOG_TABLES, REFERENCE_TABLES | CATALOG_TABLES),
    **dict.fromkeys(USER_TABLES, EXPECTED_TABLES),
}

# Composite PKs (§9.8, §9.12, §9.13, §10.2-§10.6, §11.4, §11.5).
COMPOSITE_PK = {
    "food_nutrients": ("food_id", "nutrient_id"),
    "ingredient_allergens": ("ingredient_id", "allergen_id"),
    "ingredient_tags": ("ingredient_id", "tag_id"),
    "meal_ingredients": ("meal_id", "position"),
    "meal_nutrients": ("meal_id", "nutrient_id"),
    "meal_allergens": ("meal_id", "allergen_id"),
    "meal_tags": ("meal_id", "tag_id"),
    "meal_translations": ("meal_id", "lang"),
    "user_allergen_prefs": ("user_id", "allergen_id"),
    "user_ingredient_prefs": ("user_id", "ingredient_id"),
}
# Composite-PK columns that are not foreign keys.
NON_FK_PK_COLUMNS = {("meal_ingredients", "position"), ("meal_translations", "lang")}
# Single-column PKs that are also the FK to the parent (1:1, §11.2).
FK_AS_PK = {"user_profiles": "user_id"}
SURROGATE_PK_TABLES = sorted(EXPECTED_TABLES - COMPOSITE_PK.keys() - FK_AS_PK.keys())

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
    "meals",
    "users",
    "user_profiles",
    "user_health_conditions",
    "user_allergen_prefs",
    "user_ingredient_prefs",
    "meal_plans",
    "meal_plan_items",
    "weight_logs",
}
# weight_logs.updated_at is client-supplied (§11.10), so the ORM must not maintain it.
CLIENT_UPDATED_AT_TABLES = {"weight_logs"}
APPEND_ONLY_TABLES = {
    "consumption_logs",
    "water_logs",
    "user_interactions",
    "user_targets",
    "refresh_tokens",
}
# refresh_tokens.issued_at serves as created_at (§15.10).
CREATED_AT_COLUMN = {"refresh_tokens": "issued_at"}
NO_AUDIT_TABLES = {
    "food_nutrients",
    "portions_food",
    "ingredient_aliases",
    "ingredient_allergens",
    "ingredient_tags",
    "meal_ingredients",
    "meal_nutrients",
    "meal_allergens",
    "meal_tags",
    "meal_translations",
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
    ("meals", "weight_method"): cat.WeightMethod,
    ("meals", "quality_tier"): cat.QualityTier,
    ("meal_tags", "source"): cat.MealTagSource,
    ("user_profiles", "sex"): usr.Sex,
    ("user_profiles", "activity_level"): usr.ActivityLevel,
    ("user_profiles", "goal_type"): usr.GoalType,
    ("user_profiles", "physiological_status"): usr.PhysiologicalStatus,
    ("user_health_conditions", "severity"): usr.ConditionSeverity,
    ("user_allergen_prefs", "severity"): usr.AllergenSeverity,
    ("user_ingredient_prefs", "stance"): usr.IngredientStance,
    ("user_interactions", "event_type"): usr.InteractionEventType,
    ("meal_plan_items", "slot"): usr.MealSlot,
    ("consumption_logs", "slot"): usr.MealSlot,
    ("weight_logs", "source"): usr.WeightSource,
    ("user_targets", "reason"): usr.TargetReason,
}

# §15.2 precision exceptions; every other Numeric column is NUMERIC(12,3).
NUMERIC_PRECISION_EXCEPTIONS = {
    ("ingredient_aliases", "confidence"): (4, 3),
    ("meal_ingredients", "mapping_confidence"): (4, 3),
    ("meal_plan_items", "servings_multiplier"): (3, 2),
}

# Client-generated identifiers (§15.1, §33.4).
CLIENT_UUID_TABLES = ["user_interactions", "consumption_logs", "water_logs"]

# §15.5 ISO 639-1 language-code columns.
LANG_COLUMNS = [
    ("ingredient_aliases", "lang"),
    ("meals", "default_lang"),
    ("meal_translations", "lang"),
]

# §15.9 normalized search columns with a GIN pg_trgm index.
TRIGRAM_COLUMNS = [
    ("ingredient_aliases", "alias_normalized"),
    ("meals", "name_normalized"),
    ("meal_translations", "name_normalized"),
]

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
        is_fk = bool(col.foreign_keys)
        assert is_fk != ((table_name, col.name) in NON_FK_PK_COLUMNS), f"{table_name}.{col.name}"
        assert col.identity is None


@pytest.mark.parametrize(("table_name", "column"), sorted(FK_AS_PK.items()))
def test_fk_as_pk(table_name: str, column: str) -> None:
    table = _table(table_name)
    assert [c.name for c in table.primary_key.columns] == [column]
    col = table.c[column]
    assert col.foreign_keys
    assert col.identity is None
    assert isinstance(col.type, BigInteger)


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
def test_numeric_precision(table_name: str) -> None:
    for col in _table(table_name).columns:
        if isinstance(col.type, Numeric):
            expected = NUMERIC_PRECISION_EXCEPTIONS.get((table_name, col.name), (12, 3))
            actual = (col.type.precision, col.type.scale)
            assert actual == expected, f"{table_name}.{col.name}"


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
    table = _table(table_name)
    columns = set(table.columns.keys())
    if table_name in MUTABLE_TABLES:
        assert {"created_at", "updated_at"} <= columns
        updated_at = table.c.updated_at
        assert updated_at.nullable is False
        if table_name in CLIENT_UPDATED_AT_TABLES:
            assert updated_at.onupdate is None
            assert updated_at.server_default is None
        else:
            assert updated_at.onupdate is not None
            assert updated_at.server_default is not None
    elif table_name in APPEND_ONLY_TABLES:
        assert "updated_at" not in columns
        created = CREATED_AT_COLUMN.get(table_name, "created_at")
        assert created in columns
        if created != "created_at":
            assert "created_at" not in columns
    elif table_name in NO_AUDIT_TABLES:
        assert not {"created_at", "updated_at"} & columns
    else:
        pytest.fail(f"{table_name} is not assigned to a §15.10 class in this test")
    for name in ("created_at", "updated_at", CREATED_AT_COLUMN.get(table_name)):
        if name in columns:
            col_type = table.c[name].type
            assert isinstance(col_type, DateTime) and col_type.timezone is True, name


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
    ("meals", "cuisine_id"): "RESTRICT",
    ("meal_ingredients", "meal_id"): "CASCADE",
    ("meal_ingredients", "ingredient_id"): "RESTRICT",
    ("meal_ingredients", "food_id"): "SET NULL",
    ("meal_nutrients", "meal_id"): "CASCADE",
    ("meal_nutrients", "nutrient_id"): "RESTRICT",
    ("meal_allergens", "meal_id"): "CASCADE",
    ("meal_allergens", "allergen_id"): "RESTRICT",
    ("meal_tags", "meal_id"): "CASCADE",
    ("meal_tags", "tag_id"): "RESTRICT",
    ("meal_translations", "meal_id"): "CASCADE",
    ("user_profiles", "user_id"): "CASCADE",
    ("user_health_conditions", "user_id"): "CASCADE",
    ("user_health_conditions", "condition_id"): "RESTRICT",
    ("user_allergen_prefs", "user_id"): "CASCADE",
    ("user_allergen_prefs", "allergen_id"): "RESTRICT",
    ("user_ingredient_prefs", "user_id"): "CASCADE",
    ("user_ingredient_prefs", "ingredient_id"): "RESTRICT",
    ("user_interactions", "user_id"): "CASCADE",
    ("user_interactions", "meal_id"): "RESTRICT",
    ("meal_plans", "user_id"): "CASCADE",
    ("meal_plans", "target_id"): "SET NULL",
    ("meal_plan_items", "plan_id"): "CASCADE",
    ("meal_plan_items", "meal_id"): "RESTRICT",
    ("consumption_logs", "user_id"): "CASCADE",
    ("consumption_logs", "plan_item_id"): "SET NULL",
    ("consumption_logs", "meal_id"): "RESTRICT",
    ("consumption_logs", "food_id"): "RESTRICT",
    ("weight_logs", "user_id"): "CASCADE",
    ("user_targets", "user_id"): "CASCADE",
    ("refresh_tokens", "user_id"): "CASCADE",
    ("refresh_tokens", "replaced_by_token_id"): "SET NULL",
    ("water_logs", "user_id"): "CASCADE",
}


def test_ondelete_policy_matches_expected() -> None:
    actual = {
        (table.name, fk.parent.name): fk.ondelete
        for table in Base.metadata.tables.values()
        for fk in table.foreign_keys
    }
    assert actual == EXPECTED_ONDELETE


@pytest.mark.parametrize("table_name", sorted(EXPECTED_TABLES))
def test_dependency_direction(table_name: str) -> None:
    allowed = ALLOWED_FK_TARGETS[table_name]
    for fk in _table(table_name).foreign_keys:
        assert fk.column.table.name in allowed, f"{table_name} -> {fk.target_fullname}"


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


def test_ingredient_aliases_unique_text_per_lang() -> None:
    assert ("alias_text", "lang") in _unique_column_sets(_table("ingredient_aliases"))


@pytest.mark.parametrize(("table_name", "column"), TRIGRAM_COLUMNS)
def test_trigram_search_index(table_name: str, column: str) -> None:
    table = _table(table_name)
    assert table.c[column].nullable is False
    gin = [ix for ix in table.indexes if ix.dialect_options["postgresql"]["using"] == "gin"]
    assert len(gin) == 1
    assert [c.name for c in gin[0].columns] == [column]
    assert gin[0].dialect_options["postgresql"]["ops"] == {column: "gin_trgm_ops"}


@pytest.mark.parametrize(("table_name", "column"), LANG_COLUMNS)
def test_language_code_column(table_name: str, column: str) -> None:
    table = _table(table_name)
    col_type = table.c[column].type
    assert isinstance(col_type, String)
    assert col_type.length == 2
    assert table.c[column].nullable is False
    checks = {str(c.sqltext) for c in table.constraints if isinstance(c, CheckConstraint)}
    assert f"{column} ~ '^[a-z]{{2}}$'" in checks


def _checks(table_name: str) -> set[str]:
    return {
        str(c.sqltext) for c in _table(table_name).constraints if isinstance(c, CheckConstraint)
    }


def test_meals_columns_and_checks() -> None:
    meals = _table("meals")
    assert not {"owner_user_id", "visibility"} & set(meals.columns.keys())
    assert isinstance(meals.c.servings.type, Integer)
    assert meals.c.cuisine_id.nullable is True
    assert meals.c.ref_external.nullable is True
    assert meals.c.source_license.nullable is False
    assert ("source", "ref_external") in _unique_column_sets(meals)
    assert {"servings > 0", "total_grams > 0"} <= _checks("meals")


def test_meal_translations_description_is_optional() -> None:
    assert _table("meal_translations").c.description.nullable is True
    assert "description" not in _table("meals").columns


def test_meal_ingredients_columns_and_checks() -> None:
    table = _table("meal_ingredients")
    assert isinstance(table.c.position.type, Integer)
    assert table.c.food_id.nullable is True
    assert table.c.ingredient_id.nullable is False
    assert table.c.text_original.nullable is True
    assert {
        "grams > 0",
        "position >= 1",
        "mapping_confidence BETWEEN 0 AND 1",
    } <= _checks("meal_ingredients")


def test_meal_nutrients_not_null_and_non_negative() -> None:
    table = _table("meal_nutrients")
    for column in ("amount_per_serving", "amount_per_100g", "computed_at", "computation_version"):
        assert table.c[column].nullable is False, column
    assert {"amount_per_serving >= 0", "amount_per_100g >= 0"} <= _checks("meal_nutrients")


def test_server_defaults() -> None:
    def default_sql(table: str, column: str) -> str:
        default = _table(table).c[column].server_default
        assert default is not None, f"{table}.{column} has no server default"
        return str(default.arg)  # type: ignore[attr-defined]

    assert default_sql("ingredients", "review_status") == "PENDING"
    assert default_sql("health_conditions", "is_supported") == "false"
    assert default_sql("health_conditions", "fluid_goal_requires_clinician") == "false"
    assert default_sql("nutrients", "is_mandatory") == "false"
    assert default_sql("meals", "is_active") == "true"
    assert default_sql("meals", "is_verified") == "false"
    assert default_sql("meals", "ingested_at") == "now()"
    assert default_sql("user_profiles", "physiological_status") == "NONE"
    assert default_sql("user_health_conditions", "diagnosed") == "false"
    assert default_sql("meal_plan_items", "reason_codes") == "[]"
    assert default_sql("user_interactions", "context") == "{}"
    assert default_sql("meal_plan_items", "was_swapped") == "false"
    assert default_sql("refresh_tokens", "issued_at") == "now()"


# --- USER domain (§11) ---------------------------------------------------------


def _indexes(table_name: str) -> set[tuple[tuple[str, ...], bool, str | None]]:
    """(columns, unique, partial WHERE) for every index on the table."""
    result = set()
    for index in _table(table_name).indexes:
        where = index.dialect_options["postgresql"]["where"]
        cols = tuple(c.name for c in index.columns)
        result.add((cols, bool(index.unique), None if where is None else str(where)))
    return result


def test_users_email_unique_and_lowercase() -> None:
    assert ("email",) in _unique_column_sets(_table("users"))
    assert "email = lower(email)" in _checks("users")
    assert _table("users").c.hashed_password.nullable is False


def test_user_profiles_columns_and_checks() -> None:
    table = _table("user_profiles")
    for column in ("target_weight_kg", "weekly_rate_kg", "water_goal_ml"):
        assert table.c[column].nullable is True, column
    for column in ("sex", "birth_date", "height_cm", "timezone", "physiological_status"):
        assert table.c[column].nullable is False, column
    assert isinstance(table.c.water_goal_ml.type, Integer)
    assert not {"weight_kg", "target_kcal", "targets_computed_at"} & set(table.columns.keys())
    assert {
        "height_cm BETWEEN 100 AND 250",
        "target_weight_kg BETWEEN 30 AND 300",
        "weekly_rate_kg > 0 AND weekly_rate_kg <= 1.0",
        "water_goal_ml BETWEEN 500 AND 5000",
        "sex = 'FEMALE' OR physiological_status = 'NONE'",
        "goal_type = 'MAINTAIN' OR (target_weight_kg IS NOT NULL AND weekly_rate_kg IS NOT NULL)",
    } <= _checks("user_profiles")
    names = {c.name for c in table.constraints if isinstance(c, CheckConstraint)}
    assert "ck_user_profiles_water_goal_range" in names


def test_user_health_conditions_unique_and_optional_severity() -> None:
    table = _table("user_health_conditions")
    assert ("user_id", "condition_id") in _unique_column_sets(table)
    assert table.c.severity.nullable is True
    assert table.c.diagnosed.nullable is False


def test_user_interactions_value_and_index() -> None:
    table = _table("user_interactions")
    assert isinstance(table.c.value.type, SmallInteger)
    assert table.c.value.nullable is True
    assert {
        "value IS NULL OR value BETWEEN 1 AND 5",
        "event_type <> 'RATE' OR value IS NOT NULL",
    } <= _checks("user_interactions")
    assert isinstance(table.c.context.type, JSONB)
    assert table.c.context.nullable is False
    assert (("user_id", "created_at"), False, None) in _indexes("user_interactions")


@pytest.mark.parametrize("table_name", CLIENT_UUID_TABLES)
def test_client_uuid_is_nullable_unique_uuid(table_name: str) -> None:
    col = _table(table_name).c.client_uuid
    assert isinstance(col.type, Uuid)
    assert col.nullable is True
    assert ("client_uuid",) in _unique_column_sets(_table(table_name))


def test_meal_plans_columns_and_index() -> None:
    table = _table("meal_plans")
    assert table.c.target_id.nullable is True
    assert isinstance(table.c.target_snapshot.type, JSONB)
    assert "date_to >= date_from" in _checks("meal_plans")
    assert (("user_id", "date_from"), False, None) in _indexes("meal_plans")


def test_meal_plan_items_columns_and_checks() -> None:
    table = _table("meal_plan_items")
    assert "was_consumed" not in table.columns
    multiplier = table.c.servings_multiplier.type
    assert isinstance(multiplier, Numeric)
    assert (multiplier.precision, multiplier.scale) == (3, 2)
    assert isinstance(table.c.reason_codes.type, JSONB)
    assert table.c.reason_codes.nullable is False
    assert {
        "servings_multiplier IN (0.5, 1.0, 1.5, 2.0)",
        "day_index >= 0",
    } <= _checks("meal_plan_items")


def test_consumption_logs_columns_and_checks() -> None:
    table = _table("consumption_logs")
    for column in ("slot", "plan_item_id", "meal_id", "food_id", "deleted_at"):
        assert table.c[column].nullable is True, column
    for column in ("consumed_at", "log_date", "nutrients_snapshot"):
        assert table.c[column].nullable is False, column
    assert {
        "(meal_id IS NOT NULL) <> (food_id IS NOT NULL)",
        "meal_id IS NULL OR (servings_consumed > 0 AND grams_consumed IS NULL)",
        "food_id IS NULL OR (grams_consumed > 0 AND servings_consumed IS NULL)",
        "plan_item_id IS NULL OR meal_id IS NOT NULL",
    } <= _checks("consumption_logs")


@pytest.mark.parametrize("table_name", ["consumption_logs", "water_logs"])
def test_tombstoned_log_indexes(table_name: str) -> None:
    indexes = _indexes(table_name)
    assert (("user_id", "log_date"), False, "deleted_at IS NULL") in indexes
    assert (("user_id",), False, None) in indexes


def test_weight_logs_one_per_day() -> None:
    table = _table("weight_logs")
    assert ("user_id", "measured_on") in _unique_column_sets(table)
    assert "weight_kg BETWEEN 20 AND 400" in _checks("weight_logs")


def test_user_targets_indexes_and_checks() -> None:
    indexes = _indexes("user_targets")
    assert (("user_id",), True, "valid_to IS NULL") in indexes
    assert (("user_id", "valid_from"), False, None) in indexes
    assert "valid_to IS NULL OR valid_to > valid_from" in _checks("user_targets")
    table = _table("user_targets")
    assert table.c.valid_to.nullable is True
    assert table.c.was_floor_applied.nullable is False


def test_refresh_tokens_columns_and_indexes() -> None:
    table = _table("refresh_tokens")
    assert ("token_hash",) in _unique_column_sets(table)
    assert isinstance(table.c.family_id.type, Uuid)
    assert table.c.family_id.nullable is False
    assert table.c.revoked_at.nullable is True
    assert table.c.replaced_by_token_id.nullable is True
    (fk,) = table.c.replaced_by_token_id.foreign_keys
    assert fk.column.table.name == "refresh_tokens"
    assert "expires_at > issued_at" in _checks("refresh_tokens")
    indexes = _indexes("refresh_tokens")
    assert (("user_id",), False, None) in indexes
    assert (("family_id",), False, None) in indexes


def test_water_logs_amount_range() -> None:
    table = _table("water_logs")
    assert isinstance(table.c.amount_ml.type, Integer)
    names = {c.name for c in table.constraints if isinstance(c, CheckConstraint)}
    assert "ck_water_logs_amount_range" in names
    assert "amount_ml BETWEEN 1 AND 2000" in _checks("water_logs")


# --- DDL smoke test (db_test, fixture in conftest.py) -------------------------


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
