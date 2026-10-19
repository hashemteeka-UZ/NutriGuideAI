"""Water goal only. Logging arrives in I.6 (#179, §30.7)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Final, Literal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import HealthCondition, UserHealthCondition
from app.db.models.user import Sex
from app.services.screening import ScreeningResult

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
