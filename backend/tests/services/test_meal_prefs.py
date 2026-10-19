"""Meal stance writes a learning event only when the stance actually changes (#182)."""

from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import UserInteraction
from app.services.common import MealNotFoundError
from app.services.meal_prefs import clear_meal_pref, list_meal_prefs, set_meal_pref
from tests.builders import make_meal, make_user

NOW = datetime(2026, 10, 12, 9, 0, tzinfo=UTC)


def _events(session: Session, user_id: int) -> list[str]:
    return list(
        session.scalars(
            select(UserInteraction.event_type)
            .where(UserInteraction.user_id == user_id)
            .order_by(UserInteraction.id)
        ).all()
    )


def test_events_follow_real_changes_and_another_user_is_hidden(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    other = make_user(integrity_conn)
    meal = make_meal(integrity_conn, is_active=True)
    hidden = make_meal(integrity_conn, is_active=True)
    set_meal_pref(session, user, meal, "LIKE", NOW)
    set_meal_pref(session, user, meal, "LIKE", NOW + timedelta(minutes=1))
    set_meal_pref(session, user, meal, "DISLIKE", NOW + timedelta(minutes=2))
    assert clear_meal_pref(session, user, meal, NOW + timedelta(minutes=3)) is True
    assert clear_meal_pref(session, user, meal, NOW + timedelta(minutes=4)) is False
    set_meal_pref(session, other, hidden, "LIKE", NOW)
    assert _events(session, user) == ["PREF_LIKE", "PREF_DISLIKE", "PREF_CLEAR"]
    assert list_meal_prefs(session, user) == []
    assert [row.meal_id for row in list_meal_prefs(session, other)] == [hidden]
    context = session.scalars(
        select(UserInteraction.context).where(UserInteraction.user_id == user)
    ).all()
    assert context == [{"source": "meal_prefs"}] * 3
    assert session.scalar(select(func.count()).select_from(UserInteraction)) == 4


def test_unknown_and_inactive_meals_are_missing(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    inactive = make_meal(integrity_conn, is_active=False)
    for meal_id in (inactive, 999_999_999):
        try:
            set_meal_pref(session, user, meal_id, "LIKE", NOW)
        except MealNotFoundError:
            pass
        else:
            raise AssertionError(meal_id)
        try:
            clear_meal_pref(session, user, meal_id, NOW)
        except MealNotFoundError:
            pass
        else:
            raise AssertionError(meal_id)
    assert _events(session, user) == []
