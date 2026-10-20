"""One user, over HTTP, from registration through account deletion (#216)."""

from __future__ import annotations

from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import (
    ConsumptionLog,
    MealPlan,
    RefreshToken,
    User,
    UserInteraction,
    UserMealPref,
    UserProfile,
    UserTarget,
    WaterLog,
    WeightLog,
)
from app.db.models.user import InteractionEventType
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from tests.api.conftest import NOW

TODAY = "2026-10-12"
AT = "2026-10-12T11:00:00+02:00"
EMAIL = "scenario-i8@example.com"
PASSWORD = "password1"


def _count(session: Session, model: type, user_id: int) -> int:
    column = model.user_id  # type: ignore[attr-defined]
    return session.scalar(select(func.count()).select_from(model).where(column == user_id))


def _profile() -> dict[str, object]:
    return {
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


def test_user_walks_the_api(client: TestClient, api_session: Session) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)

    registered = client.post("/api/v1/auth/register", json={"email": EMAIL, "password": PASSWORD})
    assert registered.status_code == 201, registered.text
    logged_in = client.post("/api/v1/auth/login", json={"email": EMAIL, "password": PASSWORD})
    assert logged_in.status_code == 200, logged_in.text
    login_refresh = logged_in.json()["refresh_token"]
    rotated = client.post("/api/v1/auth/refresh", json={"refresh_token": login_refresh})
    assert rotated.status_code == 200, rotated.text
    access = rotated.json()["access_token"]
    refresh = rotated.json()["refresh_token"]
    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": login_refresh})
    assert reused.status_code == 401
    assert reused.json()["code"] == "TOKEN_REUSED"
    headers = {"Authorization": f"Bearer {access}"}

    me = client.get("/api/v1/me", headers=headers)
    assert me.status_code == 200, me.text
    assert me.json()["has_profile"] is False
    assert me.json()["email"] == EMAIL
    user_id = me.json()["user_id"]

    reference = client.get("/api/v1/reference")
    assert reference.status_code == 200, reference.text
    lists = reference.json()
    assert "LOSE" in lists["goal_types"]
    assert "MODERATE" in lists["activity_levels"]
    hypertension = next(row for row in lists["health_conditions"] if row["code"] == "HYPERTENSION")
    assert hypertension["is_supported"] is True

    saved = client.put("/api/v1/me/profile", json=_profile(), headers=headers)
    assert saved.status_code == 200, saved.text
    assert saved.json()["screening"]["eligible"] is True
    assert saved.json()["profile"]["goal_type"] == "LOSE"
    assert saved.json()["target"]["reason"] == "INITIAL"
    initial_target = saved.json()["target"]["target_id"]

    targets = client.get("/api/v1/me/targets", headers=headers)
    assert targets.status_code == 200, targets.text
    assert targets.json()["target"]["target_id"] == initial_target
    assert targets.json()["target"]["kcal"] > 0

    snapshot = client.get("/api/v1/catalog/snapshot", headers=headers)
    assert snapshot.status_code == 200, snapshot.text
    etag = snapshot.headers["etag"]
    assert etag
    assert snapshot.json()["meals"]
    cached = client.get("/api/v1/catalog/snapshot", headers={**headers, "If-None-Match": etag})
    assert cached.status_code == 304
    assert cached.content == b""

    generated = client.post("/api/v1/plans/days", json={"date": TODAY}, headers=headers)
    assert generated.status_code == 201, generated.text
    plan = generated.json()
    assert plan["date"] == TODAY
    assert plan["stats"]["solver_status"] in {"OPTIMAL", "FEASIBLE"}
    breakfast = next(item for item in plan["items"] if item["slot"] == "BREAKFAST")

    viewed = client.get(f"/api/v1/days/{TODAY}", headers=headers)
    assert viewed.status_code == 200, viewed.text
    assert viewed.json()["date"] == TODAY
    assert viewed.json()["plan"]["plan_id"] == plan["plan_id"]

    swap_item = next(item for item in plan["items"] if item["slot"] != "BREAKFAST")
    alternatives = client.get(
        f"/api/v1/plan-items/{swap_item['plan_item_id']}/alternatives", headers=headers
    )
    assert alternatives.status_code == 200, alternatives.text
    assert alternatives.json()
    swapped = client.post(
        f"/api/v1/plan-items/{swap_item['plan_item_id']}/swap",
        json={"meal_id": alternatives.json()[0]["meal"]["meal_id"]},
        headers=headers,
    )
    assert swapped.status_code == 200, swapped.text
    assert swapped.json()["was_swapped"] is True
    assert swapped.json()["meal"]["meal_id"] == alternatives.json()[0]["meal"]["meal_id"]

    shopping = client.get(
        "/api/v1/shopping-list", params={"from": TODAY, "to": TODAY}, headers=headers
    )
    assert shopping.status_code == 200, shopping.text
    assert shopping.json()["date_from"] == TODAY
    assert shopping.json()["items"]

    logged = client.post(
        "/api/v1/consumption-logs",
        json={
            "kind": "PLAN_ITEM",
            "client_uuid": str(uuid4()),
            "plan_item_id": breakfast["plan_item_id"],
            "servings_consumed": breakfast["servings_multiplier"],
            "consumed_at": AT,
        },
        headers=headers,
    )
    assert logged.status_code == 201, logged.text
    assert logged.json()["status"] == "CREATED"
    api_session.expire_all()
    accepts = api_session.scalar(
        select(func.count())
        .select_from(UserInteraction)
        .where(
            UserInteraction.user_id == user_id,
            UserInteraction.event_type == InteractionEventType.ACCEPT.value,
        )
    )
    assert accepts == 1

    catalog_meal = snapshot.json()["meals"][0]["meal_id"]
    meal_log = client.post(
        "/api/v1/consumption-logs",
        json={
            "kind": "MEAL",
            "client_uuid": str(uuid4()),
            "meal_id": catalog_meal,
            "servings_consumed": 1,
            "consumed_at": AT,
            "slot": "SNACK",
        },
        headers=headers,
    )
    assert meal_log.status_code == 201, meal_log.text
    assert meal_log.json()["kind"] == "MEAL"
    api_session.expire_all()
    assert (
        api_session.scalar(
            select(func.count())
            .select_from(UserInteraction)
            .where(
                UserInteraction.user_id == user_id,
                UserInteraction.event_type == InteractionEventType.ACCEPT.value,
            )
        )
        == 1
    )

    first_water = str(uuid4())
    glass = client.post(
        "/api/v1/water-logs",
        json={"client_uuid": first_water, "amount_ml": 250, "consumed_at": AT},
        headers=headers,
    )
    assert glass.status_code == 201, glass.text
    second = client.post(
        "/api/v1/water-logs",
        json={"client_uuid": str(uuid4()), "amount_ml": 300, "consumed_at": AT},
        headers=headers,
    )
    assert second.status_code == 201, second.text
    removed = client.delete(f"/api/v1/water-logs/{second.json()['log_id']}", headers=headers)
    assert removed.status_code == 204
    water = client.get("/api/v1/water", params={"date": TODAY}, headers=headers)
    assert water.status_code == 200, water.text
    assert water.json()["total_ml"] == 250

    weighed = client.put(
        f"/api/v1/weights/{TODAY}",
        json={"weight_kg": 80, "updated_at": "2026-10-12T09:01:00Z"},
        headers=headers,
    )
    assert weighed.status_code == 200, weighed.text
    assert weighed.json()["target_status"] == "CREATED"
    assert weighed.json()["new_target_id"] not in {None, initial_target}
    latest = client.get("/api/v1/me/targets", headers=headers)
    assert latest.json()["target"]["target_id"] == weighed.json()["new_target_id"]
    assert latest.json()["target"]["based_on_weight_kg"] == 80

    adherence = client.get(
        "/api/v1/adherence", params={"from": TODAY, "to": TODAY}, headers=headers
    )
    assert adherence.status_code == 200, adherence.text
    assert [day["date"] for day in adherence.json()["days"]] == [TODAY]
    assert adherence.json()["days"][0]["log_count"] >= 1

    batch = client.post(
        "/api/v1/sync/batch",
        json={
            "operations": [
                {
                    "op": "WATER_CREATE",
                    "op_id": str(uuid4()),
                    "client_uuid": str(uuid4()),
                    "amount_ml": 200,
                    "consumed_at": AT,
                },
                {
                    "op": "WATER_CREATE",
                    "op_id": str(uuid4()),
                    "client_uuid": first_water,
                    "amount_ml": 250,
                    "consumed_at": AT,
                },
                {
                    "op": "CONSUMPTION_DELETE",
                    "op_id": str(uuid4()),
                    "log_id": 999_999_999,
                },
            ]
        },
        headers=headers,
    )
    assert batch.status_code == 200, batch.text
    results = batch.json()["results"]
    assert [row["status"] for row in results] == ["CREATED", "DUPLICATE", "REJECTED"]
    assert results[2]["code"] == "LOG_NOT_FOUND"
    server_time = batch.json()["server_time"]

    changes = client.get("/api/v1/sync/changes", params={"since": server_time}, headers=headers)
    assert changes.status_code == 200, changes.text
    assert changes.json()["server_time"]
    water_ids = {row["log_id"] for row in changes.json()["water_logs"]}
    assert results[0]["entity_id"] in water_ids

    liked = client.put(
        f"/api/v1/me/meal-prefs/{catalog_meal}", json={"stance": "LIKE"}, headers=headers
    )
    assert liked.status_code == 200, liked.text
    assert liked.json()["stance"] == "LIKE"
    cleared = client.delete(f"/api/v1/me/meal-prefs/{catalog_meal}", headers=headers)
    assert cleared.status_code == 204
    prefs = client.get("/api/v1/me/meal-prefs", headers=headers)
    assert prefs.status_code == 200
    assert prefs.json() == []

    logout = client.post("/api/v1/auth/logout", json={"refresh_token": refresh})
    assert logout.status_code == 204
    deleted = client.delete("/api/v1/me", headers=headers)
    assert deleted.status_code == 204
    gone = client.get("/api/v1/me", headers=headers)
    assert gone.status_code == 401
    assert gone.json()["code"] == "UNAUTHORIZED"

    api_session.expire_all()
    for model in (
        User,
        UserProfile,
        UserTarget,
        WeightLog,
        MealPlan,
        ConsumptionLog,
        WaterLog,
        UserInteraction,
        UserMealPref,
        RefreshToken,
    ):
        assert _count(api_session, model, user_id) == 0
