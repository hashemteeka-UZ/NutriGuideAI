"""Alembic migration tests on db_test (§34.7, P-02): round-trip, no drift, migrated shape."""

from collections.abc import Iterator
from pathlib import Path

import pytest
from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import inspect, text
from sqlalchemy.engine import Connection, Engine

import app.db.models  # noqa: F401  (registers every model on Base.metadata)
from app.db.base import Base

ALEMBIC_INI = Path(__file__).resolve().parents[1] / "alembic.ini"

PROJECT_TABLES = set(Base.metadata.tables)
SURROGATE_PKS = sorted(
    (table.name, col.name)
    for table in Base.metadata.tables.values()
    for col in table.primary_key.columns
    if len(table.primary_key.columns) == 1 and not col.foreign_keys
)
GIN_TRGM_INDEXES = {
    "ix_ingredient_aliases_alias_normalized",
    "ix_meals_name_normalized",
    "ix_meal_translations_name_normalized",
}
MEAL_PLAN_SLOT_INDEX = "ix_meal_plan_items_plan_id_day_index_slot"
VARIANT_GROUP_INDEX = "ix_meals_variant_group"
MIGRATION_0003_COLUMNS = {
    ("cuisines", "code"),
    ("allergens", "code"),
    ("meals", "variant_group"),
    ("meals", "yield_factor"),
    ("meals", "yield_factor_source"),
    ("meals", "reviewed_by"),
    ("meal_ingredients", "is_optional"),
    ("meal_tags", "rule_version"),
}
MIGRATION_0004_COLUMNS = {
    ("ingredients", "code"),
    ("condition_tag_restrictions", "source_reference"),
}
MIGRATION_0005_COLUMNS = {
    ("user_profiles", "wake_time"),
    ("user_profiles", "sleep_time"),
    ("meals", "dish_form"),
    ("consumption_logs", "entry_group"),
    ("consumption_logs", "entry_label"),
}
MIGRATION_0005_TABLES = {"meal_steps", "user_meal_prefs", "user_cuisine_prefs"}


def _alembic_config(conn: Connection) -> Config:
    """Real alembic.ini, but env.py migrates `conn` (db_test) instead of DATABASE_URL."""
    config = Config(ALEMBIC_INI)
    config.attributes["connection"] = conn
    return config


def _upgrade(engine: Engine, revision: str = "head") -> None:
    with engine.begin() as conn:
        command.upgrade(_alembic_config(conn), revision)


def _downgrade(engine: Engine, revision: str = "base") -> None:
    with engine.begin() as conn:
        command.downgrade(_alembic_config(conn), revision)


def _tables(engine: Engine) -> set[str]:
    return set(inspect(engine).get_table_names())


def _extensions(engine: Engine) -> set[str]:
    with engine.connect() as conn:
        return set(conn.execute(text("SELECT extname FROM pg_extension")).scalars())


def _index_names(engine: Engine) -> set[str]:
    with engine.connect() as conn:
        return set(
            conn.execute(
                text("SELECT indexname FROM pg_indexes WHERE schemaname = 'public'")
            ).scalars()
        )


def _columns(engine: Engine) -> set[tuple[str, str]]:
    with engine.connect() as conn:
        return {
            (row.table_name, row.column_name)
            for row in conn.execute(
                text(
                    "SELECT table_name, column_name FROM information_schema.columns "
                    "WHERE table_schema = 'public'"
                )
            )
        }


def _current_revision(engine: Engine) -> str | None:
    with engine.connect() as conn:
        return MigrationContext.configure(conn).get_current_revision()


@pytest.fixture
def migration_db(test_db_engine: Engine) -> Iterator[Engine]:
    """Empty db_test; downgraded to base and emptied again afterwards."""
    leftovers = _tables(test_db_engine)
    if leftovers:
        pytest.fail(f"db_test is not empty, refusing to run migrations: {sorted(leftovers)}")
    try:
        yield test_db_engine
    finally:
        _downgrade(test_db_engine)
        with test_db_engine.begin() as conn:
            conn.execute(text("DROP TABLE IF EXISTS alembic_version"))
        assert not _tables(test_db_engine)


