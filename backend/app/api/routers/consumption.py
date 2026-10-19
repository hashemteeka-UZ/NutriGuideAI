"""What the user ate (I.6). Logging a plan item also writes ACCEPT (#169)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.consumption import (
    ConsumptionCreate,
    ConsumptionLogOut,
    LogCorrection,
)

router = APIRouter(tags=["consumption"], dependencies=[Depends(bearer)])

_LOG_CODES = error_codes(
    "UNAUTHORIZED",
    "PLAN_ITEM_NOT_FOUND",
    "MEAL_NOT_FOUND",
    "FOOD_NOT_FOUND",
    "PLAN_ITEM_ALREADY_LOGGED",
    "CLIENT_UUID_CONFLICT",
    "INCOMPLETE_NUTRITION",
    "VALIDATION_ERROR",
)


@router.post(
    "/consumption-logs",
    status_code=201,
    response_model=ConsumptionLogOut,
    responses={
        **PROBLEM_RESPONSES,
        200: {
            "model": ConsumptionLogOut,
            "description": "Same client_uuid and the same content were already stored.",
        },
    },
    description=(
        "Log a plan item, a catalog meal, or one food. "
        "201 when created, 200 when the same client_uuid and content were already stored. "
        "A plan item also writes ACCEPT.\n" + _LOG_CODES
    ),
)
def create_consumption_log(body: ConsumptionCreate) -> ConsumptionLogOut:
    raise not_implemented()


@router.get(
    "/consumption-logs",
    response_model=list[ConsumptionLogOut],
    responses=PROBLEM_RESPONSES,
    description=(
        "Active logs of that local day.\n" + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_consumption_logs(
    log_date: Annotated[date, Query(alias="date")],
) -> list[ConsumptionLogOut]:
    raise not_implemented()


@router.post(
    "/consumption-logs/{log_id}/correction",
    status_code=201,
    response_model=ConsumptionLogOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Tombstone the old row and return the new one. At least one measured field must change.\n"
        + error_codes("UNAUTHORIZED", "LOG_NOT_FOUND", "CLIENT_UUID_CONFLICT", "VALIDATION_ERROR")
    ),
)
def correct_consumption_log(log_id: int, body: LogCorrection) -> ConsumptionLogOut:
    raise not_implemented()


@router.delete(
    "/consumption-logs/{log_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=("Tombstone the log.\n" + error_codes("UNAUTHORIZED", "LOG_NOT_FOUND")),
)
def delete_consumption_log(log_id: int) -> None:
    raise not_implemented()
