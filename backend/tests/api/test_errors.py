"""Service exceptions, validation, and HTTP errors become problem+json."""

from __future__ import annotations

from decimal import Decimal

import pytest
from fastapi import APIRouter, FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel

from app.api.errors import SERVICE_ERRORS, ApiError
from app.api.main import create_app
from app.services.condition_limits import ConditionConflictError, LimitSource, ResolvedLimit
from app.services.consumption import PlanItemNotFoundError
from app.services.plan_swap import SwapRejectedError
from app.services.planner import NoFeasiblePlanError
from app.services.targets import UserNotEligibleError


class _Payload(BaseModel):
    servings: int


def _limit(value: str, code: str) -> ResolvedLimit:
    amount = Decimal(value)
    source = LimitSource(
        condition_code=code,
        source_reference="test",
        limit_basis="ABSOLUTE",
        stated_value=amount,
        value=amount,
    )
    return ResolvedLimit(value=amount, sources=(source,))


def _instance(exc_type: type[Exception]) -> Exception:
    if exc_type is UserNotEligibleError:
        return UserNotEligibleError(1, ["UNDER_18"])
    if exc_type is ConditionConflictError:
        return ConditionConflictError(
            "sodium", _limit("5", "HYPERTENSION"), _limit("1", "HEART_DISEASE")
        )
    if exc_type is NoFeasiblePlanError:
        return NoFeasiblePlanError("BREAKFAST", {"MEAL_ALREADY_USED": 2}, 4)
    if exc_type is SwapRejectedError:
        return SwapRejectedError(["SAME_MEAL"])
    return exc_type("failure")


def _client_raising(exc: Exception) -> TestClient:
    application = create_app()
    router = APIRouter()

    @router.get("/_test/raise")
    def raise_it() -> None:
        raise exc

    application.include_router(router)
    return TestClient(application, raise_server_exceptions=False)


def test_api_error_uses_its_fields() -> None:
    exc = ApiError(
        409,
        "CUSTOM_CODE",
        "Custom title",
        detail="because",
        reasons=["ONE"],
        headers={"X-Custom": "yes"},
    )
    with _client_raising(exc) as client:
        response = client.get("/_test/raise", headers={"X-Request-ID": "api-err"})
    assert response.status_code == 409
    assert response.headers["content-type"] == "application/problem+json"
    assert response.headers["x-custom"] == "yes"
    assert response.json() == {
        "type": "about:blank",
        "title": "Custom title",
        "status": 409,
        "detail": "because",
        "code": "CUSTOM_CODE",
        "request_id": "api-err",
        "reasons": ["ONE"],
    }


@pytest.mark.parametrize("exc_type", list(SERVICE_ERRORS), ids=lambda cls: cls.__name__)
def test_service_exception_becomes_problem(exc_type: type[Exception]) -> None:
    status, code = SERVICE_ERRORS[exc_type]
    exc = _instance(exc_type)
    with _client_raising(exc) as client:
        response = client.get("/_test/raise")
    assert response.status_code == status
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["code"] == code
    assert body["status"] == status
    assert body["detail"] == str(exc)


def test_user_not_eligible_includes_reasons() -> None:
    exc = UserNotEligibleError(4, ["UNDER_18", "UNSUPPORTED_CONDITION"])
    with _client_raising(exc) as client:
        body = client.get("/_test/raise").json()
    assert body["reasons"] == ["UNDER_18", "UNSUPPORTED_CONDITION"]
    assert body["code"] == "NOT_ELIGIBLE"


def test_swap_rejected_includes_exclusion_codes_as_reasons() -> None:
    exc = SwapRejectedError(["SAME_MEAL", "MAX_PER_DAY"])
    with _client_raising(exc) as client:
        body = client.get("/_test/raise").json()
    assert body["reasons"] == ["SAME_MEAL", "MAX_PER_DAY"]
    assert body["code"] == "SWAP_REJECTED"


def test_service_error_subclass_uses_the_most_specific_mapping() -> None:
    class _SpecificError(PlanItemNotFoundError):
        pass

    with _client_raising(_SpecificError("gone")) as client:
        body = client.get("/_test/raise").json()
    assert body["code"] == "PLAN_ITEM_NOT_FOUND"
    assert body["status"] == 404


def test_service_error_codes_are_unique() -> None:
    codes = [code for _status, code in SERVICE_ERRORS.values()]
    assert len(codes) == len(set(codes))
    assert len(codes) == len(SERVICE_ERRORS)


def test_unmapped_exception_is_internal_error_without_detail() -> None:
    with _client_raising(RuntimeError("secret-db-password")) as client:
        response = client.get("/_test/raise")
    assert response.status_code == 500
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["code"] == "INTERNAL_ERROR"
    assert body["title"] == "Internal server error"
    assert "detail" not in body
    assert "secret-db-password" not in response.text


def test_request_validation_error_lists_issues() -> None:
    application: FastAPI = create_app()
    router = APIRouter()

    @router.post("/_test/validate")
    def validate(body: _Payload) -> _Payload:
        return body

    application.include_router(router)
    with TestClient(application, raise_server_exceptions=False) as client:
        response = client.post("/_test/validate", json={"servings": "many"})
    assert response.status_code == 422
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["code"] == "VALIDATION_ERROR"
    assert body["errors"]
    issue = body["errors"][0]
    assert "servings" in issue["loc"]
    assert issue["msg"]
    assert issue["type"]


def test_unknown_path_is_not_found() -> None:
    with TestClient(create_app(), raise_server_exceptions=False) as client:
        response = client.get("/api/v1/missing")
    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json()["code"] == "NOT_FOUND"


def test_wrong_method_is_method_not_allowed() -> None:
    with TestClient(create_app(), raise_server_exceptions=False) as client:
        response = client.post("/api/v1/health")
    assert response.status_code == 405
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json()["code"] == "METHOD_NOT_ALLOWED"
    assert response.headers["allow"] == "GET"
