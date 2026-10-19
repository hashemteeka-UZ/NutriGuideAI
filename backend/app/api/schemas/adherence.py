"""Day and range adherence (§30.5)."""

from datetime import date
from typing import Literal

from pydantic import BaseModel

from app.api.schemas.common import ExceededLimitOut, NutrientTotals, UnmetMinimumOut, with_example

DAY_TOTALS = {
    "kcal": 1800,
    "protein_g": 120,
    "carb_g": 195,
    "fat_g": 60,
    "fiber_g": 22,
    "sodium_mg": 1550,
    "sugars_g": 36,
    "saturated_fat_g": 14,
}

DAY_ADHERENCE_EXAMPLE = {
    "date": "2026-10-20",
    "status": "ACHIEVED",
    "reason": None,
    "target_kcal": 1800,
    "totals": DAY_TOTALS,
    "log_count": 4,
    "exceeded_limits": [],
    "unmet_minimums": [{"nutrient": "fiber", "minimum": 30, "total": 22}],
    "fiber_target_g": 30,
    "plan_items_total": 4,
    "plan_items_consumed": 4,
    "completion": 1,
}


class DayAdherenceOut(BaseModel):
    date: date
    status: Literal["ACHIEVED", "PARTIAL", "NOT_ACHIEVED"] | None = None
    reason: str | None = None
    target_kcal: float | None = None
    totals: NutrientTotals
    log_count: int
    exceeded_limits: list[ExceededLimitOut]
    unmet_minimums: list[UnmetMinimumOut]
    fiber_target_g: int | None = None
    plan_items_total: int
    plan_items_consumed: int
    completion: float | None = None

    model_config = with_example(DAY_ADHERENCE_EXAMPLE)


class AdherenceRangeOut(BaseModel):
    days: list[DayAdherenceOut]
    streak: int

    model_config = with_example({"days": [DAY_ADHERENCE_EXAMPLE], "streak": 4})
