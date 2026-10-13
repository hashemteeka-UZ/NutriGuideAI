from typing import Literal

from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: Literal["ok"]
    api_version: str
    database: Literal["ok"]
    dataset_version: str | None
    default_planner: str
