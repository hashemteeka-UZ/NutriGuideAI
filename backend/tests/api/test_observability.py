"""Request ids are echoed, and each request writes one JSON access line."""

from __future__ import annotations

import io
import json
import logging
import re

from fastapi.testclient import TestClient

from app.api.observability import JsonFormatter, configure_logging

_HEX_ID = re.compile(r"^[0-9a-f]{32}$")


def test_safe_request_id_is_echoed_in_header_and_problem(client: TestClient) -> None:
    request_id = "trace.abc_01-Z"
    response = client.get("/api/v1/missing", headers={"X-Request-ID": request_id})
    assert response.status_code == 404
    assert response.headers["x-request-id"] == request_id
    assert response.json()["request_id"] == request_id
    assert response.json()["code"] == "NOT_FOUND"


def test_unsafe_request_id_is_replaced(client: TestClient) -> None:
    for incoming in ("x" * 100, "bad id"):
        response = client.get("/api/v1/health", headers={"X-Request-ID": incoming})
        generated = response.headers["x-request-id"]
        assert _HEX_ID.fullmatch(generated)
        assert generated != incoming


def test_missing_request_id_is_generated(client: TestClient) -> None:
    response = client.get("/api/v1/health")
    assert _HEX_ID.fullmatch(response.headers["x-request-id"])


def test_access_log_is_json_and_omits_query_and_headers(client: TestClient) -> None:
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    access = logging.getLogger("nutriguide.api.access")
    access.addHandler(handler)
    try:
        response = client.get(
            "/api/v1/health?token=secret",
            headers={"Authorization": "Bearer super-secret-token"},
        )
    finally:
        access.removeHandler(handler)
    assert response.status_code == 200
    lines = [line for line in stream.getvalue().splitlines() if line.strip()]
    assert len(lines) == 1
    payload = json.loads(lines[0])
    assert payload["method"] == "GET"
    assert payload["path"] == "/api/v1/health"
    assert "?" not in payload["path"]
    assert payload["status"] == 200
    assert isinstance(payload["duration_ms"], int | float)
    assert payload["request_id"] == response.headers["x-request-id"]
    assert "secret" not in lines[0]
    assert "Bearer" not in lines[0]
    assert "super-secret-token" not in lines[0]


def test_configure_logging_twice_leaves_one_handler() -> None:
    configure_logging()
    logger = logging.getLogger("nutriguide")
    ours = [handler for handler in logger.handlers if isinstance(handler.formatter, JsonFormatter)]
    assert len(ours) == 1
    before = list(logger.handlers)
    configure_logging()
    assert logger.handlers == before
    assert logger.propagate is False
