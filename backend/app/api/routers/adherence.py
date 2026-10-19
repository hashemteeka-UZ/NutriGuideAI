"""Adherence over a date range (I.6, §30.5)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.adherence import AdherenceRangeOut
from app.api.schemas.common import HistoryDateRange

router = APIRouter(tags=["adherence"], dependencies=[Depends(bearer)])


@router.get(
    "/adherence",
    response_model=AdherenceRangeOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "One row per day in the inclusive range, plus the streak of ACHIEVED days. "
        "Maximum 92 days.\n" + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def get_adherence(span: Annotated[HistoryDateRange, Query()]) -> AdherenceRangeOut:
    raise not_implemented()
