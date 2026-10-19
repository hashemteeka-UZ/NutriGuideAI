"""Meal like and dislike, with a learning event only when the stance changes (#182)."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Meal, UserInteraction, UserMealPref
from app.db.models.user import InteractionEventType, MealStance
from app.services.common import MealNotFoundError

_EVENT_FOR_STANCE = {
    MealStance.LIKE.value: InteractionEventType.PREF_LIKE.value,
    MealStance.DISLIKE.value: InteractionEventType.PREF_DISLIKE.value,
}
_PREF_CONTEXT = {"source": "meal_prefs"}


def _active_meal(session: Session, meal_id: int) -> None:
    active = session.execute(
        select(Meal.meal_id).where(Meal.meal_id == meal_id, Meal.is_active.is_(True))
    ).scalar_one_or_none()
    if active is None:
        raise MealNotFoundError(f"no active meal with meal_id {meal_id}")


def _event(session: Session, user_id: int, meal_id: int, event_type: str, now: datetime) -> None:
    session.add(
        UserInteraction(
            user_id=user_id,
            meal_id=meal_id,
            event_type=event_type,
            context=dict(_PREF_CONTEXT),
            created_at=now,
        )
    )


def list_meal_prefs(session: Session, user_id: int) -> list[UserMealPref]:
    """The user's rows, newest updated_at first."""
    return list(
        session.scalars(
            select(UserMealPref)
            .where(UserMealPref.user_id == user_id)
            .order_by(UserMealPref.updated_at.desc(), UserMealPref.meal_id)
        ).all()
    )


def set_meal_pref(
    session: Session, user_id: int, meal_id: int, stance: MealStance | str, now: datetime
) -> UserMealPref:
    """Upsert the stance. Write PREF_LIKE or PREF_DISLIKE only when it is new or changed."""
    _active_meal(session, meal_id)
    value = stance.value if isinstance(stance, MealStance) else stance
    row = session.get(UserMealPref, (user_id, meal_id))
    if row is None:
        row = UserMealPref(
            user_id=user_id,
            meal_id=meal_id,
            stance=value,
            created_at=now,
            updated_at=now,
        )
        session.add(row)
        _event(session, user_id, meal_id, _EVENT_FOR_STANCE[value], now)
    elif row.stance != value:
        row.stance = value
        _event(session, user_id, meal_id, _EVENT_FOR_STANCE[value], now)
    session.flush()
    return row


def clear_meal_pref(session: Session, user_id: int, meal_id: int, now: datetime) -> bool:
    """Delete the row and write PREF_CLEAR. Missing row writes nothing."""
    _active_meal(session, meal_id)
    row = session.get(UserMealPref, (user_id, meal_id))
    if row is None:
        return False
    session.delete(row)
    _event(session, user_id, meal_id, InteractionEventType.PREF_CLEAR.value, now)
    session.flush()
    return True
