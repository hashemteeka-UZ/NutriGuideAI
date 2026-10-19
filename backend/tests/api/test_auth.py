"""Register, login, refresh, logout, and the access-token dependency."""

from __future__ import annotations

import logging
from collections.abc import Iterator
from datetime import datetime, timedelta

import jwt
import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_now
from app.api.limiting import limiter
from app.api.main import create_app
from app.core.config import get_settings
from tests.api.conftest import NOW

PASSWORD = "purple-platypus-password-42"
EMAIL = "User@Example.com"


def _problem(response: Response) -> dict[str, object]:
    body: dict[str, object] = response.json()
    body.pop("request_id", None)
    return body


def _register(
    client: TestClient, email: str = EMAIL, password: str = PASSWORD
) -> dict[str, object]:
    response = client.post("/api/v1/auth/register", json={"email": email, "password": password})
    assert response.status_code == 201, response.text
    return response.json()


@pytest.fixture
def clocked(api_session: Session) -> Iterator[tuple[TestClient, dict[str, datetime]]]:
    state: dict[str, datetime] = {"now": NOW}
    limiter.enabled = False
    application = create_app()

    def override_db() -> Iterator[Session]:
        yield api_session

    application.dependency_overrides[get_db] = override_db
    application.dependency_overrides[get_now] = lambda: state["now"]
    with TestClient(application, raise_server_exceptions=False) as test_client:
        yield test_client, state


def test_register_returns_tokens_and_stores_the_email_in_lower_case(client: TestClient) -> None:
    body = _register(client)
    assert body["expires_in"] == 900
    assert body["token_type"] == "bearer"
    me = client.get("/api/v1/me", headers={"Authorization": f"Bearer {body['access_token']}"})
    assert me.status_code == 200
    assert me.json()["email"] == "user@example.com"
    assert me.json()["has_profile"] is False


def test_duplicate_email_is_taken_in_any_case(client: TestClient) -> None:
    _register(client, "user@example.com")
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "USER@example.com", "password": PASSWORD},
    )
    assert response.status_code == 409
    assert response.json()["code"] == "EMAIL_TAKEN"


def test_short_password_is_rejected(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "user@example.com", "password": "short"},
    )
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"


def test_login_and_identical_failures(client: TestClient) -> None:
    _register(client)
    ok = client.post("/api/v1/auth/login", json={"email": EMAIL, "password": PASSWORD})
    assert ok.status_code == 200
    wrong = client.post(
        "/api/v1/auth/login",
        json={"email": EMAIL, "password": "wrong-password"},
        headers={"X-Request-ID": "wrong-password-id"},
    )
    unknown = client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": PASSWORD},
        headers={"X-Request-ID": "unknown-email-id"},
    )
    assert wrong.status_code == 401, wrong.text
    assert unknown.status_code == 401, unknown.text
    assert _problem(wrong) == _problem(unknown)
    assert wrong.json()["code"] == "INVALID_CREDENTIALS"
    assert wrong.json()["request_id"] != unknown.json()["request_id"]


def test_login_password_over_128_characters_is_rejected(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "user@example.com", "password": "p" * 129},
    )
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"


def test_refresh_rotates_and_reuse_revokes_the_newest_token(client: TestClient) -> None:
    first = _register(client)
    rotated = client.post("/api/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert rotated.status_code == 200
    new_access = rotated.json()["access_token"]
    me = client.get("/api/v1/me", headers={"Authorization": f"Bearer {new_access}"})
    assert me.status_code == 200
    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert reused.status_code == 401
    assert reused.json()["code"] == "TOKEN_REUSED"
    newest = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": rotated.json()["refresh_token"]}
    )
    assert newest.status_code == 401
    assert newest.json()["code"] == "TOKEN_REUSED"


