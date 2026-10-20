"""Adherence over a date range (I.6, #206, §30.5)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import CurrentUser, DbSession, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.routers.plans import day_adherence_out
from app.api.schemas.adherence import AdherenceRangeOut
from app.api.schemas.common import HistoryDateRange
from app.services.adherence import adherence_range

router = APIRouter(tags=["adherence"], dependencies=[Depends(get_current_user)])


@router.get(
    "/adherence",
    response_model=AdherenceRangeOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "One row per day in the inclusive range, plus the streak of consecutive ACHIEVED days "
        "ending on the last day. Maximum 92 days; a longer range is VALIDATION_ERROR.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND", "VALIDATION_ERROR")
    ),
)
def get_adherence(
    span: Annotated[HistoryDateRange, Query()],
    session: DbSession,
    user_id: CurrentUser,
) -> AdherenceRangeOut:
    result = adherence_range(session, user_id, span.date_from, span.date_to)
    return AdherenceRangeOut(
        days=[day_adherence_out(day) for day in result.days],
        streak=result.streak,
    )
