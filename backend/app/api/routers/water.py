"""Water for one day (I.6)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.water import WaterDay, WaterLogCreate, WaterLogResult

router = APIRouter(tags=["water"], dependencies=[Depends(bearer)])


@router.get(
    "/water",
    response_model=WaterDay,
    responses=PROBLEM_RESPONSES,
    description=(
        "Total, goal, and logs for one local date.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def get_water_day(day: Annotated[date, Query(alias="date")]) -> WaterDay:
    raise not_implemented()


@router.post(
    "/water-logs",
    status_code=201,
    response_model=WaterLogResult,
    responses={
        **PROBLEM_RESPONSES,
        200: {
            "model": WaterLogResult,
            "description": "Same client_uuid and the same content were already stored.",
        },
    },
    description=(
        "Add a glass. 201 when created, 200 when the same client_uuid "
        "and content were already stored.\n"
        + error_codes("UNAUTHORIZED", "CLIENT_UUID_CONFLICT", "VALIDATION_ERROR")
    ),
)
def create_water_log(body: WaterLogCreate) -> WaterLogResult:
    raise not_implemented()


@router.delete(
    "/water-logs/{log_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=("Remove a water log.\n" + error_codes("UNAUTHORIZED", "LOG_NOT_FOUND")),
)
def delete_water_log(log_id: int) -> None:
    raise not_implemented()
