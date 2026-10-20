"""What the user ate (I.6). Logging a plan item also writes ACCEPT (#169, #201)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response

from app.api.deps import CurrentUser, DbSession, Lang, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import DEFAULT_RATE_LIMIT, limiter, plan_generation_key
from app.api.schemas.common import NutrientTotals
from app.api.schemas.consumption import (
    ConsumptionCreate,
    ConsumptionLogOut,
    FoodLog,
    LogCorrection,
    MealLog,
    PlanItemLog,
)
from app.db.models.user import MealSlot
from app.services.consumption import LogStatus
from app.services.logging_requests import LoggedConsumption, create_log, logs_of_day
from app.services.logging_requests import correct as correct_stored_log
from app.services.logging_requests import delete as delete_stored_log

router = APIRouter(tags=["consumption"], dependencies=[Depends(get_current_user)])

_LOG_CODES = error_codes(
    "UNAUTHORIZED",
    "PROFILE_NOT_FOUND",
    "PLAN_ITEM_NOT_FOUND",
    "MEAL_NOT_FOUND",
    "FOOD_NOT_FOUND",
    "PLAN_ITEM_ALREADY_LOGGED",
    "CLIENT_UUID_CONFLICT",
    "INCOMPLETE_NUTRITION",
    "CLOCK_SKEW",
    "VALIDATION_ERROR",
)

_WINDOW = (
    "consumed_at may be at most 5 minutes after the server clock (CLOCK_SKEW) "
    "and its local date may not be more than 30 days before the user's local today "
    "(VALIDATION_ERROR). A plan item's local date must equal the item's plan date. "
)


def _out(view: LoggedConsumption) -> ConsumptionLogOut:
    return ConsumptionLogOut(
        log_id=view.log_id,
        kind=view.kind,
        log_date=view.log_date,
        consumed_at=view.consumed_at,
        slot=None if view.slot is None else MealSlot(view.slot),
        plan_item_id=view.plan_item_id,
        meal_id=view.meal_id,
        food_id=view.food_id,
        servings_consumed=view.servings_consumed,
        grams_consumed=view.grams_consumed,
        name=view.name,
        nutrients=NutrientTotals(**view.nutrients),
        status=view.status.value,
    )


def _status(response: Response, status: LogStatus) -> None:
    if status is LogStatus.DUPLICATE:
        response.status_code = 200


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
        "Log a plan item, a catalog meal, or one food from ingredient search. "
        "A composite off-catalog dish is not supported yet. "
        + _WINDOW
        + "201 when created, 200 when the same client_uuid and content were already stored. "
        "The server writes ACCEPT when a plan-item log is created.\n" + _LOG_CODES
    ),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def create_consumption_log(
    request: Request,
    response: Response,
    body: ConsumptionCreate,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
) -> ConsumptionLogOut:
    del request
    if isinstance(body, PlanItemLog):
        view = create_log(
            session,
            user_id,
            kind="PLAN_ITEM",
            client_uuid=body.client_uuid,
            consumed_at=body.consumed_at,
            now=now,
            lang=lang,
            plan_item_id=body.plan_item_id,
            servings_consumed=body.servings_consumed,
        )
    elif isinstance(body, MealLog):
        view = create_log(
            session,
            user_id,
            kind="MEAL",
            client_uuid=body.client_uuid,
            consumed_at=body.consumed_at,
            now=now,
            lang=lang,
            meal_id=body.meal_id,
            servings_consumed=body.servings_consumed,
            slot=None if body.slot is None else body.slot.value,
        )
    else:
        assert isinstance(body, FoodLog)
        view = create_log(
            session,
            user_id,
            kind="FOOD",
            client_uuid=body.client_uuid,
            consumed_at=body.consumed_at,
            now=now,
            lang=lang,
            food_id=body.food_id,
            grams_consumed=body.grams_consumed,
            slot=None if body.slot is None else body.slot.value,
        )
    session.commit()
    _status(response, view.status)
    return _out(view)


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
    session: DbSession,
    user_id: CurrentUser,
    lang: Lang,
) -> list[ConsumptionLogOut]:
    return [_out(view) for view in logs_of_day(session, user_id, log_date, lang)]


@router.post(
    "/consumption-logs/{log_id}/correction",
    status_code=201,
    response_model=ConsumptionLogOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Tombstone the old row and return the new one. At least one measured field must change. "
        "The correction uses a new client_uuid. "
        "If consumed_at is sent, it follows the same 30-day window and clock skew, "
        "and a plan-item log must stay on its plan date. No new ACCEPT is written.\n"
        + error_codes(
            "UNAUTHORIZED",
            "PROFILE_NOT_FOUND",
            "LOG_NOT_FOUND",
            "PLAN_ITEM_NOT_FOUND",
            "CLIENT_UUID_CONFLICT",
            "INCOMPLETE_NUTRITION",
            "CLOCK_SKEW",
            "VALIDATION_ERROR",
        )
    ),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def correct_consumption_log(
    request: Request,
    response: Response,
    log_id: int,
    body: LogCorrection,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
) -> ConsumptionLogOut:
    del request
    view = correct_stored_log(
        session,
        user_id,
        log_id,
        new_client_uuid=body.new_client_uuid,
        now=now,
        lang=lang,
        servings_consumed=body.servings_consumed,
        grams_consumed=body.grams_consumed,
        consumed_at=body.consumed_at,
        slot=None if body.slot is None else body.slot.value,
    )
    session.commit()
    _status(response, view.status)
    return _out(view)


@router.delete(
    "/consumption-logs/{log_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=("Tombstone the log.\n" + error_codes("UNAUTHORIZED", "LOG_NOT_FOUND")),
)
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def delete_consumption_log(
    request: Request,
    log_id: int,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
) -> None:
    del request
    delete_stored_log(session, user_id, log_id, now)
    session.commit()
