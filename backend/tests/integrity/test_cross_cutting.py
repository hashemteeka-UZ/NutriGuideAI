"""Cross-cutting integrity: CHECKs, UNIQUEs, FKs, NOT NULL, naming, defaults, identity."""

from __future__ import annotations

from datetime import UTC, datetime

import pytest
from sqlalchemy import delete
from sqlalchemy.engine import Connection
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.orm import Session
from sqlalchemy.sql import text

from app.db.base import Base
from app.db.models.reference import Food
from tests.builders import (
    insert_values,
    make_food,
    make_user,
    values_for,
)
from tests.integrity.check_cases import (
    CHECK_CASES,
    ENUM_INVALID,
    ENUM_ROW_EXTRAS,
    PARTIAL_UNIQUE_CASES,
    UNIQUE_CASES,
    resolve,
)
from tests.integrity.helpers import (
    BAD_ID,
    assert_rejects,
    fetch_by_pk,
    insert_invalid,
    maker,
    pg_btree_leading_columns,
    pg_check_names,
    pg_constraints,
    pg_foreign_keys,
    pg_indexes,
    pg_not_null_without_default,
    pg_partial_unique_index_names,
    pg_unique_names,
)
from tests.test_models_metadata import ENUM_COLUMNS, EXPECTED_ONDELETE, SURROGATE_PK_TABLES

CONSTRAINT_PREFIX = {"p": "pk_", "f": "fk_", "u": "uq_", "c": "ck_"}

DOCUMENTED_DEFAULTS: dict[tuple[str, str], object] = {
    ("meals", "is_active"): True,
    ("meals", "is_verified"): False,
    ("ingredients", "review_status"): "PENDING",
    ("user_health_conditions", "diagnosed"): False,
    ("meal_plan_items", "was_swapped"): False,
    ("user_profiles", "physiological_status"): "NONE",
    ("health_conditions", "fluid_goal_requires_clinician"): False,
    ("health_conditions", "is_supported"): False,
    ("meal_plan_items", "reason_codes"): [],
    ("user_interactions", "context"): {},
    ("nutrients", "is_mandatory"): False,
}

TIMESTAMP_DEFAULT_COLUMNS = (
    ("categories", "created_at"),
    ("categories", "updated_at"),
    ("meals", "ingested_at"),
    ("refresh_tokens", "issued_at"),
    ("users", "created_at"),
)


def _orm_not_null_without_default() -> list[tuple[str, str]]:
    result: list[tuple[str, str]] = []
    for tbl in Base.metadata.tables.values():
        for col in tbl.columns:
            if col.nullable or col.server_default is not None or col.identity is not None:
                continue
            result.append((tbl.name, col.name))
    return result


def test_check_registry_covers_every_pg_check(integrity_conn: Connection) -> None:
    assert pg_check_names(integrity_conn) == set(CHECK_CASES)


@pytest.mark.parametrize("name", sorted(CHECK_CASES))
def test_check_constraint_accepts_boundary(integrity_conn: Connection, name: str) -> None:
    case = CHECK_CASES[name]
    maker(case.table)(integrity_conn, **resolve(case.positive, integrity_conn))


@pytest.mark.parametrize("name", sorted(CHECK_CASES))
def test_check_constraint_rejects_invalid(integrity_conn: Connection, name: str) -> None:
    case = CHECK_CASES[name]
    assert_rejects(
        integrity_conn,
        name,
        lambda: maker(case.table)(integrity_conn, **resolve(case.negative, integrity_conn)),
    )


def test_unique_registry_covers_every_pg_unique(integrity_conn: Connection) -> None:
    assert pg_unique_names(integrity_conn) == set(UNIQUE_CASES)
    assert pg_partial_unique_index_names(integrity_conn) == set(PARTIAL_UNIQUE_CASES)


@pytest.mark.parametrize("name", sorted(UNIQUE_CASES))
def test_unique_duplicate_rejected(integrity_conn: Connection, name: str) -> None:
    case = UNIQUE_CASES[name]
    duplicate = resolve(case.duplicate, integrity_conn)
    maker(case.table)(integrity_conn, **duplicate)
    assert_rejects(
        integrity_conn,
        name,
        lambda: maker(case.table)(integrity_conn, **duplicate),
    )


@pytest.mark.parametrize(
    "name",
    sorted(name for name, case in UNIQUE_CASES.items() if case.nullable),
)
def test_unique_two_nulls_accepted(integrity_conn: Connection, name: str) -> None:
    case = UNIQUE_CASES[name]
    equal = resolve(case.nullable_equal, integrity_conn)
    nulls = dict.fromkeys(case.nullable)
    maker(case.table)(integrity_conn, **equal, **nulls)
    maker(case.table)(integrity_conn, **equal, **nulls)


