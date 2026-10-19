"""Consumption logs: a plan item, a catalog meal, or one food (I.6)."""

from datetime import date, datetime
from typing import Annotated, Literal, Self
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, model_validator

from app.api.schemas.common import NutrientTotals, with_example
from app.db.models.user import MealSlot

LOG_NUTRIENTS = {
    "kcal": 310,
    "protein_g": 25,
    "carb_g": 30,
    "fat_g": 10,
    "fiber_g": 6,
    "sodium_mg": 420,
    "sugars_g": 8,
    "saturated_fat_g": 3,
}

CONSUMPTION_LOG_EXAMPLE = {
    "log_id": 21,
    "kind": "PLAN_ITEM",
    "log_date": "2026-10-20",
    "consumed_at": "2026-10-20T08:15:00Z",
    "slot": "BREAKFAST",
    "plan_item_id": 5,
    "meal_id": 42,
    "food_id": None,
    "servings_consumed": 1,
    "grams_consumed": 250,
    "name": "شكشوكة",
    "nutrients": LOG_NUTRIENTS,
    "status": "CREATED",
}


def require_one_change(
    *,
    servings_consumed: float | None,
    grams_consumed: float | None,
    consumed_at: datetime | None,
    slot: MealSlot | None,
) -> None:
    if (
        servings_consumed is None
        and grams_consumed is None
        and consumed_at is None
        and slot is None
    ):
        raise ValueError(
            "at least one of servings_consumed, grams_consumed, consumed_at, slot is required"
        )


class PlanItemLog(BaseModel):
    model_config = ConfigDict(extra="forbid")

    kind: Literal["PLAN_ITEM"]
    client_uuid: UUID
    plan_item_id: int
    servings_consumed: float = Field(gt=0, le=10)
    consumed_at: AwareDatetime


class MealLog(BaseModel):
    model_config = ConfigDict(extra="forbid")

    kind: Literal["MEAL"]
    client_uuid: UUID
    meal_id: int
    servings_consumed: float = Field(gt=0, le=10)
    consumed_at: AwareDatetime
    slot: MealSlot | None = None


class FoodLog(BaseModel):
    model_config = ConfigDict(extra="forbid")

    kind: Literal["FOOD"]
    client_uuid: UUID
    food_id: int
    grams_consumed: float = Field(gt=0, le=3000)
    consumed_at: AwareDatetime
    slot: MealSlot | None = None


ConsumptionCreate = Annotated[PlanItemLog | MealLog | FoodLog, Field(discriminator="kind")]


class ConsumptionLogOut(BaseModel):
    log_id: int
    kind: Literal["PLAN_ITEM", "MEAL", "FOOD"]
    log_date: date
    consumed_at: datetime
    slot: MealSlot | None = None
    plan_item_id: int | None = None
    meal_id: int | None = None
    food_id: int | None = None
    servings_consumed: float | None = None
    grams_consumed: float | None = None
    name: str
    nutrients: NutrientTotals
    status: Literal["CREATED", "DUPLICATE"]

    model_config = with_example(CONSUMPTION_LOG_EXAMPLE)


class LogCorrection(BaseModel):
    model_config = ConfigDict(extra="forbid")

    new_client_uuid: UUID
    servings_consumed: float | None = Field(default=None, gt=0, le=10)
    grams_consumed: float | None = Field(default=None, gt=0, le=3000)
    consumed_at: AwareDatetime | None = None
    slot: MealSlot | None = None

    @model_validator(mode="after")
    def one_change(self) -> Self:
        require_one_change(
            servings_consumed=self.servings_consumed,
            grams_consumed=self.grams_consumed,
            consumed_at=self.consumed_at,
            slot=self.slot,
        )
        return self
