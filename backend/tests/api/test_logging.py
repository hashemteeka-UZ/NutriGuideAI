"""Logging and progress over HTTP (I.6, #201 to #206)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import func, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.db.models import (
    ConsumptionLog,
    Food,
    Meal,
    MealPlanItem,
    User,
    UserInteraction,
    WaterLog,
    WeightLog,
)
from app.db.models.user import InteractionEventType
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.consumption import SNAPSHOT_NUTRIENTS_KEY
from app.services.planner import create_day_plan
from tests.api.conftest import NOW

TODAY = "2026-10-12"
AT = "2026-10-12T11:00:00+02:00"
PLAN_DAY = date(2026, 10, 12)
_UUID = "11111111-1111-4111-8111-111111111111"


def _auth(client: TestClient, email: str) -> dict[str, str]:
    response = client.post("/api/v1/auth/register", json={"email": email, "password": "password1"})
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


def _food_id(session: Session) -> int:
    return session.execute(
        select(Food.food_id).where(Food.external_source == "FDC", Food.external_code == "11215")
    ).scalar_one()


def _plan(session: Session, user_id: int) -> list[MealPlanItem]:
    plan = create_day_plan(session, user_id, PLAN_DAY, NOW, planner="greedy")
    return list(
        session.scalars(
            select(MealPlanItem)
            .where(MealPlanItem.plan_id == plan.plan_id)
            .order_by(MealPlanItem.id)
        ).all()
    )


def test_each_kind_duplicate_conflict_window_and_correction(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-flow@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "log-flow@example.com")
    items = _plan(api_session, user_id)
    breakfast = next(item for item in items if item.slot == "BREAKFAST")
    meal_id = breakfast.meal_id
    food_id = _food_id(api_session)

    plan_body = {
        "kind": "PLAN_ITEM",
        "client_uuid": str(uuid4()),
        "plan_item_id": breakfast.id,
        "servings_consumed": breakfast.servings_multiplier,
        "consumed_at": AT,
    }
    created = client.post("/api/v1/consumption-logs", json=plan_body, headers=headers)
    assert created.status_code == 201, created.text
    assert created.json()["status"] == "CREATED"
    assert created.json()["kind"] == "PLAN_ITEM"
    assert created.json()["name"]
    duplicate = client.post("/api/v1/consumption-logs", json=plan_body, headers=headers)
    assert duplicate.status_code == 200, duplicate.text
    assert duplicate.json()["status"] == "DUPLICATE"
    assert duplicate.json()["log_id"] == created.json()["log_id"]
    conflict = client.post(
        "/api/v1/consumption-logs",
        json={**plan_body, "servings_consumed": 0.5},
        headers=headers,
    )
    assert conflict.status_code == 409
    assert conflict.json()["code"] == "CLIENT_UUID_CONFLICT"
    accepts = list(
        api_session.scalars(
            select(UserInteraction).where(
                UserInteraction.user_id == user_id,
                UserInteraction.event_type == InteractionEventType.ACCEPT.value,
            )
        ).all()
    )
    assert len(accepts) == 1
    assert accepts[0].client_uuid is None
    assert set(accepts[0].context) == {
        "plan_id",
        "plan_item_id",
        "slot",
        "algorithm_version",
        "servings_ratio",
    }
    assert accepts[0].context["plan_item_id"] == breakfast.id
    assert accepts[0].context["slot"] == "BREAKFAST"
    assert accepts[0].context["servings_ratio"] == 1.0

    second = client.post(
        "/api/v1/consumption-logs",
        json={**plan_body, "client_uuid": str(uuid4())},
        headers=headers,
    )
    assert second.status_code == 409
    assert second.json()["code"] == "PLAN_ITEM_ALREADY_LOGGED"
    wrong_day = client.post(
        "/api/v1/consumption-logs",
        json={**plan_body, "client_uuid": str(uuid4()), "consumed_at": "2026-10-11T12:00:00+02:00"},
        headers=headers,
    )
    assert wrong_day.status_code == 422
    assert wrong_day.json()["code"] == "VALIDATION_ERROR"
    assert "plan date" in wrong_day.json()["detail"]

    meal_body = {
        "kind": "MEAL",
        "client_uuid": str(uuid4()),
        "meal_id": meal_id,
        "servings_consumed": 1,
        "consumed_at": AT,
        "slot": "SNACK",
    }
    snack = client.post("/api/v1/consumption-logs", json=meal_body, headers=headers)
    assert snack.status_code == 201, snack.text
    meal_again = client.post("/api/v1/consumption-logs", json=meal_body, headers=headers)
    assert meal_again.status_code == 200
    meal_conflict = client.post(
        "/api/v1/consumption-logs",
        json={**meal_body, "servings_consumed": 2},
        headers=headers,
    )
    assert meal_conflict.status_code == 409
    assert meal_conflict.json()["code"] == "CLIENT_UUID_CONFLICT"

    future = client.post(
        "/api/v1/consumption-logs",
        json={**meal_body, "client_uuid": str(uuid4()), "consumed_at": "2026-10-12T09:10:00Z"},
        headers=headers,
    )
    assert future.status_code == 422
    assert future.json()["code"] == "CLOCK_SKEW"
    too_old = client.post(
        "/api/v1/consumption-logs",
        json={**meal_body, "client_uuid": str(uuid4()), "consumed_at": "2026-09-11T12:00:00+02:00"},
        headers=headers,
    )
    assert too_old.status_code == 422
    assert too_old.json()["code"] == "VALIDATION_ERROR"
    recent = client.post(
        "/api/v1/consumption-logs",
        json={**meal_body, "client_uuid": str(uuid4()), "consumed_at": "2026-09-13T12:00:00+02:00"},
        headers=headers,
    )
    assert recent.status_code == 201, recent.text

    api_session.execute(update(Meal).where(Meal.meal_id == meal_id).values(is_active=False))
    api_session.flush()
    inactive = client.post(
        "/api/v1/consumption-logs",
        json={**meal_body, "client_uuid": str(uuid4())},
        headers=headers,
    )
    assert inactive.status_code == 404
    assert inactive.json()["code"] == "MEAL_NOT_FOUND"
    api_session.execute(update(Meal).where(Meal.meal_id == meal_id).values(is_active=True))
    api_session.flush()

    unknown = client.post(
        "/api/v1/consumption-logs",
        json={
            "kind": "FOOD",
            "client_uuid": str(uuid4()),
            "food_id": 999_999_999,
            "grams_consumed": 40,
            "consumed_at": AT,
        },
        headers=headers,
    )
    assert unknown.status_code == 404
    assert unknown.json()["code"] == "FOOD_NOT_FOUND"

    food_body = {
        "kind": "FOOD",
        "client_uuid": str(uuid4()),
        "food_id": food_id,
        "grams_consumed": 40,
        "consumed_at": AT,
        "slot": "SNACK",
    }
    food = client.post("/api/v1/consumption-logs", json=food_body, headers=headers)
    assert food.status_code == 201, food.text
    assert food.json()["kind"] == "FOOD"
    stored = api_session.get(ConsumptionLog, food.json()["log_id"])
    assert stored is not None
    assert stored.entry_group is None
    assert stored.entry_label is None
    food_again = client.post("/api/v1/consumption-logs", json=food_body, headers=headers)
    assert food_again.status_code == 200
    food_conflict = client.post(
        "/api/v1/consumption-logs",
        json={**food_body, "grams_consumed": 80},
        headers=headers,
    )
    assert food_conflict.status_code == 409

    nutrients = dict(stored.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY])
    nutrients.pop("fiber")
    stored.nutrients_snapshot = {**stored.nutrients_snapshot, SNAPSHOT_NUTRIENTS_KEY: nutrients}
    flag_modified(stored, "nutrients_snapshot")
    api_session.flush()
    listed_before = client.get("/api/v1/consumption-logs", params={"date": TODAY}, headers=headers)
    assert listed_before.status_code == 200
    food_row = next(row for row in listed_before.json() if row["log_id"] == food.json()["log_id"])
    assert food_row["nutrients"]["fiber_g"] is None
    assert food_row["nutrients"]["kcal"] not in (None, 0)

    grams = client.post(
        f"/api/v1/consumption-logs/{snack.json()['log_id']}/correction",
        json={"new_client_uuid": str(uuid4()), "grams_consumed": 100},
        headers=headers,
    )
    assert grams.status_code == 422
    assert grams.json()["code"] == "VALIDATION_ERROR"

    corrected = client.post(
        f"/api/v1/consumption-logs/{food.json()['log_id']}/correction",
        json={"new_client_uuid": str(uuid4()), "grams_consumed": 55},
        headers=headers,
    )
    assert corrected.status_code == 201, corrected.text
    assert corrected.json()["log_id"] != food.json()["log_id"]
    assert corrected.json()["grams_consumed"] == 55
    api_session.expire_all()
    old = api_session.get(ConsumptionLog, food.json()["log_id"])
    assert old is not None and old.deleted_at is not None
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

    removed = client.delete(f"/api/v1/consumption-logs/{snack.json()['log_id']}", headers=headers)
    assert removed.status_code == 204
    missing = client.delete(f"/api/v1/consumption-logs/{snack.json()['log_id']}", headers=headers)
    assert missing.status_code == 404
    assert missing.json()["code"] == "LOG_NOT_FOUND"
    listed = client.get("/api/v1/consumption-logs", params={"date": TODAY}, headers=headers)
    assert listed.status_code == 200, listed.text
    ids = {row["log_id"] for row in listed.json()}
    assert snack.json()["log_id"] not in ids
    assert food.json()["log_id"] not in ids
    assert corrected.json()["log_id"] in ids


def test_logging_every_plan_item_updates_the_day(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-day@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "log-day@example.com")
    items = _plan(api_session, user_id)
    for item in items:
        response = client.post(
            "/api/v1/consumption-logs",
            json={
                "kind": "PLAN_ITEM",
                "client_uuid": str(uuid4()),
                "plan_item_id": item.id,
                "servings_consumed": item.servings_multiplier,
                "consumed_at": AT,
            },
            headers=headers,
        )
        assert response.status_code == 201, response.text
    viewed = client.get(f"/api/v1/days/{TODAY}", headers=headers)
    assert viewed.status_code == 200, viewed.text
    body = viewed.json()
    assert all(item["logged"] is True for item in body["plan"]["items"])
    adherence = body["adherence"]
    assert adherence["plan_items_consumed"] == adherence["plan_items_total"] == len(items)
    assert adherence["log_count"] == len(items)
    assert adherence["status"] is not None


def test_water_weight_and_a_heart_disease_goal(
    client: TestClient, api_session: Session, now_clock: dict[str, datetime]
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-progress@example.com")
    _save(client, headers)
    heart = _auth(client, "log-heart@example.com")
    _save(client, heart, conditions=[{"code": "HEART_DISEASE", "severity": "MODERATE"}])
    dry = client.get("/api/v1/water", params={"date": TODAY}, headers=heart)
    assert dry.status_code == 200, dry.text
    assert dry.json()["goal"]["goal_ml"] is None
    assert dry.json()["goal"]["source"] == "NONE"
    assert dry.json()["total_ml"] == 0

    water_body = {"client_uuid": str(uuid4()), "amount_ml": 250, "consumed_at": AT}
    first = client.post("/api/v1/water-logs", json=water_body, headers=headers)
    assert first.status_code == 201, first.text
    assert first.json()["status"] == "CREATED"
    again = client.post("/api/v1/water-logs", json=water_body, headers=headers)
    assert again.status_code == 200
    assert again.json()["status"] == "DUPLICATE"
    clash = client.post(
        "/api/v1/water-logs", json={**water_body, "amount_ml": 300}, headers=headers
    )
    assert clash.status_code == 409
    assert clash.json()["code"] == "CLIENT_UUID_CONFLICT"
    second = client.post(
        "/api/v1/water-logs",
        json={"client_uuid": str(uuid4()), "amount_ml": 500, "consumed_at": AT},
        headers=headers,
    )
    assert second.status_code == 201, second.text
    removed = client.delete(f"/api/v1/water-logs/{second.json()['log_id']}", headers=headers)
    assert removed.status_code == 204
    day = client.get("/api/v1/water", params={"date": TODAY}, headers=headers)
    assert day.status_code == 200, day.text
    assert day.json()["total_ml"] == 250
    assert day.json()["goal"]["goal_ml"] == 2000
    assert day.json()["goal"]["source"] == "DEFAULT"
    assert [row["log_id"] for row in day.json()["logs"]] == [first.json()["log_id"]]

    created = client.put(
        "/api/v1/weights/2026-10-01",
        json={"weight_kg": 80, "updated_at": "2026-10-12T09:00:00Z"},
        headers=headers,
    )
    assert created.status_code == 200, created.text
    assert created.json()["status"] == "CREATED"
    updated = client.put(
        "/api/v1/weights/2026-10-01",
        json={"weight_kg": 79, "updated_at": "2026-10-12T09:01:00Z"},
        headers=headers,
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["status"] == "UPDATED"
    stale = client.put(
        "/api/v1/weights/2026-10-01",
        json={"weight_kg": 70, "updated_at": "2026-10-12T09:00:00Z"},
        headers=headers,
    )
    assert stale.status_code == 200, stale.text
    assert stale.json()["status"] == "STALE_IGNORED"
    assert stale.json()["weight_kg"] == 79
    future = client.put(
        "/api/v1/weights/2026-10-13",
        json={"weight_kg": 79, "updated_at": "2026-10-12T09:00:00Z"},
        headers=headers,
    )
    assert future.status_code == 422
    assert future.json()["code"] == "VALIDATION_ERROR"
    # The profile target is valid_from the frozen clock. A new target needs a later now.
    now_clock["now"] = NOW + timedelta(minutes=2)
    reached = client.put(
        f"/api/v1/weights/{TODAY}",
        json={"weight_kg": 76, "updated_at": "2026-10-12T09:02:00Z"},
        headers=headers,
    )
    assert reached.status_code == 200, reached.text
    assert reached.json()["status"] == "UPDATED"
    assert reached.json()["new_target_id"] is not None
    assert reached.json()["target_status"] == "CREATED"
    assert reached.json()["goal_reached"] is True
    weights = client.get(
        "/api/v1/weights", params={"from": "2026-10-01", "to": TODAY}, headers=headers
    )
    assert weights.status_code == 200, weights.text
    assert [row["measured_on"] for row in weights.json()] == ["2026-10-01", TODAY]
    assert weights.json()[-1]["weight_kg"] == 76

    no_profile = _auth(client, "log-empty@example.com")
    bare = client.get("/api/v1/water", params={"date": TODAY}, headers=no_profile)
    assert bare.status_code == 404
    assert bare.json()["code"] == "PROFILE_NOT_FOUND"
    adherence = client.get(
        "/api/v1/adherence", params={"from": TODAY, "to": TODAY}, headers=no_profile
    )
    assert adherence.status_code == 404
    assert adherence.json()["code"] == "PROFILE_NOT_FOUND"


def test_adherence_streak_and_the_92_day_limit(
    client: TestClient,
    api_session: Session,
    integrity_conn: Connection,
    now_clock: dict[str, datetime],
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-streak@example.com")
    now_clock["now"] = datetime(2026, 10, 10, 6, 0, tzinfo=UTC)
    _save(
        client,
        headers,
        sex="FEMALE",
        birth_date="2001-01-15",
        height_cm=155,
        activity_level="SEDENTARY",
        target_weight_kg=48,
        current_weight_kg=50,
        conditions=[
            {"code": "HYPERTENSION", "severity": "MODERATE"},
            {"code": "DIABETES_T2", "severity": "MODERATE"},
        ],
    )
    user_id = _user_id(integrity_conn, "log-streak@example.com")
    now_clock["now"] = NOW
    items = _plan(api_session, user_id)
    for offset in (2, 1, 0):
        moment = f"2026-10-{12 - offset:02d}T08:00:00Z"
        for item in items:
            response = client.post(
                "/api/v1/consumption-logs",
                json={
                    "kind": "MEAL",
                    "client_uuid": str(uuid4()),
                    "meal_id": item.meal_id,
                    "servings_consumed": item.servings_multiplier,
                    "consumed_at": moment,
                    "slot": item.slot,
                },
                headers=headers,
            )
            assert response.status_code == 201, response.text
    streak = client.get(
        "/api/v1/adherence",
        params={"from": "2026-10-10", "to": TODAY},
        headers=headers,
    )
    assert streak.status_code == 200, streak.text
    body = streak.json()
    assert [day["date"] for day in body["days"]] == ["2026-10-10", "2026-10-11", TODAY]
    assert [day["status"] for day in body["days"]] == ["ACHIEVED", "ACHIEVED", "ACHIEVED"]
    assert body["streak"] == 3
    too_long = client.get(
        "/api/v1/adherence",
        params={"from": "2026-07-01", "to": "2026-10-01"},
        headers=headers,
    )
    assert too_long.status_code == 422
    assert too_long.json()["code"] == "VALIDATION_ERROR"
    weights = client.get(
        "/api/v1/weights",
        params={"from": "2026-07-01", "to": "2026-10-01"},
        headers=headers,
    )
    assert weights.status_code == 422
    assert weights.json()["code"] == "VALIDATION_ERROR"


def test_interactions_and_another_users_ids(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-events@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "log-events@example.com")
    items = _plan(api_session, user_id)
    item = items[0]
    other_item = next(row for row in items if row.meal_id != item.meal_id)
    for event_type in ("IMPRESSION", "VIEW", "SAVE", "COOK", "SKIP"):
        response = client.post(
            "/api/v1/interactions",
            json={
                "client_uuid": str(uuid4()),
                "meal_id": item.meal_id,
                "event_type": event_type,
                "plan_item_id": item.id,
            },
            headers=headers,
        )
        assert response.status_code == 201, response.text
        assert response.json()["status"] == "CREATED"
    rated = client.post(
        "/api/v1/interactions",
        json={
            "client_uuid": str(uuid4()),
            "meal_id": item.meal_id,
            "event_type": "RATE",
            "value": 4,
        },
        headers=headers,
    )
    assert rated.status_code == 201, rated.text
    missing_value = client.post(
        "/api/v1/interactions",
        json={"client_uuid": str(uuid4()), "meal_id": item.meal_id, "event_type": "RATE"},
        headers=headers,
    )
    assert missing_value.status_code == 422
    assert missing_value.json()["code"] == "VALIDATION_ERROR"
    mismatch = client.post(
        "/api/v1/interactions",
        json={
            "client_uuid": str(uuid4()),
            "meal_id": other_item.meal_id,
            "event_type": "VIEW",
            "plan_item_id": item.id,
        },
        headers=headers,
    )
    assert mismatch.status_code == 422
    assert mismatch.json()["code"] == "VALIDATION_ERROR"

    view_body = {
        "client_uuid": str(uuid4()),
        "meal_id": item.meal_id,
        "event_type": "VIEW",
        "plan_item_id": item.id,
        "screen": "home",
    }
    viewed = client.post("/api/v1/interactions", json=view_body, headers=headers)
    assert viewed.status_code == 201, viewed.text
    duplicate = client.post("/api/v1/interactions", json=view_body, headers=headers)
    assert duplicate.status_code == 200
    assert duplicate.json()["status"] == "DUPLICATE"
    assert duplicate.json()["interaction_id"] == viewed.json()["interaction_id"]
    clash = client.post(
        "/api/v1/interactions",
        json={**view_body, "event_type": "SKIP"},
        headers=headers,
    )
    assert clash.status_code == 409
    assert clash.json()["code"] == "CLIENT_UUID_CONFLICT"

    other = _auth(client, "log-other@example.com")
    _save(client, other)
    foreign_item = client.post(
        "/api/v1/interactions",
        json={
            "client_uuid": str(uuid4()),
            "meal_id": item.meal_id,
            "event_type": "VIEW",
            "plan_item_id": item.id,
        },
        headers=other,
    )
    assert foreign_item.status_code == 404
    assert foreign_item.json()["code"] == "PLAN_ITEM_NOT_FOUND"
    foreign_log = client.delete(f"/api/v1/consumption-logs/{1}", headers=other)
    own_log = client.post(
        "/api/v1/consumption-logs",
        json={
            "kind": "MEAL",
            "client_uuid": str(uuid4()),
            "meal_id": item.meal_id,
            "servings_consumed": 1,
            "consumed_at": AT,
        },
        headers=headers,
    )
    assert own_log.status_code == 201, own_log.text
    stolen = client.delete(f"/api/v1/consumption-logs/{own_log.json()['log_id']}", headers=other)
    assert stolen.status_code == 404
    assert stolen.json()["code"] == "LOG_NOT_FOUND"
    water = client.post(
        "/api/v1/water-logs",
        json={"client_uuid": str(uuid4()), "amount_ml": 250, "consumed_at": AT},
        headers=headers,
    )
    assert water.status_code == 201, water.text
    stolen_water = client.delete(f"/api/v1/water-logs/{water.json()['log_id']}", headers=other)
    assert stolen_water.status_code == 404
    assert stolen_water.json()["code"] == "LOG_NOT_FOUND"
    assert foreign_log.status_code == 404


def test_delete_me_removes_logs_water_weights_and_interactions(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "log-delete@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "log-delete@example.com")
    meal = api_session.scalar(select(Meal.meal_id).where(Meal.is_active.is_(True)))
    assert meal is not None
    logged = client.post(
        "/api/v1/consumption-logs",
        json={
            "kind": "MEAL",
            "client_uuid": str(uuid4()),
            "meal_id": meal,
            "servings_consumed": 1,
            "consumed_at": AT,
        },
        headers=headers,
    )
    assert logged.status_code == 201, logged.text
    water = client.post(
        "/api/v1/water-logs",
        json={"client_uuid": str(uuid4()), "amount_ml": 250, "consumed_at": AT},
        headers=headers,
    )
    assert water.status_code == 201, water.text
    weight = client.put(
        "/api/v1/weights/2026-10-11",
        json={"weight_kg": 80, "updated_at": AT},
        headers=headers,
    )
    assert weight.status_code == 200, weight.text
    interaction = client.post(
        "/api/v1/interactions",
        json={"client_uuid": str(uuid4()), "meal_id": meal, "event_type": "VIEW"},
        headers=headers,
    )
    assert interaction.status_code == 201, interaction.text
    deleted = client.delete("/api/v1/me", headers=headers)
    assert deleted.status_code == 204
    api_session.expire_all()
    for model in (ConsumptionLog, WaterLog, WeightLog, UserInteraction):
        remaining = api_session.scalar(
            select(func.count()).select_from(model).where(model.user_id == user_id)
        )
        assert remaining == 0


def test_logging_routes_require_a_token(client: TestClient) -> None:
    calls = [
        (
            "POST",
            "/api/v1/consumption-logs",
            {
                "kind": "MEAL",
                "client_uuid": _UUID,
                "meal_id": 1,
                "servings_consumed": 1,
                "consumed_at": AT,
            },
            None,
        ),
        ("GET", "/api/v1/consumption-logs", None, {"date": TODAY}),
        (
            "POST",
            "/api/v1/consumption-logs/1/correction",
            {"new_client_uuid": _UUID, "servings_consumed": 1},
            None,
        ),
        ("DELETE", "/api/v1/consumption-logs/1", None, None),
        ("PUT", "/api/v1/weights/2026-10-12", {"weight_kg": 80, "updated_at": AT}, None),
        ("GET", "/api/v1/weights", None, {"from": TODAY, "to": TODAY}),
        ("GET", "/api/v1/water", None, {"date": TODAY}),
        (
            "POST",
            "/api/v1/water-logs",
            {"client_uuid": _UUID, "amount_ml": 250, "consumed_at": AT},
            None,
        ),
        ("DELETE", "/api/v1/water-logs/1", None, None),
        ("GET", "/api/v1/adherence", None, {"from": TODAY, "to": TODAY}),
        (
            "POST",
            "/api/v1/interactions",
            {"client_uuid": _UUID, "meal_id": 1, "event_type": "VIEW"},
            None,
        ),
    ]
    for method, path, body, params in calls:
        response = client.request(method, path, json=body, params=params)
        assert response.status_code == 401, (method, path, response.text)
        assert response.json()["code"] == "UNAUTHORIZED"
