"""Per-user meal like and dislike (I.3)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.api.schemas.common import with_example
from app.db.models.user import MealStance

MEAL_PREF_EXAMPLE = {
    "meal_id": 42,
    "stance": "LIKE",
    "updated_at": "2026-10-19T18:30:00Z",
}


class MealPrefUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    stance: MealStance


class MealPref(BaseModel):
    meal_id: int
    stance: MealStance
    updated_at: datetime

    model_config = with_example(MEAL_PREF_EXAMPLE)
