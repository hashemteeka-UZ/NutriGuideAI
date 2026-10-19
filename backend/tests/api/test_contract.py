"""The OpenAPI document is the mobile contract: paths, security, examples, and 501 stubs."""

from __future__ import annotations

import importlib
from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient
from pydantic import BaseModel

from app.api.errors import PLANNED_ERROR_CODES, SERVICE_ERRORS
from app.api.main import create_app

_UUID = "11111111-1111-4111-8111-111111111111"
_AT = "2026-10-20T08:15:00Z"
_PROFILE: dict[str, Any] = {
    "sex": "MALE",
    "birth_date": "1990-04-12",
    "height_cm": 175,
    "activity_level": "MODERATE",
    "goal_type": "LOSE",
    "target_weight_kg": 75,
    "weekly_rate_kg": 0.5,
    "timezone": "Africa/Tripoli",
    "wake_time": "07:00",
    "sleep_time": "23:00",
    "water_goal_ml": 2500,
    "current_weight_kg": 82.5,
    "conditions": [{"code": "HYPERTENSION", "severity": "MODERATE"}],
    "allergens": [{"code": "GLUTEN", "severity": "AVOID"}],
    "ingredient_prefs": [{"ingredient_id": 18, "stance": "LIKE"}],
    "cuisines": ["LIBYAN"],
}
_PLAN_ITEM_LOG = {
    "kind": "PLAN_ITEM",
    "client_uuid": _UUID,
    "plan_item_id": 5,
    "servings_consumed": 1,
    "consumed_at": _AT,
}

# operationId -> (json body or None, query params or None)
_CALLS: dict[str, tuple[dict[str, Any] | None, dict[str, str] | None]] = {
    "register": ({"email": "user@example.com", "password": "password1"}, None),
    "login": ({"email": "user@example.com", "password": "password1"}, None),
    "refresh_session": ({"refresh_token": "refresh-token"}, None),
    "logout": ({"refresh_token": "refresh-token"}, None),
    "get_me": (None, None),
    "delete_me": (None, None),
    "get_reference": (None, None),
    "search_ingredients": (None, {"q": "فول"}),
    "get_profile": (None, None),
    "update_profile": (_PROFILE, None),
    "get_targets": (None, None),
    "list_meal_prefs": (None, None),
    "set_meal_pref": ({"stance": "LIKE"}, None),
    "delete_meal_pref": (None, None),
    "list_meals": (None, None),
    "get_meal": (None, None),
    "get_catalog_snapshot": (None, None),
    "create_plan_day": ({"date": "2026-10-20"}, None),
    "list_plans": (None, {"from": "2026-10-20", "to": "2026-10-20"}),
    "get_day_view": (None, None),
    "list_alternatives": (None, None),
    "swap_plan_item": ({"meal_id": 1}, None),
    "get_shopping_list": (None, {"from": "2026-10-20", "to": "2026-10-26"}),
    "create_consumption_log": (_PLAN_ITEM_LOG, None),
    "list_consumption_logs": (None, {"date": "2026-10-20"}),
    "correct_consumption_log": ({"new_client_uuid": _UUID, "servings_consumed": 0.5}, None),
    "delete_consumption_log": (None, None),
    "put_weight": ({"weight_kg": 82.5, "updated_at": _AT}, None),
    "list_weights": (None, {"from": "2026-10-01", "to": "2026-10-31"}),
    "get_water_day": (None, {"date": "2026-10-20"}),
    "create_water_log": ({"client_uuid": _UUID, "amount_ml": 250, "consumed_at": _AT}, None),
    "delete_water_log": (None, None),
    "get_adherence": (None, {"from": "2026-10-01", "to": "2026-10-31"}),
    "create_interaction": (
        {"client_uuid": _UUID, "meal_id": 42, "event_type": "VIEW"},
        None,
    ),
    "sync_batch": (
        {
            "operations": [
                {
                    "op": "WATER_CREATE",
                    "op_id": _UUID,
                    "client_uuid": _UUID,
                    "amount_ml": 250,
                    "consumed_at": _AT,
                }
            ]
        },
        None,
    ),
    "get_sync_changes": (None, {"since": "2026-10-20T00:00:00Z"}),
}

_PUBLIC = {
    ("GET", "/api/v1/health"),
    ("GET", "/api/v1/reference"),
    ("POST", "/api/v1/auth/register"),
    ("POST", "/api/v1/auth/login"),
    ("POST", "/api/v1/auth/refresh"),
    ("POST", "/api/v1/auth/logout"),
}

_PATH_VALUES = {
    "meal_id": "42",
    "plan_item_id": "5",
    "log_id": "21",
    "date": "2026-10-20",
    "measured_on": "2026-10-20",
}

_SCHEMA_MODULES = (
    "common",
    "health",
    "auth",
    "account",
    "reference",
    "profile",
    "meal_prefs",
    "meals",
    "plans",
    "consumption",
    "weights",
    "water",
    "adherence",
    "interactions",
    "sync",
)

