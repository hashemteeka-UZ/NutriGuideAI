"""GET /api/v1/health reads the database and reports one catalog version."""

from __future__ import annotations

import logging
from collections.abc import Iterator

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.api.main import create_app
from app.db.models import Meal
from tests.builders import make_meal, values_meals


def test_health_returns_ok_with_exact_keys(client: TestClient) -> None:
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "api_version": "0.7.0",
        "database": "ok",
        "dataset_version": None,
        "default_planner": "cpsat",
    }


def test_health_dataset_version_matches_the_manifest_when_batches_match(
    client: TestClient, integrity_conn: Connection
) -> None:
    for version in (
        "team_recipes_v1",
        "team_recipes_v2",
        "team_recipes_v3",
        "team_recipes_v4",
        "team_recipes_v5",
    ):
        make_meal(integrity_conn, dataset_version=version, is_active=True)
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json()["dataset_version"] == "catalog_v3"
    assert response.json()["default_planner"] == "cpsat"
    reference = client.get("/api/v1/reference")
    assert reference.status_code == 200
    assert reference.json()["dataset_version"] == "catalog_v3"


def test_health_dataset_version_is_none_when_active_versions_differ(
    client: TestClient, integrity_conn: Connection
) -> None:
    make_meal(integrity_conn, dataset_version="v-a", is_active=True)
    make_meal(integrity_conn, dataset_version="v-b", is_active=True)
    records: list[logging.LogRecord] = []

    class _Capture(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            records.append(record)

    handler = _Capture()
    version_log = logging.getLogger("app.services.catalog_version")
    version_log.addHandler(handler)
    version_log.setLevel(logging.WARNING)
    try:
        response = client.get("/api/v1/health")
    finally:
        version_log.removeHandler(handler)
    assert response.status_code == 200
    assert response.json()["dataset_version"] is None
    warnings = [record for record in records if record.levelno >= logging.WARNING]
    assert len(warnings) == 1
    assert "expected" in warnings[0].getMessage()
    assert "found" in warnings[0].getMessage()


def test_health_returns_database_unavailable_when_execute_raises() -> None:
    application = create_app()

    class _FailingSession:
        def execute(self, *_args: object, **_kwargs: object) -> None:
            raise OperationalError("SELECT 1", {}, Exception("down"))

    def override_db() -> Iterator[_FailingSession]:
        yield _FailingSession()

    application.dependency_overrides[get_db] = override_db
    with TestClient(application, raise_server_exceptions=False) as test_client:
        response = test_client.get("/api/v1/health")
    assert response.status_code == 503
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["code"] == "DATABASE_UNAVAILABLE"
    assert body["status"] == 503
    assert body["title"] == "Database unavailable"
    assert "detail" not in body


def test_row_committed_through_api_session_is_visible(
    api_session: Session, integrity_conn: Connection
) -> None:
    before = integrity_conn.execute(select(func.count()).select_from(Meal)).scalar_one()
    values = values_meals(integrity_conn, dataset_version="commit-visible")
    api_session.add(Meal(**values))
    api_session.commit()
    after = api_session.execute(select(func.count()).select_from(Meal)).scalar_one()
    assert after == before + 1
    stored = api_session.scalars(select(Meal).where(Meal.dataset_version == "commit-visible")).one()
    assert stored.name == values["name"]


def test_explicit_commit_is_rolled_back_after_the_test(integrity_engine: Engine) -> None:
    with integrity_engine.connect() as connection:
        count = connection.execute(select(func.count()).select_from(Meal)).scalar_one()
    assert count == 0
