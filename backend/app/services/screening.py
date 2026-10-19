"""Screening before any personalized plan (§30.1).

The multi-condition limit conflict check of §30.1 belongs to plan generation (pass F.1-c).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Final

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import HealthCondition, UserHealthCondition, UserProfile

ADULT_AGE_YEARS: Final = 18

UNDER_18: Final = "UNDER_18"
UNSUPPORTED_CONDITION: Final = "UNSUPPORTED_CONDITION"


class ProfileNotFoundError(LookupError):
    pass


@dataclass(frozen=True)
class ScreeningResult:
    eligible: bool
    reasons: list[str]


def age_in_years(birth_date: date, on: date) -> int:
    """Full years completed on `on`."""
    before_birthday = (on.month, on.day) < (birth_date.month, birth_date.day)
    return on.year - birth_date.year - before_birthday


def screen_user(session: Session, user_id: int, as_of: date) -> ScreeningResult:
    birth_date = session.execute(
        select(UserProfile.birth_date).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    if birth_date is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")

    reasons: list[str] = []
    if age_in_years(birth_date, as_of) < ADULT_AGE_YEARS:
        reasons.append(UNDER_18)
    unsupported = session.execute(
        select(HealthCondition.code)
        .join(UserHealthCondition, UserHealthCondition.condition_id == HealthCondition.condition_id)
        .where(UserHealthCondition.user_id == user_id, HealthCondition.is_supported.is_(False))
        .order_by(HealthCondition.code)
    ).scalars()
    reasons += [f"{UNSUPPORTED_CONDITION}:{code}" for code in unsupported]
    return ScreeningResult(eligible=not reasons, reasons=reasons)
