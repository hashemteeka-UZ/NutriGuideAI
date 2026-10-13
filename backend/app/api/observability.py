"""JSON logs and a request id on every HTTP response."""

from __future__ import annotations

import json
import logging
import re
import sys
import time
from contextvars import ContextVar
from datetime import UTC, datetime
from typing import Any, Final
from uuid import uuid4

from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send

request_id_var: ContextVar[str | None] = ContextVar("request_id", default=None)

LOGGER_NAME: Final = "nutriguide"
API_LOGGER_NAME: Final = "nutriguide.api"
ACCESS_LOGGER_NAME: Final = "nutriguide.api.access"

_REQUEST_ID_RE: Final = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
_CONFIGURED = False
_LOG_RECORD_KEYS: Final = frozenset(logging.makeLogRecord({}).__dict__) | {"message", "asctime"}


class JsonFormatter(logging.Formatter):
    """One JSON object per line. Never includes request headers or bodies."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "ts": datetime.fromtimestamp(record.created, UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
            "request_id": request_id_var.get(),
        }
        for key, value in record.__dict__.items():
            if key not in _LOG_RECORD_KEYS and key not in payload:
                payload[key] = value
        if record.exc_info:
            payload["exc_info"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: str = "INFO") -> None:
    """Install one stdout handler on the nutriguide logger. Idempotent.

    Does not reconfigure the root logger or uvicorn's loggers.
    """
    global _CONFIGURED
    if _CONFIGURED:
        return
    logger = logging.getLogger(LOGGER_NAME)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger.addHandler(handler)
    logger.setLevel(level)
    logger.propagate = False
    logging.getLogger(API_LOGGER_NAME)
    logging.getLogger(ACCESS_LOGGER_NAME)
    _CONFIGURED = True


def _incoming_request_id(scope: Scope) -> str | None:
    headers = scope.get("headers")
    if not isinstance(headers, list):
        return None
    for key, value in headers:
        if key.lower() != b"x-request-id":
            continue
        try:
            decoded = bytes(value).decode("ascii")
        except UnicodeDecodeError:
            return None
        if _REQUEST_ID_RE.fullmatch(decoded):
            return decoded
        return None
    return None


class RequestIdMiddleware:
    """Pure ASGI middleware: accept or mint X-Request-ID, then log one access line."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_id = _incoming_request_id(scope) or uuid4().hex
        token = request_id_var.set(request_id)
        started = time.perf_counter()
        status_code = 500

        async def send_with_request_id(message: Message) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = int(message["status"])
                headers = MutableHeaders(scope=message)
                headers["X-Request-ID"] = request_id
            await send(message)

        try:
            await self.app(scope, receive, send_with_request_id)
        finally:
            duration_ms = round((time.perf_counter() - started) * 1000, 2)
            logging.getLogger(ACCESS_LOGGER_NAME).info(
                "request",
                extra={
                    "method": scope.get("method", ""),
                    "path": scope.get("path", ""),
                    "status": status_code,
                    "duration_ms": duration_ms,
                },
            )
            request_id_var.reset(token)
