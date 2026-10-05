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
from app.db.models.user import PhysiologicalStatus

ADULT_AGE_YEARS: Final = 18
EXCLUDED_PHYSIOLOGICAL_STATUSES: Final = frozenset(
    {PhysiologicalStatus.PREGNANT, PhysiologicalStatus.LACTATING}
)

UNDER_18: Final = "UNDER_18"
PREGNANT_OR_LACTATING: Final = "PREGNANT_OR_LACTATING"
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
    profile = session.execute(
        select(UserProfile.birth_date, UserProfile.physiological_status).where(
            UserProfile.user_id == user_id
        )
    ).one_or_none()
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")

    reasons: list[str] = []
    if age_in_years(profile.birth_date, as_of) < ADULT_AGE_YEARS:
        reasons.append(UNDER_18)
    if profile.physiological_status in EXCLUDED_PHYSIOLOGICAL_STATUSES:
        reasons.append(PREGNANT_OR_LACTATING)
    unsupported = session.execute(
        select(HealthCondition.code)
        .join(UserHealthCondition, UserHealthCondition.condition_id == HealthCondition.condition_id)
        .where(UserHealthCondition.user_id == user_id, HealthCondition.is_supported.is_(False))
        .order_by(HealthCondition.code)
    ).scalars()
    reasons += [f"{UNSUPPORTED_CONDITION}:{code}" for code in unsupported]
    return ScreeningResult(eligible=not reasons, reasons=reasons)
