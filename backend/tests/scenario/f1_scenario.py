"""Deterministic F.1-e scenario: three personas, three local days, public services only."""

from __future__ import annotations

import time
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from datetime import time as dt_time
from decimal import Decimal
from typing import Final
from uuid import uuid4
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    ConsumptionLog,
    Food,
    HealthCondition,
    Ingredient,
    Meal,
    MealPlan,
    MealPlanItem,
    Nutrient,
    UserTarget,
)
from app.db.models.user import MealSlot, TargetReason
from app.services.adherence import AdherenceRange, DayAdherence, adherence_range, daily_adherence
from app.services.common import to_decimal
from app.services.condition_limits import ResolvedLimits, resolve_condition_limits
from app.services.consumption import correct_log, log_food, log_meal, log_plan_item
from app.services.meal_filter import MealFacts, load_meal_facts
from app.services.plan_swap import SwapRejectedError, swap_plan_item
from app.services.planner import (
    KCAL_TOLERANCE,
    PlanTarget,
    UnmetMinimum,
    build_day_plan,
    create_day_plan,
    unmet_minimums,
)
from app.services.screening import ScreeningResult, age_in_years, screen_user
from app.services.targets import UserNotEligibleError, create_user_target, fiber_target_g
from app.services.weight import WeightResult, record_weight
from tests.builders import (
    make_user,
    make_user_allergen_pref,
    make_user_health_condition,
    make_user_ingredient_pref,
    make_user_profile,
)

TIMEZONE: Final = "Africa/Tripoli"
DATES_NDB: Final = "09087"
GARLIC_NDB: Final = "11215"
CHICKPEAS_NDB: Final = "16358"
PEANUT_NAME: Final = "Peanut"
P3_MEAL_REF: Final = "F1-B01"
SLOT_HOUR: Final[Mapping[str, int]] = {
    MealSlot.BREAKFAST: 8,
    MealSlot.LUNCH: 13,
    MealSlot.DINNER: 19,
}
SNACK_HOURS: Final = (16, 21)
MAIN_SLOTS: Final = (MealSlot.BREAKFAST, MealSlot.LUNCH, MealSlot.DINNER)


@dataclass(frozen=True)
class ScenarioTarget:
    target_id: int
    reason: str
    kcal: Decimal
    protein_g: Decimal
    carb_g: Decimal
    fat_g: Decimal
    fiber_g: Decimal
    was_floor_applied: bool
    based_on_weight_kg: Decimal
    valid_from: datetime
    valid_to: datetime | None
    formula_version: str


@dataclass(frozen=True)
class ScenarioPlanItem:
    item_id: int
    slot: str
    meal_id: int
    ref_external: str | None
    name_ar: str
    multiplier: Decimal
    reason_codes: tuple[str, ...]
    nutrients: Mapping[str, Decimal]
    was_swapped: bool
    variant_group: str | None


@dataclass(frozen=True)
class ScenarioLog:
    log_id: int
    kind: str
    item: str
    amount: Decimal
    status: str
    slot: str | None
    plan_item_id: int | None
    meal_id: int | None
    food_id: int | None
    deleted_at: datetime | None
    nutrients_snapshot: Mapping[str, object]


@dataclass(frozen=True)
class PersonaDay:
    offset: int
    plan_date: date
    plan_id: int | None
    planned_items: tuple[ScenarioPlanItem, ...]
    items: tuple[ScenarioPlanItem, ...]
    target: ScenarioTarget | None
    target_snapshot: Mapping[str, object] | None
    limits: ResolvedLimits | None
    plan_totals: Mapping[str, Decimal | None]
    kcal_within_10pct: bool | None
    unmet_minimums: tuple[UnmetMinimum, ...]
    logs: tuple[ScenarioLog, ...]
    adherence: DayAdherence
    build_ms: float | None
    lunch_swap: tuple[str | None, str | None] | None = None


@dataclass(frozen=True)
class ProfileSummary:
    sex: str
    birth_date: date
    age_years: int
    height_cm: Decimal
    start_weight_kg: Decimal
    activity_level: str
    goal_type: str
    target_weight_kg: Decimal | None
    weekly_rate_kg: Decimal | None
    conditions: tuple[str, ...]
    timezone: str


@dataclass(frozen=True)
class WeightEvent:
    measured_on: date
    weight_kg: Decimal
    weight_status: str
    target_status: str
    new_target_id: int | None
    goal_reached: bool


