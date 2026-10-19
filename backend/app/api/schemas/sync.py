"""Offline batch upload and the change feed (I.7, #138).

CONSUMPTION_CREATE carries the log under `log` because the batch is discriminated on `op`
and the log itself is discriminated on `kind`.
"""

from datetime import date, datetime
from typing import Annotated, Literal, Self
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, model_validator

from app.api.schemas.common import with_example
from app.api.schemas.consumption import (
    CONSUMPTION_LOG_EXAMPLE,
    ConsumptionLogOut,
    FoodLog,
    MealLog,
    PlanItemLog,
    require_one_change,
)
from app.api.schemas.interactions import InteractionCreate
from app.api.schemas.meal_prefs import MEAL_PREF_EXAMPLE, MealPref
from app.api.schemas.plans import DAY_PLAN_EXAMPLE, DayPlanOut
from app.api.schemas.water import WATER_LOG_EXAMPLE, WaterLogOut
from app.api.schemas.weights import WEIGHT_POINT_EXAMPLE, WeightPoint
from app.db.models.user import MealSlot

_OP_ID = "6f1b9c3e-8a2d-4e55-9c1a-2b7d0e4f8a10"
_CLIENT = "11111111-1111-4111-8111-111111111111"


class SyncConsumptionCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["CONSUMPTION_CREATE"]
    op_id: UUID
    log: Annotated[PlanItemLog | MealLog | FoodLog, Field(discriminator="kind")]


class SyncConsumptionCorrect(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["CONSUMPTION_CORRECT"]
    op_id: UUID
    log_id: int
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


class SyncConsumptionDelete(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["CONSUMPTION_DELETE"]
    op_id: UUID
    log_id: int


class SyncWaterCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["WATER_CREATE"]
    op_id: UUID
    client_uuid: UUID
    amount_ml: int = Field(ge=50, le=1000)
    consumed_at: AwareDatetime


class SyncWaterDelete(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["WATER_DELETE"]
    op_id: UUID
    log_id: int


class SyncWeightPut(BaseModel):
    model_config = ConfigDict(extra="forbid")

    op: Literal["WEIGHT_PUT"]
    op_id: UUID
    measured_on: date
    weight_kg: float = Field(ge=20, le=400)
    updated_at: AwareDatetime


class SyncInteractionCreate(InteractionCreate):
    model_config = ConfigDict(extra="forbid")

    op: Literal["INTERACTION_CREATE"]
    op_id: UUID


SyncOperation = Annotated[
    SyncConsumptionCreate
    | SyncConsumptionCorrect
    | SyncConsumptionDelete
    | SyncWaterCreate
    | SyncWaterDelete
    | SyncWeightPut
    | SyncInteractionCreate,
    Field(discriminator="op"),
]

_CONSUMPTION_OP = {
    "op": "CONSUMPTION_CREATE",
    "op_id": _OP_ID,
    "log": {
        "kind": "PLAN_ITEM",
        "client_uuid": _CLIENT,
        "plan_item_id": 5,
        "servings_consumed": 1,
        "consumed_at": "2026-10-20T08:15:00Z",
    },
}


class SyncBatch(BaseModel):
    model_config = ConfigDict(extra="forbid")

    operations: list[SyncOperation] = Field(min_length=1, max_length=500)


class SyncOpResult(BaseModel):
    op_id: UUID
    status: Literal["CREATED", "UPDATED", "DUPLICATE", "REJECTED"]
    code: str | None = None
    entity_id: int | None = None

    model_config = with_example(
        {
            "op_id": _OP_ID,
            "status": "CREATED",
            "code": None,
            "entity_id": 21,
        }
    )


class SyncResult(BaseModel):
    results: list[SyncOpResult]
    server_time: datetime

    model_config = with_example(
        {
            "results": [
                {
                    "op_id": _OP_ID,
                    "status": "CREATED",
                    "code": None,
                    "entity_id": 21,
                }
            ],
            "server_time": "2026-10-20T08:16:00Z",
        }
    )


class SyncChanges(BaseModel):
    server_time: datetime
    consumption_logs: list[ConsumptionLogOut]
    deleted_consumption_log_ids: list[int]
    water_logs: list[WaterLogOut]
    deleted_water_log_ids: list[int]
    weights: list[WeightPoint]
    plans: list[DayPlanOut]
    meal_prefs: list[MealPref]
    profile_changed: bool

    model_config = with_example(
        {
            "server_time": "2026-10-20T08:16:00Z",
            "consumption_logs": [CONSUMPTION_LOG_EXAMPLE],
            "deleted_consumption_log_ids": [],
            "water_logs": [WATER_LOG_EXAMPLE],
            "deleted_water_log_ids": [],
            "weights": [WEIGHT_POINT_EXAMPLE],
            "plans": [DAY_PLAN_EXAMPLE],
            "meal_prefs": [MEAL_PREF_EXAMPLE],
            "profile_changed": False,
        }
    )


SYNC_BATCH_EXAMPLE = {"operations": [_CONSUMPTION_OP]}