def test_round_trip_upgrade_downgrade_upgrade(migration_db: Engine) -> None:
    script = ScriptDirectory.from_config(Config(ALEMBIC_INI))
    head = script.get_current_head()
    revisions = [rev.revision for rev in reversed(list(script.walk_revisions()))]
    assert revisions[:5] == ["0001", "0002", "0003", "0004", "0005"]
    assert revisions[-1] == head

    for revision in revisions:
        _upgrade(migration_db, revision)
        assert _current_revision(migration_db) == revision
    assert MEAL_PLAN_SLOT_INDEX in _index_names(migration_db)
    assert _columns(migration_db) >= (
        MIGRATION_0003_COLUMNS | MIGRATION_0004_COLUMNS | MIGRATION_0005_COLUMNS
    )
    assert _tables(migration_db) >= MIGRATION_0005_TABLES
    assert VARIANT_GROUP_INDEX in _index_names(migration_db)

    for revision in reversed(revisions[:-1]):
        _downgrade(migration_db, revision)
        assert _current_revision(migration_db) == revision
        if revision == "0004":
            assert not MIGRATION_0005_COLUMNS & _columns(migration_db)
            assert not MIGRATION_0005_TABLES & _tables(migration_db)
        if revision == "0003":
            assert not MIGRATION_0004_COLUMNS & _columns(migration_db)
        if revision == "0002":
            assert not MIGRATION_0003_COLUMNS & _columns(migration_db)
            assert VARIANT_GROUP_INDEX not in _index_names(migration_db)
    assert MEAL_PLAN_SLOT_INDEX not in _index_names(migration_db)

    _downgrade(migration_db)
    assert _current_revision(migration_db) is None
    assert not _tables(migration_db) & PROJECT_TABLES
    assert "pg_trgm" not in _extensions(migration_db)

    _upgrade(migration_db)
    assert _current_revision(migration_db) == head
    assert _tables(migration_db) >= PROJECT_TABLES


def test_0003_backfills_codes_of_existing_rows(migration_db: Engine) -> None:
    _upgrade(migration_db, "0002")
    with migration_db.begin() as conn:
        conn.execute(text("INSERT INTO cuisines (name_en, name_ar) VALUES ('Libyan', 'ليبي')"))
        conn.execute(
            text("INSERT INTO allergens (name_en, name_ar) VALUES ('Tree nuts', 'مكسرات')")
        )
    _upgrade(migration_db, "0003")
    with migration_db.begin() as conn:
        assert conn.execute(text("SELECT code FROM cuisines")).scalars().all() == ["LIBYAN"]
        assert conn.execute(text("SELECT code FROM allergens")).scalars().all() == ["TREE_NUTS"]
        conn.execute(text("DELETE FROM cuisines"))
        conn.execute(text("DELETE FROM allergens"))


def test_0004_backfills_ingredient_codes_and_restriction_source(migration_db: Engine) -> None:
    _upgrade(migration_db, "0003")
    with migration_db.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO ingredients (canonical_name, canonical_name_ar) "
                "VALUES ('Egg', 'بيض'), ('Low-fat milk (1%)', 'حليب قليل الدسم')"
            )
        )
        conn.execute(
            text(
                "INSERT INTO health_conditions (code, name_en, name_ar) "
                "VALUES ('HYPERTENSION', 'Hypertension', 'ضغط')"
            )
        )
        conn.execute(
            text(
                "INSERT INTO dietary_tags (code, name_en, name_ar, tag_group) "
                "VALUES ('high_sodium', 'High sodium', 'صوديوم', 'CONDITION')"
            )
        )
        conn.execute(
            text(
                "INSERT INTO condition_tag_restrictions "
                "(condition_id, tag_id, restriction_type) "
                "SELECT c.condition_id, t.tag_id, 'LIMIT' "
                "FROM health_conditions c, dietary_tags t "
                "WHERE c.code = 'HYPERTENSION' AND t.code = 'high_sodium'"
            )
        )
    _upgrade(migration_db, "0004")
    with migration_db.begin() as conn:
        codes = dict(conn.execute(text("SELECT canonical_name, code FROM ingredients")).all())
        assert codes == {"Egg": "EGG", "Low-fat milk (1%)": "LOW_FAT_MILK_1"}
        assert conn.execute(
            text("SELECT source_reference FROM condition_tag_restrictions")
        ).all() == [("backfilled by migration 0004; reloaded from the reference seed",)]
        conn.execute(text("DELETE FROM condition_tag_restrictions"))
        conn.execute(text("DELETE FROM dietary_tags"))
        conn.execute(text("DELETE FROM health_conditions"))
        conn.execute(text("DELETE FROM ingredients"))


