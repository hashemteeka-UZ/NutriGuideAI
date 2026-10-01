"""Shared fixtures. db_test is the throwaway database of the docker compose profile "test"."""

from collections.abc import Iterator

import pytest
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine, make_url
from sqlalchemy.exc import OperationalError

from app.core.config import REPO_ROOT, get_settings


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
