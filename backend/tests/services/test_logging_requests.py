"""Request-layer logging: the time window, ACCEPT, names, and the adherence read cost."""

from __future__ import annotations

import time
from datetime import date, datetime, timedelta
from uuid import uuid4
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import event, func, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.db.models import ConsumptionLog, Food, Meal, UserInteraction
from app.db.models.user import InteractionEventType, MealPlanItem
from app.services.common import MealNotFoundError
from app.services.consumption import (
    SNAPSHOT_NUTRIENTS_KEY,
    ClientUuidConflictError,
    FoodNotFoundError,
    LogNotFoundError,
    LogStatus,
    PlanItemAlreadyLoggedError,
)
from app.services.interactions import record_interaction
from app.services.logging_requests import (
    LOG_HISTORY_DAYS,
    correct,
    create_log,
    delete,
    logs_of_day,
    snapshot_nutrients,
)
from app.services.planner import create_day_plan
from app.services.water import WaterStatus, delete_water, log_water
from app.services.weight import ClockSkewError
from tests.services.conftest import NOW, case_1_user, meal_id, plan_target

TRIPOLI = ZoneInfo("Africa/Tripoli")
TODAY = date(2026, 10, 6)  # NOW 09:00 UTC is 11:00 in Tripoli
AT = datetime(2026, 10, 6, 10, 0, tzinfo=TRIPOLI)  # 08:00 UTC, before NOW
GARLIC_NDB = "11215"


def _food_id(session: Session) -> int:
    return session.execute(
        select(Food.food_id).where(Food.external_source == "FDC", Food.external_code == GARLIC_NDB)
    ).scalar_one()


def _accepts(session: Session, user: int) -> list[UserInteraction]:
    return list(
        session.scalars(
            select(UserInteraction).where(
                UserInteraction.user_id == user,
                UserInteraction.event_type == InteractionEventType.ACCEPT.value,
            )
        ).all()
    )


def _selects(session: Session, call) -> int:
    statements: list[str] = []

    def _before(_conn, _cursor, statement: str, _parameters, _context, _executemany: bool) -> None:
        if statement.lstrip().upper().startswith(("SELECT", "WITH")):
            statements.append(statement)

    bind = session.connection()
    event.listen(bind, "before_cursor_execute", _before)
    try:
        call()
    finally:
        event.remove(bind, "before_cursor_execute", _before)
    return len(statements)


def test_snapshot_nutrient_missing_from_the_snapshot_is_null() -> None:
    totals = snapshot_nutrients({SNAPSHOT_NUTRIENTS_KEY: {"energy_kcal": "10", "protein": "1"}})
    assert totals["kcal"] == 10
    assert totals["protein_g"] == 1
    assert totals["fiber_g"] is None
    assert totals["sodium_mg"] is None


