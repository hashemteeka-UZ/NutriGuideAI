"""Apply one offline batch through the same functions the single routes use (#208, #209)."""

from __future__ import annotations

import logging
import time
from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime
from enum import StrEnum
from uuid import UUID

from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, WaterLog
from app.services.consumption import LogStatus
from app.services.interactions import record_interaction
from app.services.logging_requests import LogKind, create_log
from app.services.logging_requests import correct as correct_log
from app.services.logging_requests import delete as delete_log
from app.services.water import WaterStatus, delete_water, log_water
from app.services.weight import WeightStatus, record_weight

logger = logging.getLogger("nutriguide.api")


class OpStatus(StrEnum):
    CREATED = "CREATED"
    UPDATED = "UPDATED"
    DUPLICATE = "DUPLICATE"
    REJECTED = "REJECTED"


@dataclass(frozen=True)
class ConsumptionCreateOp:
    op_id: UUID
    kind: LogKind
    client_uuid: UUID
    consumed_at: datetime
    plan_item_id: int | None = None
    meal_id: int | None = None
    food_id: int | None = None
    servings_consumed: float | None = None
    grams_consumed: float | None = None
    slot: str | None = None


@dataclass(frozen=True)
class ConsumptionCorrectOp:
    op_id: UUID
    log_id: int
    new_client_uuid: UUID
    servings_consumed: float | None = None
    grams_consumed: float | None = None
    consumed_at: datetime | None = None
    slot: str | None = None


@dataclass(frozen=True)
class ConsumptionDeleteOp:
    op_id: UUID
    log_id: int


@dataclass(frozen=True)
class WaterCreateOp:
    op_id: UUID
    client_uuid: UUID
    amount_ml: int
    consumed_at: datetime


@dataclass(frozen=True)
class WaterDeleteOp:
    op_id: UUID
    log_id: int


@dataclass(frozen=True)
class WeightPutOp:
    op_id: UUID
    measured_on: date
    weight_kg: float
    updated_at: datetime


@dataclass(frozen=True)
class InteractionCreateOp:
    op_id: UUID
    client_uuid: UUID
    meal_id: int
    event_type: str
    value: int | None
    plan_item_id: int | None
    screen: str | None


BatchOp = (
    ConsumptionCreateOp
    | ConsumptionCorrectOp
    | ConsumptionDeleteOp
    | WaterCreateOp
    | WaterDeleteOp
    | WeightPutOp
    | InteractionCreateOp
)


@dataclass
class OpOutcome:
    op_id: UUID
    status: OpStatus
    entity_id: int | None
    error: Exception | None = None


def _done(op_id: UUID, status: OpStatus, entity_id: int | None = None) -> OpOutcome:
    return OpOutcome(op_id, status, entity_id, None)


def _log_status(status: LogStatus) -> OpStatus:
    if status is LogStatus.DUPLICATE:
        return OpStatus.DUPLICATE
    return OpStatus.CREATED


def _water_status(status: WaterStatus) -> OpStatus:
    if status is WaterStatus.DUPLICATE:
        return OpStatus.DUPLICATE
    return OpStatus.CREATED


def _weight_status(status: WeightStatus) -> OpStatus:
    if status is WeightStatus.STALE_IGNORED:
        return OpStatus.DUPLICATE
    if status is WeightStatus.UPDATED:
        return OpStatus.UPDATED
    return OpStatus.CREATED


def _own_tombstone(row: ConsumptionLog | WaterLog | None, user_id: int) -> bool:
    return row is not None and row.user_id == user_id and row.deleted_at is not None


def _apply(
    session: Session, user_id: int, operation: BatchOp, now: datetime, lang: str
) -> OpOutcome:
    if isinstance(operation, ConsumptionCreateOp):
        view = create_log(
            session,
            user_id,
            kind=operation.kind,
            client_uuid=operation.client_uuid,
            consumed_at=operation.consumed_at,
            now=now,
            lang=lang,
            plan_item_id=operation.plan_item_id,
            meal_id=operation.meal_id,
            food_id=operation.food_id,
            servings_consumed=operation.servings_consumed,
            grams_consumed=operation.grams_consumed,
            slot=operation.slot,
        )
        return _done(operation.op_id, _log_status(view.status), view.log_id)
    if isinstance(operation, ConsumptionCorrectOp):
        view = correct_log(
            session,
            user_id,
            operation.log_id,
            new_client_uuid=operation.new_client_uuid,
            now=now,
            lang=lang,
            servings_consumed=operation.servings_consumed,
            grams_consumed=operation.grams_consumed,
            consumed_at=operation.consumed_at,
            slot=operation.slot,
        )
        return _done(operation.op_id, _log_status(view.status), view.log_id)
    if isinstance(operation, ConsumptionDeleteOp):
        meal_row = session.get(ConsumptionLog, operation.log_id)
        if _own_tombstone(meal_row, user_id):
            assert meal_row is not None
            return _done(operation.op_id, OpStatus.DUPLICATE, meal_row.id)
        delete_log(session, user_id, operation.log_id, now)
        return _done(operation.op_id, OpStatus.UPDATED, operation.log_id)
    if isinstance(operation, WaterCreateOp):
        row, water_status = log_water(
            session,
            user_id,
            operation.amount_ml,
            operation.consumed_at,
            operation.client_uuid,
            now,
        )
        return _done(operation.op_id, _water_status(water_status), row.id)
    if isinstance(operation, WaterDeleteOp):
        water_row = session.get(WaterLog, operation.log_id)
        if _own_tombstone(water_row, user_id):
            assert water_row is not None
            return _done(operation.op_id, OpStatus.DUPLICATE, water_row.id)
        delete_water(session, user_id, operation.log_id, now)
        return _done(operation.op_id, OpStatus.UPDATED, operation.log_id)
    if isinstance(operation, WeightPutOp):
        result = record_weight(
            session,
            user_id,
            operation.measured_on,
            operation.weight_kg,
            operation.updated_at,
            now,
        )
        return _done(operation.op_id, _weight_status(result.status), None)
    if not isinstance(operation, InteractionCreateOp):
        raise TypeError(f"unknown sync operation {type(operation).__name__}")
    saved, interaction_status = record_interaction(
        session,
        user_id,
        operation.client_uuid,
        operation.meal_id,
        operation.event_type,
        operation.value,
        operation.plan_item_id,
        operation.screen,
        now,
    )
    return _done(operation.op_id, _log_status(interaction_status), saved.id)


def apply_batch(
    session: Session,
    user_id: int,
    operations: list[BatchOp],
    now: datetime,
    lang: str,
    known: tuple[type[BaseException], ...],
) -> list[OpOutcome]:
    """Run each operation in its own savepoint. An unknown error aborts the batch."""
    started = time.perf_counter()
    outcomes: list[OpOutcome] = []
    for operation in operations:
        try:
            with session.begin_nested():
                outcome = _apply(session, user_id, operation, now, lang)
        except Exception as exc:
            if not isinstance(exc, known):
                raise
            outcome = OpOutcome(operation.op_id, OpStatus.REJECTED, None, exc)
        outcomes.append(outcome)
    counts = Counter(outcome.status.value for outcome in outcomes)
    logger.info(
        "sync batch user_id=%s operations=%s created=%s updated=%s duplicate=%s rejected=%s "
        "seconds=%.4f",
        user_id,
        len(operations),
        counts["CREATED"],
        counts["UPDATED"],
        counts["DUPLICATE"],
        counts["REJECTED"],
        time.perf_counter() - started,
    )
    return outcomes
