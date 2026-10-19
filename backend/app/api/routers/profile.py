"""Onboarding and profile edits, plus the current target (I.3)."""

from decimal import Decimal

from fastapi import APIRouter, Depends

from app.api.deps import CurrentUser, DbSession, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.profile import (
    AllergenChoice,
    ConditionChoice,
    IngredientChoice,
    Profile,
    ProfileState,
    ProfileUpdate,
    Screening,
    Target,
    TargetsView,
    WaterGoal,
)
from app.db.models import UserTarget
from app.db.models.user import (
    ActivityLevel,
    AllergenSeverity,
    ConditionSeverity,
    GoalType,
    IngredientStance,
    Sex,
    TargetReason,
)
from app.services.common import round_half_up, to_decimal
from app.services.profile import (
    AllergenInput,
    ConditionInput,
    IngredientInput,
    ProfileInput,
    ProfileOutcome,
    TargetsOutcome,
    load_profile,
    load_targets,
    save_profile,
)
from app.services.targets import fiber_target_g

router = APIRouter(tags=["profile"], dependencies=[Depends(get_current_user)])


def _amount(value: float | Decimal) -> float:
    return float(round_half_up(to_decimal(value), 3))


def _optional_amount(value: float | Decimal | None) -> float | None:
    return None if value is None else _amount(value)


def _input(body: ProfileUpdate) -> ProfileInput:
    return ProfileInput(
        sex=body.sex.value,
        birth_date=body.birth_date,
        height_cm=body.height_cm,
        activity_level=body.activity_level.value,
        goal_type=body.goal_type.value,
        target_weight_kg=body.target_weight_kg,
        weekly_rate_kg=body.weekly_rate_kg,
        timezone=body.timezone,
        wake_time=body.wake_time,
        sleep_time=body.sleep_time,
        water_goal_ml=body.water_goal_ml,
        current_weight_kg=body.current_weight_kg,
        conditions=tuple(
            ConditionInput(
                code=choice.code,
                severity=None if choice.severity is None else choice.severity.value,
            )
            for choice in body.conditions
        ),
        allergens=tuple(
            AllergenInput(code=choice.code, severity=choice.severity.value)
            for choice in body.allergens
        ),
        ingredient_prefs=tuple(
            IngredientInput(ingredient_id=choice.ingredient_id, stance=choice.stance.value)
            for choice in body.ingredient_prefs
        ),
        cuisines=tuple(body.cuisines),
    )


def _target(target: UserTarget | None) -> Target | None:
    if target is None:
        return None
    kcal = to_decimal(target.target_kcal)
    return Target(
        target_id=target.target_id,
        valid_from=target.valid_from,
        reason=TargetReason(target.reason),
        formula_version=target.formula_version,
        based_on_weight_kg=_amount(target.based_on_weight_kg),
        bmr_kcal=_amount(target.bmr_kcal),
        tdee_kcal=_amount(target.tdee_kcal),
        kcal=int(round_half_up(kcal, 0)),
        protein_g=_amount(target.target_protein_g),
        carb_g=_amount(target.target_carb_g),
        fat_g=_amount(target.target_fat_g),
        fiber_g=fiber_target_g(kcal),
        was_floor_applied=target.was_floor_applied,
    )


def _profile(outcome: ProfileOutcome) -> Profile:
    profile = outcome.profile
    latest_kg = None if outcome.latest_weight is None else outcome.latest_weight[1]
    latest_on = None if outcome.latest_weight is None else outcome.latest_weight[0]
    return Profile(
        sex=Sex(profile.sex),
        birth_date=profile.birth_date,
        height_cm=_amount(profile.height_cm),
        activity_level=ActivityLevel(profile.activity_level),
        goal_type=GoalType(profile.goal_type),
        target_weight_kg=_optional_amount(profile.target_weight_kg),
        weekly_rate_kg=_optional_amount(profile.weekly_rate_kg),
        timezone=profile.timezone,
        wake_time=profile.wake_time,
        sleep_time=profile.sleep_time,
        water_goal_ml=profile.water_goal_ml,
        latest_weight_kg=_optional_amount(latest_kg),
        latest_weight_on=latest_on,
        conditions=[
            ConditionChoice(
                code=item.code,
                severity=None if item.severity is None else ConditionSeverity(item.severity),
            )
            for item in outcome.conditions
        ],
        allergens=[
            AllergenChoice(code=item.code, severity=AllergenSeverity(item.severity))
            for item in outcome.allergens
        ],
        ingredient_prefs=[
            IngredientChoice(ingredient_id=item.ingredient_id, stance=IngredientStance(item.stance))
            for item in outcome.ingredient_prefs
        ],
        cuisines=list(outcome.cuisines),
    )


def _state(outcome: ProfileOutcome) -> ProfileState:
    return ProfileState(
        profile=_profile(outcome),
        screening=Screening(eligible=outcome.screening.eligible, reasons=outcome.screening.reasons),
        target=_target(outcome.target),
    )


@router.get(
    "/me/profile",
    response_model=ProfileState,
    responses=PROBLEM_RESPONSES,
    description=(
        "The saved profile, screening, and the current target when one exists.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_profile(user_id: CurrentUser, session: DbSession, now: Now) -> ProfileState:
    return _state(load_profile(session, user_id, now))


@router.put(
    "/me/profile",
    response_model=ProfileState,
    responses=PROBLEM_RESPONSES,
    description=(
        "Replace the profile. The first save requires current_weight_kg; a later value is stored "
        "as today's weight. At most one target is created per save. An ineligible screening is "
        "returned in the body, not as an error, and closes the current target.\n"
        + error_codes(
            "UNAUTHORIZED",
            "VALIDATION_ERROR",
            "UNKNOWN_CODE",
            "NO_WEIGHT",
            "TARGET_VALIDATION",
            "INVALID_TIMEZONE",
        )
    ),
)
def update_profile(
    body: ProfileUpdate, user_id: CurrentUser, session: DbSession, now: Now
) -> ProfileState:
    outcome = save_profile(session, user_id, _input(body), now)
    state = _state(outcome)
    session.commit()
    return state


@router.get(
    "/me/targets",
    response_model=TargetsView,
    responses=PROBLEM_RESPONSES,
    description=(
        "Screening, the current calorie target, and the water goal "
        "including reminders_default_off.\n" + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_targets(user_id: CurrentUser, session: DbSession, now: Now) -> TargetsView:
    view: TargetsOutcome = load_targets(session, user_id, now)
    return TargetsView(
        screening=Screening(eligible=view.screening.eligible, reasons=view.screening.reasons),
        target=_target(view.target),
        water=WaterGoal(
            goal_ml=view.water.goal_ml,
            source=view.water.source,
            requires_clinician=view.water.requires_clinician,
            reminders_default_off=view.water.reminders_default_off,
        ),
    )