_LIVE = {
    "register",
    "login",
    "refresh_session",
    "logout",
    "get_me",
    "delete_me",
    "get_reference",
    "search_ingredients",
    "get_profile",
    "update_profile",
    "get_targets",
    "list_meal_prefs",
    "set_meal_pref",
    "delete_meal_pref",
    "list_meals",
    "get_meal",
    "get_catalog_snapshot",
}

_FUTURE_CODES = (
    "PLANNER_BUSY",
    "RATE_LIMITED",
    "UNAUTHORIZED",
)


def _operations() -> list[tuple[str, str, dict[str, Any]]]:
    schema = create_app().openapi()
    found: list[tuple[str, str, dict[str, Any]]] = []
    for path, item in schema["paths"].items():
        for method, operation in item.items():
            if method in {"get", "post", "put", "delete"}:
                found.append((method.upper(), path, operation))
    return found


def _fill(path: str) -> str:
    filled = path
    for name, value in _PATH_VALUES.items():
        filled = filled.replace("{" + name + "}", value)
    return filled


@pytest.fixture
def api() -> Iterator[TestClient]:
    with TestClient(create_app(), raise_server_exceptions=False) as client:
        yield client


def test_paths_are_exactly_the_contract() -> None:
    found = {(method, path) for method, path, _operation in _operations()}
    expected = _PUBLIC | {
        ("GET", "/api/v1/me"),
        ("DELETE", "/api/v1/me"),
        ("GET", "/api/v1/ingredients"),
        ("GET", "/api/v1/me/profile"),
        ("PUT", "/api/v1/me/profile"),
        ("GET", "/api/v1/me/targets"),
        ("GET", "/api/v1/me/meal-prefs"),
        ("PUT", "/api/v1/me/meal-prefs/{meal_id}"),
        ("DELETE", "/api/v1/me/meal-prefs/{meal_id}"),
        ("GET", "/api/v1/meals"),
        ("GET", "/api/v1/meals/{meal_id}"),
        ("GET", "/api/v1/catalog/snapshot"),
        ("POST", "/api/v1/plans/days"),
        ("GET", "/api/v1/plans"),
        ("GET", "/api/v1/days/{date}"),
        ("GET", "/api/v1/plan-items/{plan_item_id}/alternatives"),
        ("POST", "/api/v1/plan-items/{plan_item_id}/swap"),
        ("GET", "/api/v1/shopping-list"),
        ("POST", "/api/v1/consumption-logs"),
        ("GET", "/api/v1/consumption-logs"),
        ("POST", "/api/v1/consumption-logs/{log_id}/correction"),
        ("DELETE", "/api/v1/consumption-logs/{log_id}"),
        ("PUT", "/api/v1/weights/{measured_on}"),
        ("GET", "/api/v1/weights"),
        ("GET", "/api/v1/water"),
        ("POST", "/api/v1/water-logs"),
        ("DELETE", "/api/v1/water-logs/{log_id}"),
        ("GET", "/api/v1/adherence"),
        ("POST", "/api/v1/interactions"),
        ("POST", "/api/v1/sync/batch"),
        ("GET", "/api/v1/sync/changes"),
    }
    assert found == expected


def _endpoint_names(router: object) -> set[str]:
    names: set[str] = set()
    for route in getattr(router, "routes", []):
        if isinstance(route, APIRoute):
            assert route.name == route.endpoint.__name__
            names.add(route.endpoint.__name__)
            continue
        original = getattr(route, "original_router", None)
        if original is not None:
            names |= _endpoint_names(original)
    return names


def test_operation_ids_match_function_names() -> None:
    application = create_app()
    ids = [operation["operationId"] for _method, _path, operation in _operations()]
    assert len(ids) == len(set(ids))
    assert set(ids) == _endpoint_names(application.router)


def test_security_is_bearer_except_the_public_six() -> None:
    for method, path, operation in _operations():
        if (method, path) in _PUBLIC:
            assert "security" not in operation
        else:
            assert operation["security"] == [{"HTTPBearer": []}]


def test_catalog_snapshot_declares_etag_and_not_modified() -> None:
    operation = create_app().openapi()["paths"]["/api/v1/catalog/snapshot"]["get"]
    assert "ETag" in operation["responses"]["200"]["headers"]
    assert "ETag" in operation["responses"]["304"]["headers"]
    names = [parameter["name"] for parameter in operation["parameters"]]
    assert "If-None-Match" in names


