"""Shared fixtures. db_test is the throwaway database of the docker compose profile "test"."""

from __future__ import annotations

import os
from collections.abc import Iterator
from typing import NoReturn

import pytest
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.engine import URL, Connection, Engine, make_url
from sqlalchemy.exc import OperationalError

from app.core.config import REPO_ROOT, get_settings
from app.db.admin import admin_engine, create_database, drop_database, require_db_name, upgrade_head

# Test-only. Overrides .env so the suite never signs tokens with a developer secret,
# and so auth routes are not rate-limited unless a test turns the limiter on.
# Must run before any test module imports the app (collection imports this file first).
os.environ["JWT_SECRET"] = "test-only-jwt-secret-not-for-production-use"
os.environ["RATE_LIMIT_ENABLED"] = "false"


class _TestDbSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=REPO_ROOT / ".env", extra="ignore")

    POSTGRES_TEST_DB: str
    POSTGRES_TEST_PORT: int = 5433


def _skip_or_fail_ci(message: str) -> NoReturn:
    if os.environ.get("CI") == "true":
        pytest.fail(message)
    pytest.skip(message)


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


@pytest.fixture(scope="session")
def integrity_engine() -> Iterator[Engine]:
    """Migrated sibling of db_test: `{POSTGRES_TEST_DB}_integrity`. Not create_all."""
    url = _test_db_url()
    admin = admin_engine(url)
    try:
        admin.connect().close()
    except OperationalError:
        admin.dispose()
        _skip_or_fail_ci(
            f"db_test is not reachable on {url.host}:{url.port}; "
            "start it with `docker compose --profile test up -d db_test`"
        )

    integrity_name = require_db_name(f"{url.database}_integrity")
    engine: Engine | None = None
    created = False
    try:
        drop_database(admin, integrity_name)
        create_database(admin, integrity_name)
        created = True
        engine = create_engine(url.set(database=integrity_name))
        upgrade_head(engine)
        yield engine
    finally:
        if engine is not None:
            engine.dispose()
        if created:
            drop_database(admin, integrity_name)
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
