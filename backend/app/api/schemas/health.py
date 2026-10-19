from typing import Literal

from pydantic import BaseModel

from app.api.schemas.common import with_example
from app.api.version import API_VERSION


class HealthResponse(BaseModel):
    status: Literal["ok"]
    api_version: str
    database: Literal["ok"]
    dataset_version: str | None
    default_planner: str

    model_config = with_example(
        {
            "status": "ok",
            "api_version": API_VERSION,
            "database": "ok",
            "dataset_version": "catalog_v3",
            "default_planner": "cpsat",
        }
    )
