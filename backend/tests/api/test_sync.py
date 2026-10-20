"""Offline batch upload and the change feed (I.7, #208 to #211)."""

from __future__ import annotations

import time
from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import event, func, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.api.limiting import limiter
from app.db.models import (
    ConsumptionLog,
    MealPlanItem,
    User,
    UserInteraction,
    UserTarget,
    WaterLog,
)
from app.db.models.user import InteractionEventType
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.logging_requests import create_log
from app.services.planner import create_day_plan
from tests.api.conftest import NOW

TODAY = "2026-10-12"
AT = "2026-10-12T11:00:00+02:00"
PLAN_DAY = date(2026, 10, 12)


def _auth(client: TestClient, email: str) -> dict[str, str]:
    response = client.post("/api/v1/auth/register", json={"email": email, "password": "password1"})
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


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


def _save(client: TestClient, headers: dict[str, str]) -> None:
    saved = client.put("/api/v1/me/profile", json=_profile(), headers=headers)
    assert saved.status_code == 200, saved.text


def _user_id(conn: Connection, email: str) -> int:
    return conn.execute(select(User.user_id).where(User.email == email)).scalar_one()


def _items(session: Session, user_id: int, now: datetime = NOW) -> list[MealPlanItem]:
    plan = create_day_plan(session, user_id, PLAN_DAY, now, planner="greedy")
    return list(
        session.scalars(
            select(MealPlanItem)
            .where(MealPlanItem.plan_id == plan.plan_id)
            .order_by(MealPlanItem.id)
        ).all()
    )


def _water(op_id: str | None = None) -> dict[str, object]:
    return {
        "op": "WATER_CREATE",
        "op_id": op_id or str(uuid4()),
        "client_uuid": str(uuid4()),
        "amount_ml": 250,
        "consumed_at": AT,
    }


def _post(client: TestClient, headers: dict[str, str], operations: list[dict[str, object]]):
    return client.post("/api/v1/sync/batch", json={"operations": operations}, headers=headers)


def _selects(session: Session, call) -> tuple[int, float]:
    statements: list[str] = []

    def _before(_conn, _cursor, statement: str, _parameters, _context, _executemany: bool) -> None:
        if statement.lstrip().upper().startswith(("SELECT", "WITH")):
            statements.append(statement)

    bind = session.connection()
    event.listen(bind, "before_cursor_execute", _before)
    started = time.perf_counter()
    try:
        call()
    finally:
        event.remove(bind, "before_cursor_execute", _before)
    return len(statements), time.perf_counter() - started