def test_window_plan_item_accept_and_food_columns(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, TODAY, NOW, planner="greedy")
    item = slice_session.scalars(
        select(MealPlanItem).where(
            MealPlanItem.plan_id == plan.plan_id, MealPlanItem.slot == "BREAKFAST"
        )
    ).one()
    meal = meal_id(slice_session, "F1-B01")
    client = uuid4()

    created = create_log(
        slice_session,
        user,
        kind="PLAN_ITEM",
        client_uuid=client,
        consumed_at=AT,
        now=NOW,
        lang="ar",
        plan_item_id=item.id,
        servings_consumed=item.servings_multiplier,
    )
    assert created.status is LogStatus.CREATED
    assert created.kind == "PLAN_ITEM"
    assert created.name
    accepts = _accepts(slice_session, user)
    assert len(accepts) == 1
    assert accepts[0].client_uuid is None
    assert accepts[0].meal_id == item.meal_id
    assert accepts[0].context == {
        "plan_id": plan.plan_id,
        "plan_item_id": item.id,
        "slot": item.slot,
        "algorithm_version": plan.algorithm_version,
        "servings_ratio": 1.0,
    }

    again = create_log(
        slice_session,
        user,
        kind="PLAN_ITEM",
        client_uuid=client,
        consumed_at=AT,
        now=NOW,
        lang="ar",
        plan_item_id=item.id,
        servings_consumed=item.servings_multiplier,
    )
    assert again.status is LogStatus.DUPLICATE
    assert again.log_id == created.log_id
    assert len(_accepts(slice_session, user)) == 1

    with pytest.raises(PlanItemAlreadyLoggedError):
        create_log(
            slice_session,
            user,
            kind="PLAN_ITEM",
            client_uuid=uuid4(),
            consumed_at=AT,
            now=NOW,
            lang="ar",
            plan_item_id=item.id,
            servings_consumed=item.servings_multiplier,
        )

    yesterday = datetime(2026, 10, 5, 10, 0, tzinfo=TRIPOLI)
    with pytest.raises(ValueError, match="plan date"):
        create_log(
            slice_session,
            user,
            kind="PLAN_ITEM",
            client_uuid=uuid4(),
            consumed_at=yesterday,
            now=NOW,
            lang="ar",
            plan_item_id=item.id,
            servings_consumed=1,
        )

    with pytest.raises(ClockSkewError):
        create_log(
            slice_session,
            user,
            kind="MEAL",
            client_uuid=uuid4(),
            consumed_at=NOW + timedelta(minutes=10),
            now=NOW,
            lang="ar",
            meal_id=meal,
            servings_consumed=1,
        )
    with pytest.raises(ValueError, match=str(LOG_HISTORY_DAYS)):
        create_log(
            slice_session,
            user,
            kind="MEAL",
            client_uuid=uuid4(),
            consumed_at=datetime(2026, 9, 5, 10, 0, tzinfo=TRIPOLI),
            now=NOW,
            lang="ar",
            meal_id=meal,
            servings_consumed=1,
        )
    allowed = create_log(
        slice_session,
        user,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 9, 7, 10, 0, tzinfo=TRIPOLI),
        now=NOW,
        lang="ar",
        meal_id=meal,
        servings_consumed=1,
        slot="SNACK",
    )
    assert allowed.status is LogStatus.CREATED
    boundary = create_log(
        slice_session,
        user,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=datetime(2026, 9, 6, 10, 0, tzinfo=TRIPOLI),
        now=NOW,
        lang="ar",
        meal_id=meal,
        servings_consumed=1,
    )
    assert boundary.status is LogStatus.CREATED

    slice_session.execute(update(Meal).where(Meal.meal_id == meal).values(is_active=False))
    with pytest.raises(MealNotFoundError):
        create_log(
            slice_session,
            user,
            kind="MEAL",
            client_uuid=uuid4(),
            consumed_at=AT,
            now=NOW,
            lang="ar",
            meal_id=meal,
            servings_consumed=1,
        )

    food = _food_id(slice_session)
    food_log = create_log(
        slice_session,
        user,
        kind="FOOD",
        client_uuid=uuid4(),
        consumed_at=AT,
        now=NOW,
        lang="en",
        food_id=food,
        grams_consumed=50,
        slot="SNACK",
    )
    assert food_log.kind == "FOOD"
    assert food_log.name
    stored = slice_session.get(ConsumptionLog, food_log.log_id)
    assert stored is not None
    assert stored.entry_group is None
    assert stored.entry_label is None
    with pytest.raises(FoodNotFoundError):
        create_log(
            slice_session,
            user,
            kind="FOOD",
            client_uuid=uuid4(),
            consumed_at=AT,
            now=NOW,
            lang="ar",
            food_id=999_999_999,
            grams_consumed=50,
        )


def test_correction_writes_no_accept_and_the_day_list_query_count_is_fixed(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, TODAY, NOW, planner="greedy")
    item = slice_session.scalars(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id)
    ).first()
    assert item is not None
    meal = item.meal_id
    created = create_log(
        slice_session,
        user,
        kind="PLAN_ITEM",
        client_uuid=uuid4(),
        consumed_at=AT,
        now=NOW,
        lang="ar",
        plan_item_id=item.id,
        servings_consumed=item.servings_multiplier,
    )
    corrected = correct(
        slice_session,
        user,
        created.log_id,
        new_client_uuid=uuid4(),
        now=NOW,
        lang="ar",
        servings_consumed=item.servings_multiplier,
        consumed_at=AT + timedelta(minutes=5),
    )
    assert corrected.status is LogStatus.CREATED
    assert corrected.log_id != created.log_id
    old = slice_session.get(ConsumptionLog, created.log_id)
    assert old is not None and old.deleted_at == NOW
    assert len(_accepts(slice_session, user)) == 1

    snack = create_log(
        slice_session,
        user,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=AT,
        now=NOW,
        lang="ar",
        meal_id=meal,
        servings_consumed=1,
        slot="SNACK",
    )
    with pytest.raises(ValueError, match="servings"):
        correct(
            slice_session,
            user,
            snack.log_id,
            new_client_uuid=uuid4(),
            now=NOW,
            lang="ar",
            grams_consumed=100,
        )
    delete(slice_session, user, snack.log_id, NOW)
    with pytest.raises(LogNotFoundError):
        delete(slice_session, user, snack.log_id, NOW)

    listed = logs_of_day(slice_session, user, TODAY, "ar")
    assert [row.log_id for row in listed] == [corrected.log_id]
    stored = slice_session.get(ConsumptionLog, corrected.log_id)
    assert stored is not None
    nutrients = dict(stored.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY])
    nutrients.pop("fiber")
    stored.nutrients_snapshot = {
        **stored.nutrients_snapshot,
        SNAPSHOT_NUTRIENTS_KEY: nutrients,
    }
    flag_modified(stored, "nutrients_snapshot")
    slice_session.flush()
    missing = logs_of_day(slice_session, user, TODAY, "ar")
    assert missing[0].nutrients["fiber_g"] is None
    assert missing[0].nutrients["kcal"] is not None

    one = _selects(slice_session, lambda: logs_of_day(slice_session, user, TODAY, "ar"))
    create_log(
        slice_session,
        user,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=AT,
        now=NOW,
        lang="ar",
        meal_id=meal,
        servings_consumed=1,
        slot="LUNCH",
    )
    two = _selects(slice_session, lambda: logs_of_day(slice_session, user, TODAY, "ar"))
    assert one == two == 2
    assert len(logs_of_day(slice_session, user, TODAY, "ar")) == 2


