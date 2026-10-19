"""Meal like and dislike. The server writes PREF_LIKE, PREF_DISLIKE, or PREF_CLEAR (#169)."""

from fastapi import APIRouter, Depends

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.meal_prefs import MealPref, MealPrefUpdate

router = APIRouter(prefix="/me/meal-prefs", tags=["meal-prefs"], dependencies=[Depends(bearer)])


@router.get(
    "",
    response_model=list[MealPref],
    responses=PROBLEM_RESPONSES,
    description=(
        "Stances the user has set. Meals with no row are omitted.\n" + error_codes("UNAUTHORIZED")
    ),
)
def list_meal_prefs() -> list[MealPref]:
    raise not_implemented()


@router.put(
    "/{meal_id}",
    response_model=MealPref,
    responses=PROBLEM_RESPONSES,
    description=(
        "Set LIKE or DISLIKE. Also writes PREF_LIKE or PREF_DISLIKE.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def set_meal_pref(meal_id: int, body: MealPrefUpdate) -> MealPref:
    raise not_implemented()


@router.delete(
    "/{meal_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Clear the stance. Also writes PREF_CLEAR.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def delete_meal_pref(meal_id: int) -> None:
    raise not_implemented()
