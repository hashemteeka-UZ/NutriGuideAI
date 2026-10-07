"""Daily adherence (§30.5) from consumption_logs and the current plan covering the day."""

from __future__ import annotations

from datetime import date, datetime, timedelta
from decimal import Decimal
from uuid import uuid4
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Food, FoodNutrient, Nutrient, UserTarget
from app.db.models.user import MealPlanItem, TargetReason
from app.services.adherence import (
    NO_TARGET,
    DayStatus,
    adherence_range,
    daily_adherence,
    day_status,
    snapshot_totals,
)
from app.services.common import to_decimal
from app.services.consumption import (
    SNAPSHOT_NUTRIENTS_KEY,
    active_logs,
    delete_log,
    log_food,
    log_meal,
    log_plan_item,
)
from app.services.planner import create_day_plan
from app.services.targets import create_user_target
from tests.builders import make_user_profile, make_weight_log
from tests.services.conftest import NOW, PLAN_DATE, htn_dm2_plan

D = Decimal
EATEN = datetime(2026, 10, 7, 12, 0, tzinfo=ZoneInfo("Africa/Tripoli"))
GARLIC_NDB = "11215"


def _items(session: Session, plan_id: int) -> list[MealPlanItem]:
    return list(
        session.execute(
            select(MealPlanItem).where(MealPlanItem.plan_id == plan_id).order_by(MealPlanItem.id)
        ).scalars()
    )


def _log_items(
    session: Session, user: int, items: list[MealPlanItem], consumed_at: datetime = EATEN
) -> None:
    for item in items:
        log_plan_item(
            session, user, item.id, to_decimal(item.servings_multiplier), consumed_at, uuid4(), NOW
        )


def _log_off_plan_copies(
    session: Session,
    user: int,
    items: list[MealPlanItem],
    consumed_at: datetime,
    scale: Decimal | None = None,
) -> None:
    """Off-plan copies: one active log per plan item would block reuse across days."""
    servings_scale = D(1) if scale is None else scale
    for item in items:
        log_meal(
            session,
            user,
            item.meal_id,
            to_decimal(item.servings_multiplier) * servings_scale,
            consumed_at,
            item.slot,
            uuid4(),
            NOW,
        )


def test_status_boundaries_are_inclusive() -> None:
    target = D(1000)
    assert day_status(D(900), target, True) is DayStatus.ACHIEVED
    assert day_status(D(1100), target, True) is DayStatus.ACHIEVED
    assert day_status(D(1100), target, False) is DayStatus.PARTIAL
    assert day_status(D(750), target, True) is DayStatus.PARTIAL
    assert day_status(D(1250), target, True) is DayStatus.PARTIAL
    assert day_status(D("749.9"), target, True) is DayStatus.NOT_ACHIEVED
    assert day_status(D("1250.1"), target, True) is DayStatus.NOT_ACHIEVED
    assert day_status(None, target, True) is DayStatus.NOT_ACHIEVED


def test_snapshot_totals_leave_a_missing_nutrient_unknown() -> None:
    snapshots = [
        {SNAPSHOT_NUTRIENTS_KEY: {"energy_kcal": "10", "sodium": "1"}},
        {SNAPSHOT_NUTRIENTS_KEY: {"energy_kcal": "5"}},
    ]
    totals = snapshot_totals(snapshots, ["energy_kcal", "sodium"])
    assert totals["energy_kcal"] == 15
    assert totals["sodium"] is None


