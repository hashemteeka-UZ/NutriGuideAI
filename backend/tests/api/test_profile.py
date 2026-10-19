"""Profile and target routes (#176-#179)."""

import logging
from datetime import timedelta
from decimal import Decimal

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import UserProfile, UserTarget, WeightLog
from app.db.models.user import ActivityLevel, GoalType, Sex
from app.services.targets import TargetInputs, compute_targets
from tests.builders import make_allergen, make_cuisine, make_health_condition, make_ingredient

PASSWORD = "profile-secret-value"


def _register(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "profile@example.com", "password": PASSWORD},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _body(**overrides: object) -> dict[str, object]:
    body: dict[str, object] = {
        "sex": "MALE",
        "birth_date": "1996-01-15",
        "height_cm": 180,
        "activity_level": "MODERATE",
        "goal_type": "LOSE",
        "target_weight_kg": 80,
        "weekly_rate_kg": 0.5,
        "timezone": "Africa/Tripoli",
        "wake_time": "07:00",
        "sleep_time": "23:00",
        "current_weight_kg": 90,
        "conditions": [],
        "allergens": [],
        "ingredient_prefs": [],
        "cuisines": [],
    }
    body.update(overrides)
    return body


def _catalog(conn: Connection) -> int:
    make_health_condition(conn, code="HYPERTENSION", is_supported=True)
    make_health_condition(conn, code="DIABETES_INSULIN", is_supported=False)
    make_allergen(conn, code="GLUTEN")
    make_cuisine(conn, code="LIBYAN")
    return make_ingredient(conn)


def test_first_save_without_weight_is_409_and_writes_nothing(
    client: TestClient, api_session: Session
) -> None:
    headers = _register(client)
    response = client.put(
        "/api/v1/me/profile",
        json=_body(current_weight_kg=None),
        headers=headers,
    )
    assert response.status_code == 409
    assert response.json()["code"] == "NO_WEIGHT"
    missing = client.get("/api/v1/me/profile", headers=headers)
    assert missing.status_code == 404
    assert missing.json()["code"] == "PROFILE_NOT_FOUND"
    assert api_session.scalar(select(func.count()).select_from(UserProfile)) == 0
    assert api_session.scalar(select(func.count()).select_from(WeightLog)) == 0