def test_batch_is_idempotent_and_writes_accept_once(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "sync-batch@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "sync-batch@example.com")
    items = _items(api_session, user_id)
    breakfast = next(item for item in items if item.slot == "BREAKFAST")
    meal_uuid = str(uuid4())
    water_uuid = str(uuid4())
    view_uuid = str(uuid4())
    weight_uuid = str(uuid4())
    meal_op = str(uuid4())
    first = [
        {
            "op": "CONSUMPTION_CREATE",
            "op_id": meal_op,
            "log": {
                "kind": "MEAL",
                "client_uuid": meal_uuid,
                "meal_id": breakfast.meal_id,
                "servings_consumed": 1,
                "consumed_at": AT,
                "slot": "SNACK",
            },
        },
        {
            "op": "WATER_CREATE",
            "op_id": str(uuid4()),
            "client_uuid": water_uuid,
            "amount_ml": 250,
            "consumed_at": AT,
        },
        {
            "op": "WEIGHT_PUT",
            "op_id": weight_uuid,
            "measured_on": "2026-10-01",
            "weight_kg": 81,
            "updated_at": "2026-10-12T09:00:00Z",
        },
        {
            "op": "INTERACTION_CREATE",
            "op_id": str(uuid4()),
            "client_uuid": view_uuid,
            "meal_id": breakfast.meal_id,
            "event_type": "VIEW",
            "screen": "plan",
        },
    ]
    created = _post(client, headers, first)
    assert created.status_code == 200, created.text
    body = created.json()
    assert [row["status"] for row in body["results"]] == [
        "CREATED",
        "CREATED",
        "CREATED",
        "CREATED",
    ]
    meal_log = body["results"][0]["entity_id"]
    assert meal_log
    assert body["results"][2]["entity_id"] is None
    accepts = api_session.scalar(
        select(func.count())
        .select_from(UserInteraction)
        .where(
            UserInteraction.user_id == user_id,
            UserInteraction.event_type == InteractionEventType.ACCEPT.value,
        )
    )
    assert accepts == 0

    plan_op = {
        "op": "CONSUMPTION_CREATE",
        "op_id": str(uuid4()),
        "log": {
            "kind": "PLAN_ITEM",
            "client_uuid": str(uuid4()),
            "plan_item_id": breakfast.id,
            "servings_consumed": breakfast.servings_multiplier,
            "consumed_at": AT,
        },
    }
    planned = _post(client, headers, [plan_op])
    assert planned.status_code == 200, planned.text
    assert planned.json()["results"][0]["status"] == "CREATED"
    again = _post(client, headers, [plan_op])
    assert again.json()["results"][0]["status"] == "DUPLICATE"
    accepts = api_session.scalar(
        select(func.count())
        .select_from(UserInteraction)
        .where(
            UserInteraction.user_id == user_id,
            UserInteraction.event_type == InteractionEventType.ACCEPT.value,
        )
    )
    assert accepts == 1

    correct_uuid = str(uuid4())
    corrected = _post(
        client,
        headers,
        [
            {
                "op": "CONSUMPTION_CORRECT",
                "op_id": str(uuid4()),
                "log_id": meal_log,
                "new_client_uuid": correct_uuid,
                "servings_consumed": 0.5,
            }
        ],
    )
    assert corrected.status_code == 200, corrected.text
    assert corrected.json()["results"][0]["status"] == "CREATED"
    new_log = corrected.json()["results"][0]["entity_id"]
    same_correction = _post(
        client,
        headers,
        [
            {
                "op": "CONSUMPTION_CORRECT",
                "op_id": str(uuid4()),
                "log_id": meal_log,
                "new_client_uuid": correct_uuid,
                "servings_consumed": 0.5,
            }
        ],
    )
    assert same_correction.json()["results"][0]["status"] == "DUPLICATE"
    assert same_correction.json()["results"][0]["entity_id"] == new_log

    removed = _post(
        client,
        headers,
        [{"op": "CONSUMPTION_DELETE", "op_id": str(uuid4()), "log_id": new_log}],
    )
    assert removed.json()["results"][0]["status"] == "UPDATED"
    deleted_again = _post(
        client,
        headers,
        [{"op": "CONSUMPTION_DELETE", "op_id": str(uuid4()), "log_id": new_log}],
    )
    assert deleted_again.json()["results"][0]["status"] == "DUPLICATE"

    water_delete = _post(
        client,
        headers,
        [
            {
                "op": "WATER_DELETE",
                "op_id": str(uuid4()),
                "log_id": body["results"][1]["entity_id"],
            }
        ],
    )
    assert water_delete.json()["results"][0]["status"] == "UPDATED"

    duplicate = _post(client, headers, first)
    assert [row["status"] for row in duplicate.json()["results"]] == [
        "DUPLICATE",
        "DUPLICATE",
        "DUPLICATE",
        "DUPLICATE",
    ]
    meal_rows = api_session.scalar(
        select(func.count()).select_from(ConsumptionLog).where(ConsumptionLog.user_id == user_id)
    )
    assert meal_rows == 3

    stale = _post(
        client,
        headers,
        [
            {
                "op": "WEIGHT_PUT",
                "op_id": str(uuid4()),
                "measured_on": TODAY,
                "weight_kg": 70,
                "updated_at": "2026-10-12T08:00:00Z",
            }
        ],
    )
    assert stale.json()["results"][0]["status"] == "DUPLICATE"


def test_a_rejected_operation_does_not_drop_the_rest(
    client: TestClient, api_session: Session, integrity_conn: Connection, monkeypatch
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "sync-reject@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "sync-reject@example.com")
    other = _auth(client, "sync-other@example.com")
    _save(client, other)
    other_id = _user_id(integrity_conn, "sync-other@example.com")
    items = _items(api_session, other_id)
    foreign = create_log(
        api_session,
        other_id,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 10, 12, 9, 0, tzinfo=UTC),
        now=NOW,
        lang="en",
        meal_id=items[0].meal_id,
        servings_consumed=1,
        slot="SNACK",
    )
    mixed = _post(
        client,
        headers,
        [
            _water(),
            {
                "op": "CONSUMPTION_CREATE",
                "op_id": str(uuid4()),
                "log": {
                    "kind": "MEAL",
                    "client_uuid": str(uuid4()),
                    "meal_id": 999999,
                    "servings_consumed": 1,
                    "consumed_at": AT,
                },
            },
            _water(),
            {
                "op": "CONSUMPTION_DELETE",
                "op_id": str(uuid4()),
                "log_id": foreign.log_id,
            },
        ],
    )
    assert mixed.status_code == 200, mixed.text
    statuses = [(row["status"], row["code"]) for row in mixed.json()["results"]]
    assert statuses[0] == ("CREATED", None)
    assert statuses[1] == ("REJECTED", "MEAL_NOT_FOUND")
    assert statuses[2] == ("CREATED", None)
    assert statuses[3] == ("REJECTED", "LOG_NOT_FOUND")
    stored = api_session.scalar(
        select(func.count()).select_from(WaterLog).where(WaterLog.user_id == user_id)
    )
    assert stored == 2

    def _boom(*_args: object, **_kwargs: object) -> None:
        raise RuntimeError("sync-boom-secret")

    monkeypatch.setattr("app.services.sync_batch.record_interaction", _boom)
    failed = _post(
        client,
        headers,
        [
            _water(),
            {
                "op": "INTERACTION_CREATE",
                "op_id": str(uuid4()),
                "client_uuid": str(uuid4()),
                "meal_id": items[0].meal_id,
                "event_type": "VIEW",
            },
        ],
    )
    assert failed.status_code == 500, failed.text
    assert failed.json()["code"] == "INTERNAL_ERROR"
    assert "sync-boom-secret" not in failed.text
    api_session.expire_all()
    stored = api_session.scalar(
        select(func.count()).select_from(WaterLog).where(WaterLog.user_id == user_id)
    )
    assert stored == 2


def test_batch_size_and_rate_limit(client: TestClient, api_session: Session) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "sync-size@example.com")
    _save(client, headers)
    too_many = _post(client, headers, [_water() for _ in range(501)])
    assert too_many.status_code == 422
    assert too_many.json()["code"] == "VALIDATION_ERROR"

    operations = [_water() for _ in range(500)]

    def _send() -> None:
        response = _post(client, headers, operations)
        assert response.status_code == 200, response.text
        assert [row["status"] for row in response.json()["results"]] == ["CREATED"] * 500

    queries, elapsed = _selects(api_session, _send)
    print(f"SYNC_BATCH_500 queries={queries} seconds={elapsed:.4f}")

    limiter.reset()
    limiter.enabled = True
    try:
        for _ in range(60):
            response = _post(client, headers, [_water()])
            assert response.status_code == 200, response.text
        blocked = _post(client, headers, [_water()])
    finally:
        limiter.enabled = False
        limiter.reset()
    assert blocked.status_code == 429
    assert blocked.json()["code"] == "RATE_LIMITED"