@pytest.mark.parametrize("name", sorted(PARTIAL_UNIQUE_CASES))
def test_partial_unique_index_duplicate_rejected(integrity_conn: Connection, name: str) -> None:
    case = PARTIAL_UNIQUE_CASES[name]
    duplicate = resolve(case.duplicate, integrity_conn)
    maker(case.table)(integrity_conn, **duplicate)
    assert_rejects(
        integrity_conn,
        name,
        lambda: maker(case.table)(integrity_conn, **duplicate),
    )


@pytest.mark.parametrize("name", sorted(PARTIAL_UNIQUE_CASES))
def test_partial_unique_index_rows_outside_predicate_accepted(
    integrity_conn: Connection, name: str
) -> None:
    case = PARTIAL_UNIQUE_CASES[name]
    excluded = resolve(case.outside_predicate, integrity_conn)
    maker(case.table)(integrity_conn, **excluded)
    maker(case.table)(integrity_conn, **excluded)


def test_fk_catalog_matches_expected_ondelete(integrity_conn: Connection) -> None:
    actual = {(fk.table, fk.column): fk.ondelete for fk in pg_foreign_keys(integrity_conn)}
    assert actual == EXPECTED_ONDELETE
    assert len(actual) == 47


@pytest.mark.parametrize(("table_name", "column"), sorted(EXPECTED_ONDELETE))
def test_fk_invalid_reference_rejected(
    integrity_conn: Connection, table_name: str, column: str
) -> None:
    fks = {(fk.table, fk.column): fk for fk in pg_foreign_keys(integrity_conn)}
    fk = fks[(table_name, column)]
    assert_rejects(
        integrity_conn,
        fk.name,
        lambda: insert_invalid(integrity_conn, table_name, **{column: BAD_ID}),
    )


@pytest.mark.parametrize(("table_name", "column"), sorted(EXPECTED_ONDELETE))
def test_fk_on_delete_action(integrity_conn: Connection, table_name: str, column: str) -> None:
    fks = {(fk.table, fk.column): fk for fk in pg_foreign_keys(integrity_conn)}
    fk = fks[(table_name, column)]
    expected = EXPECTED_ONDELETE[(table_name, column)]
    assert fk.ondelete == expected

    parent_id = maker(fk.referred_table)(integrity_conn)
    child_pk = maker(table_name)(integrity_conn, **{column: parent_id})
    parent_tbl = Base.metadata.tables[fk.referred_table]
    parent_col = parent_tbl.c[fk.referred_column]

    def do_delete() -> None:
        integrity_conn.execute(delete(parent_tbl).where(parent_col == parent_id))

    if expected == "RESTRICT":
        assert_rejects(integrity_conn, fk.name, do_delete)
        assert fetch_by_pk(integrity_conn, table_name, child_pk) is not None
        return
    do_delete()
    if expected == "CASCADE":
        assert fetch_by_pk(integrity_conn, table_name, child_pk) is None
        assert fetch_by_pk(integrity_conn, fk.referred_table, parent_id) is None
        return
    if expected == "SET NULL":
        row = fetch_by_pk(integrity_conn, table_name, child_pk)
        assert row is not None
        assert row._mapping[column] is None
        return
    pytest.fail(f"unexpected ON DELETE {expected}")


def test_not_null_catalog_matches_metadata(integrity_conn: Connection) -> None:
    assert set(pg_not_null_without_default(integrity_conn)) == set(_orm_not_null_without_default())


@pytest.mark.filterwarnings("ignore::sqlalchemy.exc.SAWarning")
@pytest.mark.parametrize(("table_name", "column"), _orm_not_null_without_default())
def test_not_null_omitted_column_rejected(
    integrity_conn: Connection, table_name: str, column: str
) -> None:
    values = values_for(integrity_conn, table_name)
    assert column in values, f"{table_name}.{column} missing from valid-row builder"
    del values[column]
    with pytest.raises(IntegrityError) as caught, integrity_conn.begin_nested():
        insert_values(integrity_conn, table_name, values)
    orig = caught.value.orig
    assert orig.sqlstate == "23502", f"{table_name}.{column}: {caught.value}"
    assert orig.diag.column_name == column


@pytest.mark.parametrize(("table_name", "column"), sorted(ENUM_COLUMNS))
def test_enum_like_out_of_set_value_rejected(
    integrity_conn: Connection, table_name: str, column: str
) -> None:
    enum_cls = ENUM_COLUMNS[(table_name, column)]
    extras = ENUM_ROW_EXTRAS.get((table_name, column), {})
    assert ENUM_INVALID not in {member.value for member in enum_cls}
    assert_rejects(
        integrity_conn,
        f"ck_{table_name}_{column}_valid",
        lambda: insert_invalid(integrity_conn, table_name, **{column: ENUM_INVALID, **extras}),
    )


