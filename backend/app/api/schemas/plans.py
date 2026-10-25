"""Day plans, the home day view, swaps, and the shopping list (I.5)."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.api.schemas.adherence import DAY_ADHERENCE_EXAMPLE, DayAdherenceOut
from app.api.schemas.common import ClockTime, NutrientTotals, UnmetMinimumOut, with_example
from app.api.schemas.meals import COUSCOUS, LABNEH, MOLOKHIA, SHAKSHUKA, MealSummary, meal_summary
from app.api.schemas.water import WATER_DAY_EXAMPLE, WaterDay
from app.db.models.user import MealSlot

PLAN_TARGET = {"kcal": 1800, "protein_g": 120, "carb_g": 195, "fat_g": 60, "fiber_g": 30}


def _number(item: dict[str, object], key: str) -> float:
    value = item[key]
    if isinstance(value, bool) or not isinstance(value, int | float):
        raise TypeError(key)
    return float(value)


def _plan_item(
    plan_item_id: int,
    slot: str,
    meal: dict[str, object],
    reason_codes: tuple[str, ...] = ("HIGH_PROTEIN",),
) -> dict[str, object]:
    return {
        "plan_item_id": plan_item_id,
        "slot": slot,
        "meal": meal,
        "servings_multiplier": 1,
        "grams": meal["serving_grams"],
        "kcal": meal["kcal"],
        "protein_g": meal["protein_g"],
        "carb_g": meal["carb_g"],
        "fat_g": meal["fat_g"],
        "reason_codes": list(reason_codes),
        "was_swapped": False,
        "logged": True,
    }


PLAN_ITEMS = [
    _plan_item(5, "BREAKFAST", SHAKSHUKA, ("LEARNED_PREFERENCE", "HIGH_PROTEIN")),
    _plan_item(6, "LUNCH", MOLOKHIA),
    _plan_item(7, "DINNER", COUSCOUS),
    _plan_item(8, "SNACK", LABNEH),
]

_KCAL = sum(_number(item, "kcal") for item in PLAN_ITEMS)
_PROTEIN = sum(_number(item, "protein_g") for item in PLAN_ITEMS)
_CARB = sum(_number(item, "carb_g") for item in PLAN_ITEMS)
_FAT = sum(_number(item, "fat_g") for item in PLAN_ITEMS)
if (_KCAL, _PROTEIN, _CARB, _FAT) != (1800, 120, 195, 60):
    raise RuntimeError("plan item macros do not add up to the day target")

PLAN_TOTALS = {
    "kcal": _KCAL,
    "protein_g": _PROTEIN,
    "carb_g": _CARB,
    "fat_g": _FAT,
    "fiber_g": 22,
    "sodium_mg": 1550,
    "sugars_g": 36,
    "saturated_fat_g": 14,
}

DAY_PLAN_EXAMPLE = {
    "plan_id": 15,
    "date": "2026-10-20",
    "algorithm_version": "cpsat_v2_learned",
    "created_at": "2026-10-19T21:05:00Z",
    "target": PLAN_TARGET,
    "items": PLAN_ITEMS,
    "totals": PLAN_TOTALS,
    "kcal_within_10pct": True,
    "unmet_minimums": [{"nutrient": "fiber", "minimum": 30, "total": 22}],
    "stats": {
        "solver_status": "FEASIBLE",
        "kcal_relaxed": False,
        "solve_seconds": 0.842,
        "candidate_meals": 86,
    },
}

_EGG_TOMATO = meal_summary(
    meal_id=46,
    name="بيض بالطماطم",
    cuisine="LIBYAN",
    dish_form="ONE_DISH",
    serving_grams=230,
    protein_g=22,
    carb_g=28,
    fat_g=8,
    allergens=["EGG"],
    tags=["breakfast_suitable"],
    my_stance=None,
)
ALTERNATIVE_EXAMPLE = {
    "meal": _EGG_TOMATO,
    "servings_multiplier": 1,
    "kcal": _EGG_TOMATO["kcal"],
    "kcal_delta": _number(_EGG_TOMATO, "kcal") - _number(SHAKSHUKA, "kcal"),
}

SHOPPING_LIST_EXAMPLE = {
    "date_from": "2026-10-20",
    "date_to": "2026-10-20",
    "items": [
        {"ingredient_id": 18, "name": "طماطم", "grams": 120, "meals": 1},
        {"ingredient_id": 19, "name": "بيض", "grams": 100, "meals": 1},
    ],
}

DAY_VIEW_EXAMPLE = {
    "date": "2026-10-20",
    "plan": DAY_PLAN_EXAMPLE,
    "meal_windows": [
        {"slot": "BREAKFAST", "start": "07:00", "end": "10:00"},
        {"slot": "LUNCH", "start": "12:00", "end": "15:00"},
        {"slot": "DINNER", "start": "18:00", "end": "21:00"},
        {"slot": "SNACK", "start": "16:00", "end": "17:30"},
    ],
    "adherence": DAY_ADHERENCE_EXAMPLE,
    "water": WATER_DAY_EXAMPLE,
}


class PlanDayRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    date: date


class PlanTargetOut(BaseModel):
    kcal: int
    protein_g: float
    carb_g: float
    fat_g: float
    fiber_g: int

    model_config = with_example(PLAN_TARGET)


class PlanItemOut(BaseModel):
    plan_item_id: int
    slot: MealSlot
    meal: MealSummary
    servings_multiplier: float
    grams: float
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    reason_codes: list[str]
    was_swapped: bool
    logged: bool

    model_config = with_example(PLAN_ITEMS[0])


class PlanStats(BaseModel):
    solver_status: str = Field(
        description="CP-SAT status stored on the plan (OPTIMAL or FEASIBLE)."
    )
    kcal_relaxed: bool = Field(description="True when phase 2 dropped the daily energy band.")
    solve_seconds: float = Field(description="Solver time in seconds, rounded to 3 decimal places.")
    candidate_meals: int = Field(
        description="Distinct meals that passed Layer 1 for at least one position."
    )

    model_config = with_example(DAY_PLAN_EXAMPLE["stats"])


class DayPlanOut(BaseModel):
    plan_id: int
    date: date
    algorithm_version: str
    created_at: datetime
    target: PlanTargetOut
    items: list[PlanItemOut]
    totals: NutrientTotals
    kcal_within_10pct: bool
    unmet_minimums: list[UnmetMinimumOut]
    stats: PlanStats | None = None

    model_config = with_example(DAY_PLAN_EXAMPLE)


class MealWindow(BaseModel):
    slot: MealSlot
    start: ClockTime
    end: ClockTime

    model_config = with_example({"slot": "BREAKFAST", "start": "07:00", "end": "10:00"})


class DayView(BaseModel):
    date: date
    plan: DayPlanOut | None = None
    meal_windows: list[MealWindow]
    adherence: DayAdherenceOut
    water: WaterDay

    model_config = with_example(DAY_VIEW_EXAMPLE)


class Alternative(BaseModel):
    meal: MealSummary
    servings_multiplier: float
    kcal: float
    kcal_delta: float

    model_config = with_example(ALTERNATIVE_EXAMPLE)


class SwapRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    meal_id: int


class ShoppingItem(BaseModel):
    ingredient_id: int
    name: str
    grams: float
    meals: int

    model_config = with_example(SHOPPING_LIST_EXAMPLE["items"][0])


class ShoppingList(BaseModel):
    date_from: date
    date_to: date
    items: list[ShoppingItem]

    model_config = with_example(SHOPPING_LIST_EXAMPLE)
