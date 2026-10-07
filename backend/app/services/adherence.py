"""Daily adherence, computed on demand and never stored (§30.5, §18.11).

Totals are the sums of the active logs' nutrients_snapshot (tombstones ignored, §11.9); a log
whose snapshot lacks a mandatory nutrient makes that total unknown (None), never zero (§9.8).
The day is compared with the user_targets row valid on that date (#72) and with the
condition max_per_day values resolved for that target's kcal.

Condition history is not stored (user_health_conditions has no validity dates, §11.3), so
every day, past days included, is judged against the user's *current* conditions.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal
from enum import StrEnum
from typing import Final

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, MealPlan, MealPlanItem, Nutrient, UserProfile, UserTarget
from app.services.common import round_half_up, to_decimal, zone
from app.services.condition_limits import (
    ENERGY_NUTRIENT,
    ConditionConflictError,
    resolve_condition_limits,
)
from app.services.consumption import SNAPSHOT_NUTRIENTS_KEY, active_logs
from app.services.planner import KCAL_TOLERANCE, UnmetMinimum, current_plan_id, unmet_minimums
from app.services.screening import ProfileNotFoundError
from app.services.targets import fiber_target_g

# --- §30.5 day status ------------------------------------------------------------------------
ACHIEVED_KCAL_TOLERANCE: Final = KCAL_TOLERANCE  # ±10% of target_kcal
PARTIAL_KCAL_TOLERANCE: Final = Decimal("0.25")  # ±25% of target_kcal
COMPLETION_PLACES: Final = 3  # F.1-d decision
FIBER_NUTRIENT: Final = "fiber"  # §30.4b: shown, not part of the status
# ---------------------------------------------------------------------------------------------

NO_TARGET: Final = "NO_TARGET"
LIMITS_CONFLICT: Final = "LIMITS_CONFLICT"


class DayStatus(StrEnum):
    ACHIEVED = "ACHIEVED"
    PARTIAL = "PARTIAL"
    NOT_ACHIEVED = "NOT_ACHIEVED"


@dataclass(frozen=True)
class ExceededLimit:
    nutrient: str
    total: Decimal | None
    limit: Decimal


@dataclass(frozen=True)
class DayAdherence:
    user_id: int
    log_date: date
    status: DayStatus | None
    reason: str | None
    target_id: int | None
    target_kcal: Decimal | None
    totals: Mapping[str, Decimal | None]
    log_count: int
    exceeded_max_per_day: tuple[ExceededLimit, ...]
    unmet_minimums: tuple[UnmetMinimum, ...]
    fiber_target_g: int | None
    fiber_g: Decimal | None
    plan_id: int | None
    plan_items_total: int
    plan_items_consumed: int
    completion: Decimal | None

    @property
    def energy_kcal(self) -> Decimal | None:
        return self.totals.get(ENERGY_NUTRIENT)


@dataclass(frozen=True)
class AdherenceRange:
    days: tuple[DayAdherence, ...]
    streak: int  # consecutive ACHIEVED days ending at the last day


def day_status(energy_kcal: Decimal | None, target_kcal: Decimal, limits_met: bool) -> DayStatus:
    """§30.5 status; both tolerance bounds are inclusive. Unknown energy is NOT_ACHIEVED."""
    if energy_kcal is None:
        return DayStatus.NOT_ACHIEVED
    deviation = abs(energy_kcal - target_kcal)
    if limits_met and deviation <= ACHIEVED_KCAL_TOLERANCE * target_kcal:
        return DayStatus.ACHIEVED
    if deviation <= PARTIAL_KCAL_TOLERANCE * target_kcal:
        return DayStatus.PARTIAL
    return DayStatus.NOT_ACHIEVED


def snapshot_totals(
    snapshots: list[Mapping[str, object]], nutrient_codes: list[str]
) -> dict[str, Decimal | None]:
    """Per mandatory nutrient, the sum over the snapshots; None if any snapshot lacks it."""
    totals: dict[str, Decimal | None] = {code: Decimal(0) for code in nutrient_codes}
    for snapshot in snapshots:
        values = snapshot.get(SNAPSHOT_NUTRIENTS_KEY)
        values = values if isinstance(values, Mapping) else {}
        for code in nutrient_codes:
            running = totals[code]
            value = values.get(code)
            totals[code] = None if running is None or value is None else running + Decimal(value)
    return totals


def end_of_local_day(day: date, timezone: str) -> datetime:
    """The next local midnight after `day`, in UTC."""
    return datetime.combine(day + timedelta(days=1), time(0), tzinfo=zone(timezone)).astimezone(UTC)


def target_on(session: Session, user_id: int, day: date, timezone: str) -> UserTarget | None:
    """#72: the latest user_targets row whose valid_from is before the end of that local day."""
    return session.execute(
        select(UserTarget)
        .where(
            UserTarget.user_id == user_id,
            UserTarget.valid_from < end_of_local_day(day, timezone),
        )
        .order_by(UserTarget.valid_from.desc(), UserTarget.target_id.desc())
        .limit(1)
    ).scalar_one_or_none()


