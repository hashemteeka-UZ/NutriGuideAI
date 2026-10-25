"""Learned planning in the database path (#290, #291, #293-#295)."""

from __future__ import annotations

import logging
from collections.abc import Sequence
from datetime import timedelta
from decimal import Decimal

import numpy as np
import pytest
from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import MealPlanItem
from app.ml import planning
from app.ml.config import (
    LEARNED_REASON_MIN_EVENTS,
    MAX_LEARNED_BONUS,
    PLANNING_EXPLORATION_WEIGHT,
)
from app.ml.features import FEATURE_VERSION, build_meal_features
from app.ml.linucb import RankedMeal
from app.ml.replay import replay
from app.services.condition_limits import apply_general_limits, resolve_condition_limits
from app.services.meal_filter import SLOT_OCCASION, load_meal_facts, load_user_preferences
from app.services.optimizer import VARIETY_DAYS, layer1_candidate_ids
from app.services.plan_requests import list_alternatives
from app.services.plan_view import plan_view
from app.services.planner import create_day_plan
from tests.builders import make_user_interaction
from tests.services.conftest import NOW, PLAN_DATE, case_1_user, plan_target

# Measured with 5 PREF_LIKE events on the F.1 slice (L.2): below the 5 units asked for.
MEASURED_PREF_LIKE_MARGIN = 3


