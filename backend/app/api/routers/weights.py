"""Weight log and the target it may replace (I.6)."""

import logging
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request

from app.api.deps import CurrentUser, DbSession, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import DEFAULT_RATE_LIMIT, limiter, plan_generation_key
from app.api.schemas.common import HistoryDateRange
from app.api.schemas.weights import WeightOut, WeightPoint, WeightUpdate
from app.services.weight import record_weight, weights_between

logger = logging.getLogger("nutriguide.api")

router = APIRouter(tags=["weights"], dependencies=[Depends(get_current_user)])


@router.put(
    "/weights/{measured_on}",
    response_model=WeightOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Create or replace the weight of that local date. "
        "STALE_IGNORED keeps the stored row when updated_at is older. "
        "A new target created by the weight is stored in the same transaction.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND", "CLOCK_SKEW", "VALIDATION_ERROR")
    ),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def put_weight(
    request: Request,
    measured_on: date,
    body: WeightUpdate,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
) -> WeightOut:
    del request
    result = record_weight(session, user_id, measured_on, body.weight_kg, body.updated_at, now)
    session.commit()
    logger.info(
        "weight write user_id=%s kind=%s status=%s",
        user_id,
        "WEIGHT",
        result.status.value,
    )
    return WeightOut(
        measured_on=result.weight_log.measured_on,
        weight_kg=result.weight_log.weight_kg,
        status=result.status.value,
        target_status=result.target_status.value,
        new_target_id=result.new_target_id,
        goal_reached=result.goal_reached,
    )


@router.get(
    "/weights",
    response_model=list[WeightPoint],
    responses=PROBLEM_RESPONSES,
    description=(
        "Weights in the inclusive range, ordered by date. Maximum 92 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_weights(
    span: Annotated[HistoryDateRange, Query()],
    session: DbSession,
    user_id: CurrentUser,
) -> list[WeightPoint]:
    rows = weights_between(session, user_id, span.date_from, span.date_to)
    return [WeightPoint(measured_on=row.measured_on, weight_kg=row.weight_kg) for row in rows]
