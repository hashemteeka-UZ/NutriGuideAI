"""targets_v1 (§30.2-§30.4b): pure function, exact expected values."""

from __future__ import annotations

import logging
from decimal import Decimal

import pytest

from app.db.models.user import ActivityLevel, GoalType, Sex
from app.services.targets import (
    CARB_BELOW_MINIMUM,
    FAT_LOWERED,
    FORMULA_VERSION,
    PROTEIN_LOWERED,
    TargetInputs,
    TargetValidationError,
    compute_targets,
)

D = Decimal


def inputs(**overrides: object) -> TargetInputs:
    values: dict[str, object] = {
        "sex": Sex.MALE,
        "age_years": 30,
        "height_cm": D(180),
        "weight_kg": D(90),
        "activity_level": ActivityLevel.MODERATE,
        "goal_type": GoalType.MAINTAIN,
        **overrides,
    }
    return TargetInputs(**values)  # type: ignore[arg-type]


def test_case_1_male_lose_moderate() -> None:
    r = compute_targets(
        inputs(goal_type=GoalType.LOSE, weekly_rate_kg=D("0.5"), target_weight_kg=D(80))
    )
    assert (r.bmr_kcal, r.tdee_kcal, r.target_kcal) == (D("1880.0"), D("2914.0"), 2364)
    assert (r.protein_g, r.fat_g, r.carb_g, r.fiber_g) == (D("126.0"), D("78.8"), D("287.7"), 33)
    assert not r.was_floor_applied
    assert not r.rate_was_capped
    assert not r.adjustment_was_capped
    assert r.adjustment_kcal == D(-550)
    assert r.protein_reference_weight_kg == D(90)
    assert r.carb_adjustments == ()
    assert not r.carb_minimum_unmet
    assert r.formula_version == FORMULA_VERSION == "targets_v1"


def test_case_2_female_floor_applied() -> None:
    r = compute_targets(
        inputs(
            sex=Sex.FEMALE,
            age_years=25,
            height_cm=D(155),
            weight_kg=D(50),
            activity_level=ActivityLevel.SEDENTARY,
            goal_type=GoalType.LOSE,
            weekly_rate_kg=D("0.5"),
            target_weight_kg=D(48),
        )
    )
    assert (r.bmr_kcal, r.tdee_kcal) == (D("1182.8"), D("1419.3"))
    assert round(r.raw_target_kcal) == 869
    assert r.was_floor_applied
    assert r.target_kcal == 1200
    assert (r.protein_g, r.fat_g, r.carb_g, r.fiber_g) == (D("70.0"), D("40.0"), D("140.0"), 17)
    assert r.carb_adjustments == ()


def test_case_3_obese_female_capped_and_carb_minimum(caplog: pytest.LogCaptureFixture) -> None:
    with caplog.at_level(logging.WARNING):
        r = compute_targets(
            inputs(
                sex=Sex.FEMALE,
                age_years=40,
                height_cm=D(160),
                weight_kg=D(95),
                activity_level=ActivityLevel.SEDENTARY,
                goal_type=GoalType.LOSE,
                weekly_rate_kg=D("1.0"),
                target_weight_kg=D(70),
            )
        )
    assert (r.bmr_kcal, r.tdee_kcal) == (D("1589.0"), D("1906.8"))
    assert r.rate_was_capped
    assert r.effective_weekly_rate_kg == D("0.95")
    assert r.adjustment_was_capped
    assert r.adjustment_kcal == D(-1000)
    assert r.was_floor_applied
    assert r.target_kcal == 1200
    assert r.protein_reference_weight_kg == D("76.4")
    assert (r.fat_g, r.protein_g, r.carb_g) == (D("33.3"), D("95.0"), D("130.0"))
    assert r.carb_adjustments == (FAT_LOWERED, PROTEIN_LOWERED)
    assert not r.carb_minimum_unmet
    assert caplog.records == []


def test_case_4_athlete_maintain_uses_1_8_g_per_kg() -> None:
    r = compute_targets(inputs(activity_level=ActivityLevel.ATHLETE))
    assert r.protein_g_per_kg == D("1.8")
    assert r.protein_g == D("162.0")
    assert r.adjustment_kcal == 0
    assert r.target_kcal == round(1880 * D("1.9"))


def test_case_4_gain_rate_capped_to_0_5() -> None:
    r = compute_targets(
        inputs(goal_type=GoalType.GAIN, weekly_rate_kg=D("0.8"), target_weight_kg=D(95))
    )
    assert r.rate_was_capped
    assert r.effective_weekly_rate_kg == D("0.5")
    assert r.adjustment_was_capped
    assert r.adjustment_kcal == D(500)
    assert r.target_kcal == 2914 + 500
    assert r.protein_g == D("162.0")


def test_bmi_below_30_uses_actual_weight() -> None:
    r = compute_targets(inputs(weight_kg=D("97.1")))
    assert r.protein_reference_weight_kg == D("97.1")


def test_fat_lowering_alone_can_reach_the_carb_minimum() -> None:
    r = compute_targets(
        inputs(
            sex=Sex.FEMALE,
            age_years=40,
            height_cm=D(160),
            weight_kg=D(60),
            activity_level=ActivityLevel.SEDENTARY,
            goal_type=GoalType.LOSE,
            weekly_rate_kg=D("0.6"),
            target_weight_kg=D(55),
        )
    )
    assert r.target_kcal == 1200
    assert r.carb_adjustments == (FAT_LOWERED,)
    assert (r.protein_g, r.fat_g, r.carb_g) == (D("84.0"), D("38.2"), D("130.0"))


def test_carb_shortfall_after_both_steps_is_kept_and_reported(
    caplog: pytest.LogCaptureFixture,
) -> None:
    with caplog.at_level(logging.DEBUG):
        r = compute_targets(
            inputs(
                sex=Sex.FEMALE,
                age_years=80,
                height_cm=D(150),
                weight_kg=D(120),
                activity_level=ActivityLevel.SEDENTARY,
                goal_type=GoalType.LOSE,
                weekly_rate_kg=D("1.0"),
                target_weight_kg=D(90),
            )
        )
    assert r.target_kcal == 1200
    assert r.protein_reference_weight_kg == D("81.75")
    assert r.carb_adjustments == (FAT_LOWERED, PROTEIN_LOWERED, CARB_BELOW_MINIMUM)
    assert (r.protein_g, r.fat_g, r.carb_g) == (D("98.1"), D("33.3"), D("126.9"))
    assert r.carb_minimum_unmet
    assert caplog.records == []


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        (
            {"goal_type": GoalType.LOSE, "weekly_rate_kg": D("0.5"), "target_weight_kg": D(90)},
            "LOSE",
        ),
        (
            {"goal_type": GoalType.LOSE, "weekly_rate_kg": D("0.5"), "target_weight_kg": D(95)},
            "LOSE",
        ),
        (
            {"goal_type": GoalType.GAIN, "weekly_rate_kg": D("0.5"), "target_weight_kg": D(85)},
            "GAIN",
        ),
        ({"goal_type": GoalType.LOSE, "target_weight_kg": D(80)}, "weekly_rate_kg"),
        ({"goal_type": GoalType.GAIN, "weekly_rate_kg": D("0.5")}, "target_weight_kg"),
    ],
)
def test_validation(overrides: dict[str, object], message: str) -> None:
    with pytest.raises(TargetValidationError, match=message):
        compute_targets(inputs(**overrides))
