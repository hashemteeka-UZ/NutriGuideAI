"""API tests share the migrated integrity database; explicit commits stay inside the test."""

from __future__ import annotations

from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_now
from app.api.limiting import limiter
from app.api.main import create_app

NOW = datetime(2026, 10, 12, 9, 0, tzinfo=UTC)


@pytest.fixture
def api_session(integrity_conn: Connection) -> Iterator[Session]:
    session = Session(bind=integrity_conn, join_transaction_mode="create_savepoint")
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def now_clock() -> dict[str, datetime]:
    return {"now": NOW}


@pytest.fixture
def client(api_session: Session, now_clock: dict[str, datetime]) -> Iterator[TestClient]:
    limiter.enabled = False
    application = create_app()

    def override_db() -> Iterator[Session]:
        try:
            yield api_session
        except BaseException:
            api_session.rollback()
            raise

    application.dependency_overrides[get_db] = override_db
    application.dependency_overrides[get_now] = lambda: now_clock["now"]
    test_client = TestClient(application, raise_server_exceptions=False)
    try:
        with test_client:
            yield test_client
    finally:
        application.dependency_overrides.clear()
