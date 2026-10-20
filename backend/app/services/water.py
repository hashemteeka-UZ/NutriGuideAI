"""Water goal, the home-screen day, and water writes (#179, #196, #204, §30.7)."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, datetime
from enum import StrEnum
from typing import Final, Literal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import HealthCondition, UserHealthCondition, UserProfile, WaterLog
from app.db.models.user import Sex
from app.services.common import require_aware
from app.services.consumption import ClientUuidConflictError, LogNotFoundError
from app.services.logging_requests import ensure_log_instant
from app.services.screening import ProfileNotFoundError, ScreeningResult, screen_user

logger = logging.getLogger("nutriguide.api")

# EFSA (2010) adequate intake of total water, minus about 20% supplied by food:
# 2.0 L for women and 2.5 L for men.
DEFAULT_WATER_ML_FEMALE: Final = 1600
DEFAULT_WATER_ML_MALE: Final = 2000

_DEFAULT_ML: Final = {
    Sex.FEMALE.value: DEFAULT_WATER_ML_FEMALE,
    Sex.MALE.value: DEFAULT_WATER_ML_MALE,
}

WaterSource = Literal["USER", "DEFAULT", "NONE"]


@dataclass(frozen=True)
class WaterGoalResult:
    goal_ml: int | None
    source: WaterSource
    requires_clinician: bool
    reminders_default_off: bool


def water_goal(
    session: Session,
    user_id: int,
    screening: ScreeningResult,
    sex: Sex | str,
    water_goal_ml: int | None,
) -> WaterGoalResult:
    """User amount, else no default when flagged or ineligible, else the EFSA default."""
    flagged = (
        session.execute(
            select(HealthCondition.condition_id)
            .join(
                UserHealthCondition,
                UserHealthCondition.condition_id == HealthCondition.condition_id,
            )
            .where(
                UserHealthCondition.user_id == user_id,
                HealthCondition.fluid_goal_requires_clinician.is_(True),
            )
            .limit(1)
        ).first()
        is not None
    )
    sex_value = sex.value if isinstance(sex, Sex) else sex
    if water_goal_ml is not None:
        return WaterGoalResult(water_goal_ml, "USER", flagged, flagged)
    if flagged or not screening.eligible:
        return WaterGoalResult(None, "NONE", flagged, flagged)
    return WaterGoalResult(_DEFAULT_ML[sex_value], "DEFAULT", False, False)


def water_day(
    session: Session, user_id: int, day: date
) -> tuple[int, WaterGoalResult, list[WaterLog]]:
    """Active logs of that local date, their sum, and the water goal (#196)."""
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    goal = water_goal(
        session,
        user_id,
        screen_user(session, user_id, day),
        profile.sex,
        profile.water_goal_ml,
    )
    logs = list(
        session.scalars(
            select(WaterLog)
            .where(
                WaterLog.user_id == user_id,
                WaterLog.log_date == day,
                WaterLog.deleted_at.is_(None),
            )
            .order_by(WaterLog.consumed_at, WaterLog.id)
        ).all()
    )
    return sum(log.amount_ml for log in logs), goal, logs


class WaterStatus(StrEnum):
    CREATED = "CREATED"
    DUPLICATE = "DUPLICATE"


def _write(user_id: int, status: str) -> None:
    logger.info("water write user_id=%s kind=%s status=%s", user_id, "WATER", status)


def log_water(
    session: Session,
    user_id: int,
    amount_ml: int,
    consumed_at: datetime,
    client_uuid: UUID,
    now: datetime,
) -> tuple[WaterLog, WaterStatus]:
    """Same client_uuid and the same amount and time is a DUPLICATE.

    log_date is the user's local date of consumed_at.
    """
    require_aware(consumed_at, "consumed_at")
    require_aware(now, "now")
    eaten = ensure_log_instant(session, user_id, consumed_at, now)
    existing = session.execute(
        select(WaterLog).where(WaterLog.client_uuid == client_uuid)
    ).scalar_one_or_none()
    if existing is not None:
        same = (
            existing.user_id == user_id
            and existing.amount_ml == amount_ml
            and existing.consumed_at == consumed_at
        )
        if not same:
            raise ClientUuidConflictError(
                f"client_uuid {client_uuid} already belongs to water log {existing.id} "
                "with other content"
            )
        _write(user_id, WaterStatus.DUPLICATE.value)
        return existing, WaterStatus.DUPLICATE
    row = WaterLog(
        user_id=user_id,
        consumed_at=consumed_at,
        log_date=eaten,
        amount_ml=amount_ml,
        client_uuid=client_uuid,
        created_at=now,
        deleted_at=None,
    )
    session.add(row)
    session.flush()
    _write(user_id, WaterStatus.CREATED.value)
    return row, WaterStatus.CREATED


def delete_water(session: Session, user_id: int, log_id: int, now: datetime) -> WaterLog:
    """Tombstone an active water log of this user. deleted_at is the server time."""
    require_aware(now, "now")
    log = session.execute(
        select(WaterLog)
        .where(
            WaterLog.id == log_id,
            WaterLog.user_id == user_id,
            WaterLog.deleted_at.is_(None),
        )
        .with_for_update()
    ).scalar_one_or_none()
    if log is None:
        raise LogNotFoundError(f"user {user_id} has no active water log {log_id}")
    log.deleted_at = now
    session.flush()
    _write(user_id, "DELETED")
    return log
