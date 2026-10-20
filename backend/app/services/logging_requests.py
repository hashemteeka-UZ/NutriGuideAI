"""Request rules for consumption logging (#201, #202, #203).

The window and the plan-date check live here so consumption.py, and the reports that call it,
stay unchanged. A created plan-item log writes one ACCEPT row; a duplicate, a correction, and
a deletion do not.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Final, Literal
from uuid import UUID

from sqlalchemy import and_, case, func, select
from sqlalchemy.orm import Session, aliased

from app.core.text import pick_name
from app.db.models import (
    ConsumptionLog,
    Food,
    Ingredient,
    Meal,
    MealPlan,
    MealPlanItem,
    MealTranslation,
    UserInteraction,
)
from app.db.models.user import InteractionEventType
from app.services.common import (
    InputRejectedError,
    MealNotFoundError,
    require_aware,
    round_half_up,
    to_decimal,
)
from app.services.consumption import (
    SNAPSHOT_NUTRIENTS_KEY,
    FoodNotFoundError,
    LogNotFoundError,
    LogResult,
    LogStatus,
    PlanItemNotFoundError,
    active_logs,
    correct_log,
    delete_log,
    local_date,
    log_food,
    log_meal,
    log_plan_item,
)
from app.services.weight import CLOCK_SKEW_TOLERANCE, ClockSkewError

logger = logging.getLogger("nutriguide.api")

LOG_HISTORY_DAYS: Final = 30
RATIO_PLACES: Final = 3

LogKind = Literal["PLAN_ITEM", "MEAL", "FOOD"]

# Response fields and the snapshot codes they read. A code absent from the snapshot is None.
_NUTRIENT_FIELDS: Final = (
    ("kcal", "energy_kcal"),
    ("protein_g", "protein"),
    ("carb_g", "carbohydrate"),
    ("fat_g", "total_fat"),
    ("fiber_g", "fiber"),
    ("sodium_mg", "sodium"),
    ("sugars_g", "sugars"),
    ("saturated_fat_g", "saturated_fat"),
)


@dataclass(frozen=True)
class LoggedConsumption:
    log_id: int
    kind: LogKind
    log_date: date
    consumed_at: datetime
    slot: str | None
    plan_item_id: int | None
    meal_id: int | None
    food_id: int | None
    servings_consumed: float | None
    grams_consumed: float | None
    name: str
    nutrients: dict[str, float | None]
    status: LogStatus


def ensure_log_instant(
    session: Session, user_id: int, consumed_at: datetime, now: datetime
) -> date:
    """Local date of consumed_at, or CLOCK_SKEW / InputRejectedError outside the window."""
    require_aware(consumed_at, "consumed_at")
    require_aware(now, "now")
    if consumed_at > now + CLOCK_SKEW_TOLERANCE:
        raise ClockSkewError(
            f"consumed_at {consumed_at.isoformat()} is more than {CLOCK_SKEW_TOLERANCE} after "
            f"the server time {now.isoformat()}"
        )
    eaten = local_date(session, user_id, consumed_at)
    today = local_date(session, user_id, now)
    earliest = today - timedelta(days=LOG_HISTORY_DAYS)
    if eaten < earliest:
        raise InputRejectedError(
            f"consumed_at local date {eaten.isoformat()} is more than {LOG_HISTORY_DAYS} days "
            f"before the user's local today {today.isoformat()}"
        )
    return eaten


def _plan_day(plan: MealPlan, item: MealPlanItem) -> date:
    return plan.date_from + timedelta(days=item.day_index)


def _owned_item(session: Session, user_id: int, plan_item_id: int) -> tuple[MealPlanItem, MealPlan]:
    found = session.execute(
        select(MealPlanItem, MealPlan)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlanItem.id == plan_item_id, MealPlan.user_id == user_id)
    ).one_or_none()
    if found is None:
        raise PlanItemNotFoundError(f"plan item {plan_item_id} is not in a plan of user {user_id}")
    item, plan = found
    return item, plan


def _require_plan_date(
    session: Session, user_id: int, plan_item_id: int, eaten: date
) -> tuple[MealPlanItem, MealPlan]:
    item, plan = _owned_item(session, user_id, plan_item_id)
    plan_day = _plan_day(plan, item)
    if eaten != plan_day:
        raise InputRejectedError(
            f"consumed_at local date {eaten.isoformat()} is not the plan date "
            f"{plan_day.isoformat()}"
        )
    return item, plan


def _kind(log: ConsumptionLog) -> LogKind:
    if log.plan_item_id is not None:
        return "PLAN_ITEM"
    if log.meal_id is not None:
        return "MEAL"
    return "FOOD"


def snapshot_nutrients(snapshot: dict[str, object]) -> dict[str, float | None]:
    """Map a stored snapshot onto the response fields. A missing nutrient is None, never 0."""
    raw = snapshot.get(SNAPSHOT_NUTRIENTS_KEY)
    values = raw if isinstance(raw, dict) else {}
    totals: dict[str, float | None] = {}
    for field, code in _NUTRIENT_FIELDS:
        stored = values.get(code)
        if stored is None:
            totals[field] = None
        else:
            totals[field] = float(round_half_up(Decimal(str(stored)), RATIO_PLACES))
    return totals


def _meal_names(session: Session, meal_ids: list[int], lang: str) -> dict[int, str]:
    """Catalog display name, including an inactive meal a log can still point at (#184)."""
    if not meal_ids:
        return {}
    translation = aliased(MealTranslation)
    display_name = case(
        (Meal.default_lang == lang, Meal.name),
        else_=func.coalesce(translation.name, Meal.name),
    )
    rows = session.execute(
        select(Meal.meal_id, display_name)
        .outerjoin(
            translation,
            and_(translation.meal_id == Meal.meal_id, translation.lang == lang),
        )
        .where(Meal.meal_id.in_(meal_ids))
    ).all()
    return {meal_id: name for meal_id, name in rows}


def _food_names(session: Session, food_ids: list[int], lang: str) -> dict[int, str]:
    """Ingredient name via pick_name; the food description when no ingredient points at it."""
    if not food_ids:
        return {}
    chosen: dict[int, str] = {}
    rows = session.execute(
        select(
            Ingredient.default_food_id,
            Ingredient.canonical_name_ar,
            Ingredient.canonical_name,
        )
        .where(Ingredient.default_food_id.in_(food_ids))
        .order_by(Ingredient.ingredient_id)
    ).all()
    for food_id, name_ar, name_en in rows:
        if food_id is not None and food_id not in chosen:
            chosen[food_id] = pick_name(lang, name_ar, name_en)
    descriptions: dict[int, str] = {}
    for food_id, description in session.execute(
        select(Food.food_id, Food.description).where(Food.food_id.in_(food_ids))
    ).all():
        descriptions[food_id] = description
    names: dict[int, str] = {}
    for food_id in food_ids:
        if food_id in chosen:
            names[food_id] = chosen[food_id]
        elif food_id in descriptions:
            names[food_id] = pick_name(lang, descriptions[food_id], descriptions[food_id])
        else:
            raise FoodNotFoundError(f"food {food_id} does not exist")
    return names


def _views(
    session: Session, logs: list[ConsumptionLog], status: LogStatus, lang: str
) -> list[LoggedConsumption]:
    meal_ids = sorted({log.meal_id for log in logs if log.meal_id is not None})
    food_ids = sorted({log.food_id for log in logs if log.food_id is not None})
    meals = _meal_names(session, meal_ids, lang)
    foods = _food_names(session, food_ids, lang)
    views: list[LoggedConsumption] = []
    for log in logs:
        if log.meal_id is not None:
            name = meals.get(log.meal_id)
            if name is None:
                raise MealNotFoundError(f"meal {log.meal_id} does not exist")
        else:
            assert log.food_id is not None
            name = foods[log.food_id]
        views.append(
            LoggedConsumption(
                log_id=log.id,
                kind=_kind(log),
                log_date=log.log_date,
                consumed_at=log.consumed_at,
                slot=log.slot,
                plan_item_id=log.plan_item_id,
                meal_id=log.meal_id,
                food_id=log.food_id,
                servings_consumed=log.servings_consumed,
                grams_consumed=log.grams_consumed,
                name=name,
                nutrients=snapshot_nutrients(log.nutrients_snapshot),
                status=status,
            )
        )
    return views


def _one(session: Session, result: LogResult, lang: str) -> LoggedConsumption:
    return _views(session, [result.log], result.status, lang)[0]


def _write(user_id: int, kind: str, status: str) -> None:
    logger.info("consumption write user_id=%s kind=%s status=%s", user_id, kind, status)


def _accept(
    session: Session,
    user_id: int,
    item: MealPlanItem,
    plan: MealPlan,
    servings_consumed: float,
    now: datetime,
) -> None:
    ratio = round_half_up(
        to_decimal(servings_consumed) / to_decimal(item.servings_multiplier),
        RATIO_PLACES,
    )
    session.add(
        UserInteraction(
            user_id=user_id,
            meal_id=item.meal_id,
            event_type=InteractionEventType.ACCEPT.value,
            context={
                "plan_id": plan.plan_id,
                "plan_item_id": item.id,
                "slot": item.slot,
                "algorithm_version": plan.algorithm_version,
                "servings_ratio": float(ratio),
            },
            created_at=now,
        )
    )
    session.flush()


def create_log(
    session: Session,
    user_id: int,
    *,
    kind: LogKind,
    client_uuid: UUID,
    consumed_at: datetime,
    now: datetime,
    lang: str,
    plan_item_id: int | None = None,
    meal_id: int | None = None,
    food_id: int | None = None,
    servings_consumed: float | None = None,
    grams_consumed: float | None = None,
    slot: str | None = None,
) -> LoggedConsumption:
    """Log one plan item, catalog meal, or single food. Never fills entry_group or entry_label."""
    eaten = ensure_log_instant(session, user_id, consumed_at, now)
    if kind == "PLAN_ITEM":
        assert plan_item_id is not None and servings_consumed is not None
        item, plan = _require_plan_date(session, user_id, plan_item_id, eaten)
        result = log_plan_item(
            session, user_id, plan_item_id, servings_consumed, consumed_at, client_uuid, now
        )
        if result.status is LogStatus.CREATED:
            _accept(session, user_id, item, plan, servings_consumed, now)
    elif kind == "MEAL":
        assert meal_id is not None and servings_consumed is not None
        active = session.execute(
            select(Meal.meal_id).where(Meal.meal_id == meal_id, Meal.is_active.is_(True))
        ).scalar_one_or_none()
        if active is None:
            raise MealNotFoundError(f"meal {meal_id} is not an active meal")
        result = log_meal(
            session, user_id, meal_id, servings_consumed, consumed_at, slot, client_uuid, now
        )
    else:
        assert food_id is not None and grams_consumed is not None
        result = log_food(
            session, user_id, food_id, grams_consumed, consumed_at, slot, client_uuid, now
        )
    _write(user_id, kind, result.status.value)
    return _one(session, result, lang)


def correct(
    session: Session,
    user_id: int,
    log_id: int,
    *,
    new_client_uuid: UUID,
    now: datetime,
    lang: str,
    servings_consumed: float | None = None,
    grams_consumed: float | None = None,
    consumed_at: datetime | None = None,
    slot: str | None = None,
) -> LoggedConsumption:
    """Correct an active log of this user. A repeated new_client_uuid is a DUPLICATE.

    The window applies only while the old row is still active, so a retry of a correction
    that already tombstoned it stays a DUPLICATE (#209). No new ACCEPT.
    """
    old = session.execute(
        select(ConsumptionLog).where(ConsumptionLog.id == log_id, ConsumptionLog.user_id == user_id)
    ).scalar_one_or_none()
    if old is None:
        raise LogNotFoundError(f"user {user_id} has no log {log_id}")
    if consumed_at is not None and old.deleted_at is None:
        eaten = ensure_log_instant(session, user_id, consumed_at, now)
        if old.plan_item_id is not None:
            _require_plan_date(session, user_id, old.plan_item_id, eaten)
    result = correct_log(
        session,
        user_id,
        log_id,
        servings_consumed=servings_consumed,
        grams_consumed=grams_consumed,
        consumed_at=consumed_at,
        slot=slot,
        new_client_uuid=new_client_uuid,
        now=now,
    )
    _write(user_id, _kind(result.log), result.status.value)
    return _one(session, result, lang)


def delete(session: Session, user_id: int, log_id: int, now: datetime) -> None:
    """Tombstone the caller's active log. Writes no interaction row."""
    delete_log(session, user_id, log_id, now)
    _write(user_id, "CONSUMPTION", "DELETED")


def consumption_views(
    session: Session, logs: list[ConsumptionLog], lang: str
) -> list[LoggedConsumption]:
    """Active rows mapped like GET /consumption-logs. Names are loaded once per kind."""
    return _views(session, logs, LogStatus.CREATED, lang)


def logs_of_day(
    session: Session, user_id: int, log_date: date, lang: str
) -> list[LoggedConsumption]:
    """Active logs of that local day, with names loaded in one query per kind."""
    rows = active_logs(session, user_id, log_date)
    return _views(session, rows, LogStatus.CREATED, lang)
