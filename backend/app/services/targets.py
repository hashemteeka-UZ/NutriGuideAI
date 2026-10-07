"""targets_v1: daily energy and macronutrient targets (§30.2-§30.4b, §30.6, §11.11).

compute_targets is pure; create_user_target stores a new current user_targets row.
All values are engineering defaults to be reviewed by a dietitian (§30).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Final
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import UserProfile, UserTarget, WeightLog
from app.db.models.user import ActivityLevel, GoalType, Sex, TargetReason
from app.services.common import round_half_up, to_decimal
from app.services.screening import ProfileNotFoundError, age_in_years, screen_user

logger = logging.getLogger(__name__)

FORMULA_VERSION: Final = "targets_v1"

# --- targets_v1 constants -------------------------------------------------------------------
# §30.2 Mifflin-St Jeor: 10·W + 6.25·H - 5·A + s (s = +5 men, -161 women).
BMR_WEIGHT_FACTOR: Final = Decimal(10)
BMR_HEIGHT_FACTOR: Final = Decimal("6.25")
BMR_AGE_FACTOR: Final = Decimal(5)
BMR_SEX_CONSTANT: Final = {Sex.MALE: Decimal(5), Sex.FEMALE: Decimal(-161)}
# §30.2 physical activity level multipliers.
PAL: Final = {
    ActivityLevel.SEDENTARY: Decimal("1.2"),
    ActivityLevel.LIGHT: Decimal("1.375"),
    ActivityLevel.MODERATE: Decimal("1.55"),
    ActivityLevel.HIGH: Decimal("1.725"),
    ActivityLevel.ATHLETE: Decimal("1.9"),
}
# §30.3 goal adjustment and safety.
KCAL_PER_KG_BODY_WEIGHT: Final = Decimal(7700)
DAYS_PER_WEEK: Final = Decimal(7)
LOSE_MAX_WEEKLY_RATE_FRACTION: Final = Decimal("0.01")  # of body weight
LOSE_MAX_DEFICIT_KCAL: Final = Decimal(1000)
GAIN_MAX_WEEKLY_RATE_KG: Final = Decimal("0.5")
GAIN_MAX_SURPLUS_KCAL: Final = Decimal(500)
CALORIE_FLOOR_KCAL: Final = {Sex.FEMALE: Decimal(1200), Sex.MALE: Decimal(1500)}
# §30.4 protein (#64-#66): midpoint of the range in g/kg; ATHLETE whatever the goal.
PROTEIN_G_PER_KG: Final = {
    GoalType.LOSE: Decimal("1.4"),
    GoalType.MAINTAIN: Decimal("1.0"),
    GoalType.GAIN: Decimal("1.8"),
}
ATHLETE_PROTEIN_G_PER_KG: Final = Decimal("1.8")
# §30.4 low end of the protein range, used by the 130 g carbohydrate rule; MAINTAIN has no range.
PROTEIN_MIN_G_PER_KG: Final = {GoalType.LOSE: Decimal("1.2"), GoalType.GAIN: Decimal("1.6")}
ATHLETE_PROTEIN_MIN_G_PER_KG: Final = Decimal("1.6")
# §30.4 protein reference weight (#65).
OBESITY_BMI: Final = Decimal(30)
IDEAL_BMI: Final = Decimal(25)
ADJUSTED_WEIGHT_FRACTION: Final = Decimal("0.4")
# §30.4 fat share of energy and carbohydrate minimum (#67).
FAT_ENERGY_FRACTION: Final = Decimal("0.30")
FAT_MIN_ENERGY_FRACTION: Final = Decimal("0.25")
MIN_CARB_G: Final = Decimal(130)
KCAL_PER_G_PROTEIN: Final = Decimal(4)
KCAL_PER_G_CARB: Final = Decimal(4)
KCAL_PER_G_FAT: Final = Decimal(9)
# §30.4b fiber: 14 g per 1000 kcal, returned but not stored.
FIBER_G_PER_1000_KCAL: Final = Decimal(14)
# §11.11 stored precision.
KCAL_PLACES: Final = 1
TARGET_KCAL_PLACES: Final = 0
GRAM_PLACES: Final = 1
# ---------------------------------------------------------------------------------------------

FAT_LOWERED: Final = "FAT_LOWERED"
PROTEIN_LOWERED: Final = "PROTEIN_LOWERED"
CARB_BELOW_MINIMUM: Final = "CARB_BELOW_MINIMUM"


class TargetError(Exception):
    pass


class TargetValidationError(TargetError, ValueError):
    pass


class MissingWeightError(TargetError, LookupError):
    pass


class UserNotEligibleError(TargetError):
    def __init__(self, user_id: int, reasons: list[str]) -> None:
        super().__init__(f"user {user_id} fails screening (§30.1): {', '.join(reasons)}")
        self.reasons = reasons


@dataclass(frozen=True)
class TargetInputs:
    sex: Sex
    age_years: int
    height_cm: Decimal
    weight_kg: Decimal
    activity_level: ActivityLevel
    goal_type: GoalType
    weekly_rate_kg: Decimal | None = None
    target_weight_kg: Decimal | None = None


@dataclass(frozen=True)
class TargetResult:
    bmr_kcal: Decimal
    tdee_kcal: Decimal
    raw_target_kcal: Decimal
    target_kcal: int
    protein_g: Decimal
    fat_g: Decimal
    carb_g: Decimal
    fiber_g: int
    effective_weekly_rate_kg: Decimal | None
    adjustment_kcal: Decimal
    rate_was_capped: bool
    adjustment_was_capped: bool
    was_floor_applied: bool
    protein_g_per_kg: Decimal
    protein_reference_weight_kg: Decimal
    carb_adjustments: tuple[str, ...]
    carb_minimum_unmet: bool
    formula_version: str = FORMULA_VERSION


def _validate(inputs: TargetInputs) -> None:
    if inputs.height_cm <= 0 or inputs.weight_kg <= 0:
        raise TargetValidationError("height_cm and weight_kg must be positive")
    if inputs.goal_type == GoalType.MAINTAIN:
        return
    if inputs.weekly_rate_kg is None or inputs.weekly_rate_kg <= 0:
        raise TargetValidationError(f"{inputs.goal_type} requires a positive weekly_rate_kg")
    if inputs.target_weight_kg is None:
        raise TargetValidationError(f"{inputs.goal_type} requires target_weight_kg")
    # §11.2: direction consistency with the current weight is application logic.
    if inputs.goal_type == GoalType.LOSE and not inputs.target_weight_kg < inputs.weight_kg:
        raise TargetValidationError(
            f"LOSE requires target_weight_kg ({inputs.target_weight_kg}) below the current "
            f"weight ({inputs.weight_kg})"
        )
    if inputs.goal_type == GoalType.GAIN and not inputs.target_weight_kg > inputs.weight_kg:
        raise TargetValidationError(
            f"GAIN requires target_weight_kg ({inputs.target_weight_kg}) above the current "
            f"weight ({inputs.weight_kg})"
        )


def _goal_adjustment(inputs: TargetInputs) -> tuple[Decimal | None, Decimal, bool, bool]:
    """(effective weekly rate, signed kcal adjustment, rate capped, adjustment capped)."""
    if inputs.goal_type == GoalType.MAINTAIN or inputs.weekly_rate_kg is None:
        return None, Decimal(0), False, False
    if inputs.goal_type == GoalType.LOSE:
        max_rate = LOSE_MAX_WEEKLY_RATE_FRACTION * inputs.weight_kg
        max_adjustment, sign = LOSE_MAX_DEFICIT_KCAL, -1
    else:
        max_rate = GAIN_MAX_WEEKLY_RATE_KG
        max_adjustment, sign = GAIN_MAX_SURPLUS_KCAL, 1
    rate = min(inputs.weekly_rate_kg, max_rate)
    adjustment = rate * KCAL_PER_KG_BODY_WEIGHT / DAYS_PER_WEEK
    return (
        rate,
        sign * min(adjustment, max_adjustment),
        inputs.weekly_rate_kg > max_rate,
        adjustment > max_adjustment,
    )


def protein_reference_weight(weight_kg: Decimal, height_cm: Decimal) -> Decimal:
    height_m_squared = (height_cm / 100) ** 2
    if weight_kg / height_m_squared < OBESITY_BMI:
        return weight_kg
    ideal = IDEAL_BMI * height_m_squared
    return ideal + ADJUSTED_WEIGHT_FRACTION * (weight_kg - ideal)


def fiber_target_g(target_kcal: Decimal) -> int:
    """§30.4b: 14 g per 1000 kcal, rounded; not stored, fully determined by target_kcal."""
    return int(round_half_up(FIBER_G_PER_1000_KCAL * target_kcal / 1000, 0))


def compute_targets(inputs: TargetInputs) -> TargetResult:
    _validate(inputs)
    bmr = (
        BMR_WEIGHT_FACTOR * inputs.weight_kg
        + BMR_HEIGHT_FACTOR * inputs.height_cm
        - BMR_AGE_FACTOR * inputs.age_years
        + BMR_SEX_CONSTANT[inputs.sex]
    )
    tdee = bmr * PAL[inputs.activity_level]
    rate, adjustment, rate_capped, adjustment_capped = _goal_adjustment(inputs)
    raw_target = tdee + adjustment
    floor = CALORIE_FLOOR_KCAL[inputs.sex]
    kcal = round_half_up(max(raw_target, floor), TARGET_KCAL_PLACES)

    athlete = inputs.activity_level == ActivityLevel.ATHLETE
    g_per_kg = ATHLETE_PROTEIN_G_PER_KG if athlete else PROTEIN_G_PER_KG[inputs.goal_type]
    min_g_per_kg = (
        ATHLETE_PROTEIN_MIN_G_PER_KG if athlete else PROTEIN_MIN_G_PER_KG.get(inputs.goal_type)
    )
    reference = protein_reference_weight(inputs.weight_kg, inputs.height_cm)

    # Energy shares in kcal, so "only as much as needed" lands exactly on the 130 g minimum.
    protein_kcal = KCAL_PER_G_PROTEIN * g_per_kg * reference
    fat_kcal = FAT_ENERGY_FRACTION * kcal
    min_carb_kcal = KCAL_PER_G_CARB * MIN_CARB_G
    adjustments: list[str] = []
    if kcal - protein_kcal - fat_kcal < min_carb_kcal:
        fat_kcal = max(kcal - protein_kcal - min_carb_kcal, FAT_MIN_ENERGY_FRACTION * kcal)
        adjustments.append(FAT_LOWERED)
    if kcal - protein_kcal - fat_kcal < min_carb_kcal and min_g_per_kg is not None:
        protein_kcal = max(
            kcal - fat_kcal - min_carb_kcal, KCAL_PER_G_PROTEIN * min_g_per_kg * reference
        )
        adjustments.append(PROTEIN_LOWERED)
    carb_kcal = kcal - protein_kcal - fat_kcal
    carb_minimum_unmet = carb_kcal < min_carb_kcal
    if carb_minimum_unmet:
        adjustments.append(CARB_BELOW_MINIMUM)

    return TargetResult(
        bmr_kcal=round_half_up(bmr, KCAL_PLACES),
        tdee_kcal=round_half_up(tdee, KCAL_PLACES),
        raw_target_kcal=raw_target,
        target_kcal=int(kcal),
        protein_g=round_half_up(protein_kcal / KCAL_PER_G_PROTEIN, GRAM_PLACES),
        fat_g=round_half_up(fat_kcal / KCAL_PER_G_FAT, GRAM_PLACES),
        carb_g=round_half_up(carb_kcal / KCAL_PER_G_CARB, GRAM_PLACES),
        fiber_g=fiber_target_g(kcal),
        effective_weekly_rate_kg=rate,
        adjustment_kcal=adjustment,
        rate_was_capped=rate_capped,
        adjustment_was_capped=adjustment_capped,
        was_floor_applied=raw_target < floor,
        protein_g_per_kg=g_per_kg,
        protein_reference_weight_kg=reference,
        carb_adjustments=tuple(adjustments),
        carb_minimum_unmet=carb_minimum_unmet,
    )


def create_user_target(
    session: Session, user_id: int, reason: TargetReason, now: datetime
) -> UserTarget:
    """Close the current target (valid_to = now) and insert the new current one (§11.11)."""
    if now.tzinfo is None:
        raise ValueError("now must be timezone-aware")
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    local_date = now.astimezone(ZoneInfo(profile.timezone)).date()

    screening = screen_user(session, user_id, local_date)
    if not screening.eligible:
        raise UserNotEligibleError(user_id, screening.reasons)

    weight_kg = session.execute(
        select(WeightLog.weight_kg)
        .where(WeightLog.user_id == user_id)
        .order_by(WeightLog.measured_on.desc())
        .limit(1)
    ).scalar_one_or_none()
    if weight_kg is None:
        raise MissingWeightError(f"user {user_id} has no weight_logs row")

    result = compute_targets(
        TargetInputs(
            sex=Sex(profile.sex),
            age_years=age_in_years(profile.birth_date, local_date),
            height_cm=to_decimal(profile.height_cm),
            weight_kg=to_decimal(weight_kg),
            activity_level=ActivityLevel(profile.activity_level),
            goal_type=GoalType(profile.goal_type),
            weekly_rate_kg=_optional_decimal(profile.weekly_rate_kg),
            target_weight_kg=_optional_decimal(profile.target_weight_kg),
        )
    )
    stored = (result.protein_g, result.fat_g, result.carb_g)
    if min(stored) <= 0:
        raise TargetError(f"user {user_id}: targets_v1 gives a non-positive macro target {stored}")

    current = session.execute(
        select(UserTarget)
        .where(UserTarget.user_id == user_id, UserTarget.valid_to.is_(None))
        .with_for_update()
    ).scalar_one_or_none()
    if current is not None:
        if now <= current.valid_from:
            raise TargetError(
                f"user {user_id}: now ({now.isoformat()}) must be after the current target's "
                f"valid_from ({current.valid_from.isoformat()})"
            )
        current.valid_to = now
        session.flush()

    target = UserTarget(
        user_id=user_id,
        valid_from=now,
        valid_to=None,
        based_on_weight_kg=weight_kg,
        bmr_kcal=float(result.bmr_kcal),
        tdee_kcal=float(result.tdee_kcal),
        target_kcal=float(result.target_kcal),
        target_protein_g=float(result.protein_g),
        target_carb_g=float(result.carb_g),
        target_fat_g=float(result.fat_g),
        formula_version=result.formula_version,
        reason=reason,
        was_floor_applied=result.was_floor_applied,
    )
    session.add(target)
    session.flush()
    if result.carb_minimum_unmet:
        # Logs are not access-controlled like the database: no personal health values here.
        logger.warning(
            "%s: carbohydrate minimum not met (§30.4): user_id=%s goal_type=%s "
            "activity_level=%s carb_g=%s",
            result.formula_version,
            user_id,
            profile.goal_type,
            profile.activity_level,
            result.carb_g,
        )
    return target


def _optional_decimal(value: float | None) -> Decimal | None:
    return None if value is None else to_decimal(value)