def test_water_duplicate_conflict_and_delete(session: Session, integrity_conn: Connection) -> None:
    user = case_1_user(integrity_conn)
    client = uuid4()
    created, status = log_water(session, user, 250, AT, client, NOW)
    assert status is WaterStatus.CREATED
    duplicate, again = log_water(session, user, 250, AT, client, NOW)
    assert again is WaterStatus.DUPLICATE
    assert duplicate.id == created.id
    with pytest.raises(ClientUuidConflictError):
        log_water(session, user, 300, AT, client, NOW)
    delete_water(session, user, created.id, NOW)
    with pytest.raises(LogNotFoundError):
        delete_water(session, user, created.id, NOW)


def test_interaction_guard_duplicate_and_conflict(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, TODAY, NOW, planner="greedy")
    item = slice_session.scalars(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id)
    ).first()
    assert item is not None
    other = slice_session.scalars(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id, MealPlanItem.id != item.id)
    ).first()
    assert other is not None
    client = uuid4()
    row, status = record_interaction(
        slice_session, user, client, item.meal_id, "VIEW", None, item.id, "plan", NOW
    )
    assert status is LogStatus.CREATED
    assert row.context["plan_id"] == plan.plan_id
    assert row.context["slot"] == item.slot
    assert row.context["algorithm_version"] == plan.algorithm_version
    assert row.context["screen"] == "plan"
    again, duplicate = record_interaction(
        slice_session, user, client, item.meal_id, "VIEW", None, item.id, "plan", NOW
    )
    assert duplicate is LogStatus.DUPLICATE
    assert again.id == row.id
    with pytest.raises(ClientUuidConflictError):
        record_interaction(
            slice_session, user, client, item.meal_id, "SKIP", None, item.id, "plan", NOW
        )
    with pytest.raises(ValueError, match="meal_id"):
        record_interaction(
            slice_session, user, uuid4(), other.meal_id, "VIEW", None, item.id, None, NOW
        )
    with pytest.raises(ValueError, match="RATE"):
        record_interaction(
            slice_session, user, uuid4(), item.meal_id, "RATE", None, None, None, NOW
        )
    with pytest.raises(ValueError, match="client event"):
        record_interaction(
            slice_session, user, uuid4(), item.meal_id, "ACCEPT", None, None, None, NOW
        )


def test_adherence_range_query_cost_for_31_and_92_days(
    slice_session: Session, integrity_conn: Connection
) -> None:
    """Measured, not optimised (#206). The listener is attached, so the times include it."""
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    meal = meal_id(slice_session, "F1-B01")
    create_log(
        slice_session,
        user,
        kind="MEAL",
        client_uuid=uuid4(),
        consumed_at=AT,
        now=NOW,
        lang="ar",
        meal_id=meal,
        servings_consumed=1,
    )
    from app.services.adherence import adherence_range

    def _measure(days: int) -> tuple[int, float]:
        start = TODAY - timedelta(days=days - 1)
        queries = 0
        began = time.perf_counter()

        def _run() -> None:
            nonlocal queries
            queries = _selects(
                slice_session, lambda: adherence_range(slice_session, user, start, TODAY)
            )

        _run()
        return queries, time.perf_counter() - began

    queries_31, seconds_31 = _measure(31)
    queries_92, seconds_92 = _measure(92)
    assert queries_31 > 0
    assert queries_92 >= queries_31
    count = slice_session.execute(
        select(func.count()).select_from(ConsumptionLog).where(ConsumptionLog.user_id == user)
    ).scalar_one()
    assert count >= 1
    print(
        f"ADHERENCE_RANGE queries_31={queries_31} seconds_31={seconds_31:.4f} "
        f"queries_92={queries_92} seconds_92={seconds_92:.4f}"
    )
