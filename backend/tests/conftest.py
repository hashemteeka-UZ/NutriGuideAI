"""Shared fixtures. db_test is the throwaway database of the docker compose profile "test"."""

from __future__ import annotations

import os
import re
from collections.abc import Iterator
from pathlib import Path
from typing import NoReturn

import pytest
from alembic import command
from alembic.config import Config
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Connection, Engine, make_url
from sqlalchemy.exc import OperationalError

from app.core.config import REPO_ROOT, get_settings

ALEMBIC_INI = Path(__file__).resolve().parents[1] / "alembic.ini"
_DB_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")


class _TestDbSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=REPO_ROOT / ".env", extra="ignore")

    POSTGRES_TEST_DB: str
    POSTGRES_TEST_PORT: int = 5433


def _skip_or_fail_ci(message: str) -> NoReturn:
    if os.environ.get("CI") == "true":
        pytest.fail(message)
    pytest.skip(message)


def _alembic_config(conn: Connection) -> Config:
    """Real alembic.ini, but env.py migrates `conn` instead of DATABASE_URL."""
    config = Config(ALEMBIC_INI)
    config.attributes["connection"] = conn
    return config


def _require_db_name(name: str) -> str:
    if not _DB_NAME_RE.match(name):
        raise ValueError(f"refusing to use database name {name!r}")
    return name


def _test_db_url() -> URL:
    try:
        test_settings = _TestDbSettings()
    except Exception as exc:
        _skip_or_fail_ci(f"POSTGRES_TEST_DB is not configured in .env: {exc}")

    dev_url = make_url(get_settings().DATABASE_URL)
    url = dev_url.set(
        port=test_settings.POSTGRES_TEST_PORT, database=test_settings.POSTGRES_TEST_DB
    )
    assert (url.port, url.database) != (dev_url.port, dev_url.database), "refusing to use dev DB"
    return url


@pytest.fixture
def test_db_engine() -> Iterator[Engine]:
    url = _test_db_url()
    engine = create_engine(url, connect_args={"connect_timeout": 3})
    try:
        engine.connect().close()
    except OperationalError:
        engine.dispose()
        _skip_or_fail_ci(
            f"db_test is not reachable on {url.host}:{url.port}; "
            "start it with `docker compose --profile test up -d db_test`"
        )
    yield engine
    engine.dispose()


def _drop_database(admin: Engine, name: str) -> None:
    ident = _require_db_name(name)
    with admin.connect() as conn:
        conn.execute(text(f"DROP DATABASE IF EXISTS {ident} WITH (FORCE)"))


@pytest.fixture(scope="session")
def integrity_engine() -> Iterator[Engine]:
    """Migrated sibling of db_test: `{POSTGRES_TEST_DB}_integrity`. Not create_all."""
    url = _test_db_url()
    admin = create_engine(url, isolation_level="AUTOCOMMIT", connect_args={"connect_timeout": 3})
    try:
        admin.connect().close()
    except OperationalError:
        admin.dispose()
        _skip_or_fail_ci(
            f"db_test is not reachable on {url.host}:{url.port}; "
            "start it with `docker compose --profile test up -d db_test`"
        )

    integrity_name = _require_db_name(f"{url.database}_integrity")
    engine: Engine | None = None
    created = False
    try:
        _drop_database(admin, integrity_name)
        with admin.connect() as conn:
            conn.execute(text(f"CREATE DATABASE {integrity_name}"))
        created = True
        engine = create_engine(url.set(database=integrity_name))
        with engine.begin() as conn:
            command.upgrade(_alembic_config(conn), "head")
        yield engine
    finally:
        if engine is not None:
            engine.dispose()
        if created:
            _drop_database(admin, integrity_name)
        admin.dispose()


@pytest.fixture
def integrity_conn(integrity_engine: Engine) -> Iterator[Connection]:
    """Per-test connection; outer transaction rolls back. SAVEPOINTs isolate IntegrityError."""
    connection = integrity_engine.connect()
    trans = connection.begin()
    try:
        yield connection
    finally:
        trans.rollback()
        connection.close()


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    if os.environ.get("CI") != "true":
        return
    reporter = session.config.pluginmanager.get_plugin("terminalreporter")
    if reporter is None:
        return
    skipped = reporter.stats.get("skipped", [])
    if skipped:
        session.exitstatus = pytest.ExitCode.TESTS_FAILED
