"""Water day and water logs (I.6)."""

from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field

from app.api.schemas.common import with_example
from app.api.schemas.profile import WATER_GOAL_EXAMPLE, WaterGoal

WATER_LOG_EXAMPLE = {
    "log_id": 3,
    "amount_ml": 250,
    "consumed_at": "2026-10-20T09:00:00Z",
}

WATER_DAY_EXAMPLE = {
    "date": "2026-10-20",
    "total_ml": 750,
    "goal": WATER_GOAL_EXAMPLE,
    "logs": [
        WATER_LOG_EXAMPLE,
        {"log_id": 4, "amount_ml": 500, "consumed_at": "2026-10-20T13:00:00Z"},
    ],
}


class WaterLogCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    client_uuid: UUID
    amount_ml: int = Field(ge=50, le=1000)
    consumed_at: AwareDatetime


class WaterLogOut(BaseModel):
    log_id: int
    amount_ml: int
    consumed_at: datetime

    model_config = with_example(WATER_LOG_EXAMPLE)


class WaterLogResult(WaterLogOut):
    """POST /water-logs adds status. GET logs stay WaterLogOut."""

    status: Literal["CREATED", "DUPLICATE"]

    model_config = with_example({**WATER_LOG_EXAMPLE, "status": "CREATED"})


class WaterDay(BaseModel):
    date: date
    total_ml: int
    goal: WaterGoal
    logs: list[WaterLogOut]

    model_config = with_example(WATER_DAY_EXAMPLE)
