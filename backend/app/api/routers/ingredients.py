"""Ingredient search for preferences and for logging one food (#168)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.reference import IngredientPage, IngredientQuery

router = APIRouter(tags=["ingredients"], dependencies=[Depends(get_current_user)])


@router.get(
    "/ingredients",
    response_model=IngredientPage,
    responses=PROBLEM_RESPONSES,
    description=(
        "Search Arabic names, English names, and aliases. "
        "Log the hit's food_id, not a food search.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def search_ingredients(query: Annotated[IngredientQuery, Query()]) -> IngredientPage:
    raise not_implemented()