def test_expired_and_unknown_refresh_tokens(
    clocked: tuple[TestClient, dict[str, datetime]],
) -> None:
    client, state = clocked
    first = _register(client)
    state["now"] = NOW + timedelta(days=30)
    expired = client.post("/api/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert expired.status_code == 401
    assert expired.json()["code"] == "TOKEN_INVALID"
    state["now"] = NOW
    unknown = client.post("/api/v1/auth/refresh", json={"refresh_token": "not-a-token"})
    assert unknown.status_code == 401
    assert unknown.json()["code"] == "TOKEN_INVALID"


def test_logout_revokes_the_token_and_unknown_logout_is_empty(client: TestClient) -> None:
    first = _register(client)
    unknown = client.post("/api/v1/auth/logout", json={"refresh_token": "not-a-token"})
    assert unknown.status_code == 204
    assert unknown.content == b""
    logged_out = client.post("/api/v1/auth/logout", json={"refresh_token": first["refresh_token"]})
    assert logged_out.status_code == 204
    again = client.post("/api/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert again.status_code == 401
    assert again.json()["code"] == "TOKEN_REUSED"


def test_access_token_failures_are_unauthorized(
    clocked: tuple[TestClient, dict[str, datetime]],
) -> None:
    client, state = clocked
    first = _register(client)
    access = str(first["access_token"])
    secret = get_settings().JWT_SECRET.get_secret_value()
    wrong_type = jwt.encode(
        {
            "sub": "1",
            "iat": int(NOW.timestamp()),
            "exp": int(NOW.timestamp()) + 900,
            "typ": "refresh",
        },
        secret,
        algorithm="HS256",
    )
    bad_signature = access[:-1] + ("a" if access[-1] != "a" else "b")
    cases = [
        {},
        {"Authorization": "Basic abc"},
        {"Authorization": f"Bearer {bad_signature}"},
        {"Authorization": f"Bearer {wrong_type}"},
    ]
    for headers in cases:
        response = client.get("/api/v1/me", headers=headers)
        assert response.status_code == 401, headers
        assert response.headers["www-authenticate"] == "Bearer"
        assert response.json()["code"] == "UNAUTHORIZED"
    state["now"] = NOW + timedelta(minutes=16)
    expired = client.get("/api/v1/me", headers={"Authorization": f"Bearer {access}"})
    assert expired.status_code == 401
    assert expired.headers["www-authenticate"] == "Bearer"
    assert expired.json()["code"] == "UNAUTHORIZED"


def test_passwords_are_not_logged(client: TestClient) -> None:
    records: list[logging.LogRecord] = []

    class _Capture(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            records.append(record)

    handler = _Capture()
    loggers = [logging.getLogger(name) for name in ("", "nutriguide", "slowapi")]
    for logger in loggers:
        logger.addHandler(handler)
    try:
        registered = _register(client)
        response = client.post("/api/v1/auth/login", json={"email": EMAIL, "password": PASSWORD})
        assert response.status_code == 200
    finally:
        for logger in loggers:
            logger.removeHandler(handler)
    rendered = "\n".join(f"{record.getMessage()} {record.__dict__}" for record in records)
    assert PASSWORD not in rendered
    assert str(registered["access_token"]) not in rendered
    assert str(registered["refresh_token"]) not in rendered


def test_eleventh_login_is_rate_limited(client: TestClient) -> None:
    limiter.reset()
    limiter.enabled = True
    try:
        _register(client)
        for _ in range(10):
            response = client.post(
                "/api/v1/auth/login", json={"email": EMAIL, "password": PASSWORD}
            )
            assert response.status_code == 200, response.text
        blocked = client.post("/api/v1/auth/login", json={"email": EMAIL, "password": PASSWORD})
    finally:
        limiter.enabled = False
        limiter.reset()
    assert blocked.status_code == 429
    assert blocked.headers["content-type"].startswith("application/problem+json")
    assert blocked.json()["code"] == "RATE_LIMITED"
    assert int(blocked.headers["retry-after"]) >= 1