@dataclass
class PersonaResult:
    key: str
    user_id: int
    profile: ProfileSummary
    screening: ScreeningResult
    targets: tuple[ScenarioTarget, ...]
    days: list[PersonaDay]
    weight_events: list[WeightEvent]
    streak: int
    target_error: str | None = None
    plan_error: str | None = None


@dataclass
class ScenarioResult:
    start_date: date
    start_now: datetime
    personas: dict[str, PersonaResult] = field(default_factory=dict)
    build_timings_ms: list[float] = field(default_factory=list)


def _food_id(session: Session, ndb: str) -> int:
    return session.execute(select(Food.food_id).where(Food.external_code == ndb)).scalar_one()


def _ingredient_id(session: Session, ndb: str) -> int:
    return session.execute(
        select(Ingredient.ingredient_id)
        .join(Food, Food.food_id == Ingredient.default_food_id)
        .where(Food.external_code == ndb)
    ).scalar_one()


def _allergen_id(session: Session, name_en: str) -> int:
    return session.execute(
        select(Allergen.allergen_id).where(Allergen.name_en == name_en)
    ).scalar_one()


def _condition_id(session: Session, code: str) -> int:
    return session.execute(
        select(HealthCondition.condition_id).where(HealthCondition.code == code)
    ).scalar_one()


def _meal_id(session: Session, ref_external: str) -> int:
    return session.execute(
        select(Meal.meal_id).where(Meal.ref_external == ref_external)
    ).scalar_one()


def _nutrient_codes(session: Session) -> tuple[str, ...]:
    return tuple(session.execute(select(Nutrient.code).order_by(Nutrient.nutrient_id)).scalars())


def _facts(session: Session) -> dict[int, MealFacts]:
    return {meal.meal_id: meal for meal in load_meal_facts(session)}


def _scenario_target(row: UserTarget) -> ScenarioTarget:
    kcal = to_decimal(row.target_kcal)
    return ScenarioTarget(
        target_id=row.target_id,
        reason=row.reason,
        kcal=kcal,
        protein_g=to_decimal(row.target_protein_g),
        carb_g=to_decimal(row.target_carb_g),
        fat_g=to_decimal(row.target_fat_g),
        fiber_g=Decimal(fiber_target_g(kcal)),
        was_floor_applied=row.was_floor_applied,
        based_on_weight_kg=to_decimal(row.based_on_weight_kg),
        valid_from=row.valid_from,
        valid_to=row.valid_to,
        formula_version=row.formula_version,
    )


def _user_targets(session: Session, user_id: int) -> tuple[ScenarioTarget, ...]:
    rows = session.execute(
        select(UserTarget)
        .where(UserTarget.user_id == user_id)
        .order_by(UserTarget.valid_from, UserTarget.target_id)
    ).scalars()
    return tuple(_scenario_target(row) for row in rows)


def _current_target(session: Session, user_id: int) -> UserTarget:
    return session.execute(
        select(UserTarget).where(UserTarget.user_id == user_id, UserTarget.valid_to.is_(None))
    ).scalar_one()


def _plan_items(
    session: Session,
    plan_id: int,
    facts: Mapping[int, MealFacts],
    nutrient_codes: Sequence[str],
) -> tuple[ScenarioPlanItem, ...]:
    rows = session.execute(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan_id).order_by(MealPlanItem.id)
    ).scalars()
    items = []
    for row in rows:
        meal = facts[row.meal_id]
        multiplier = to_decimal(row.servings_multiplier)
        items.append(
            ScenarioPlanItem(
                item_id=row.id,
                slot=row.slot,
                meal_id=row.meal_id,
                ref_external=meal.ref_external,
                name_ar=meal.name,
                multiplier=multiplier,
                reason_codes=tuple(row.reason_codes),
                nutrients={
                    code: amount
                    for code in nutrient_codes
                    if (amount := meal.amount(code, multiplier)) is not None
                },
                was_swapped=row.was_swapped,
                variant_group=meal.variant_group,
            )
        )
    return tuple(items)


def _totals(
    items: Sequence[ScenarioPlanItem], nutrient_codes: Sequence[str]
) -> dict[str, Decimal | None]:
    totals: dict[str, Decimal | None] = {}
    for code in nutrient_codes:
        total = Decimal(0)
        known = True
        for item in items:
            amount = item.nutrients.get(code)
            if amount is None:
                known = False
                break
            total += amount
        totals[code] = total if known else None
    return totals


