"""Ingredient search for preferences and for logging one food (#168)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import DbSession, Lang, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.reference import IngredientHit, IngredientPage, IngredientQuery
from app.services.ingredient_search import search_ingredients as find_ingredients

router = APIRouter(tags=["ingredients"], dependencies=[Depends(get_current_user)])


@router.get(
    "/ingredients",
    response_model=IngredientPage,
    responses=PROBLEM_RESPONSES,
    description=(
        "Search Arabic names, English names, and aliases. "
        "Ranked by exact match, then prefix, then contains, then similarity. "
        "Rejected ingredients are excluded. "
        "Log the hit's food_id, not a food search.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def search_ingredients(
    session: DbSession, lang: Lang, query: Annotated[IngredientQuery, Query()]
) -> IngredientPage:
    hits, total = find_ingredients(session, query.q, query.limit, query.offset, lang)
    return IngredientPage(
        items=[
            IngredientHit(
                ingredient_id=hit.ingredient_id,
                code=hit.code,
                name=hit.name,
                food_id=hit.food_id,
            )
            for hit in hits
        ],
        total=total,
    )
