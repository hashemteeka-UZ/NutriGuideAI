"""Consumption logging (§11.9, §33.4): immutable rows, corrections and deletions as tombstones.

Every service takes the server receive time `now` (created_at, deleted_at) and a client_uuid
(F.1-d decision: every log behaves like a synced device log); a repeated upload with the same
client_uuid and the same content is a DUPLICATE and writes nothing. nutrients_snapshot holds
every mandatory nutrient (§9.7) for the consumed amount, computed once at log time; missing ≠
zero (§9.8), so a meal or food without all mandatory values cannot be logged.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Any, Final
from uuid import UUID

from sqlalchemy import exists, select
from sqlalchemy.orm import Session

from app.db.models import (
    ConsumptionLog,
    Food,
    FoodNutrient,
    Meal,
    MealNutrient,
    MealPlan,
    MealPlanItem,
    Nutrient,
    UserProfile,
)
from app.db.models.user import MealSlot
from app.services.common import (
    MealNotFoundError,
    measure,
    require_aware,
    to_decimal,
    zone,
)
from app.services.meal_nutrition import COMPUTATION_VERSION, is_meal_nutritionally_complete
from app.services.screening import ProfileNotFoundError

# --- §11.9 nutrients_snapshot ----------------------------------------------------------------
SNAPSHOT_VERSION_KEY: Final = "computation_version"
SNAPSHOT_NUTRIENTS_KEY: Final = "nutrients"
GRAMS_BASIS: Final = Decimal(100)  # food_nutrients are per 100 g (§9.8)
# ---------------------------------------------------------------------------------------------


class LogStatus(StrEnum):
    CREATED = "CREATED"
    DUPLICATE = "DUPLICATE"


class ConsumptionError(Exception):
    pass


class IncompleteNutritionError(ConsumptionError):
    pass


class ClientUuidConflictError(ConsumptionError):
    pass


class PlanItemNotFoundError(ConsumptionError, LookupError):
    pass


class PlanItemAlreadyLoggedError(ConsumptionError):
    pass


class LogNotFoundError(ConsumptionError, LookupError):
    pass


class FoodNotFoundError(ConsumptionError, LookupError):
    pass


@dataclass(frozen=True)
class LogResult:
    log: ConsumptionLog
    status: LogStatus


@dataclass(frozen=True)
class _NewLog:
    """The content compared for idempotency; log_date and the snapshot follow from it."""

    user_id: int
    plan_item_id: int | None
    meal_id: int | None
    food_id: int | None
    servings_consumed: Decimal | None
    grams_consumed: Decimal | None
    consumed_at: datetime
    slot: str | None

    def matches(self, row: ConsumptionLog) -> bool:
        def same(stored: float | None, wanted: Decimal | None) -> bool:
            if stored is None or wanted is None:
                return stored is None and wanted is None
            return to_decimal(stored) == wanted

        return (
            row.user_id == self.user_id
            and row.plan_item_id == self.plan_item_id
            and row.meal_id == self.meal_id
            and row.food_id == self.food_id
            and same(row.servings_consumed, self.servings_consumed)
            and same(row.grams_consumed, self.grams_consumed)
            and row.consumed_at == self.consumed_at
            and row.slot == self.slot
        )


def _mandatory_codes(session: Session) -> list[str]:
    return list(
        session.execute(
            select(Nutrient.code).where(Nutrient.is_mandatory).order_by(Nutrient.code)
        ).scalars()
    )


def _snapshot(nutrients: dict[str, Decimal]) -> dict[str, Any]:
    return {
        SNAPSHOT_VERSION_KEY: COMPUTATION_VERSION,
        SNAPSHOT_NUTRIENTS_KEY: {code: str(nutrients[code]) for code in sorted(nutrients)},
    }


def meal_snapshot(session: Session, meal_id: int, servings: Decimal) -> dict[str, Any]:
    """amount_per_serving times servings, for every mandatory nutrient (§10.3, §11.9)."""
    if not is_meal_nutritionally_complete(session, meal_id):
        raise IncompleteNutritionError(
            f"meal {meal_id} lacks a mandatory nutrient; it cannot be logged (§9.8)"
        )
    rows = session.execute(
        select(Nutrient.code, MealNutrient.amount_per_serving, MealNutrient.computation_version)
        .join(MealNutrient, MealNutrient.nutrient_id == Nutrient.nutrient_id)
        .where(MealNutrient.meal_id == meal_id, Nutrient.is_mandatory)
    ).all()
    other_versions = sorted({r.computation_version for r in rows} - {COMPUTATION_VERSION})
    if other_versions:
        raise IncompleteNutritionError(
            f"meal {meal_id} nutrients were computed with {other_versions}, not "
            f"{COMPUTATION_VERSION}"
        )
    return _snapshot({r.code: to_decimal(r.amount_per_serving) * servings for r in rows})


def food_snapshot(session: Session, food_id: int, grams: Decimal) -> dict[str, Any]:
    """food_nutrients.amount_per_100g * grams / 100, for every mandatory nutrient (§9.8)."""
    amounts = dict(
        session.execute(
            select(Nutrient.code, FoodNutrient.amount_per_100g)
            .join(FoodNutrient, FoodNutrient.nutrient_id == Nutrient.nutrient_id)
            .where(FoodNutrient.food_id == food_id, Nutrient.is_mandatory)
        )
        .tuples()
        .all()
    )
    missing = [code for code in _mandatory_codes(session) if code not in amounts]
    if missing:
        raise IncompleteNutritionError(
            f"food {food_id} has no value for mandatory {missing}; it cannot be logged (§9.8)"
        )
    return _snapshot(
        {code: to_decimal(amount) * grams / GRAMS_BASIS for code, amount in amounts.items()}
    )


def local_date(session: Session, user_id: int, moment: datetime) -> date:
    """The user's local calendar day of `moment` (user_profiles.timezone, §11.9)."""
    timezone = session.execute(
        select(UserProfile.timezone).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    if timezone is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    return moment.astimezone(zone(timezone)).date()


def _positive(value: Decimal | int | float, name: str) -> Decimal:
    amount = measure(value, name)
    if amount <= 0:
        raise ValueError(f"{name} must be > 0, got {amount}")
    return amount


def _slot(slot: str | None) -> str | None:
    if slot is None:
        return None
    try:
        return MealSlot(slot).value
    except ValueError as exc:
        raise ValueError(f"unknown slot {slot!r}") from exc


def _existing(session: Session, client_uuid: UUID, wanted: _NewLog) -> LogResult | None:
    row = session.execute(
        select(ConsumptionLog).where(ConsumptionLog.client_uuid == client_uuid)
    ).scalar_one_or_none()
    if row is None:
        return None
    if not wanted.matches(row):
        raise ClientUuidConflictError(
            f"client_uuid {client_uuid} already belongs to log {row.id} with other content"
        )
    return LogResult(row, LogStatus.DUPLICATE)


def has_active_log(session: Session, plan_item_id: int) -> bool:
    return bool(
        session.execute(
            select(
                exists().where(
                    ConsumptionLog.plan_item_id == plan_item_id,
                    ConsumptionLog.deleted_at.is_(None),
                )
            )
        ).scalar_one()
    )


def _insert(
    session: Session,
    wanted: _NewLog,
    snapshot: dict[str, Any],
    client_uuid: UUID,
    now: datetime,
) -> LogResult:
    log = ConsumptionLog(
        user_id=wanted.user_id,
        consumed_at=wanted.consumed_at,
        log_date=local_date(session, wanted.user_id, wanted.consumed_at),
        slot=wanted.slot,
        plan_item_id=wanted.plan_item_id,
        meal_id=wanted.meal_id,
        food_id=wanted.food_id,
        servings_consumed=_as_float(wanted.servings_consumed),
        grams_consumed=_as_float(wanted.grams_consumed),
        created_at=now,
        deleted_at=None,
        client_uuid=client_uuid,
        nutrients_snapshot=snapshot,
    )
    session.add(log)
    session.flush()
    return LogResult(log, LogStatus.CREATED)


def _as_float(value: Decimal | None) -> float | None:
    """At most 3 decimal places (checked by measure), so the float round-trips exactly."""
    return None if value is None else float(value)


def _plan_item(session: Session, user_id: int, plan_item_id: int) -> MealPlanItem:
    item = session.execute(
        select(MealPlanItem)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlanItem.id == plan_item_id, MealPlan.user_id == user_id)
    ).scalar_one_or_none()
    if item is None:
        raise PlanItemNotFoundError(f"plan item {plan_item_id} is not in a plan of user {user_id}")
    return item


