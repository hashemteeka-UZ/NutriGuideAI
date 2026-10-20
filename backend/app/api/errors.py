"""Problem responses (RFC 9457) and the domain-exception to HTTP map (#126)."""

from __future__ import annotations

import logging
from collections.abc import Mapping
from http import HTTPStatus
from typing import Any, Final, cast

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException
from starlette.types import ASGIApp, Receive, Scope, Send

from app.api.observability import API_LOGGER_NAME, request_id_var
from app.api.schemas.common import ProblemDetail, ValidationIssue
from app.services.auth import (
    EmailTakenError,
    InvalidCredentialsError,
    TokenInvalidError,
    TokenReusedError,
)
from app.services.common import InvalidTimezoneError, MealNotFoundError
from app.services.condition_limits import ConditionConflictError
from app.services.consumption import (
    ClientUuidConflictError,
    FoodNotFoundError,
    IncompleteNutritionError,
    LogNotFoundError,
    PlanItemAlreadyLoggedError,
    PlanItemNotFoundError,
)
from app.services.plan_requests import PlanDateOutOfRangeError
from app.services.plan_swap import SwapRejectedError
from app.services.planner import MissingTargetError, NoFeasiblePlanError
from app.services.profile import UnknownCodeError
from app.services.screening import ProfileNotFoundError
from app.services.targets import MissingWeightError, TargetValidationError, UserNotEligibleError
from app.services.text_search import EmptySearchError
from app.services.weight import ClockSkewError

logger = logging.getLogger(API_LOGGER_NAME)

PROBLEM_MEDIA_TYPE: Final = "application/problem+json"

# Most specific class wins: lookup walks the raised exception's MRO.
SERVICE_ERRORS: Mapping[type[Exception], tuple[int, str]] = {
    ProfileNotFoundError: (404, "PROFILE_NOT_FOUND"),
    MealNotFoundError: (404, "MEAL_NOT_FOUND"),
    FoodNotFoundError: (404, "FOOD_NOT_FOUND"),
    LogNotFoundError: (404, "LOG_NOT_FOUND"),
    PlanItemNotFoundError: (404, "PLAN_ITEM_NOT_FOUND"),
    UserNotEligibleError: (409, "NOT_ELIGIBLE"),
    MissingTargetError: (409, "NO_TARGET"),
    MissingWeightError: (409, "NO_WEIGHT"),
    ConditionConflictError: (409, "CONDITION_CONFLICT"),
    PlanItemAlreadyLoggedError: (409, "PLAN_ITEM_ALREADY_LOGGED"),
    ClientUuidConflictError: (409, "CLIENT_UUID_CONFLICT"),
    NoFeasiblePlanError: (422, "NO_FEASIBLE_PLAN"),
    IncompleteNutritionError: (422, "INCOMPLETE_NUTRITION"),
    SwapRejectedError: (422, "SWAP_REJECTED"),
    ClockSkewError: (422, "CLOCK_SKEW"),
    TargetValidationError: (422, "TARGET_VALIDATION"),
    InvalidTimezoneError: (422, "INVALID_TIMEZONE"),
    UnknownCodeError: (422, "UNKNOWN_CODE"),
    EmptySearchError: (422, "VALIDATION_ERROR"),
    PlanDateOutOfRangeError: (422, "VALIDATION_ERROR"),
    EmailTakenError: (409, "EMAIL_TAKEN"),
    InvalidCredentialsError: (401, "INVALID_CREDENTIALS"),
    TokenInvalidError: (401, "TOKEN_INVALID"),
    TokenReusedError: (401, "TOKEN_REUSED"),
}

_HTTP_CODES: Final[dict[int, str]] = {
    401: "UNAUTHORIZED",
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    405: "METHOD_NOT_ALLOWED",
    429: "RATE_LIMITED",
    501: "NOT_IMPLEMENTED",
    503: "SERVICE_UNAVAILABLE",
}

_PROBLEM_SCHEMA: Final[dict[str, Any]] = {
    "application/problem+json": {"schema": {"$ref": "#/components/schemas/ProblemDetail"}}
}

PROBLEM_RESPONSES: dict[int | str, dict[str, Any]] = {
    422: {
        "model": ProblemDetail,
        "description": "Validation error",
        "content": _PROBLEM_SCHEMA,
    },
    "default": {
        "model": ProblemDetail,
        "description": "Problem",
        "content": _PROBLEM_SCHEMA,
    },
}


