"""Active meals (I.4)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.meals import MealDetail, MealListQuery, MealPage

router = APIRouter(tags=["meals"], dependencies=[Depends(get_current_user)])


@router.get(
    "/meals",
    response_model=MealPage,
    responses=PROBLEM_RESPONSES,
    description=(
        "Active meals. Without q, alphabetical. Nutrition is for one serving. "
        "Names and steps follow Accept-Language (ar default, en).\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_meals(query: Annotated[MealListQuery, Query()]) -> MealPage:
    raise not_implemented()


@router.get(
    "/meals/{meal_id}",
    response_model=MealDetail,
    responses=PROBLEM_RESPONSES,
    description=(
        "One meal, including nutrients, ingredients, and steps in the requested language "
        "(Arabic when the meal has no translation). steps is empty when the meal has none.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def get_meal(meal_id: int) -> MealDetail:
    raise not_implemented()