def _kcal_within(totals: Mapping[str, Decimal | None], target_kcal: Decimal) -> bool:
    energy = totals.get("energy_kcal")
    return energy is not None and abs(energy - target_kcal) <= KCAL_TOLERANCE * target_kcal


def _logs(session: Session, user_id: int, log_date: date) -> tuple[ScenarioLog, ...]:
    rows = session.execute(
        select(ConsumptionLog)
        .where(ConsumptionLog.user_id == user_id, ConsumptionLog.log_date == log_date)
        .order_by(ConsumptionLog.id)
    ).scalars()
    out: list[ScenarioLog] = []
    for row in rows:
        if row.plan_item_id is not None:
            kind = "PLAN_ITEM"
        elif row.food_id is not None:
            kind = "FOOD"
        else:
            kind = "MEAL"
        if row.meal_id is not None:
            item = session.execute(
                select(Meal.ref_external).where(Meal.meal_id == row.meal_id)
            ).scalar_one()
            amount = to_decimal(row.servings_consumed or 0)
        else:
            item = session.execute(
                select(Food.external_code).where(Food.food_id == row.food_id)
            ).scalar_one()
            amount = to_decimal(row.grams_consumed or 0)
        out.append(
            ScenarioLog(
                log_id=row.id,
                kind=kind,
                item=item or "",
                amount=amount,
                status="TOMBSTONE" if row.deleted_at is not None else "ACTIVE",
                slot=row.slot,
                plan_item_id=row.plan_item_id,
                meal_id=row.meal_id,
                food_id=row.food_id,
                deleted_at=row.deleted_at,
                nutrients_snapshot=row.nutrients_snapshot,
            )
        )
    return tuple(out)


def _morning(start_now: datetime, offset: int) -> datetime:
    return start_now + timedelta(days=offset)


def _slot_time(start_date: date, offset: int, slot: str, snack_index: int) -> datetime:
    hour = SNACK_HOURS[snack_index] if slot == MealSlot.SNACK else SLOT_HOUR[slot]
    local_day = start_date + timedelta(days=offset)
    return datetime.combine(local_day, dt_time(hour), tzinfo=ZoneInfo(TIMEZONE))


def _item_times(
    start_date: date, offset: int, items: Sequence[ScenarioPlanItem]
) -> dict[int, datetime]:
    snack_index = 0
    times: dict[int, datetime] = {}
    for item in items:
        index = snack_index if item.slot == MealSlot.SNACK else 0
        if item.slot == MealSlot.SNACK:
            snack_index += 1
        times[item.item_id] = _slot_time(start_date, offset, item.slot, index)
    return times


def _record_weight(
    session: Session,
    persona: PersonaResult,
    measured_on: date,
    weight_kg: Decimal | float,
    now: datetime,
) -> WeightResult:
    result = record_weight(session, persona.user_id, measured_on, weight_kg, now, now)
    persona.weight_events.append(
        WeightEvent(
            measured_on=measured_on,
            weight_kg=to_decimal(weight_kg),
            weight_status=result.status.value,
            target_status=result.target_status.value,
            new_target_id=result.new_target_id,
            goal_reached=result.goal_reached,
        )
    )
    return result


def _time_build(
    session: Session,
    user_id: int,
    plan_date: date,
    timings: list[float],
) -> tuple[float, UserTarget, ResolvedLimits]:
    current = _current_target(session, user_id)
    target = PlanTarget.from_user_target(current)
    limits = resolve_condition_limits(session, user_id, target.kcal)
    started = time.perf_counter()
    build_day_plan(session, user_id, limits, target, plan_date)
    elapsed_ms = (time.perf_counter() - started) * 1000
    timings.append(elapsed_ms)
    return elapsed_ms, current, limits


def _first_lunch_swap(
    session: Session, user_id: int, lunch: ScenarioPlanItem, now: datetime
) -> MealFacts:
    for meal in sorted(load_meal_facts(session), key=lambda row: row.sort_key):
        if meal.meal_id == lunch.meal_id:
            continue
        try:
            swap_plan_item(session, user_id, lunch.item_id, meal.meal_id, now)
        except SwapRejectedError:
            continue
        return meal
    raise RuntimeError(f"no eligible lunch swap for plan item {lunch.item_id}")


def _log_item(
    session: Session,
    user_id: int,
    item: ScenarioPlanItem,
    servings: Decimal,
    consumed_at: datetime,
    now: datetime,
) -> None:
    log_plan_item(session, user_id, item.item_id, servings, consumed_at, uuid4(), now)


