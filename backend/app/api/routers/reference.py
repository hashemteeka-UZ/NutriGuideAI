"""Vocabularies the app needs before sign-in (I.3)."""

from fastapi import APIRouter

from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.reference import Reference

router = APIRouter(tags=["reference"])


@router.get(
    "/reference",
    response_model=Reference,
    responses=PROBLEM_RESPONSES,
    description=(
        "Conditions, allergens, cuisines, and the closed lists for sex, activity, goal, and slot. "
        "Names follow Accept-Language (ar default, en). DIABETES_INSULIN is included with "
        "is_supported false.\n" + error_codes()
    ),
)
def get_reference() -> Reference:
    raise not_implemented()