class ApiError(Exception):
    def __init__(
        self,
        status: int,
        code: str,
        title: str,
        detail: str | None = None,
        reasons: list[str] | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(title if detail is None else detail)
        self.status = status
        self.code = code
        self.title = title
        self.detail = detail
        self.reasons = reasons
        self.headers = headers


def not_implemented() -> ApiError:
    """Raised by every route this pass only declares. Not part of the lasting contract."""
    return ApiError(501, "NOT_IMPLEMENTED", "Not implemented")


def error_codes(*codes: str) -> str:
    """Last line of an operation description. 501 is never listed."""
    return "Error codes: " + ", ".join(codes)


# Every code named by an operation description, sorted. Later passes raise the ones
# that are not in SERVICE_ERRORS yet: PLANNER_BUSY, RATE_LIMITED, UNAUTHORIZED.
PLANNED_ERROR_CODES: Final[tuple[str, ...]] = (
    "CLIENT_UUID_CONFLICT",
    "CLOCK_SKEW",
    "CONDITION_CONFLICT",
    "EMAIL_TAKEN",
    "FOOD_NOT_FOUND",
    "INCOMPLETE_NUTRITION",
    "INVALID_CREDENTIALS",
    "INVALID_TIMEZONE",
    "LOG_NOT_FOUND",
    "MEAL_NOT_FOUND",
    "NOT_ELIGIBLE",
    "NO_FEASIBLE_PLAN",
    "NO_TARGET",
    "NO_WEIGHT",
    "PLANNER_BUSY",
    "PLAN_ITEM_ALREADY_LOGGED",
    "PLAN_ITEM_NOT_FOUND",
    "PROFILE_NOT_FOUND",
    "RATE_LIMITED",
    "SWAP_REJECTED",
    "TARGET_VALIDATION",
    "TOKEN_INVALID",
    "TOKEN_REUSED",
    "UNAUTHORIZED",
    "UNKNOWN_CODE",
    "VALIDATION_ERROR",
)


def problem_response(
    status: int,
    code: str,
    title: str,
    detail: str | None = None,
    *,
    errors: list[ValidationIssue] | None = None,
    reasons: list[str] | None = None,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    body = ProblemDetail(
        title=title,
        status=status,
        detail=detail,
        code=code,
        request_id=request_id_var.get(),
        errors=errors,
        reasons=reasons,
    )
    return JSONResponse(
        status_code=status,
        content=body.model_dump(mode="json", exclude_none=True),
        media_type=PROBLEM_MEDIA_TYPE,
        headers=headers,
    )


def _service_error(exc: Exception) -> tuple[int, str] | None:
    table = cast("Mapping[type[BaseException], tuple[int, str]]", SERVICE_ERRORS)
    for cls in type(exc).__mro__:
        mapped = table.get(cls)
        if mapped is not None:
            return mapped
    return None


def _reasons(exc: Exception) -> list[str] | None:
    if isinstance(exc, UserNotEligibleError):
        return list(exc.reasons)
    if isinstance(exc, SwapRejectedError):
        return list(exc.exclusion_codes)
    return None


def _title(code: str) -> str:
    return code.replace("_", " ").capitalize()


def _validation_issues(exc: RequestValidationError) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []
    for error in exc.errors():
        loc = error.get("loc", ())
        issues.append(
            ValidationIssue(
                loc=[
                    part if isinstance(part, int) and not isinstance(part, bool) else str(part)
                    for part in loc
                ],
                msg=str(error.get("msg", "")),
                type=str(error.get("type", "")),
            )
        )
    return issues


def _http_title(status: int) -> str:
    try:
        return HTTPStatus(status).phrase
    except ValueError:
        return "HTTP error"


async def _api_error_handler(_request: Request, exc: Exception) -> JSONResponse:
    if not isinstance(exc, ApiError):
        return problem_response(500, "INTERNAL_ERROR", "Internal server error")
    return problem_response(
        exc.status,
        exc.code,
        exc.title,
        exc.detail,
        reasons=exc.reasons,
        headers=exc.headers,
    )


def _mapped_problem(exc: Exception) -> JSONResponse | None:
    mapped = _service_error(exc)
    if mapped is None:
        return None
    status, code = mapped
    return problem_response(status, code, _title(code), str(exc), reasons=_reasons(exc))


class ServiceErrorMiddleware:
    """Turn a mapped service exception into a problem response inside the request.

    Starlette runs the `Exception` handler on the outermost server-error middleware,
    which is outside the request-id middleware. Handling the mapped errors here keeps
    `request_id` on the body and the real status on the access log.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        try:
            await self.app(scope, receive, send)
        except Exception as exc:
            response = _mapped_problem(exc)
            if response is None:
                raise
            await response(scope, receive, send)


async def _unhandled_handler(_request: Request, exc: Exception) -> JSONResponse:
    response = _mapped_problem(exc)
    if response is not None:
        return response
    logger.exception("unhandled exception", exc_info=exc)
    return problem_response(500, "INTERNAL_ERROR", "Internal server error")


async def _validation_handler(_request: Request, exc: Exception) -> JSONResponse:
    if not isinstance(exc, RequestValidationError):
        return problem_response(500, "INTERNAL_ERROR", "Internal server error")
    return problem_response(
        422,
        "VALIDATION_ERROR",
        "Validation error",
        errors=_validation_issues(exc),
    )


async def _http_exception_handler(_request: Request, exc: Exception) -> JSONResponse:
    if not isinstance(exc, HTTPException):
        return problem_response(500, "INTERNAL_ERROR", "Internal server error")
    detail = exc.detail if isinstance(exc.detail, str) else None
    headers = dict(exc.headers) if exc.headers else None
    code = _HTTP_CODES.get(exc.status_code, f"HTTP_{exc.status_code}")
    return problem_response(
        exc.status_code,
        code,
        _http_title(exc.status_code),
        detail,
        headers=headers,
    )


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(ApiError, _api_error_handler)
    app.add_exception_handler(Exception, _unhandled_handler)
    app.add_exception_handler(RequestValidationError, _validation_handler)
    app.add_exception_handler(HTTPException, _http_exception_handler)
