"""Profile replace, screening, and the current target (I.3)."""

from datetime import date, datetime
from typing import Literal, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.api.schemas.common import ClockTime, with_example
from app.db.models.user import (
    ActivityLevel,
    AllergenSeverity,
    ConditionSeverity,
    GoalType,
    IngredientStance,
    Sex,
    TargetReason,
)

TARGET_EXAMPLE = {
    "target_id": 7,
    "valid_from": "2026-10-19T06:00:00Z",
    "reason": "INITIAL",
    "formula_version": "targets_v1",
    "based_on_weight_kg": 82.5,
    "bmr_kcal": 1700,
    "tdee_kcal": 2635,
    "kcal": 1800,
    "protein_g": 120,
    "carb_g": 195,
    "fat_g": 60,
    "fiber_g": 30,
    "was_floor_applied": False,
}

SCREENING_EXAMPLE = {"eligible": True, "reasons": []}

WATER_GOAL_EXAMPLE = {
    "goal_ml": 2500,
    "source": "USER",
    "requires_clinician": False,
    "reminders_default_off": False,
}

PROFILE_EXAMPLE = {
    "sex": "MALE",
    "birth_date": "1990-04-12",
    "height_cm": 175,
    "activity_level": "MODERATE",
    "goal_type": "LOSE",
    "target_weight_kg": 75,
    "weekly_rate_kg": 0.5,
    "timezone": "Africa/Tripoli",
    "wake_time": "07:00",
    "sleep_time": "23:00",
    "water_goal_ml": 2500,
    "latest_weight_kg": 82.5,
    "latest_weight_on": "2026-10-19",
    "conditions": [{"code": "HYPERTENSION", "severity": "MODERATE"}],
    "allergens": [{"code": "GLUTEN", "severity": "AVOID"}],
    "ingredient_prefs": [{"ingredient_id": 18, "stance": "LIKE"}],
    "cuisines": ["LIBYAN"],
}


class ConditionChoice(BaseModel):
    model_config = with_example(
        {"code": "HYPERTENSION", "severity": "MODERATE"},
        forbid_extra=True,
    )

    code: str
    severity: ConditionSeverity | None = None


class AllergenChoice(BaseModel):
    model_config = with_example({"code": "GLUTEN", "severity": "AVOID"}, forbid_extra=True)

    code: str
    severity: AllergenSeverity


class IngredientChoice(BaseModel):
    model_config = with_example(
        {"ingredient_id": 18, "stance": "LIKE"},
        forbid_extra=True,
    )

    ingredient_id: int
    stance: IngredientStance


class ProfileUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    sex: Sex
    birth_date: date
    height_cm: float = Field(ge=100, le=250)
    activity_level: ActivityLevel
    goal_type: GoalType
    target_weight_kg: float | None = Field(default=None, ge=30, le=300)
    weekly_rate_kg: float | None = Field(default=None, gt=0, le=1)
    timezone: str
    wake_time: ClockTime
    sleep_time: ClockTime
    water_goal_ml: int | None = Field(default=None, ge=500, le=5000)
    current_weight_kg: float | None = Field(default=None, ge=20, le=400)
    conditions: list[ConditionChoice] = Field(max_length=10)
    allergens: list[AllergenChoice] = Field(max_length=20)
    ingredient_prefs: list[IngredientChoice] = Field(max_length=100)
    cuisines: list[str] = Field(max_length=10)

    @model_validator(mode="after")
    def consistent(self) -> Self:
        if self.wake_time == self.sleep_time:
            raise ValueError("wake_time and sleep_time must differ")
        if self.goal_type is not GoalType.MAINTAIN and (
            self.target_weight_kg is None or self.weekly_rate_kg is None
        ):
            raise ValueError(
                "target_weight_kg and weekly_rate_kg are required unless goal is MAINTAIN"
            )
        if len(self.conditions) != len({choice.code for choice in self.conditions}):
            raise ValueError("duplicate condition code")
        if len(self.allergens) != len({choice.code for choice in self.allergens}):
            raise ValueError("duplicate allergen code")
        if len(self.cuisines) != len(set(self.cuisines)):
            raise ValueError("duplicate cuisine code")
        ingredient_ids = {choice.ingredient_id for choice in self.ingredient_prefs}
        if len(self.ingredient_prefs) != len(ingredient_ids):
            raise ValueError("duplicate ingredient id")
        return self


class Profile(BaseModel):
    sex: Sex
    birth_date: date
    height_cm: float
    activity_level: ActivityLevel
    goal_type: GoalType
    target_weight_kg: float | None = None
    weekly_rate_kg: float | None = None
    timezone: str
    wake_time: ClockTime
    sleep_time: ClockTime
    water_goal_ml: int | None = None
    latest_weight_kg: float | None = None
    latest_weight_on: date | None = None
    conditions: list[ConditionChoice]
    allergens: list[AllergenChoice]
    ingredient_prefs: list[IngredientChoice]
    cuisines: list[str]

    model_config = with_example(PROFILE_EXAMPLE)


class Screening(BaseModel):
    eligible: bool
    reasons: list[str]

    model_config = with_example(SCREENING_EXAMPLE)


class Target(BaseModel):
    target_id: int
    valid_from: datetime
    reason: TargetReason
    formula_version: str
    based_on_weight_kg: float
    bmr_kcal: float
    tdee_kcal: float
    kcal: int
    protein_g: float
    carb_g: float
    fat_g: float
    fiber_g: int
    was_floor_applied: bool

    model_config = with_example(TARGET_EXAMPLE)


class WaterGoal(BaseModel):
    goal_ml: int | None = None
    source: Literal["USER", "DEFAULT", "NONE"]
    requires_clinician: bool
    reminders_default_off: bool

    model_config = with_example(WATER_GOAL_EXAMPLE)


class ProfileState(BaseModel):
    profile: Profile
    screening: Screening
    target: Target | None = None

    model_config = with_example(
        {
            "profile": PROFILE_EXAMPLE,
            "screening": SCREENING_EXAMPLE,
            "target": TARGET_EXAMPLE,
        }
    )


class TargetsView(BaseModel):
    screening: Screening
    target: Target | None = None
    water: WaterGoal

    model_config = with_example(
        {
            "screening": SCREENING_EXAMPLE,
            "target": TARGET_EXAMPLE,
            "water": WATER_GOAL_EXAMPLE,
        }
    )
