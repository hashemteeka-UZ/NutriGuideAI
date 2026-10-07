"""Weight log with last-write-wins upsert and the WEIGHT_UPDATE recompute (§11.10, §30.6, §33.4).

updated_at is the device time of the edit (#44, #63): the server rejects values beyond a small
clock skew, and of two versions of one day the newer updated_at wins. A written weight that is
the user's latest (by measured_on) and differs ≥ 1 kg from the current target's
based_on_weight_kg creates a WEIGHT_UPDATE target; a back-dated entry never does.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from enum import StrEnum
from typing import Final

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.db.models import UserProfile, UserTarget, WeightLog
from app.db.models.user import TargetReason, WeightSource
from app.services.common import measure, require_aware, to_decimal, zone
from app.services.screening import ProfileNotFoundError
from app.services.targets import TargetValidationError, UserNotEligibleError, create_user_target

# --- §11.10 / §30.6 / §33.4 --------------------------------------------------------------------
CLOCK_SKEW_TOLERANCE: Final = timedelta(minutes=5)  # F.1-d decision
WEIGHT_RECOMPUTE_DELTA_KG: Final = Decimal("1")  # §30.6, inclusive
GOAL_REACHED_DELTA_KG: Final = Decimal("1")  # F.1-d decision, inclusive
WEIGHT_MIN_KG: Final = Decimal(20)  # weight_logs.weight_range
WEIGHT_MAX_KG: Final = Decimal(400)
# ---------------------------------------------------------------------------------------------


class ClockSkewError(ValueError):
    pass


class WeightStatus(StrEnum):
    CREATED = "CREATED"
    UPDATED = "UPDATED"
    STALE_IGNORED = "STALE_IGNORED"


class TargetStatus(StrEnum):
    NOT_TRIGGERED = "NOT_TRIGGERED"  # stale, back-dated, or below the 1 kg delta
    NO_CURRENT_TARGET = "NO_CURRENT_TARGET"
    CREATED = "CREATED"
    INELIGIBLE = "INELIGIBLE"  # screening failed (§30.1); the weight is kept
    GOAL_INVALID = "GOAL_INVALID"  # the goal no longer fits the weight (§30.3); weight kept


@dataclass(frozen=True)
class WeightResult:
    weight_log: WeightLog
    status: WeightStatus
    target_status: TargetStatus
    new_target_id: int | None
    goal_reached: bool


def _weight(value: Decimal | int | float) -> Decimal:
    weight = measure(value, "weight_kg")
    if not WEIGHT_MIN_KG <= weight <= WEIGHT_MAX_KG:
        raise ValueError(f"weight_kg must be between {WEIGHT_MIN_KG} and {WEIGHT_MAX_KG}")
    return weight


def _upsert(
    session: Session,
    user_id: int,
    measured_on: date,
    weight: Decimal,
    updated_at: datetime,
    now: datetime,
) -> tuple[WeightLog, WeightStatus]:
    inserted = session.execute(
        insert(WeightLog)
        .values(
            user_id=user_id,
            measured_on=measured_on,
            weight_kg=float(weight),
            source=WeightSource.MANUAL,
            created_at=now,
            updated_at=updated_at,
        )
        .on_conflict_do_nothing(index_elements=[WeightLog.user_id, WeightLog.measured_on])
        .returning(WeightLog.id)
    ).scalar_one_or_none()
    row = session.execute(
        select(WeightLog)
        .where(WeightLog.user_id == user_id, WeightLog.measured_on == measured_on)
        .with_for_update()
        .execution_options(populate_existing=True)
    ).scalar_one()
    if inserted is not None:
        return row, WeightStatus.CREATED
    if row.updated_at >= updated_at:
        return row, WeightStatus.STALE_IGNORED
    row.weight_kg = float(weight)
    row.updated_at = updated_at
    session.flush()
    return row, WeightStatus.UPDATED


def _latest_weight(session: Session, user_id: int) -> tuple[date, Decimal]:
    measured_on, weight_kg = session.execute(
        select(WeightLog.measured_on, WeightLog.weight_kg)
        .where(WeightLog.user_id == user_id)
        .order_by(WeightLog.measured_on.desc())
        .limit(1)
    ).one()
    return measured_on, to_decimal(weight_kg)


def _recompute(
    session: Session, user_id: int, weight: Decimal, now: datetime
) -> tuple[TargetStatus, int | None]:
    based_on = session.execute(
        select(UserTarget.based_on_weight_kg).where(
            UserTarget.user_id == user_id, UserTarget.valid_to.is_(None)
        )
    ).scalar_one_or_none()
    if based_on is None:
        return TargetStatus.NO_CURRENT_TARGET, None
    if abs(weight - to_decimal(based_on)) < WEIGHT_RECOMPUTE_DELTA_KG:
        return TargetStatus.NOT_TRIGGERED, None
    try:
        with session.begin_nested():
            target = create_user_target(session, user_id, TargetReason.WEIGHT_UPDATE, now)
    except UserNotEligibleError:
        return TargetStatus.INELIGIBLE, None
    except TargetValidationError:
        return TargetStatus.GOAL_INVALID, None
    return TargetStatus.CREATED, target.target_id


def record_weight(
    session: Session,
    user_id: int,
    measured_on: date,
    weight_kg: Decimal | int | float,
    updated_at: datetime,
    now: datetime,
) -> WeightResult:
    weight = _weight(weight_kg)
    require_aware(updated_at, "updated_at")
    require_aware(now, "now")
    if updated_at > now + CLOCK_SKEW_TOLERANCE:
        raise ClockSkewError(
            f"updated_at {updated_at.isoformat()} is more than {CLOCK_SKEW_TOLERANCE} after the "
            f"server time {now.isoformat()}"
        )
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    local_today = (now + CLOCK_SKEW_TOLERANCE).astimezone(zone(profile.timezone)).date()
    if measured_on > local_today:
        raise ValueError(f"measured_on {measured_on} is after the user's local date {local_today}")

    row, status = _upsert(session, user_id, measured_on, weight, updated_at, now)
    latest_on, latest_weight = _latest_weight(session, user_id)
    target_status, new_target_id = TargetStatus.NOT_TRIGGERED, None
    if status is not WeightStatus.STALE_IGNORED and latest_on == measured_on:
        target_status, new_target_id = _recompute(session, user_id, weight, now)

    goal = profile.target_weight_kg
    goal_reached = (
        goal is not None and abs(latest_weight - to_decimal(goal)) <= GOAL_REACHED_DELTA_KG
    )
    return WeightResult(row, status, target_status, new_target_id, goal_reached)
