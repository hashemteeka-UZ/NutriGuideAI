"""Learned planning inputs (Step L.2, #290-#295): what cpsat_v2_learned adds to cpsat_v1.

Layer 1 still decides which meals are allowed. This module only scores the Layer 1
candidates, so the model never sees an unsafe meal (#283), and turns the scores into
objective-only terms:

- learned bonus (#291): planning score s = mean + PLANNING_EXPLORATION_WEIGHT x width (the
  damped UCB), clipped to [-1, 1], minus the smallest clipped s among the day's candidates,
  then linear: a difference of 2 (the whole range) is MAX_LEARNED_BONUS. Main positions
  always hold one meal, but snacks are optional, so a bonus every meal gets would make an
  extra snack look attractive; only the difference between candidates may steer the choice.
  A user the model knows nothing about gets the same score for every meal, so no bonus.
- weekly variety penalty (#292): optimizer.variety_penalty_for_age for meals of the current
  plans of days D-2 to D-6.
- LEARNED_PREFERENCE (#294): learned mean >= LEARNED_REASON_MIN_MEAN and the user has at least
  LEARNED_REASON_MIN_EVENTS real events.

Any failure while building them falls back to cpsat_v1 (#295); the log line names the
exception class only.
"""

from __future__ import annotations

import logging
from collections import Counter
from collections.abc import Sequence
from datetime import date, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.models import MealPlanItem
from app.ml.config import (
    LEARNED_REASON_MIN_EVENTS,
    LEARNED_REASON_MIN_MEAN,
    MAX_LEARNED_BONUS,
    PLANNING_EXPLORATION_WEIGHT,
)
from app.ml.features import FEATURE_VERSION
from app.ml.linucb import RankedMeal
from app.ml.replay import ModelState, replay
from app.services.condition_limits import ResolvedLimits
from app.services.meal_filter import load_meal_facts, load_user_preferences
from app.services.optimizer import (
    VARIETY_DAYS,
    LearnedInputs,
    layer1_candidate_ids,
    variety_penalty_for_age,
)
from app.services.planner import current_plan_id

logger = logging.getLogger("nutriguide.api")


def ml_planning_enabled() -> bool:
    return get_settings().ML_PLANNING_ENABLED


def planning_score(meal: RankedMeal) -> float:
    """Damped UCB clipped to the reward range [-1, 1] (#291)."""
    score = meal.mean + PLANNING_EXPLORATION_WEIGHT * meal.width
    return min(max(score, -1.0), 1.0)


def relative_bonus(ranked: Sequence[RankedMeal]) -> dict[int, int]:
    """Bonus from each meal's planning score above the day's lowest; zeros are left out."""
    scores = {meal.meal_id: planning_score(meal) for meal in ranked}
    if not scores:
        return {}
    low = min(scores.values())
    bonus = {
        meal_id: round((score - low) / 2.0 * MAX_LEARNED_BONUS) for meal_id, score in scores.items()
    }
    return {meal_id: value for meal_id, value in bonus.items() if value > 0}


def variety_penalty(session: Session, user_id: int, plan_date: date) -> dict[int, int]:
    """Objective units per meal planned on days D-2 to D-6 (current plans only, #72)."""
    penalty: Counter[int] = Counter()
    for age in range(2, VARIETY_DAYS + 1):
        plan_id = current_plan_id(session, user_id, plan_date - timedelta(days=age))
        if plan_id is None:
            continue
        for meal_id in session.scalars(
            select(MealPlanItem.meal_id).where(MealPlanItem.plan_id == plan_id)
        ):
            penalty[meal_id] += variety_penalty_for_age(age)
    return dict(penalty)


def reason_meal_ids(
    state: ModelState, user_id: int, ranked: Sequence[RankedMeal]
) -> frozenset[int]:
    if state.user_events.get(user_id, 0) < LEARNED_REASON_MIN_EVENTS:
        return frozenset()
    return frozenset(meal.meal_id for meal in ranked if meal.mean >= LEARNED_REASON_MIN_MEAN)


def build_learned_inputs(
    session: Session, user_id: int, plan_date: date, limits: ResolvedLimits
) -> LearnedInputs:
    state = replay(session)
    candidates = layer1_candidate_ids(
        load_meal_facts(session), load_user_preferences(session, user_id), limits
    )
    ranked = state.scorer().rank(user_id, sorted(candidates))
    return LearnedInputs(
        bonus=relative_bonus(ranked),
        penalty=variety_penalty(session, user_id, plan_date),
        reason_meal_ids=reason_meal_ids(state, user_id, ranked),
        snapshot={
            "ml": {
                "feature_version": FEATURE_VERSION,
                "alpha": state.model.alpha,
                "n_user_events": state.user_events.get(user_id, 0),
                "bonus_max": MAX_LEARNED_BONUS,
                "variety_days": VARIETY_DAYS,
            }
        },
    )


def learned_inputs_or_none(
    session: Session, user_id: int, plan_date: date, limits: ResolvedLimits
) -> tuple[LearnedInputs | None, dict[str, Any]]:
    """(inputs, snapshot block): (None, {}) when disabled, (None, ml_fallback) on failure."""
    if not ml_planning_enabled():
        return None, {}
    try:
        inputs = build_learned_inputs(session, user_id, plan_date, limits)
    except Exception as exc:
        logger.warning("ml_planning_fallback error=%s", type(exc).__name__)
        return None, {"ml_fallback": True}
    return inputs, dict(inputs.snapshot)


def learned_means(session: Session, user_id: int, meal_ids: Sequence[int]) -> dict[int, float]:
    """Learned mean per meal for swap ordering (#293); empty when the user has no own events.

    Empty also when ML planning is off or the model fails, so the caller keeps today's order.
    """
    if not ml_planning_enabled():
        return {}
    try:
        state = replay(session)
        if state.user_events.get(user_id, 0) == 0:
            return {}
        return {meal.meal_id: meal.mean for meal in state.scorer().rank(user_id, meal_ids)}
    except Exception as exc:
        logger.warning("ml_swap_fallback error=%s", type(exc).__name__)
        return {}


def learned_reason(session: Session, user_id: int, meal_id: int) -> bool:
    """LEARNED_PREFERENCE for a swapped-in meal of a cpsat_v2_learned plan (#294)."""
    if not ml_planning_enabled():
        return False
    try:
        state = replay(session)
        ranked = state.scorer().rank(user_id, [meal_id])
        return meal_id in reason_meal_ids(state, user_id, ranked)
    except Exception as exc:
        logger.warning("ml_swap_fallback error=%s", type(exc).__name__)
        return False
