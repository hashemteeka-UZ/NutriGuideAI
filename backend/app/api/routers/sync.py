"""Offline batch and the change feed (I.7, #138, #208 to #211)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request
from pydantic import AwareDatetime

from app.api.deps import CurrentUser, DbSession, Lang, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, SERVICE_ERRORS, error_codes, service_error
from app.api.limiting import SYNC_RATE_LIMIT, limiter, plan_generation_key
from app.api.routers.consumption import _out
from app.api.routers.plans import _plan
from app.api.schemas.consumption import FoodLog, MealLog, PlanItemLog
from app.api.schemas.meal_prefs import MealPref
from app.api.schemas.sync import (
    SyncBatch,
    SyncChanges,
    SyncConsumptionCorrect,
    SyncConsumptionCreate,
    SyncConsumptionDelete,
    SyncInteractionCreate,
    SyncOperation,
    SyncOpResult,
    SyncResult,
    SyncWaterCreate,
    SyncWaterDelete,
    SyncWeightPut,
)
from app.api.schemas.water import WaterLogOut
from app.api.schemas.weights import WeightPoint
from app.db.models.user import MealStance
from app.services.sync_batch import (
    BatchOp,
    ConsumptionCorrectOp,
    ConsumptionCreateOp,
    ConsumptionDeleteOp,
    InteractionCreateOp,
    OpOutcome,
    WaterCreateOp,
    WaterDeleteOp,
    WeightPutOp,
    apply_batch,
)
from app.services.sync_changes import changes_since

router = APIRouter(prefix="/sync", tags=["sync"], dependencies=[Depends(get_current_user)])

_BATCH = (
    "Apply 1 to 500 operations in the order given. Each operation runs in its own savepoint "
    "and the request commits once. A known error sets that operation to REJECTED with its code "
    "and the rest continue. An unexpected error returns 500 and stores nothing; resending the "
    "same batch is safe. A create or a correction whose client id and content are already stored, "
    "and a delete of a log this user already deleted, come back DUPLICATE. A weight with an older "
    "updated_at is DUPLICATE; a weight that replaced the stored value is UPDATED. "
    "server_time is the instant to send as the next since.\n"
    + error_codes("UNAUTHORIZED", "VALIDATION_ERROR", "RATE_LIMITED")
)

_FEED = (
    "since may be at most 5 minutes after the server clock (CLOCK_SKEW) and not more than "
    "30 days before it (VALIDATION_ERROR; the app reloads). Rows are read from since minus "
    "2 minutes. Consumption and water include logs created after that cutoff and ids deleted "
    "after it. Weights are every weight of the last 30 local days, because their updated_at "
    "comes from the phone. meal_prefs is the full current list. plans are the current plan of "
    "each day from local yesterday onward when that plan was created after the cutoff or one "
    "of its items was updated after it, so a swap appears. profile_changed is true when the "
    "profile, health conditions, allergies, ingredient preferences, or a new target changed "
    "after the cutoff. Send server_time back as the next since.\n"
    + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND", "CLOCK_SKEW", "VALIDATION_ERROR")
)


def _operation(op: SyncOperation) -> BatchOp:
    if isinstance(op, SyncConsumptionCreate):
        log = op.log
        plan_item_id = log.plan_item_id if isinstance(log, PlanItemLog) else None
        meal_id = log.meal_id if isinstance(log, MealLog) else None
        food_id = log.food_id if isinstance(log, FoodLog) else None
        servings = None if isinstance(log, FoodLog) else log.servings_consumed
        grams = log.grams_consumed if isinstance(log, FoodLog) else None
        slot = log.slot if isinstance(log, MealLog | FoodLog) else None
        return ConsumptionCreateOp(
            op_id=op.op_id,
            kind=log.kind,
            client_uuid=log.client_uuid,
            consumed_at=log.consumed_at,
            plan_item_id=plan_item_id,
            meal_id=meal_id,
            food_id=food_id,
            servings_consumed=servings,
            grams_consumed=grams,
            slot=None if slot is None else slot.value,
        )
    if isinstance(op, SyncConsumptionCorrect):
        return ConsumptionCorrectOp(
            op_id=op.op_id,
            log_id=op.log_id,
            new_client_uuid=op.new_client_uuid,
            servings_consumed=op.servings_consumed,
            grams_consumed=op.grams_consumed,
            consumed_at=op.consumed_at,
            slot=None if op.slot is None else op.slot.value,
        )
    if isinstance(op, SyncConsumptionDelete):
        return ConsumptionDeleteOp(op.op_id, op.log_id)
    if isinstance(op, SyncWaterCreate):
        return WaterCreateOp(op.op_id, op.client_uuid, op.amount_ml, op.consumed_at)
    if isinstance(op, SyncWaterDelete):
        return WaterDeleteOp(op.op_id, op.log_id)
    if isinstance(op, SyncWeightPut):
        return WeightPutOp(op.op_id, op.measured_on, op.weight_kg, op.updated_at)
    if not isinstance(op, SyncInteractionCreate):
        raise TypeError(f"unknown sync operation {type(op).__name__}")
    return InteractionCreateOp(
        op_id=op.op_id,
        client_uuid=op.client_uuid,
        meal_id=op.meal_id,
        event_type=op.event_type,
        value=op.value,
        plan_item_id=op.plan_item_id,
        screen=op.screen,
    )


def _result(outcome: OpOutcome) -> SyncOpResult:
    code = None
    if outcome.error is not None:
        mapped = service_error(outcome.error)
        code = None if mapped is None else mapped[1]
    return SyncOpResult(
        op_id=outcome.op_id,
        status=outcome.status.value,
        code=code,
        entity_id=outcome.entity_id,
    )


@router.post(
    "/batch",
    response_model=SyncResult,
    responses=PROBLEM_RESPONSES,
    description=_BATCH,
)
@limiter.limit(SYNC_RATE_LIMIT, key_func=plan_generation_key)
def sync_batch(
    request: Request,
    body: SyncBatch,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
) -> SyncResult:
    del request
    outcomes = apply_batch(
        session,
        user_id,
        [_operation(op) for op in body.operations],
        now,
        lang,
        tuple(SERVICE_ERRORS),
    )
    session.commit()
    return SyncResult(results=[_result(outcome) for outcome in outcomes], server_time=now)


@router.get(
    "/changes",
    response_model=SyncChanges,
    responses=PROBLEM_RESPONSES,
    description=_FEED,
)
def get_sync_changes(
    since: Annotated[AwareDatetime, Query()],
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
) -> SyncChanges:
    feed = changes_since(session, user_id, since, now, lang)
    return SyncChanges(
        server_time=now,
        consumption_logs=[_out(view) for view in feed.consumption_logs],
        deleted_consumption_log_ids=feed.deleted_consumption_log_ids,
        water_logs=[
            WaterLogOut(log_id=row.id, amount_ml=row.amount_ml, consumed_at=row.consumed_at)
            for row in feed.water_logs
        ],
        deleted_water_log_ids=feed.deleted_water_log_ids,
        weights=[
            WeightPoint(measured_on=row.measured_on, weight_kg=row.weight_kg)
            for row in feed.weights
        ],
        plans=[_plan(plan) for plan in feed.plans],
        meal_prefs=[
            MealPref(meal_id=row.meal_id, stance=MealStance(row.stance), updated_at=row.updated_at)
            for row in feed.meal_prefs
        ],
        profile_changed=feed.profile_changed,
    )