def test_first_save_returns_the_initial_target(
    client: TestClient, integrity_conn: Connection
) -> None:
    _catalog(integrity_conn)
    headers = _register(client)
    response = client.put("/api/v1/me/profile", json=_body(), headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    expected = compute_targets(
        TargetInputs(
            sex=Sex.MALE,
            age_years=30,
            height_cm=Decimal(180),
            weight_kg=Decimal(90),
            activity_level=ActivityLevel.MODERATE,
            goal_type=GoalType.LOSE,
            weekly_rate_kg=Decimal("0.5"),
            target_weight_kg=Decimal(80),
        )
    )
    assert body["screening"]["eligible"] is True
    assert body["target"]["reason"] == "INITIAL"
    assert body["target"]["kcal"] == expected.target_kcal
    assert body["target"]["protein_g"] == float(expected.protein_g)
    assert body["target"]["fiber_g"] == expected.fiber_g
    assert body["profile"]["latest_weight_kg"] == 90
    assert body["profile"]["latest_weight_on"] == "2026-10-12"
    targets = client.get("/api/v1/me/targets", headers=headers)
    assert targets.status_code == 200
    assert targets.json()["target"]["kcal"] == expected.target_kcal
    assert targets.json()["water"] == {
        "goal_ml": 2000,
        "source": "DEFAULT",
        "requires_clinician": False,
        "reminders_default_off": False,
    }


def test_goal_change_ineligible_profile_and_validation(
    client: TestClient,
    integrity_conn: Connection,
    api_session: Session,
    now_clock: dict,
) -> None:
    _catalog(integrity_conn)
    headers = _register(client)
    created = client.put("/api/v1/me/profile", json=_body(), headers=headers)
    assert created.status_code == 200, created.text
    first_id = created.json()["target"]["target_id"]

    now_clock["now"] = now_clock["now"] + timedelta(minutes=1)
    changed = client.put(
        "/api/v1/me/profile",
        json=_body(goal_type="MAINTAIN", target_weight_kg=None, weekly_rate_kg=None),
        headers=headers,
    )
    assert changed.status_code == 200, changed.text
    assert changed.json()["target"]["reason"] == "GOAL_CHANGE"
    assert changed.json()["target"]["target_id"] != first_id

    now_clock["now"] = now_clock["now"] + timedelta(minutes=1)
    blocked = client.put(
        "/api/v1/me/profile",
        json=_body(
            goal_type="MAINTAIN",
            target_weight_kg=None,
            weekly_rate_kg=None,
            conditions=[{"code": "DIABETES_INSULIN"}],
        ),
        headers=headers,
    )
    assert blocked.status_code == 200, blocked.text
    assert blocked.json()["screening"] == {
        "eligible": False,
        "reasons": ["UNSUPPORTED_CONDITION:DIABETES_INSULIN"],
    }
    assert blocked.json()["target"] is None
    targets = client.get("/api/v1/me/targets", headers=headers)
    assert targets.json()["target"] is None
    closed = api_session.get(UserTarget, changed.json()["target"]["target_id"])
    assert closed is not None
    assert closed.valid_to == now_clock["now"]

    now_clock["now"] = now_clock["now"] + timedelta(minutes=1)
    restored = client.put(
        "/api/v1/me/profile",
        json=_body(goal_type="MAINTAIN", target_weight_kg=None, weekly_rate_kg=None),
        headers=headers,
    )
    assert restored.status_code == 200, restored.text
    assert restored.json()["target"]["reason"] == "PROFILE_CHANGE"

    rejected = client.put(
        "/api/v1/me/profile",
        json=_body(goal_type="LOSE", target_weight_kg=95, current_weight_kg=90),
        headers=headers,
    )
    assert rejected.status_code == 422
    assert rejected.json()["code"] == "TARGET_VALIDATION"
    kept = client.get("/api/v1/me/profile", headers=headers)
    assert kept.json()["profile"]["goal_type"] == "MAINTAIN"


def test_unknown_code_timezone_and_pydantic_rules(
    client: TestClient, integrity_conn: Connection
) -> None:
    _catalog(integrity_conn)
    headers = _register(client)
    unknown = client.put(
        "/api/v1/me/profile",
        json=_body(conditions=[{"code": "hypertension"}]),
        headers=headers,
    )
    assert unknown.status_code == 422
    assert unknown.json()["code"] == "UNKNOWN_CODE"
    assert "hypertension" in unknown.json()["detail"]
    zone = client.put(
        "/api/v1/me/profile",
        json=_body(timezone="Not/AZone"),
        headers=headers,
    )
    assert zone.status_code == 422
    assert zone.json()["code"] == "INVALID_TIMEZONE"
    duplicate = client.put(
        "/api/v1/me/profile",
        json=_body(conditions=[{"code": "HYPERTENSION"}, {"code": "HYPERTENSION"}]),
        headers=headers,
    )
    assert duplicate.status_code == 422
    assert duplicate.json()["code"] == "VALIDATION_ERROR"
    same_clock = _body(wake_time="07:00", sleep_time="07:00")
    assert client.put("/api/v1/me/profile", json=same_clock, headers=headers).status_code == 422
    missing_goal = _body()
    del missing_goal["target_weight_kg"]
    assert client.put("/api/v1/me/profile", json=missing_goal, headers=headers).json()["code"] == (
        "VALIDATION_ERROR"
    )
    young = client.put(
        "/api/v1/me/profile",
        json=_body(birth_date="2010-01-01"),
        headers=headers,
    )
    assert young.status_code == 200, young.text
    assert young.json()["screening"]["reasons"] == ["UNDER_18"]
    assert young.json()["target"] is None


def test_profile_values_are_not_logged(client: TestClient, integrity_conn: Connection) -> None:
    _catalog(integrity_conn)
    headers = _register(client)
    records: list[logging.LogRecord] = []

    class _Capture(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            records.append(record)

    handler = _Capture()
    loggers = [logging.getLogger(name) for name in ("", "nutriguide", "slowapi")]
    for logger in loggers:
        logger.addHandler(handler)
    try:
        response = client.put(
            "/api/v1/me/profile",
            json=_body(
                height_cm=181.25,
                current_weight_kg=93.75,
                birth_date="1984-11-03",
                timezone="America/Adak",
                water_goal_ml=1875,
            ),
            headers=headers,
        )
        assert response.status_code == 200, response.text
    finally:
        for logger in loggers:
            logger.removeHandler(handler)
    rendered = "\n".join(f"{record.getMessage()} {record.__dict__}" for record in records)
    for secret in ("181.25", "93.75", "1984-11-03", "America/Adak", "1875", PASSWORD):
        assert secret not in rendered