def _log_all_items(
    session: Session,
    user_id: int,
    items: Sequence[ScenarioPlanItem],
    times: Mapping[int, datetime],
) -> None:
    for item in items:
        consumed_at = times[item.item_id]
        _log_item(session, user_id, item, item.multiplier, consumed_at, consumed_at)


def _finish_day(
    session: Session,
    persona: PersonaResult,
    offset: int,
    plan_date: date,
    plan: MealPlan | None,
    planned_items: tuple[ScenarioPlanItem, ...],
    items: tuple[ScenarioPlanItem, ...],
    target_row: UserTarget | None,
    limits: ResolvedLimits | None,
    nutrient_codes: Sequence[str],
    build_ms: float | None,
    lunch_swap: tuple[str | None, str | None] | None,
) -> None:
    target = None if target_row is None else _scenario_target(target_row)
    totals = _totals(items, nutrient_codes)
    if plan is not None:
        session.refresh(plan)
    persona.days.append(
        PersonaDay(
            offset=offset,
            plan_date=plan_date,
            plan_id=None if plan is None else plan.plan_id,
            planned_items=planned_items,
            items=items,
            target=target,
            target_snapshot=None if plan is None else plan.target_snapshot,
            limits=limits,
            plan_totals=totals,
            kcal_within_10pct=None if target is None else _kcal_within(totals, target.kcal),
            unmet_minimums=() if limits is None else unmet_minimums(totals, limits),
            logs=_logs(session, persona.user_id, plan_date),
            adherence=daily_adherence(session, persona.user_id, plan_date),
            build_ms=build_ms,
            lunch_swap=lunch_swap,
        )
    )


def _planned_day(
    session: Session,
    persona: PersonaResult,
    result: ScenarioResult,
    offset: int,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
) -> tuple[MealPlan, tuple[ScenarioPlanItem, ...], UserTarget, ResolvedLimits, float]:
    plan_date = start_date + timedelta(days=offset)
    now = _morning(start_now, offset)
    build_ms, current, limits = _time_build(
        session, persona.user_id, plan_date, result.build_timings_ms
    )
    plan = create_day_plan(session, persona.user_id, plan_date, now)
    items = _plan_items(session, plan.plan_id, _facts(session), nutrient_codes)
    return plan, items, current, limits, build_ms


def _day_full(
    session: Session,
    persona: PersonaResult,
    result: ScenarioResult,
    offset: int,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
) -> None:
    plan, items, current, limits, build_ms = _planned_day(
        session, persona, result, offset, start_date, start_now, nutrient_codes
    )
    _log_all_items(session, persona.user_id, items, _item_times(start_date, offset, items))
    _finish_day(
        session,
        persona,
        offset,
        start_date + timedelta(days=offset),
        plan,
        items,
        items,
        current,
        limits,
        nutrient_codes,
        build_ms,
        None,
    )


def _day_partial(
    session: Session,
    persona: PersonaResult,
    result: ScenarioResult,
    offset: int,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
    off_plan_ndb: str,
    off_plan_grams: Decimal,
) -> None:
    plan, items, current, limits, build_ms = _planned_day(
        session, persona, result, offset, start_date, start_now, nutrient_codes
    )
    by_slot = {item.slot: item for item in items if item.slot != MealSlot.SNACK}
    breakfast = by_slot[MealSlot.BREAKFAST]
    lunch = by_slot[MealSlot.LUNCH]
    times = _item_times(start_date, offset, items)
    half = breakfast.multiplier * Decimal("0.5")
    breakfast_at = times[breakfast.item_id]
    logged = log_plan_item(
        session, persona.user_id, breakfast.item_id, half, breakfast_at, uuid4(), breakfast_at
    )
    correct_log(
        session,
        persona.user_id,
        logged.log.id,
        servings_consumed=breakfast.multiplier,
        new_client_uuid=uuid4(),
        now=breakfast_at + timedelta(minutes=1),
    )
    swapped = _first_lunch_swap(session, persona.user_id, lunch, times[lunch.item_id])
    lunch_at = times[lunch.item_id]
    session.expire_all()
    final_items = _plan_items(session, plan.plan_id, _facts(session), nutrient_codes)
    final_lunch = next(item for item in final_items if item.slot == MealSlot.LUNCH)
    _log_item(session, persona.user_id, final_lunch, final_lunch.multiplier, lunch_at, lunch_at)
    snack_at = _slot_time(start_date, offset, MealSlot.SNACK, 0)
    log_food(
        session,
        persona.user_id,
        _food_id(session, off_plan_ndb),
        off_plan_grams,
        snack_at,
        MealSlot.SNACK,
        uuid4(),
        snack_at,
    )
    _finish_day(
        session,
        persona,
        offset,
        start_date + timedelta(days=offset),
        plan,
        items,
        final_items,
        current,
        limits,
        nutrient_codes,
        build_ms,
        (lunch.ref_external, swapped.ref_external),
    )


