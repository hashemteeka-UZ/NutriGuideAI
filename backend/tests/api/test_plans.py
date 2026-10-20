"""Plan routes: generate, read, swap, and the shopping list (#192 to #195)."""

from __future__ import annotations

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete, func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.api.limiting import limiter
from app.api.planner_limit import planner_semaphore
from app.db.models import MealNutrient, MealPlan, Nutrient, User, UserTarget
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.consumption import log_plan_item
from tests.api.conftest import NOW

TODAY = "2026-10-12"
TOMORROW = "2026-10-13"


def _auth(client: TestClient, email: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _user_id(conn: Connection, email: str) -> int:
    return conn.execute(select(User.user_id).where(User.email == email)).scalar_one()


def _profile(**overrides: object) -> dict[str, object]:
    body: dict[str, object] = {
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
        "current_weight_kg": 82.5,
        "conditions": [{"code": "HYPERTENSION", "severity": "MODERATE"}],
        "allergens": [],
        "ingredient_prefs": [],
        "cuisines": [],
    }
    body.update(overrides)
    return body


def _save(client: TestClient, headers: dict[str, str], **overrides: object) -> None:
    saved = client.put("/api/v1/me/profile", json=_profile(**overrides), headers=headers)
    assert saved.status_code == 200, saved.text


def test_out_of_range_not_eligible_and_no_target(client: TestClient) -> None:
    headers = _auth(client, "plans-window@example.com")
    _save(client, headers, conditions=[])
    far = client.post("/api/v1/plans/days", json={"date": "2026-12-01"}, headers=headers)
    assert far.status_code == 422
    assert far.json()["code"] == "VALIDATION_ERROR"
    assert "13" in far.json()["detail"]

    young = _auth(client, "plans-young@example.com")
    _save(
        client,
        young,
        conditions=[],
        birth_date="2015-01-01",
        height_cm=140,
        goal_type="MAINTAIN",
        target_weight_kg=None,
        weekly_rate_kg=None,
    )
    blocked = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=young)
    assert blocked.status_code == 409
    assert blocked.json()["code"] == "NOT_ELIGIBLE"
    assert "UNDER_18" in blocked.json()["reasons"]


def test_twenty_first_generation_is_rate_limited(client: TestClient) -> None:
    headers = _auth(client, "plans-rate@example.com")
    limiter.reset()
    limiter.enabled = True
    try:
        for _ in range(20):
            response = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
            assert response.status_code == 404, response.text
            assert response.json()["code"] == "PROFILE_NOT_FOUND"
        blocked = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    finally:
        limiter.enabled = False
        limiter.reset()
    assert blocked.status_code == 429
    assert blocked.json()["code"] == "RATE_LIMITED"
    assert int(blocked.headers["retry-after"]) >= 1


def test_planner_busy_then_a_generated_day(client: TestClient, api_session: Session) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "plans-busy@example.com")
    _save(client, headers)
    assert planner_semaphore.acquire(blocking=False)
    assert planner_semaphore.acquire(blocking=False)
    try:
        busy = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    finally:
        planner_semaphore.release()
        planner_semaphore.release()
    assert busy.status_code == 503
    assert busy.json()["code"] == "PLANNER_BUSY"
    assert busy.headers["retry-after"] == "5"
    created = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["date"] == TODAY
    assert body["stats"]["solver_status"] in {"OPTIMAL", "FEASIBLE"}
    assert body["stats"]["candidate_meals"] > 0
    assert body["items"]
    assert body["totals"]["kcal"] is not None
    assert body["target"]["kcal"] == int(float(body["target"]["kcal"]))
    assert "kcal_within_10pct" in body


