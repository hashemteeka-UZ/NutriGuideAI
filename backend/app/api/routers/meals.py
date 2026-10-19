"""Active meals (I.4)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import CurrentUser, DbSession, Lang, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.meals import (
    MealDetail,
    MealIngredientOut,
    MealListQuery,
    MealPage,
    MealSummary,
    NutrientAmount,
)
from app.db.models.catalog import DishForm
from app.db.models.reference import NutrientUnit
from app.db.models.user import MealStance
from app.services.meal_catalog import (
    MealDetailData,
    MealSummaryData,
)
from app.services.meal_catalog import (
    get_meal as read_meal,
)
from app.services.meal_catalog import (
    list_meals as read_meals,
)

router = APIRouter(tags=["meals"], dependencies=[Depends(get_current_user)])


def _summary(data: MealSummaryData) -> MealSummary:
    return MealSummary(
        meal_id=data.meal_id,
        name=data.name,
        cuisine=data.cuisine,
        dish_form=None if data.dish_form is None else DishForm(data.dish_form),
        serving_grams=data.serving_grams,
        kcal=data.kcal,
        protein_g=data.protein_g,
        carb_g=data.carb_g,
        fat_g=data.fat_g,
        allergens=list(data.allergens),
        tags=list(data.tags),
        my_stance=None if data.my_stance is None else MealStance(data.my_stance),
    )


def _detail(data: MealDetailData) -> MealDetail:
    summary = _summary(data.summary)
    return MealDetail(
        meal_id=summary.meal_id,
        name=summary.name,
        cuisine=summary.cuisine,
        dish_form=summary.dish_form,
        serving_grams=summary.serving_grams,
        kcal=summary.kcal,
        protein_g=summary.protein_g,
        carb_g=summary.carb_g,
        fat_g=summary.fat_g,
        allergens=summary.allergens,
        tags=summary.tags,
        my_stance=summary.my_stance,
        servings=data.servings,
        total_grams=data.total_grams,
        nutrients=[
            NutrientAmount(
                code=line.code,
                unit=NutrientUnit(line.unit),
                per_serving=line.per_serving,
                per_100g=line.per_100g,
            )
            for line in data.nutrients
        ],
        ingredients=[
            MealIngredientOut(
                ingredient_id=line.ingredient_id,
                name=line.name,
                grams_per_serving=line.grams_per_serving,
                is_optional=line.is_optional,
            )
            for line in data.ingredients
        ],
        steps=list(data.steps),
        source=data.source,
        dataset_version=data.dataset_version,
    )


@router.get(
    "/meals",
    response_model=MealPage,
    responses=PROBLEM_RESPONSES,
    description=(
        "Active meals for browsing and logging. With q, the meal name and every translation "
        "are ranked like ingredient search: exact, then prefix, then contains, then trigram "
        "similarity; one row per meal. Without q, meals are ordered by the normalized "
        "displayed name, then meal_id. slot keeps meals that carry that slot's occasion tag. "
        "cuisine filters by cuisine code; an unknown code returns an empty page. "
        "Results are not filtered by the caller's health conditions or allergies; each meal "
        "lists its allergen codes so the app can mark them. Names follow Accept-Language "
        "(ar default, en). Nutrition is for one serving.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_meals(
    session: DbSession,
    user_id: CurrentUser,
    lang: Lang,
    query: Annotated[MealListQuery, Query()],
) -> MealPage:
    items, total = read_meals(
        session,
        user_id,
        q=query.q,
        slot=query.slot,
        cuisine=query.cuisine,
        lang=lang,
        limit=query.limit,
        offset=query.offset,
    )
    return MealPage(items=[_summary(item) for item in items], total=total)


@router.get(
    "/meals/{meal_id}",
    response_model=MealDetail,
    responses=PROBLEM_RESPONSES,
    description=(
        "One active meal. The name is the meal name when Accept-Language matches "
        "default_lang, otherwise the translation in that language, otherwise the meal name. "
        "Steps are in the requested language, then Arabic, or an empty list when the meal "
        "has none. kcal is the stored energy_kcal per serving. dataset_version is this "
        "meal's batch id. Not filtered by the caller's health conditions or allergies.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def get_meal(session: DbSession, user_id: CurrentUser, lang: Lang, meal_id: int) -> MealDetail:
    return _detail(read_meal(session, user_id, meal_id, lang))
