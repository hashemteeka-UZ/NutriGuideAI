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
    assert revisions[:2] == ["0001", "0002"]
    assert revisions[-1] == head

    for revision in revisions:
        _upgrade(migration_db, revision)
        assert _current_revision(migration_db) == revision
    assert MEAL_PLAN_SLOT_INDEX in _index_names(migration_db)

    for revision in reversed(revisions[:-1]):
        _downgrade(migration_db, revision)
        assert _current_revision(migration_db) == revision
    assert MEAL_PLAN_SLOT_INDEX not in _index_names(migration_db)

    _downgrade(migration_db)
    assert _current_revision(migration_db) is None
    assert not _tables(migration_db) & PROJECT_TABLES
    assert "pg_trgm" not in _extensions(migration_db)

    _upgrade(migration_db)
    assert _current_revision(migration_db) == head
    assert _tables(migration_db) >= PROJECT_TABLES


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

    assert len(PROJECT_TABLES) == 34
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
