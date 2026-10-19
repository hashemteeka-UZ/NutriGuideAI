"""Meal summaries, meal detail, and the offline catalog snapshot (I.4, I.7)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.api.schemas.common import Page, with_example
from app.db.models.catalog import DishForm
from app.db.models.reference import NutrientUnit
from app.db.models.user import MealSlot, MealStance


def meal_summary(
    *,
    meal_id: int,
    name: str,
    cuisine: str | None,
    dish_form: str | None,
    serving_grams: float,
    protein_g: float,
    carb_g: float,
    fat_g: float,
    allergens: list[str],
    tags: list[str],
    my_stance: str | None,
) -> dict[str, object]:
    return {
        "meal_id": meal_id,
        "name": name,
        "cuisine": cuisine,
        "dish_form": dish_form,
        "serving_grams": serving_grams,
        "kcal": protein_g * 4 + carb_g * 4 + fat_g * 9,
        "protein_g": protein_g,
        "carb_g": carb_g,
        "fat_g": fat_g,
        "allergens": allergens,
        "tags": tags,
        "my_stance": my_stance,
    }


SHAKSHUKA = meal_summary(
    meal_id=42,
    name="شكشوكة",
    cuisine="LIBYAN",
    dish_form="ONE_DISH",
    serving_grams=250,
    protein_g=25,
    carb_g=30,
    fat_g=10,
    allergens=["EGG"],
    tags=["breakfast_suitable", "vegetarian"],
    my_stance="LIKE",
)
MOLOKHIA = meal_summary(
    meal_id=43,
    name="ملوخية",
    cuisine="LIBYAN",
    dish_form="ONE_DISH",
    serving_grams=380,
    protein_g=30,
    carb_g=50,
    fat_g=20,
    allergens=[],
    tags=["lunch_suitable"],
    my_stance=None,
)
COUSCOUS = meal_summary(
    meal_id=44,
    name="كسكس بالدجاج",
    cuisine="LIBYAN",
    dish_form="PLATE",
    serving_grams=450,
    protein_g=45,
    carb_g=70,
    fat_g=20,
    allergens=["GLUTEN"],
    tags=["dinner_suitable"],
    my_stance=None,
)
LABNEH = meal_summary(
    meal_id=45,
    name="لبنة بالزيت",
    cuisine="LEVANTINE",
    dish_form="ONE_DISH",
    serving_grams=200,
    protein_g=20,
    carb_g=45,
    fat_g=10,
    allergens=["MILK"],
    tags=["snack_suitable"],
    my_stance=None,
)

_SHAKSHUKA_NUTRIENTS = [
    {"code": "energy_kcal", "unit": "kcal", "per_serving": 310, "per_100g": 124},
    {"code": "protein", "unit": "g", "per_serving": 25, "per_100g": 10},
    {"code": "carbohydrate", "unit": "g", "per_serving": 30, "per_100g": 12},
    {"code": "total_fat", "unit": "g", "per_serving": 10, "per_100g": 4},
    {"code": "fiber", "unit": "g", "per_serving": 6, "per_100g": 2.4},
    {"code": "sodium", "unit": "mg", "per_serving": 420, "per_100g": 168},
]

_INGREDIENTS = [
    {"ingredient_id": 18, "name": "طماطم", "grams_per_serving": 120, "is_optional": False},
    {"ingredient_id": 19, "name": "بيض", "grams_per_serving": 100, "is_optional": False},
    {"ingredient_id": 20, "name": "فلفل أحمر", "grams_per_serving": 30, "is_optional": False},
]

_DETAIL_EXTRA = {
    "servings": 2,
    "total_grams": 500,
    "nutrients": _SHAKSHUKA_NUTRIENTS,
    "ingredients": _INGREDIENTS,
    "steps": [
        "سخّن الزيت في المقلاة.",
        "أضف الطماطم واتركها حتى تتكثف.",
        "اكسر البيض واطبخه حتى ينضج.",
    ],
    "source": "NutriGuide catalog",
    "dataset_version": "catalog_v3",
}

MEAL_DETAIL_EXAMPLE = {**SHAKSHUKA, **_DETAIL_EXTRA}
SNAPSHOT_MEAL_EXAMPLE = {
    key: value for key, value in MEAL_DETAIL_EXAMPLE.items() if key != "my_stance"
}


class MealSummary(BaseModel):
    meal_id: int
    name: str
    cuisine: str | None = None
    dish_form: DishForm | None = None
    serving_grams: float
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    allergens: list[str]
    tags: list[str]
    my_stance: MealStance | None = None

    model_config = with_example(SHAKSHUKA)


class NutrientAmount(BaseModel):
    code: str
    unit: NutrientUnit
    per_serving: float | None = None
    per_100g: float | None = None

    model_config = with_example(_SHAKSHUKA_NUTRIENTS[0])


class MealIngredientOut(BaseModel):
    ingredient_id: int
    name: str
    grams_per_serving: float
    is_optional: bool

    model_config = with_example(_INGREDIENTS[0])


class MealDetail(MealSummary):
    servings: int
    total_grams: float
    nutrients: list[NutrientAmount]
    ingredients: list[MealIngredientOut]
    steps: list[str]
    source: str
    dataset_version: str

    model_config = with_example(MEAL_DETAIL_EXAMPLE)


class SnapshotMeal(BaseModel):
    """Meal detail for the offline snapshot. No per-user stance."""

    meal_id: int
    name: str
    cuisine: str | None = None
    dish_form: DishForm | None = None
    serving_grams: float
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    allergens: list[str]
    tags: list[str]
    servings: int
    total_grams: float
    nutrients: list[NutrientAmount]
    ingredients: list[MealIngredientOut]
    steps: list[str]
    source: str
    dataset_version: str

    model_config = with_example(SNAPSHOT_MEAL_EXAMPLE)


class MealPage(Page[MealSummary]):
    model_config = with_example({"items": [SHAKSHUKA, MOLOKHIA], "total": 2})


class CatalogSnapshot(BaseModel):
    dataset_version: str
    generated_at: datetime
    meals: list[SnapshotMeal]

    model_config = with_example(
        {
            "dataset_version": "catalog_v3",
            "generated_at": "2026-10-19T12:00:00Z",
            "meals": [SNAPSHOT_MEAL_EXAMPLE],
        }
    )


class MealListQuery(BaseModel):
    model_config = ConfigDict(extra="forbid")

    q: str | None = Field(default=None, max_length=60)
    slot: MealSlot | None = None
    cuisine: str | None = None
    limit: int = Field(default=20, ge=1, le=50)
    offset: int = Field(default=0, ge=0)
