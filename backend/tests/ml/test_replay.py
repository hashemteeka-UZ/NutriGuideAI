"""Event replay (#287) and cold start (#288)."""

from __future__ import annotations

import time
from datetime import UTC, datetime, timedelta

import numpy as np
from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Cuisine, Meal
from app.ml.config import COLD_START_CAP, COLD_START_CUISINE_REWARD
from app.ml.features import MealFeatureMatrix, build_meal_features
from app.ml.linucb import HybridLinUCB
from app.ml.replay import PseudoObservation, load_cold_start, replay, replay_events
from app.ml.rewards import InteractionEvent
from tests.builders import (
    make_user,
    make_user_cuisine_pref,
    make_user_interaction,
    make_user_meal_pref,
)

AT = datetime(2026, 10, 20, 12, 0, tzinfo=UTC)


def _meals(session: Session) -> list[int]:
    return list(
        session.scalars(select(Meal.meal_id).where(Meal.is_active.is_(True)).order_by(Meal.meal_id))
    )


def test_replay_follows_created_at_then_id(
    slice_session: Session, integrity_conn: Connection
) -> None:
    meals = _meals(slice_session)
    user = make_user(integrity_conn)
    # Inserted out of time order: ids do not follow created_at.
    rows = [
        (meals[0], "SAVE", AT + timedelta(minutes=2)),
        (meals[1], "SKIP", AT),
        (meals[2], "PREF_DISLIKE", AT + timedelta(minutes=1)),
        (meals[1], "COOK", AT),
    ]
    ids = [
        make_user_interaction(
            integrity_conn, user_id=user, meal_id=meal, event_type=kind, created_at=at
        )
        for meal, kind, at in rows
    ]
    state = replay(slice_session, [user])
    assert state.taught == 4
    assert state.last_interaction_id == max(ids)

    features = build_meal_features(slice_session)
    expected = HybridLinUCB(features.d)
    ordered = sorted(zip(ids, rows, strict=True), key=lambda item: (item[1][2], item[0]))
    for _, (meal, kind, _at) in ordered:
        reward = {"SAVE": 0.5, "SKIP": -0.3, "PREF_DISLIKE": -1.0, "COOK": 0.5}[kind]
        expected.update(user, features.row(meal), reward)
    assert np.array_equal(state.model.a0, expected.a0)
    assert np.array_equal(state.model.b0, expected.b0)
    assert np.array_equal(state.model.coefficients(user)[1], expected.coefficients(user)[1])


def test_cache_is_reused_until_a_new_event(
    slice_session: Session, integrity_conn: Connection
) -> None:
    meals = _meals(slice_session)
    user = make_user(integrity_conn)
    make_user_interaction(
        integrity_conn, user_id=user, meal_id=meals[0], event_type="SAVE", created_at=AT
    )
    first = replay(slice_session, [user])
    assert replay(slice_session, [user]) is first
    make_user_interaction(
        integrity_conn, user_id=user, meal_id=meals[1], event_type="COOK", created_at=AT
    )
    second = replay(slice_session, [user])
    assert second is not first
    assert second.taught == first.taught + 1


def test_cold_start_newest_likes_capped(slice_session: Session, integrity_conn: Connection) -> None:
    meals = _meals(slice_session)
    assert len(meals) > COLD_START_CAP
    liked = meals[: COLD_START_CAP + 3]
    user = make_user(integrity_conn)
    for minute, meal in enumerate(liked):
        make_user_meal_pref(
            integrity_conn, user_id=user, meal_id=meal, created_at=AT + timedelta(minutes=minute)
        )
    features = build_meal_features(slice_session)
    rows = load_cold_start(slice_session, features, [user])[user]
    assert len(rows) == COLD_START_CAP
    newest = list(reversed(liked))[:COLD_START_CAP]
    for row, meal in zip(rows, newest, strict=True):
        assert np.array_equal(row.x, features.row(meal))
    assert all(row.reward == 1.0 for row in rows)

    state = replay(slice_session, [user])
    assert state.pseudo == COLD_START_CAP
    assert state.taught == 0


def test_cold_start_cuisine_centroid(slice_session: Session, integrity_conn: Connection) -> None:
    features = build_meal_features(slice_session)
    code = next(
        n.split(":", 1)[1]
        for n in features.names
        if n.startswith("cuisine:") and features.matrix[:, features.names.index(n)].any()
    )
    cuisine = slice_session.execute(
        select(Cuisine.cuisine_id).where(Cuisine.code == code)
    ).scalar_one()
    user = make_user(integrity_conn)
    make_user_cuisine_pref(integrity_conn, user_id=user, cuisine_id=cuisine)
    rows = load_cold_start(slice_session, features, [user])[user]
    assert len(rows) == 1
    assert rows[0].reward == COLD_START_CUISINE_REWARD
    assert rows[0].x[features.names.index(f"cuisine:{code}")] > 0
    assert np.isclose(np.linalg.norm(rows[0].x[:-1]), 1.0)
    assert rows[0].x[-1] == 1.0


def _synthetic(n: int, d: int, seed: int) -> MealFeatureMatrix:
    rng = np.random.default_rng(seed)
    body = rng.random((n, d - 1))
    body /= np.linalg.norm(body, axis=1, keepdims=True)
    matrix = np.hstack([body, np.ones((n, 1))])
    names = (*(f"f{i}" for i in range(d - 1)), "bias")
    return MealFeatureMatrix(np.arange(1, n + 1, dtype=np.int64), matrix, names)


def test_pseudo_rows_go_before_the_first_event_and_users_without_events_last() -> None:
    features = _synthetic(5, 4, 1)
    x = features.row(1)
    events = [InteractionEvent(1, 7, 2, "SAVE", AT)]
    cold = {7: [PseudoObservation(x, 1.0)], 8: [PseudoObservation(x, 0.5)]}
    model = HybridLinUCB(features.d)
    assert replay_events(model, features, events, None, cold) == (1, 2)

    expected = HybridLinUCB(features.d)
    expected.update(7, x, 1.0, weight=0.3)
    expected.update(7, features.row(2), 0.5)
    expected.update(8, x, 0.5, weight=0.3)
    assert np.allclose(model.a0, expected.a0)
    assert np.allclose(model.b0, expected.b0)


def test_replay_of_10k_events_is_fast() -> None:
    """Replay time for 10k in-memory events at the real catalog size (158 meals, d = 25)."""
    features = _synthetic(158, 25, 2)
    rng = np.random.default_rng(3)
    kinds = ["SAVE", "SKIP", "COOK", "PREF_LIKE", "PREF_DISLIKE", "VIEW", "IMPRESSION"]
    events = [
        InteractionEvent(
            i,
            int(rng.integers(100)),
            int(rng.integers(1, 159)),
            kinds[int(rng.integers(len(kinds)))],
            AT + timedelta(seconds=i),
        )
        for i in range(10_000)
    ]
    model = HybridLinUCB(features.d)
    started = time.perf_counter()
    taught, _ = replay_events(model, features, events)
    seconds = time.perf_counter() - started
    print(f"replay of 10000 events ({taught} updates): {seconds:.3f} s")
    assert taught > 6000
    assert seconds < 5.0  # target < 1 s on the development PC; looser here for slow CI