def _run_three_days(
    session: Session,
    persona: PersonaResult,
    result: ScenarioResult,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
    off_plan_ndb: str,
    off_plan_grams: Decimal,
    day2_weight: Decimal,
) -> None:
    _day_full(session, persona, result, 0, start_date, start_now, nutrient_codes)
    _day_partial(
        session,
        persona,
        result,
        1,
        start_date,
        start_now,
        nutrient_codes,
        off_plan_ndb,
        off_plan_grams,
    )
    day2 = start_date + timedelta(days=2)
    now2 = _morning(start_now, 2)
    _record_weight(session, persona, day2, day2_weight, now2)
    _day_full(session, persona, result, 2, start_date, start_now, nutrient_codes)
    persona.targets = _user_targets(session, persona.user_id)
    rang: AdherenceRange = adherence_range(session, persona.user_id, start_date, day2)
    persona.streak = rang.streak


def _new_persona(
    key: str,
    user_id: int,
    profile: ProfileSummary,
    screening: ScreeningResult,
) -> PersonaResult:
    return PersonaResult(
        key=key,
        user_id=user_id,
        profile=profile,
        screening=screening,
        targets=(),
        days=[],
        weight_events=[],
        streak=0,
    )


def _profile(
    start_date: date,
    start_weight_kg: Decimal,
    conditions: tuple[str, ...],
    *,
    sex: str,
    birth_date: date,
    height_cm: Decimal | int,
    activity_level: str,
    goal_type: str,
    target_weight_kg: Decimal | int | None,
    weekly_rate_kg: Decimal | None,
) -> ProfileSummary:
    return ProfileSummary(
        sex=sex,
        birth_date=birth_date,
        age_years=age_in_years(birth_date, start_date),
        height_cm=to_decimal(height_cm),
        start_weight_kg=start_weight_kg,
        activity_level=activity_level,
        goal_type=goal_type,
        target_weight_kg=None if target_weight_kg is None else to_decimal(target_weight_kg),
        weekly_rate_kg=weekly_rate_kg,
        conditions=conditions,
        timezone=TIMEZONE,
    )


def _run_p1(
    session: Session,
    conn: Connection,
    result: ScenarioResult,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
) -> None:
    user = make_user(conn, email="f1e.p1@example.com")
    make_user_profile(
        conn,
        user_id=user,
        sex="MALE",
        birth_date=date(1996, 1, 15),
        height_cm=175,
        activity_level="MODERATE",
        goal_type="LOSE",
        target_weight_kg=80,
        weekly_rate_kg=Decimal("0.5"),
        timezone=TIMEZONE,
    )
    session.expire_all()
    screening = screen_user(session, user, start_date)
    persona = _new_persona(
        "P1",
        user,
        _profile(
            start_date,
            Decimal(90),
            (),
            sex="MALE",
            birth_date=date(1996, 1, 15),
            height_cm=175,
            activity_level="MODERATE",
            goal_type="LOSE",
            target_weight_kg=80,
            weekly_rate_kg=Decimal("0.5"),
        ),
        screening,
    )
    now0 = _morning(start_now, 0)
    _record_weight(session, persona, start_date, 90, now0)
    create_user_target(session, user, TargetReason.INITIAL, now0)
    _run_three_days(
        session,
        persona,
        result,
        start_date,
        start_now,
        nutrient_codes,
        DATES_NDB,
        Decimal(30),
        Decimal("88.9"),
    )
    result.personas["P1"] = persona