def test_constraint_names_follow_section_17_convention(integrity_conn: Connection) -> None:
    failures: list[str] = []
    for table_name, conname, contype in pg_constraints(integrity_conn):
        if contype == "n":
            continue
        prefix = CONSTRAINT_PREFIX[contype]
        expected_start = f"{prefix}{table_name}"
        if not conname.startswith(expected_start):
            failures.append(f"{table_name}: {conname} does not start with {expected_start}")
    assert failures == []


def test_index_names_follow_section_17_convention(integrity_conn: Connection) -> None:
    failures: list[str] = []
    for table_name, indexname in pg_indexes(integrity_conn):
        allowed = (
            indexname.startswith(f"ix_{table_name}")
            or indexname.startswith(f"pk_{table_name}")
            or indexname.startswith(f"uq_{table_name}")
        )
        if not allowed:
            failures.append(f"{table_name}: {indexname}")
    assert failures == []


def test_identity_pk_explicit_value_without_overriding_rejected(
    integrity_conn: Connection,
) -> None:
    with pytest.raises(DBAPIError) as caught, integrity_conn.begin_nested():
        integrity_conn.execute(
            text(
                "INSERT INTO categories (category_id, name_en, name_ar) VALUES (12345, 'en', 'ar')"
            )
        )
    assert caught.value.orig.sqlstate == "428C9"


def test_orm_numeric_column_returns_python_float(integrity_conn: Connection) -> None:
    food_id = make_food(integrity_conn, basis_grams=100)
    with Session(bind=integrity_conn) as session:
        food = session.get(Food, food_id)
        assert food is not None
        assert type(food.basis_grams) is float


def test_every_fk_column_indexed_in_pg_index(integrity_conn: Connection) -> None:
    fks = {(fk.table, fk.column) for fk in pg_foreign_keys(integrity_conn)}
    missing = sorted(fks - pg_btree_leading_columns(integrity_conn))
    assert missing == []


def test_surrogate_pks_are_bigint_identity_always(integrity_conn: Connection) -> None:
    rows = integrity_conn.execute(
        text(
            "SELECT c.relname, a.attname, a.attidentity::text, "
            "format_type(a.atttypid, a.atttypmod) "
            "FROM pg_attribute a "
            "JOIN pg_class c ON c.oid = a.attrelid "
            "JOIN pg_namespace n ON n.oid = c.relnamespace "
            "WHERE n.nspname = 'public' AND c.relkind = 'r' AND a.attidentity <> ''"
        )
    )
    actual = {tuple(row) for row in rows}
    expected = set()
    for table_name in SURROGATE_PK_TABLES:
        pk_col = next(iter(Base.metadata.tables[table_name].primary_key.columns))
        expected.add((table_name, pk_col.name, "a", "bigint"))
    assert actual == expected


@pytest.mark.parametrize(("table_name", "column"), sorted(DOCUMENTED_DEFAULTS))
def test_server_default_documented_value(
    integrity_conn: Connection, table_name: str, column: str
) -> None:
    pk = maker(table_name)(integrity_conn)
    row = fetch_by_pk(integrity_conn, table_name, pk)
    assert row is not None
    assert row._mapping[column] == DOCUMENTED_DEFAULTS[(table_name, column)]


@pytest.mark.parametrize(("table_name", "column"), TIMESTAMP_DEFAULT_COLUMNS)
def test_server_default_timestamp_is_set(
    integrity_conn: Connection, table_name: str, column: str
) -> None:
    pk = maker(table_name)(integrity_conn)
    row = fetch_by_pk(integrity_conn, table_name, pk)
    assert row is not None
    value = row._mapping[column]
    assert isinstance(value, datetime)
    assert value.tzinfo is not None
    now = datetime.now(UTC)
    assert abs((now - value).total_seconds()) < 60


def test_verification_8_fk_unique_not_null_and_check_reject(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "fk_foods_category_id_categories",
        lambda: insert_invalid(integrity_conn, "foods", category_id=BAD_ID),
    )
    make_user(integrity_conn, email="once@example.com")
    assert_rejects(
        integrity_conn,
        "uq_users_email",
        lambda: insert_invalid(integrity_conn, "users", email="once@example.com"),
    )
    values = values_for(integrity_conn, "categories")
    del values["name_en"]
    with pytest.raises(IntegrityError) as caught, integrity_conn.begin_nested():
        insert_values(integrity_conn, "categories", values)
    assert caught.value.orig.sqlstate == "23502"
    assert_rejects(
        integrity_conn,
        "ck_meals_servings_positive",
        lambda: insert_invalid(integrity_conn, "meals", servings=0),
    )
