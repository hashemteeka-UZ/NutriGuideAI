"""Weight measurements and the target status they may trigger (I.6)."""

from datetime import date
from typing import Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field

from app.api.schemas.common import with_example

WEIGHT_OUT_EXAMPLE = {
    "measured_on": "2026-10-20",
    "weight_kg": 82.5,
    "status": "UPDATED",
    "target_status": "NOT_TRIGGERED",
    "new_target_id": None,
    "goal_reached": False,
}

WEIGHT_POINT_EXAMPLE = {"measured_on": "2026-10-20", "weight_kg": 82.5}


class WeightUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    weight_kg: float = Field(ge=20, le=400)
    updated_at: AwareDatetime


class WeightOut(BaseModel):
    measured_on: date
    weight_kg: float
    status: Literal["CREATED", "UPDATED", "STALE_IGNORED"]
    target_status: Literal[
        "NOT_TRIGGERED", "NO_CURRENT_TARGET", "CREATED", "INELIGIBLE", "GOAL_INVALID"
    ]
    new_target_id: int | None = None
    goal_reached: bool

    model_config = with_example(WEIGHT_OUT_EXAMPLE)


class WeightPoint(BaseModel):
    measured_on: date
    weight_kg: float

    model_config = with_example(WEIGHT_POINT_EXAMPLE)