def test_change_feed_window_overlap_swap_and_target(
    client: TestClient,
    api_session: Session,
    integrity_conn: Connection,
    now_clock: dict[str, datetime],
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "sync-feed@example.com")
    now_clock["now"] = NOW - timedelta(hours=1)
    _save(client, headers)
    now_clock["now"] = NOW
    user_id = _user_id(integrity_conn, "sync-feed@example.com")
    items = _items(api_session, user_id, NOW - timedelta(minutes=10))
    breakfast = next(item for item in items if item.slot == "BREAKFAST")
    other = _auth(client, "sync-feed-other@example.com")
    _save(client, other)
    other_id = _user_id(integrity_conn, "sync-feed-other@example.com")
    foreign = create_log(
        api_session,
        other_id,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 10, 12, 9, 0, tzinfo=UTC),
        now=NOW,
        lang="en",
        meal_id=breakfast.meal_id,
        servings_consumed=1,
        slot="SNACK",
    )
    old = create_log(
        api_session,
        user_id,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 10, 12, 8, 50, tzinfo=UTC),
        now=NOW - timedelta(minutes=10),
        lang="en",
        meal_id=breakfast.meal_id,
        servings_consumed=1,
        slot="LUNCH",
    )
    since = NOW - timedelta(minutes=1)
    overlapped = create_log(
        api_session,
        user_id,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 10, 12, 8, 58, tzinfo=UTC),
        now=since - timedelta(minutes=1),
        lang="en",
        meal_id=breakfast.meal_id,
        servings_consumed=1,
        slot="DINNER",
    )
    plan_id = breakfast.plan_id
    breakfast_id = breakfast.id
    # user_targets.created_at is the database clock, not the frozen request clock.
    api_session.execute(
        update(UserTarget)
        .where(UserTarget.user_id == user_id)
        .values(created_at=NOW - timedelta(hours=1))
    )
    api_session.commit()

    future = client.get(
        "/api/v1/sync/changes",
        params={"since": (NOW + timedelta(minutes=10)).isoformat()},
        headers=headers,
    )
    assert future.status_code == 422
    assert future.json()["code"] == "CLOCK_SKEW"
    aged = client.get(
        "/api/v1/sync/changes",
        params={"since": (NOW - timedelta(days=31)).isoformat()},
        headers=headers,
    )
    assert aged.status_code == 422
    assert aged.json()["code"] == "VALIDATION_ERROR"
    assert "reload" in aged.json()["detail"]

    quiet = client.get("/api/v1/sync/changes", params={"since": since.isoformat()}, headers=headers)
    assert quiet.status_code == 200, quiet.text
    quiet_body = quiet.json()
    ids = {row["log_id"] for row in quiet_body["consumption_logs"]}
    assert overlapped.log_id in ids
    assert old.log_id not in ids
    assert foreign.log_id not in ids
    assert quiet_body["profile_changed"] is False
    assert quiet_body["plans"] == []

    fresh = _post(
        client,
        headers,
        [
            {
                "op": "CONSUMPTION_CREATE",
                "op_id": str(uuid4()),
                "log": {
                    "kind": "MEAL",
                    "client_uuid": str(uuid4()),
                    "meal_id": breakfast.meal_id,
                    "servings_consumed": 1,
                    "consumed_at": AT,
                    "slot": "SNACK",
                },
            }
        ],
    )
    fresh_id = fresh.json()["results"][0]["entity_id"]
    deleted = client.delete(f"/api/v1/consumption-logs/{fresh_id}", headers=headers)
    assert deleted.status_code == 204, deleted.text
    after = client.get("/api/v1/sync/changes", params={"since": since.isoformat()}, headers=headers)
    after_body = after.json()
    assert fresh_id in after_body["deleted_consumption_log_ids"]
    assert fresh_id not in {row["log_id"] for row in after_body["consumption_logs"]}

    alternatives = client.get(f"/api/v1/plan-items/{breakfast_id}/alternatives", headers=headers)
    assert alternatives.status_code == 200, alternatives.text
    assert alternatives.json()
    swapped = client.post(
        f"/api/v1/plan-items/{breakfast_id}/swap",
        json={"meal_id": alternatives.json()[0]["meal"]["meal_id"]},
        headers=headers,
    )
    assert swapped.status_code == 200, swapped.text
    fed = client.get("/api/v1/sync/changes", params={"since": since.isoformat()}, headers=headers)
    plan_ids = {plan["plan_id"] for plan in fed.json()["plans"]}
    assert plan_id in plan_ids

    reached = client.put(
        f"/api/v1/weights/{TODAY}",
        json={"weight_kg": 80, "updated_at": "2026-10-12T09:00:00Z"},
        headers=headers,
    )
    assert reached.status_code == 200, reached.text
    assert reached.json()["target_status"] == "CREATED"
    changed = client.get(
        "/api/v1/sync/changes", params={"since": since.isoformat()}, headers=headers
    )
    assert changed.json()["profile_changed"] is True
    assert any(row["measured_on"] == TODAY for row in changed.json()["weights"])