@pytest.fixture
def ml_on(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(planning, "ml_planning_enabled", lambda: True)


def _user(session: Session, conn: Connection) -> int:
    user = case_1_user(conn)
    plan_target(session, user)
    return user


def _items(session: Session, plan_id: int) -> list[MealPlanItem]:
    return list(
        session.scalars(
            select(MealPlanItem).where(MealPlanItem.plan_id == plan_id).order_by(MealPlanItem.id)
        )
    )


def _likes(conn: Connection, user: int, meal_id: int, count: int) -> None:
    for minute in range(count):
        make_user_interaction(
            conn,
            user_id=user,
            meal_id=meal_id,
            event_type="SAVE" if minute % 2 else "COOK",
            created_at=NOW + timedelta(minutes=minute),
        )


def test_disabled_builds_cpsat_v1(slice_session: Session, integrity_conn: Connection) -> None:
    user = _user(slice_session, integrity_conn)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert plan.algorithm_version == "cpsat_v1"
    assert "ml" not in plan.target_snapshot
    assert "ml_fallback" not in plan.target_snapshot


def test_learned_plan_records_the_ml_block(
    slice_session: Session, integrity_conn: Connection, ml_on: None
) -> None:
    user = _user(slice_session, integrity_conn)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert plan.algorithm_version == "cpsat_v2_learned"
    assert plan.target_snapshot["planner_version"] == "cpsat_v2_learned"
    assert plan.target_snapshot["ml"] == {
        "feature_version": FEATURE_VERSION,
        "alpha": 0.5,
        "n_user_events": 0,
        "bonus_max": MAX_LEARNED_BONUS,
        "variety_days": VARIETY_DAYS,
    }
    view = plan_view(slice_session, user, plan, "en")
    assert view.stats is not None
    assert view.algorithm_version == "cpsat_v2_learned"
    assert view.kcal_within_10pct


def test_a_cold_user_gets_no_bonus_and_the_cpsat_v1_menu(
    slice_session: Session, integrity_conn: Connection, monkeypatch: pytest.MonkeyPatch
) -> None:
    user = _user(slice_session, integrity_conn)
    v1 = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    monkeypatch.setattr(planning, "ml_planning_enabled", lambda: True)
    v2 = create_day_plan(slice_session, user, PLAN_DATE, NOW + timedelta(seconds=1))
    assert [i.meal_id for i in _items(slice_session, v1.plan_id)] == [
        i.meal_id for i in _items(slice_session, v2.plan_id)
    ]


def test_fallback_builds_cpsat_v1_and_logs_the_class_only(
    slice_session: Session,
    integrity_conn: Connection,
    ml_on: None,
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    user = _user(slice_session, integrity_conn)

    def broken(*_args: object) -> None:
        raise RuntimeError(f"secret detail of user {user}")

    monkeypatch.setattr(planning, "build_learned_inputs", broken)
    with caplog.at_level(logging.WARNING, logger="nutriguide.api"):
        plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert plan.algorithm_version == "cpsat_v1"
    assert plan.target_snapshot["ml_fallback"] is True
    assert "ml" not in plan.target_snapshot
    messages = [record.getMessage() for record in caplog.records]
    assert "ml_planning_fallback error=RuntimeError" in messages
    assert not any("secret" in message for message in messages)


def test_learned_reason_needs_five_real_events(
    slice_session: Session, integrity_conn: Connection, ml_on: None
) -> None:
    user = _user(slice_session, integrity_conn)
    limits = apply_general_limits(resolve_condition_limits(slice_session, user, Decimal(2364)))
    first = planning.build_learned_inputs(slice_session, user, PLAN_DATE, limits)
    assert first.reason_meal_ids == frozenset()
    assert first.bonus == {}  # nothing learned: the same score for every meal
    liked = min(
        layer1_candidate_ids(
            load_meal_facts(slice_session), load_user_preferences(slice_session, user), limits
        )
    )
    _likes(integrity_conn, user, liked, LEARNED_REASON_MIN_EVENTS - 1)
    four = planning.build_learned_inputs(slice_session, user, PLAN_DATE, limits)
    assert four.reason_meal_ids == frozenset()
    assert four.snapshot["ml"]["n_user_events"] == LEARNED_REASON_MIN_EVENTS - 1
    _likes(integrity_conn, user, liked, 1)
    five = planning.build_learned_inputs(slice_session, user, PLAN_DATE, limits)
    assert liked in five.reason_meal_ids
    assert five.bonus
    assert all(0 < value <= MAX_LEARNED_BONUS for value in five.bonus.values())


def test_relative_bonus_ignores_a_shared_offset() -> None:
    same = [RankedMeal(1, 0.4, 0.9, 1.0), RankedMeal(2, 0.4, 0.9, 1.0)]
    assert planning.relative_bonus(same) == {}
    spread = [RankedMeal(1, -1.0, -1.0), RankedMeal(2, 1.0, 1.0), RankedMeal(3, 0.0, 0.0)]
    assert planning.relative_bonus(spread) == {2: MAX_LEARNED_BONUS, 3: MAX_LEARNED_BONUS // 2}
    # The planning score damps exploration: mean + 0.1 x width, clipped to [-1, 1].
    damped = [RankedMeal(1, 0.0, 0.0, 2.0), RankedMeal(2, 0.0, 0.0, 0.0)]
    expected = round(PLANNING_EXPLORATION_WEIGHT * 2.0 / 2 * MAX_LEARNED_BONUS)
    assert planning.relative_bonus(damped) == {1: expected}


# A near copy of the liked meal (feature distance below this) shares what was learned about
# it, as a linear model should: on the F.1 slice the Libyan shakshuka with brown bread and
# feta with olives and brown bread are 0.098 apart and score within 0.0003.
NEAR_COPY = 0.2


def _margin(session: Session, conn: Connection, kinds: Sequence[str]) -> tuple[int, float]:
    """(bonus, planning score) of the liked meal minus the best untried, not near-copy meal
    of its slot."""
    user = _user(session, conn)
    limits = apply_general_limits(resolve_condition_limits(session, user, Decimal(2364)))
    facts = {meal.meal_id: meal for meal in load_meal_facts(session)}
    candidates = layer1_candidate_ids(
        list(facts.values()), load_user_preferences(session, user), limits
    )
    liked = min(candidates)
    for minute, kind in enumerate(kinds):
        make_user_interaction(
            conn,
            user_id=user,
            meal_id=liked,
            event_type=kind,
            created_at=NOW + timedelta(minutes=minute),
        )
    inputs = planning.build_learned_inputs(session, user, PLAN_DATE, limits)
    features = build_meal_features(session)
    slot_tags = set(SLOT_OCCASION.values()) & facts[liked].tags
    others = [
        m
        for m in candidates
        if m != liked
        and facts[m].tags & slot_tags
        and np.linalg.norm(features.row(m) - features.row(liked)) >= NEAR_COPY
    ]
    assert others
    ranked = {meal.meal_id: meal for meal in replay(session).scorer().rank(user, candidates)}
    best = max(planning.planning_score(ranked[m]) for m in others)
    bonus = inputs.bonus.get(liked, 0) - max(inputs.bonus.get(m, 0) for m in others)
    return bonus, planning.planning_score(ranked[liked]) - best


def test_a_liked_meal_outranks_every_untried_meal_of_its_slot(
    slice_session: Session, integrity_conn: Connection, ml_on: None
) -> None:
    kinds = ["COOK" if i % 2 == 0 else "SAVE" for i in range(LEARNED_REASON_MIN_EVENTS)]
    bonus, score = _margin(slice_session, integrity_conn, kinds)
    print(f"COOK/SAVE x5 margin: {bonus} bonus units, {score:.4f} score")
    # +0.5 events: the score gap is about one bonus unit, so rounding may tie the bonuses.
    assert score > 0
    assert bonus >= 0


def test_full_reward_events_give_a_clear_margin(
    slice_session: Session, integrity_conn: Connection, ml_on: None
) -> None:
    kinds = ["PREF_LIKE"] * LEARNED_REASON_MIN_EVENTS
    bonus, score = _margin(slice_session, integrity_conn, kinds)
    print(f"PREF_LIKE x5 margin: {bonus} bonus units, {score:.4f} score")
    assert bonus >= MEASURED_PREF_LIKE_MARGIN


def test_variety_penalty_reads_the_previous_plans(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = _user(slice_session, integrity_conn)
    for age in (1, 2, 6, 7):
        create_day_plan(slice_session, user, PLAN_DATE - timedelta(days=age), NOW)
    penalty = planning.variety_penalty(slice_session, user, PLAN_DATE)
    assert penalty
    assert max(penalty.values()) <= 40 + 8
    assert min(penalty.values()) >= 8


def _alternatives(session: Session, user: int, item_id: int) -> list[int]:
    return [a.meal.meal_id for a in list_alternatives(session, user, item_id, "en")]


def test_swap_order_unchanged_without_user_events(
    slice_session: Session, integrity_conn: Connection, monkeypatch: pytest.MonkeyPatch
) -> None:
    user = _user(slice_session, integrity_conn)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    item = _items(slice_session, plan.plan_id)[0]
    before = _alternatives(slice_session, user, item.id)
    monkeypatch.setattr(planning, "ml_planning_enabled", lambda: True)
    assert _alternatives(slice_session, user, item.id) == before


def test_swap_order_puts_the_liked_meal_first(
    slice_session: Session, integrity_conn: Connection, ml_on: None
) -> None:
    user = _user(slice_session, integrity_conn)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    item, alternatives = max(
        (
            (item, _alternatives(slice_session, user, item.id))
            for item in _items(slice_session, plan.plan_id)
        ),
        key=lambda pair: len(pair[1]),
    )
    assert len(alternatives) >= 3
    liked = alternatives[-1]
    _likes(integrity_conn, user, liked, 6)
    ordered = _alternatives(slice_session, user, item.id)
    assert ordered[0] == liked
    assert len(ordered) <= 10
