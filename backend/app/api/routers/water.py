"""Water for one day (I.6, #204)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response

from app.api.deps import CurrentUser, DbSession, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import DEFAULT_RATE_LIMIT, limiter, plan_generation_key
from app.api.schemas.profile import WaterGoal
from app.api.schemas.water import WaterDay, WaterLogCreate, WaterLogOut, WaterLogResult
from app.services.water import WaterStatus, delete_water, log_water, water_day

router = APIRouter(tags=["water"], dependencies=[Depends(get_current_user)])


@router.get(
    "/water",
    response_model=WaterDay,
    responses=PROBLEM_RESPONSES,
    description=(
        "Total, goal, and active logs for one local date.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND", "VALIDATION_ERROR")
    ),
)
def get_water_day(
    day: Annotated[date, Query(alias="date")],
    session: DbSession,
    user_id: CurrentUser,
) -> WaterDay:
    total_ml, goal, logs = water_day(session, user_id, day)
    return WaterDay(
        date=day,
        total_ml=total_ml,
        goal=WaterGoal(
            goal_ml=goal.goal_ml,
            source=goal.source,
            requires_clinician=goal.requires_clinician,
            reminders_default_off=goal.reminders_default_off,
        ),
        logs=[
            WaterLogOut(log_id=log.id, amount_ml=log.amount_ml, consumed_at=log.consumed_at)
            for log in logs
        ],
    )


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
        "Add a glass. consumed_at may be at most 5 minutes after the server clock (CLOCK_SKEW) "
        "and its local date may not be more than 30 days before the user's local today "
        "(VALIDATION_ERROR). "
        "201 when created, 200 when the same client_uuid and content were already stored.\n"
        + error_codes(
            "UNAUTHORIZED",
            "PROFILE_NOT_FOUND",
            "CLIENT_UUID_CONFLICT",
            "CLOCK_SKEW",
            "VALIDATION_ERROR",
        )
    ),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def create_water_log(
    request: Request,
    response: Response,
    body: WaterLogCreate,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
) -> WaterLogResult:
    del request
    row, status = log_water(
        session, user_id, body.amount_ml, body.consumed_at, body.client_uuid, now
    )
    session.commit()
    if status is WaterStatus.DUPLICATE:
        response.status_code = 200
    return WaterLogResult(
        log_id=row.id,
        amount_ml=row.amount_ml,
        consumed_at=row.consumed_at,
        status=status.value,
    )


@router.delete(
    "/water-logs/{log_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=("Remove a water log.\n" + error_codes("UNAUTHORIZED", "LOG_NOT_FOUND")),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def delete_water_log(
    request: Request,
    log_id: int,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
) -> None:
    del request
    delete_water(session, user_id, log_id, now)
    session.commit()