def test_two_weights_in_one_batch_share_now_and_both_apply(
    client: TestClient, api_session: Session, integrity_conn: Connection
) -> None:
    """82.5 then 80 then 78, one server instant: both writes apply and a resend is duplicate."""
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    headers = _auth(client, "sync-weights@example.com")
    _save(client, headers)
    user_id = _user_id(integrity_conn, "sync-weights@example.com")
    operations = [
        {
            "op": "WEIGHT_PUT",
            "op_id": str(uuid4()),
            "measured_on": TODAY,
            "weight_kg": 80,
            "updated_at": "2026-10-12T09:01:00Z",
        },
        {
            "op": "WEIGHT_PUT",
            "op_id": str(uuid4()),
            "measured_on": TODAY,
            "weight_kg": 78,
            "updated_at": "2026-10-12T09:02:00Z",
        },
    ]
    first = _post(client, headers, operations)
    assert first.status_code == 200, first.text
    assert [row["status"] for row in first.json()["results"]] == ["UPDATED", "UPDATED"]
    api_session.expire_all()
    rows = list(
        api_session.scalars(
            select(UserTarget)
            .where(UserTarget.user_id == user_id)
            .order_by(UserTarget.valid_from, UserTarget.target_id)
        ).all()
    )
    assert len(rows) == 3
    open_rows = [row for row in rows if row.valid_to is None]
    assert len(open_rows) == 1
    assert open_rows[0].based_on_weight_kg == 78
    assert open_rows[0].reason == "WEIGHT_UPDATE"

    again = _post(client, headers, operations)
    assert again.status_code == 200, again.text
    assert [row["status"] for row in again.json()["results"]] == ["DUPLICATE", "DUPLICATE"]
    api_session.expire_all()
    after = api_session.scalar(
        select(func.count()).select_from(UserTarget).where(UserTarget.user_id == user_id)
    )
    assert after == 3