def test_day_view_plans_swap_and_shopping_list(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "plans-flow@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "plans-flow@example.com")
    empty = client.get("/api/v1/days/2026-10-14", headers=headers)
    assert empty.status_code == 200, empty.text
    empty_body = empty.json()
    assert empty_body["plan"] is None
    assert [(row["slot"], row["start"], row["end"]) for row in empty_body["meal_windows"]] == [
        ("BREAKFAST", "07:30", "09:30"),
        ("LUNCH", "13:00", "15:00"),
        ("SNACK", "16:30", "17:30"),
        ("DINNER", "18:30", "20:30"),
    ]
    assert empty_body["adherence"]["status"] == "NOT_ACHIEVED"
    assert empty_body["water"]["total_ml"] == 0
    assert empty_body["water"]["goal"]["source"] == "DEFAULT"

    first = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert first.status_code == 201, first.text
    second = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert second.status_code == 201, second.text
    assert second.json()["plan_id"] != first.json()["plan_id"]
    tomorrow = client.post("/api/v1/plans/days", json={"date": TOMORROW}, headers=headers)
    assert tomorrow.status_code == 201, tomorrow.text

    listed = client.get(
        "/api/v1/plans", params={"from": TODAY, "to": "2026-10-14"}, headers=headers
    )
    assert listed.status_code == 200, listed.text
    plans = listed.json()
    assert [plan["date"] for plan in plans] == [TODAY, TOMORROW]
    assert plans[0]["plan_id"] == second.json()["plan_id"]

    item_id = second.json()["items"][0]["plan_item_id"]
    log_plan_item(api_session, user_id, item_id, 1, NOW, uuid4(), NOW)
    api_session.commit()
    viewed = client.get(f"/api/v1/days/{TODAY}", headers=headers)
    assert viewed.status_code == 200, viewed.text
    viewed_items = viewed.json()["plan"]["items"]
    logged = next(item for item in viewed_items if item["plan_item_id"] == item_id)
    assert logged["logged"] is True
    assert viewed.json()["adherence"]["plan_items_consumed"] == 1
    assert viewed.json()["adherence"]["log_count"] == 1

    other_item = next(item for item in viewed_items if item["plan_item_id"] != item_id)
    alternatives = client.get(
        f"/api/v1/plan-items/{other_item['plan_item_id']}/alternatives", headers=headers
    )
    assert alternatives.status_code == 200, alternatives.text
    found = alternatives.json()
    assert found
    assert "kcal_delta" in found[0]
    logged_alts = client.get(f"/api/v1/plan-items/{item_id}/alternatives", headers=headers)
    assert logged_alts.status_code == 200
    assert logged_alts.json() == []

    rejected = client.post(
        f"/api/v1/plan-items/{other_item['plan_item_id']}/swap",
        json={"meal_id": other_item["meal"]["meal_id"]},
        headers=headers,
    )
    assert rejected.status_code == 422
    assert rejected.json()["code"] == "SWAP_REJECTED"
    assert rejected.json()["reasons"]

    swapped = client.post(
        f"/api/v1/plan-items/{other_item['plan_item_id']}/swap",
        json={"meal_id": found[0]["meal"]["meal_id"]},
        headers=headers,
    )
    assert swapped.status_code == 200, swapped.text
    assert swapped.json()["meal"]["meal_id"] == found[0]["meal"]["meal_id"]
    assert swapped.json()["was_swapped"] is True

    stranger = _auth(client, "plans-stranger@example.com")
    hidden = client.get(
        f"/api/v1/plan-items/{other_item['plan_item_id']}/alternatives", headers=stranger
    )
    assert hidden.status_code == 404
    assert hidden.json()["code"] == "PLAN_ITEM_NOT_FOUND"
    hidden_swap = client.post(
        f"/api/v1/plan-items/{other_item['plan_item_id']}/swap",
        json={"meal_id": found[0]["meal"]["meal_id"]},
        headers=stranger,
    )
    assert hidden_swap.status_code == 404
    assert hidden_swap.json()["code"] == "PLAN_ITEM_NOT_FOUND"

    shopping = client.get(
        "/api/v1/shopping-list", params={"from": TODAY, "to": TOMORROW}, headers=headers
    )
    assert shopping.status_code == 200, shopping.text
    shop = shopping.json()
    assert shop["date_from"] == TODAY
    assert shop["items"]
    assert all(round(item["grams"], 1) == item["grams"] for item in shop["items"])

    fiber = api_session.scalar(select(Nutrient.nutrient_id).where(Nutrient.code == "fiber"))
    meal_id = second.json()["items"][0]["meal"]["meal_id"]
    api_session.execute(
        delete(MealNutrient).where(
            MealNutrient.meal_id == meal_id, MealNutrient.nutrient_id == fiber
        )
    )
    api_session.commit()
    again = client.get("/api/v1/plans", params={"from": TODAY, "to": TODAY}, headers=headers)
    assert again.status_code == 200, again.text
    assert again.json()[0]["totals"]["fiber_g"] is None
    assert again.json()[0]["totals"]["kcal"] is not None


def test_planner_timeout_is_503_and_stores_nothing(
    client: TestClient, api_session: Session, monkeypatch: pytest.MonkeyPatch
) -> None:
    import app.services.optimizer as optimizer

    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "plans-timeout@example.com")
    _save(client, headers)
    user_id = client.get("/api/v1/me", headers=headers).json()["user_id"]
    before = api_session.scalar(
        select(func.count()).select_from(MealPlan).where(MealPlan.user_id == user_id)
    )

    def unknown(*args: object, **kwargs: object):
        return optimizer._PhaseResult("UNKNOWN", (), 0, {}), 0.0

    monkeypatch.setattr(optimizer, "_solve", unknown)
    response = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert response.status_code == 503, response.text
    assert response.json()["code"] == "PLANNER_TIMEOUT"
    assert "retry-after" not in response.headers
    api_session.expire_all()
    after = api_session.scalar(
        select(func.count()).select_from(MealPlan).where(MealPlan.user_id == user_id)
    )
    assert before == after == 0


def test_missing_target_is_409(client: TestClient, api_session: Session) -> None:
    headers = _auth(client, "plans-notarget@example.com")
    _save(client, headers, conditions=[])
    user_id = client.get("/api/v1/me", headers=headers).json()["user_id"]
    api_session.execute(delete(UserTarget).where(UserTarget.user_id == user_id))
    api_session.commit()
    missing = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert missing.status_code == 409
    assert missing.json()["code"] == "NO_TARGET"
