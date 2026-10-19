"""Onboarding and profile edits, plus the current target (I.3)."""

from fastapi import APIRouter, Depends

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.profile import ProfileState, ProfileUpdate, TargetsView

router = APIRouter(tags=["profile"], dependencies=[Depends(bearer)])


@router.get(
    "/me/profile",
    response_model=ProfileState,
    responses=PROBLEM_RESPONSES,
    description=(
        "The saved profile, screening, and the current target when one exists.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_profile() -> ProfileState:
    raise not_implemented()


@router.put(
    "/me/profile",
    response_model=ProfileState,
    responses=PROBLEM_RESPONSES,
    description=(
        "Replace the profile. The first save requires current_weight_kg; a later value is stored "
        "as today's weight. An ineligible screening is returned in the body, not as an error.\n"
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
def update_profile(body: ProfileUpdate) -> ProfileState:
    raise not_implemented()


@router.get(
    "/me/targets",
    response_model=TargetsView,
    responses=PROBLEM_RESPONSES,
    description=(
        "Screening, the current calorie target, and the water goal "
        "including reminders_default_off.\n" + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_targets() -> TargetsView:
    raise not_implemented()