def _run_p2(
    session: Session,
    conn: Connection,
    result: ScenarioResult,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
) -> None:
    user = make_user(conn, email="f1e.p2@example.com")
    make_user_profile(
        conn,
        user_id=user,
        sex="FEMALE",
        birth_date=date(1971, 1, 15),
        height_cm=160,
        activity_level="LIGHT",
        goal_type="MAINTAIN",
        timezone=TIMEZONE,
    )
    make_user_health_condition(
        conn, user_id=user, condition_id=_condition_id(session, "HYPERTENSION")
    )
    make_user_health_condition(
        conn, user_id=user, condition_id=_condition_id(session, "DIABETES_T2")
    )
    make_user_allergen_pref(
        conn, user_id=user, allergen_id=_allergen_id(session, PEANUT_NAME), severity="AVOID"
    )
    make_user_ingredient_pref(
        conn, user_id=user, ingredient_id=_ingredient_id(session, GARLIC_NDB), stance="DISLIKE"
    )
    make_user_ingredient_pref(
        conn, user_id=user, ingredient_id=_ingredient_id(session, CHICKPEAS_NDB), stance="LIKE"
    )
    session.expire_all()
    screening = screen_user(session, user, start_date)
    persona = _new_persona(
        "P2",
        user,
        _profile(
            start_date,
            Decimal(70),
            ("HYPERTENSION", "DIABETES_T2"),
            sex="FEMALE",
            birth_date=date(1971, 1, 15),
            height_cm=160,
            activity_level="LIGHT",
            goal_type="MAINTAIN",
            target_weight_kg=None,
            weekly_rate_kg=None,
        ),
        screening,
    )
    now0 = _morning(start_now, 0)
    _record_weight(session, persona, start_date, 70, now0)
    create_user_target(session, user, TargetReason.INITIAL, now0)
    _run_three_days(
        session,
        persona,
        result,
        start_date,
        start_now,
        nutrient_codes,
        GARLIC_NDB,
        Decimal(20),
        Decimal("70.4"),
    )
    result.personas["P2"] = persona


def _run_p3(
    session: Session,
    conn: Connection,
    result: ScenarioResult,
    start_date: date,
    start_now: datetime,
    nutrient_codes: Sequence[str],
) -> None:
    user = make_user(conn, email="f1e.p3@example.com")
    make_user_profile(
        conn,
        user_id=user,
        sex="MALE",
        birth_date=date(1966, 1, 15),
        height_cm=170,
        activity_level="LIGHT",
        goal_type="MAINTAIN",
        timezone=TIMEZONE,
    )
    make_user_health_condition(conn, user_id=user, condition_id=_condition_id(session, "CKD"))
    session.expire_all()
    screening = screen_user(session, user, start_date)
    persona = _new_persona(
        "P3",
        user,
        _profile(
            start_date,
            Decimal(80),
            ("CKD",),
            sex="MALE",
            birth_date=date(1966, 1, 15),
            height_cm=170,
            activity_level="LIGHT",
            goal_type="MAINTAIN",
            target_weight_kg=None,
            weekly_rate_kg=None,
        ),
        screening,
    )
    now0 = _morning(start_now, 0)
    try:
        create_user_target(session, user, TargetReason.INITIAL, now0)
    except UserNotEligibleError as exc:
        persona.target_error = str(exc)
    try:
        create_day_plan(session, user, start_date, now0)
    except UserNotEligibleError as exc:
        persona.plan_error = str(exc)
    eaten = _slot_time(start_date, 0, MealSlot.BREAKFAST, 0)
    log_meal(
        session,
        user,
        _meal_id(session, P3_MEAL_REF),
        Decimal(1),
        eaten,
        MealSlot.BREAKFAST,
        uuid4(),
        eaten,
    )
    _record_weight(session, persona, start_date, 80, now0)
    _finish_day(
        session,
        persona,
        0,
        start_date,
        None,
        (),
        (),
        None,
        None,
        nutrient_codes,
        None,
        None,
    )
    persona.targets = _user_targets(session, persona.user_id)
    persona.streak = adherence_range(session, user, start_date, start_date).streak
    result.personas["P3"] = persona


def run_f1_scenario(
    session: Session, conn: Connection, start_date: date, start_now: datetime
) -> ScenarioResult:
    """Drive the three F.1-e personas through public services. Caller owns the transaction."""
    if start_now.tzinfo is None:
        raise ValueError("start_now must be timezone-aware")
    nutrient_codes = _nutrient_codes(session)
    result = ScenarioResult(start_date=start_date, start_now=start_now)
    _run_p1(session, conn, result, start_date, start_now, nutrient_codes)
    _run_p2(session, conn, result, start_date, start_now, nutrient_codes)
    _run_p3(session, conn, result, start_date, start_now, nutrient_codes)
    return result