def _check_times(consumed_at: datetime, now: datetime) -> None:
    require_aware(consumed_at, "consumed_at")
    require_aware(now, "now")


def log_plan_item(
    session: Session,
    user_id: int,
    plan_item_id: int,
    servings_consumed: Decimal | int | float,
    consumed_at: datetime,
    client_uuid: UUID,
    now: datetime,
) -> LogResult:
    """Log a plan item; meal and slot come from the item. One active log per item (F.1-d)."""
    _check_times(consumed_at, now)
    servings = _positive(servings_consumed, "servings_consumed")
    item = _plan_item(session, user_id, plan_item_id)
    wanted = _NewLog(
        user_id, item.id, item.meal_id, None, servings, None, consumed_at, _slot(item.slot)
    )
    if (duplicate := _existing(session, client_uuid, wanted)) is not None:
        return duplicate
    if has_active_log(session, item.id):
        raise PlanItemAlreadyLoggedError(
            f"plan item {item.id} already has an active log; use correct_log"
        )
    return _insert(
        session, wanted, meal_snapshot(session, item.meal_id, servings), client_uuid, now
    )


def log_meal(
    session: Session,
    user_id: int,
    meal_id: int,
    servings_consumed: Decimal | int | float,
    consumed_at: datetime,
    slot: str | None,
    client_uuid: UUID,
    now: datetime,
) -> LogResult:
    """Off-plan catalog meal; an inactive meal may be logged (the user ate it, F.1-d)."""
    _check_times(consumed_at, now)
    servings = _positive(servings_consumed, "servings_consumed")
    if session.get(Meal, meal_id) is None:
        raise MealNotFoundError(f"meal {meal_id} does not exist")
    wanted = _NewLog(user_id, None, meal_id, None, servings, None, consumed_at, _slot(slot))
    if (duplicate := _existing(session, client_uuid, wanted)) is not None:
        return duplicate
    return _insert(session, wanted, meal_snapshot(session, meal_id, servings), client_uuid, now)


