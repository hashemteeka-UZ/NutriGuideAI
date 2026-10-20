"""Client learning events (#169, #205). ACCEPT, SWAP_OUT, and PREF_* stay server-written."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Final
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Meal, MealPlan, MealPlanItem, UserInteraction
from app.db.models.user import InteractionEventType
from app.services.common import InputRejectedError, MealNotFoundError
from app.services.consumption import ClientUuidConflictError, LogStatus, PlanItemNotFoundError

logger = logging.getLogger("nutriguide.api")

CLIENT_EVENT_TYPES: Final = frozenset(
    {
        InteractionEventType.IMPRESSION.value,
        InteractionEventType.VIEW.value,
        InteractionEventType.SAVE.value,
        InteractionEventType.RATE.value,
        InteractionEventType.COOK.value,
        InteractionEventType.SKIP.value,
    }
)


def _event(event_type: str) -> str:
    if event_type not in CLIENT_EVENT_TYPES:
        raise InputRejectedError(f"event_type {event_type!r} is not a client event")
    return event_type


def _active_meal(session: Session, meal_id: int) -> None:
    active = session.execute(
        select(Meal.meal_id).where(Meal.meal_id == meal_id, Meal.is_active.is_(True))
    ).scalar_one_or_none()
    if active is None:
        raise MealNotFoundError(f"meal {meal_id} is not an active meal")


def _context(
    session: Session,
    user_id: int,
    meal_id: int,
    plan_item_id: int | None,
    screen: str | None,
) -> dict[str, object]:
    context: dict[str, object] = {}
    if screen is not None:
        context["screen"] = screen
    if plan_item_id is None:
        return context
    found = session.execute(
        select(MealPlanItem, MealPlan)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlanItem.id == plan_item_id, MealPlan.user_id == user_id)
    ).one_or_none()
    if found is None:
        raise PlanItemNotFoundError(f"plan item {plan_item_id} is not in a plan of user {user_id}")
    item, plan = found
    if item.meal_id != meal_id:
        raise InputRejectedError(f"plan item {plan_item_id} meal does not match meal_id {meal_id}")
    context["plan_id"] = plan.plan_id
    context["plan_item_id"] = item.id
    context["slot"] = item.slot
    context["algorithm_version"] = plan.algorithm_version
    return context


def record_interaction(
    session: Session,
    user_id: int,
    client_uuid: UUID,
    meal_id: int,
    event_type: str,
    value: int | None,
    plan_item_id: int | None,
    screen: str | None,
    now: datetime,
) -> tuple[UserInteraction, LogStatus]:
    """Store one client event. The same client_uuid and content is a DUPLICATE."""
    kind = _event(event_type)
    if kind == InteractionEventType.RATE.value and value is None:
        raise InputRejectedError("value is required when event_type is RATE")
    _active_meal(session, meal_id)
    context = _context(session, user_id, meal_id, plan_item_id, screen)
    existing = session.execute(
        select(UserInteraction).where(UserInteraction.client_uuid == client_uuid)
    ).scalar_one_or_none()
    if existing is not None:
        same = (
            existing.user_id == user_id
            and existing.meal_id == meal_id
            and existing.event_type == kind
            and existing.value == value
            and existing.context == context
        )
        if not same:
            raise ClientUuidConflictError(
                f"client_uuid {client_uuid} already belongs to interaction {existing.id} "
                "with other content"
            )
        logger.info(
            "interaction write user_id=%s kind=%s status=%s",
            user_id,
            kind,
            LogStatus.DUPLICATE.value,
        )
        return existing, LogStatus.DUPLICATE
    row = UserInteraction(
        user_id=user_id,
        meal_id=meal_id,
        event_type=kind,
        value=value,
        context=context,
        client_uuid=client_uuid,
        created_at=now,
    )
    session.add(row)
    session.flush()
    logger.info(
        "interaction write user_id=%s kind=%s status=%s",
        user_id,
        kind,
        LogStatus.CREATED.value,
    )
    return row, LogStatus.CREATED
