"""Weight log and the target it may replace (I.6)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.common import HistoryDateRange
from app.api.schemas.weights import WeightOut, WeightPoint, WeightUpdate

router = APIRouter(tags=["weights"], dependencies=[Depends(bearer)])


@router.put(
    "/weights/{measured_on}",
    response_model=WeightOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Create or replace the weight of that local date. "
        "STALE_IGNORED keeps the stored row when updated_at is older.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND", "CLOCK_SKEW", "VALIDATION_ERROR")
    ),
)
def put_weight(measured_on: date, body: WeightUpdate) -> WeightOut:
    raise not_implemented()


@router.get(
    "/weights",
    response_model=list[WeightPoint],
    responses=PROBLEM_RESPONSES,
    description=(
        "Weights in the inclusive range. Maximum 92 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_weights(span: Annotated[HistoryDateRange, Query()]) -> list[WeightPoint]:
    raise not_implemented()