def test_logging_every_plan_item_is_achieved_with_completion_one(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    items = _items(slice_session, plan.plan_id)
    _log_items(slice_session, user, items)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    target_kcal = to_decimal(plan.target_snapshot["target"]["kcal"])
    energy = day.totals["energy_kcal"]
    sodium = day.totals["sodium"]
    assert energy is not None and sodium is not None
    assert abs(energy - target_kcal) <= D("0.10") * target_kcal
    assert sodium <= D(str(plan.target_snapshot["limits"]["max_per_day"]["sodium"]["value"]))
    assert day.status is DayStatus.ACHIEVED
    assert day.reason is None
    assert day.completion == D("1.000")
    assert day.plan_items_consumed == day.plan_items_total == len(items)
    assert day.plan_id == plan.plan_id
    assert day.exceeded_max_per_day == ()
    fiber = day.totals["fiber"]
    assert fiber is not None
    if fiber < 25:
        assert [u.nutrient for u in day.unmet_minimums] == ["fiber"]
    else:
        assert day.unmet_minimums == ()
    assert day.fiber_target_g == 17


def test_logging_only_breakfast_sets_completion_to_one_over_n(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    items = _items(slice_session, plan.plan_id)
    breakfast = next(i for i in items if i.slot == "BREAKFAST")
    _log_items(slice_session, user, [breakfast])
    day = daily_adherence(slice_session, user, PLAN_DATE)
    assert day.completion == D(1) / D(len(items))
    assert day.completion == D("0.250")
    assert day.plan_items_consumed == 1
    energy = day.totals["energy_kcal"]
    target = to_decimal(plan.target_snapshot["target"]["kcal"])
    assert energy is not None
    assert day.status is day_status(energy, target, not day.exceeded_max_per_day)


def test_off_plan_food_that_exceeds_sodium_is_not_achieved(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    _log_items(slice_session, user, _items(slice_session, plan.plan_id))
    before = daily_adherence(slice_session, user, PLAN_DATE)
    assert before.status is DayStatus.ACHIEVED
    sodium_limit = D(str(plan.target_snapshot["limits"]["max_per_day"]["sodium"]["value"]))
    assert before.totals["sodium"] is not None
    need = sodium_limit - before.totals["sodium"] + 1
    food = slice_session.execute(
        select(Food.food_id).where(Food.external_source == "FDC", Food.external_code == GARLIC_NDB)
    ).scalar_one()
    sodium_id = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "sodium")
    ).scalar_one()
    per_100 = to_decimal(
        slice_session.execute(
            select(FoodNutrient.amount_per_100g).where(
                FoodNutrient.food_id == food, FoodNutrient.nutrient_id == sodium_id
            )
        ).scalar_one()
    )
    grams = (need / per_100 * 100).quantize(D("0.001"))
    kcal = (
        to_decimal(
            slice_session.execute(
                select(FoodNutrient.amount_per_100g)
                .join(Nutrient, Nutrient.nutrient_id == FoodNutrient.nutrient_id)
                .where(FoodNutrient.food_id == food, Nutrient.code == "energy_kcal")
            ).scalar_one()
        )
        * grams
        / 100
    )
    log_food(slice_session, user, food, grams, EATEN, None, uuid4(), NOW)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    target = to_decimal(plan.target_snapshot["target"]["kcal"])
    assert day.totals["sodium"] is not None and day.totals["sodium"] > sodium_limit
    assert any(e.nutrient == "sodium" for e in day.exceeded_max_per_day)
    assert day.status is not DayStatus.ACHIEVED
    energy = day.totals["energy_kcal"]
    assert energy is not None
    assert energy == before.totals["energy_kcal"] + kcal
    if abs(energy - target) <= D("0.10") * target:
        assert day.status is DayStatus.PARTIAL


def test_tombstones_and_empty_days_are_not_achieved(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    empty = daily_adherence(slice_session, user, PLAN_DATE)
    assert empty.status is DayStatus.NOT_ACHIEVED
    assert empty.log_count == 0
    assert empty.totals["energy_kcal"] == 0
    assert empty.completion == 0

    items = _items(slice_session, plan.plan_id)
    _log_items(slice_session, user, items)
    for log in active_logs(slice_session, user, PLAN_DATE):
        delete_log(slice_session, user, log.id, NOW)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    assert day.status is DayStatus.NOT_ACHIEVED
    assert day.log_count == 0
    assert day.plan_items_consumed == 0
    assert day.completion == 0


def test_mid_day_target_change_applies_to_the_whole_local_day(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    first = slice_session.execute(
        select(UserTarget).where(UserTarget.user_id == user, UserTarget.valid_to.is_(None))
    ).scalar_one()
    morning = datetime(2026, 10, 7, 8, 0, tzinfo=ZoneInfo("Africa/Tripoli"))
    breakfast = next(i for i in _items(slice_session, plan.plan_id) if i.slot == "BREAKFAST")
    log_plan_item(
        slice_session, user, breakfast.id, breakfast.servings_multiplier, morning, uuid4(), NOW
    )
    make_weight_log(integrity_conn, user_id=user, measured_on=date(2026, 10, 7), weight_kg=55)
    changed_at = datetime(2026, 10, 7, 15, 0, tzinfo=ZoneInfo("Africa/Tripoli"))
    second = create_user_target(slice_session, user, TargetReason.WEIGHT_UPDATE, changed_at)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    assert day.target_id == second.target_id != first.target_id
    assert day.target_kcal == to_decimal(second.target_kcal)
    assert day.log_count == 1
    assert active_logs(slice_session, user, PLAN_DATE)[0].consumed_at == morning


def test_newer_plan_replaces_the_old_one_in_completion(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, first = htn_dm2_plan(slice_session, integrity_conn)
    _log_items(slice_session, user, _items(slice_session, first.plan_id))
    later = NOW + timedelta(hours=1)
    second = create_day_plan(slice_session, user, PLAN_DATE, later)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    assert day.plan_id == second.plan_id != first.plan_id
    assert day.plan_items_consumed == 0
    assert day.completion == 0
    assert day.log_count == len(_items(slice_session, first.plan_id))


def test_streak_counts_consecutive_achieved_days_ending_at_date_to(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    items = _items(slice_session, plan.plan_id)
    days = [PLAN_DATE + timedelta(days=offset) for offset in range(4)]
    for day in days[:3]:
        moment = datetime(day.year, day.month, day.day, 12, tzinfo=ZoneInfo("Africa/Tripoli"))
        _log_off_plan_copies(slice_session, user, items, moment)
    fourth = datetime(
        days[3].year, days[3].month, days[3].day, 12, tzinfo=ZoneInfo("Africa/Tripoli")
    )
    # 0.8 of the planned day: energy in the ±25% band but outside ±10% → PARTIAL.
    _log_off_plan_copies(slice_session, user, items, fourth, scale=D("0.8"))

    last = adherence_range(slice_session, user, days[0], days[3])
    assert last.days[-1].status is DayStatus.PARTIAL
    assert last.streak == 0
    before = adherence_range(slice_session, user, days[0], days[2])
    assert [d.status for d in before.days] == [DayStatus.ACHIEVED] * 3
    assert before.streak == 3


def test_no_target_returns_none_status(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    day = daily_adherence(slice_session, user, PLAN_DATE)
    assert day.status is None
    assert day.reason == NO_TARGET
    assert day.target_id is None
    assert day.completion is None