def _bearer(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "contract@example.com", "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


@pytest.mark.parametrize("operation_id", sorted(set(_CALLS) - _LIVE))
def test_stub_returns_not_implemented(client: TestClient, operation_id: str) -> None:
    body, params = _CALLS[operation_id]
    method, path, _operation = next(
        item for item in _operations() if item[2]["operationId"] == operation_id
    )
    response = client.request(
        method, _fill(path), json=body, params=params, headers=_bearer(client)
    )
    assert response.status_code == 501, response.text
    assert response.headers["content-type"].startswith("application/problem+json")
    payload = response.json()
    assert payload["code"] == "NOT_IMPLEMENTED"
    assert payload["status"] == 501
    assert payload["title"] == "Not implemented"


def test_protected_routes_reject_a_missing_token(client: TestClient) -> None:
    for method, path, operation in _operations():
        if (method, path) in _PUBLIC:
            continue
        body, params = _CALLS[operation["operationId"]]
        response = client.request(method, _fill(path), json=body, params=params)
        assert response.status_code == 401, (method, path, response.text)
        assert response.headers["www-authenticate"] == "Bearer"
        assert response.json()["code"] == "UNAUTHORIZED"


def test_malformed_body_is_validation_error(api: TestClient) -> None:
    response = api.post(
        "/api/v1/auth/register",
        json={"email": "user@example.com", "password": "short"},
    )
    assert response.status_code == 422
    assert response.headers["content-type"].startswith("application/problem+json")
    payload = response.json()
    assert payload["code"] == "VALIDATION_ERROR"
    assert payload["errors"]


def test_profile_rejects_equal_wake_and_sleep(client: TestClient) -> None:
    body = {**_PROFILE, "wake_time": "07:00", "sleep_time": "07:00"}
    response = client.put("/api/v1/me/profile", json=body, headers=_bearer(client))
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def test_profile_lose_requires_target_weight(client: TestClient) -> None:
    body = {key: value for key, value in _PROFILE.items() if key != "target_weight_kg"}
    response = client.put("/api/v1/me/profile", json=body, headers=_bearer(client))
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def test_profile_rejects_a_duplicate_condition(client: TestClient) -> None:
    body = {
        **_PROFILE,
        "conditions": [{"code": "HYPERTENSION"}, {"code": "HYPERTENSION"}],
    }
    response = client.put("/api/v1/me/profile", json=body, headers=_bearer(client))
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def test_plan_range_over_31_days_is_validation_error(client: TestClient) -> None:
    response = client.get(
        "/api/v1/plans",
        params={"from": "2026-10-01", "to": "2026-11-01"},
        headers=_bearer(client),
    )
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def test_rate_without_value_is_validation_error(client: TestClient) -> None:
    response = client.post(
        "/api/v1/interactions",
        json={"client_uuid": _UUID, "meal_id": 42, "event_type": "RATE"},
        headers=_bearer(client),
    )
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def test_unknown_consumption_kind_is_validation_error(client: TestClient) -> None:
    response = client.post(
        "/api/v1/consumption-logs", json={"kind": "DISH"}, headers=_bearer(client)
    )
    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    assert response.json()["errors"]


def _description_codes(description: str) -> set[str] | None:
    if "Error codes:" not in description:
        return None
    rest = description.strip().splitlines()[-1].removeprefix("Error codes:").strip()
    if not rest:
        return set()
    return {part.strip() for part in rest.split(",")}


def test_described_error_codes_are_planned() -> None:
    mapped = {code for _status, code in SERVICE_ERRORS.values()}
    allowed = set(PLANNED_ERROR_CODES) | mapped
    assert tuple(sorted(PLANNED_ERROR_CODES)) == PLANNED_ERROR_CODES
    assert set(_FUTURE_CODES) <= set(PLANNED_ERROR_CODES)
    assert set(_FUTURE_CODES).isdisjoint(mapped)
    described: set[str] = set()
    for method, path, operation in _operations():
        description = operation.get("description") or ""
        assert "NOT_IMPLEMENTED" not in description
        codes = _description_codes(description)
        if path == "/api/v1/health":
            assert codes is None
            continue
        assert codes is not None, (method, path)
        assert codes <= allowed
        described |= codes
    assert described <= set(PLANNED_ERROR_CODES)


def _models() -> dict[str, type[BaseModel]]:
    found: dict[str, type[BaseModel]] = {}
    for name in _SCHEMA_MODULES:
        module = importlib.import_module(f"app.api.schemas.{name}")
        for obj in vars(module).values():
            if isinstance(obj, type) and issubclass(obj, BaseModel):
                found[obj.__name__] = obj
    return found


def _walk_refs(node: object, components: dict[str, Any], seen: set[str]) -> None:
    if isinstance(node, dict):
        ref = node.get("$ref")
        if isinstance(ref, str):
            name = ref.rsplit("/", 1)[-1]
            if name not in seen:
                seen.add(name)
                _walk_refs(components[name], components, seen)
        for value in node.values():
            _walk_refs(value, components, seen)
    elif isinstance(node, list):
        for value in node:
            _walk_refs(value, components, seen)


def test_response_examples_validate() -> None:
    schema = create_app().openapi()
    components = schema["components"]["schemas"]
    seen: set[str] = set()
    for _method, _path, operation in _operations():
        for code, response in operation["responses"].items():
            if str(code).startswith("2"):
                _walk_refs(response, components, seen)
    models = _models()
    checked = 0
    for name in seen:
        component = components[name]
        if "enum" in component or "properties" not in component:
            continue
        example = component.get("example")
        assert example is not None, name
        models[name].model_validate(example)
        checked += 1
    assert checked >= 20