def test_0004_upgrade_then_loader_matches_existing_ingredients_by_code(
    migration_db: Engine,
) -> None:
    """F.1 rows loaded under 0003 keep their ids after 0004; the loader updates, never inserts.

    The loader runs at head: the current meal model selects columns added in 0005.
    """
    from sqlalchemy.orm import Session

    from app.seed.f1_files import SLICE_FOODS_FILE, read_slice_foods
    from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice

    foods = read_slice_foods(DEFAULT_DATA_DIR / SLICE_FOODS_FILE)
    _upgrade(migration_db, "0003")
    with migration_db.begin() as conn:
        for food in foods.foods:
            conn.execute(
                text(
                    "INSERT INTO ingredients (canonical_name, canonical_name_ar) VALUES (:en, :ar)"
                ),
                {"en": food.ingredient_en, "ar": food.ingredient_ar},
            )
    _upgrade(migration_db, "0004")
    with migration_db.connect() as conn:
        codes = dict(conn.execute(text("SELECT canonical_name, code FROM ingredients")).all())
        assert codes == {f.ingredient_en: f.ingredient_code for f in foods.foods}

    _upgrade(migration_db, "0005")
    with Session(migration_db) as session:
        report = load_f1_slice(session, DEFAULT_DATA_DIR)
        session.commit()

    assert report.ok, report.format()
    assert report.tables["ingredients"].inserted == 0
    assert report.tables["ingredients"].updated >= 0
    with migration_db.connect() as conn:
        assert conn.execute(text("SELECT count(*) FROM ingredients")).scalar_one() == 62
        assert conn.execute(text("SELECT count(DISTINCT code) FROM ingredients")).scalar_one() == 62


def test_0005_existing_profile_receives_wake_and_sleep_defaults(migration_db: Engine) -> None:
    _upgrade(migration_db, "0004")
    with migration_db.begin() as conn:
        user_id = conn.execute(
            text(
                "INSERT INTO users (email, hashed_password) "
                "VALUES ('wake@example.com', 'hashed') RETURNING user_id"
            )
        ).scalar_one()
        conn.execute(
            text(
                "INSERT INTO user_profiles "
                "(user_id, sex, birth_date, height_cm, activity_level, goal_type, timezone) "
                "VALUES (:user_id, 'MALE', '1990-01-01', 170, 'LIGHT', 'MAINTAIN', "
                "'Africa/Tripoli')"
            ),
            {"user_id": user_id},
        )
    _upgrade(migration_db, "0005")
    with migration_db.begin() as conn:
        row = conn.execute(
            text("SELECT wake_time::text, sleep_time::text FROM user_profiles")
        ).one()
        assert row == ("07:00:00", "23:00:00")
        conn.execute(text("DELETE FROM user_profiles"))
        conn.execute(text("DELETE FROM users"))


def test_no_drift_between_migration_and_models(migration_db: Engine) -> None:
    _upgrade(migration_db)
    with migration_db.connect() as conn:
        context = MigrationContext.configure(
            conn, opts={"compare_type": True, "compare_server_default": True}
        )
        diff = compare_metadata(context, Base.metadata)
    assert diff == []


def test_migrated_schema_shape(migration_db: Engine) -> None:
    _upgrade(migration_db)

    assert len(PROJECT_TABLES) == 37
    assert _tables(migration_db) == PROJECT_TABLES | {"alembic_version"}
    assert "pg_trgm" in _extensions(migration_db)

    with migration_db.connect() as conn:
        gin = dict(
            conn.execute(
                text(
                    "SELECT indexname, indexdef FROM pg_indexes "
                    "WHERE schemaname = 'public' AND indexdef LIKE '%USING gin%'"
                )
            ).all()
        )
        identity_columns = {
            tuple(row)
            for row in conn.execute(
                text(
                    "SELECT c.relname, a.attname, a.attidentity::text,"
                    " format_type(a.atttypid, a.atttypmod)"
                    " FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid"
                    " JOIN pg_namespace n ON n.oid = c.relnamespace"
                    " WHERE n.nspname = 'public' AND c.relkind = 'r' AND a.attidentity <> ''"
                )
            )
        }

    assert set(gin) == GIN_TRGM_INDEXES
    assert all("gin_trgm_ops" in indexdef for indexdef in gin.values()), gin

    assert len(SURROGATE_PKS) == 23
    assert identity_columns == {(table, column, "a", "bigint") for table, column in SURROGATE_PKS}