def _completion(session: Session, user_id: int, day: date) -> tuple[int | None, int, int]:
    """(plan_id, items, consumed items) of the current plan covering `day` (§11.7 #72)."""
    plan_id = current_plan_id(session, user_id, day)
    if plan_id is None:
        return None, 0, 0
    date_from = session.execute(
        select(MealPlan.date_from).where(MealPlan.plan_id == plan_id)
    ).scalar_one()
    day_index = (day - date_from).days
    consumed = (
        select(ConsumptionLog.id)
        .where(ConsumptionLog.plan_item_id == MealPlanItem.id, ConsumptionLog.deleted_at.is_(None))
        .exists()
    )
    total, eaten = session.execute(
        select(func.count(), func.count().filter(consumed))
        .select_from(MealPlanItem)
        .where(MealPlanItem.plan_id == plan_id, MealPlanItem.day_index == day_index)
    ).one()
    return plan_id, int(total), int(eaten)


def daily_adherence(session: Session, user_id: int, log_date: date) -> DayAdherence:
    timezone = session.execute(
        select(UserProfile.timezone).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    if timezone is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    codes = list(
        session.execute(
            select(Nutrient.code).where(Nutrient.is_mandatory).order_by(Nutrient.nutrient_id)
        ).scalars()
    )
    logs = active_logs(session, user_id, log_date)
    totals = snapshot_totals([log.nutrients_snapshot for log in logs], codes)
    plan_id, items_total, items_consumed = _completion(session, user_id, log_date)
    completion = (
        round_half_up(Decimal(items_consumed) / Decimal(items_total), COMPLETION_PLACES)
        if items_total
        else None
    )

    target = target_on(session, user_id, log_date, timezone)
    status: DayStatus | None = None
    reason: str | None = None
    target_kcal: Decimal | None = None
    exceeded: tuple[ExceededLimit, ...] = ()
    unmet: tuple[UnmetMinimum, ...] = ()
    if target is None:
        reason = NO_TARGET
    else:
        target_kcal = to_decimal(target.target_kcal)
        try:
            limits = resolve_condition_limits(session, user_id, target_kcal)
        except ConditionConflictError:
            reason = LIMITS_CONFLICT
        else:
            exceeded = tuple(
                ExceededLimit(nutrient, totals.get(nutrient), limit.value)
                for nutrient, limit in sorted(limits.max_per_day.items())
                if (total := totals.get(nutrient)) is None or total > limit.value
            )
            unmet = unmet_minimums(totals, limits)
            status = day_status(totals.get(ENERGY_NUTRIENT), target_kcal, not exceeded)

    return DayAdherence(
        user_id=user_id,
        log_date=log_date,
        status=status,
        reason=reason,
        target_id=None if target is None else target.target_id,
        target_kcal=target_kcal,
        totals=totals,
        log_count=len(logs),
        exceeded_max_per_day=exceeded,
        unmet_minimums=unmet,
        fiber_target_g=None if target_kcal is None else fiber_target_g(target_kcal),
        fiber_g=totals.get(FIBER_NUTRIENT),
        plan_id=plan_id,
        plan_items_total=items_total,
        plan_items_consumed=items_consumed,
        completion=completion,
    )


def adherence_range(
    session: Session, user_id: int, date_from: date, date_to: date
) -> AdherenceRange:
    """One DayAdherence per day; the streak may reach back before date_from."""
    if date_to < date_from:
        raise ValueError(f"date_to {date_to} is before date_from {date_from}")
    days = tuple(
        daily_adherence(session, user_id, date_from + timedelta(days=offset))
        for offset in range((date_to - date_from).days + 1)
    )
    streak = 0
    for day in reversed(days):
        if day.status is not DayStatus.ACHIEVED:
            return AdherenceRange(days, streak)
        streak += 1
    # Every day in the range is ACHIEVED: continue backwards. A day without logs is never
    # ACHIEVED (zero energy), so the walk ends at the first day before the earliest log.
    earlier = date_from - timedelta(days=1)
    while daily_adherence(session, user_id, earlier).status is DayStatus.ACHIEVED:
        streak += 1
        earlier -= timedelta(days=1)
    return AdherenceRange(days, streak)