def log_food(
    session: Session,
    user_id: int,
    food_id: int,
    grams_consumed: Decimal | int | float,
    consumed_at: datetime,
    slot: str | None,
    client_uuid: UUID,
    now: datetime,
) -> LogResult:
    """Off-catalog food, logged in grams."""
    _check_times(consumed_at, now)
    grams = _positive(grams_consumed, "grams_consumed")
    if session.get(Food, food_id) is None:
        raise FoodNotFoundError(f"food {food_id} does not exist")
    wanted = _NewLog(user_id, None, None, food_id, None, grams, consumed_at, _slot(slot))
    if (duplicate := _existing(session, client_uuid, wanted)) is not None:
        return duplicate
    return _insert(session, wanted, food_snapshot(session, food_id, grams), client_uuid, now)


def _active_log(session: Session, user_id: int, log_id: int) -> ConsumptionLog:
    log = session.execute(
        select(ConsumptionLog)
        .where(
            ConsumptionLog.id == log_id,
            ConsumptionLog.user_id == user_id,
            ConsumptionLog.deleted_at.is_(None),
        )
        .with_for_update()
    ).scalar_one_or_none()
    if log is None:
        raise LogNotFoundError(f"user {user_id} has no active log {log_id}")
    return log


def correct_log(
    session: Session,
    user_id: int,
    log_id: int,
    *,
    servings_consumed: Decimal | int | float | None = None,
    grams_consumed: Decimal | int | float | None = None,
    consumed_at: datetime | None = None,
    slot: str | None = None,
    new_client_uuid: UUID,
    now: datetime,
) -> LogResult:
    """Tombstone the log and insert its corrected copy (§11.9, §33.4).

    The new row keeps the old target (plan item, meal or food); changing the target is a
    delete plus a new log (F.1-d decision). A None argument keeps the old value. The slot of a
    plan-item log comes from the plan item and cannot be corrected.
    """
    require_aware(now, "now")
    if consumed_at is not None:
        require_aware(consumed_at, "consumed_at")
    if all(v is None for v in (servings_consumed, grams_consumed, consumed_at, slot)):
        raise ValueError("correct_log needs at least one changed value")

    old = session.execute(
        select(ConsumptionLog).where(ConsumptionLog.id == log_id, ConsumptionLog.user_id == user_id)
    ).scalar_one_or_none()
    if old is None:
        raise LogNotFoundError(f"user {user_id} has no log {log_id}")
    if old.meal_id is not None and grams_consumed is not None:
        raise ValueError("a meal log is corrected in servings; log a food to record grams")
    if old.food_id is not None and servings_consumed is not None:
        raise ValueError("a food log is corrected in grams; log a meal to record servings")
    if old.plan_item_id is not None and slot is not None and _slot(slot) != old.slot:
        raise ValueError("the slot of a plan-item log comes from the plan item")

    def amount(
        new: Decimal | int | float | None, stored: float | None, name: str
    ) -> Decimal | None:
        if new is not None:
            return _positive(new, name)
        return None if stored is None else to_decimal(stored)

    wanted = _NewLog(
        user_id=user_id,
        plan_item_id=old.plan_item_id,
        meal_id=old.meal_id,
        food_id=old.food_id,
        servings_consumed=amount(servings_consumed, old.servings_consumed, "servings_consumed"),
        grams_consumed=amount(grams_consumed, old.grams_consumed, "grams_consumed"),
        consumed_at=consumed_at if consumed_at is not None else old.consumed_at,
        slot=_slot(slot) if slot is not None else old.slot,
    )
    if (duplicate := _existing(session, new_client_uuid, wanted)) is not None:
        return duplicate
    old = _active_log(session, user_id, log_id)
    if wanted.meal_id is not None:
        assert wanted.servings_consumed is not None  # one_target / meal_requires_servings
        snapshot = meal_snapshot(session, wanted.meal_id, wanted.servings_consumed)
    else:
        assert wanted.food_id is not None and wanted.grams_consumed is not None
        snapshot = food_snapshot(session, wanted.food_id, wanted.grams_consumed)
    old.deleted_at = now
    session.flush()
    return _insert(session, wanted, snapshot, new_client_uuid, now)


def delete_log(session: Session, user_id: int, log_id: int, now: datetime) -> ConsumptionLog:
    """Tombstone only (deleted_at = server time, §33.4 #72); nothing else changes."""
    require_aware(now, "now")
    log = _active_log(session, user_id, log_id)
    log.deleted_at = now
    session.flush()
    return log


def active_logs(session: Session, user_id: int, log_date: date) -> list[ConsumptionLog]:
    return list(
        session.execute(
            select(ConsumptionLog)
            .where(
                ConsumptionLog.user_id == user_id,
                ConsumptionLog.log_date == log_date,
                ConsumptionLog.deleted_at.is_(None),
            )
            .order_by(ConsumptionLog.consumed_at, ConsumptionLog.id)
        ).scalars()
    )
