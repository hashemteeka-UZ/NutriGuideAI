"""Rewards per #286, and an undone ACCEPT that teaches nothing."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Meal
from app.ml.replay import replay
from app.ml.rewards import InteractionEvent, Observation, observations, reward_for
from tests.builders import (
    make_consumption_log,
    make_meal_plan,
    make_meal_plan_item,
    make_user,
    make_user_interaction,
)

AT = datetime(2026, 10, 20, 12, 0, tzinfo=UTC)


def _event(kind: str, value: int | None = None, **context: Any) -> InteractionEvent:
    return InteractionEvent(1, 1, 5, kind, AT, value, context)


@pytest.mark.parametrize(
    ("kind", "value", "context", "expected"),
    [
        ("ACCEPT", None, {"servings_ratio": 1.0}, 1.0),
        ("ACCEPT", None, {"servings_ratio": 0.5}, 0.75),
        ("ACCEPT", None, {"servings_ratio": 0.0}, 0.5),
        ("ACCEPT", None, {"servings_ratio": 2.0}, 1.0),
        ("ACCEPT", None, {"servings_ratio": -1.0}, 0.5),
        ("ACCEPT", None, {}, 1.0),
        ("RATE", 1, {}, -1.0),
        ("RATE", 3, {}, 0.0),
        ("RATE", 4, {}, 0.5),
        ("RATE", 5, {}, 1.0),
        ("RATE", None, {}, None),
        ("SWAP_OUT", None, {"replaced_by": 9}, -0.6),
        ("SKIP", None, {}, -0.3),
        ("SAVE", None, {}, 0.5),
        ("COOK", None, {}, 0.5),
        ("PREF_LIKE", None, {}, 1.0),
        ("PREF_DISLIKE", None, {}, -1.0),
        ("PREF_CLEAR", None, {}, None),
        ("IMPRESSION", None, {}, None),
        ("VIEW", None, {}, None),
    ],
)
def test_reward_per_event_type(
    kind: str, value: int | None, context: dict[str, Any], expected: float | None
) -> None:
    reward = reward_for(_event(kind, value, **context))
    assert reward == (None if expected is None else pytest.approx(expected))
    if reward is not None:
        assert -1.0 <= reward <= 1.0


def test_swap_out_is_two_sided() -> None:
    assert observations(_event("SWAP_OUT", replaced_by=9)) == [
        Observation(5, -0.6),
        Observation(9, 0.3),
    ]
    assert observations(_event("SWAP_OUT")) == [Observation(5, -0.6)]
    assert observations(_event("SWAP_OUT", replaced_by=True)) == [Observation(5, -0.6)]
    assert observations(_event("VIEW")) == []


def _accept_setup(session: Session, conn: Connection, deleted: bool) -> int:
    meal = (
        session.execute(select(Meal.meal_id).where(Meal.is_active.is_(True)).order_by(Meal.meal_id))
        .scalars()
        .first()
    )
    assert meal is not None
    user = make_user(conn)
    plan = make_meal_plan(conn, user_id=user)
    item = make_meal_plan_item(conn, plan_id=plan, meal_id=meal)
    make_consumption_log(
        conn,
        user_id=user,
        meal_id=meal,
        plan_item_id=item,
        deleted_at=AT + timedelta(minutes=5) if deleted else None,
    )
    make_user_interaction(
        conn,
        user_id=user,
        meal_id=meal,
        event_type="ACCEPT",
        context={"plan_item_id": item, "servings_ratio": 1.0},
        created_at=AT,
    )
    return user


def test_undone_accept_is_ignored(slice_session: Session, integrity_conn: Connection) -> None:
    user = _accept_setup(slice_session, integrity_conn, deleted=True)
    assert replay(slice_session, [user]).taught == 0


def test_kept_accept_teaches(slice_session: Session, integrity_conn: Connection) -> None:
    user = _accept_setup(slice_session, integrity_conn, deleted=False)
    state = replay(slice_session, [user])
    assert state.taught == 1
    assert state.model.observations == 1
