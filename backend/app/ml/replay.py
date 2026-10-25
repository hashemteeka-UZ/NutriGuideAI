"""Model state from the event log (#287, #288). There is no model table: user_interactions is
the only source of truth, so deleting an account deletes what was learned about it.

replay reads the events ordered by (created_at, id) and updates one hybrid model in that order.
The result is cached in process; any new event, undone log, or preference change gives a new
cache key, so the next call replays again.
"""

from __future__ import annotations

from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import datetime

import numpy as np
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, Cuisine, UserCuisinePref, UserInteraction, UserMealPref
from app.db.models.user import InteractionEventType, MealStance
from app.ml.config import (
    COLD_START_CAP,
    COLD_START_CUISINE_REWARD,
    COLD_START_LIKE_REWARD,
    COLD_START_WEIGHT,
    DEFAULT_ALPHA,
    RIDGE_LAMBDA,
)
from app.ml.features import (
    FEATURE_VERSION,
    FloatVector,
    MealFeatureMatrix,
    build_meal_features,
    catalog_key,
)
from app.ml.linucb import HybridLinUCB, LearnedScorer
from app.ml.rewards import InteractionEvent, observations


@dataclass(frozen=True)
class PseudoObservation:
    """A cold-start row (#288): a liked meal, or the centroid of a picked cuisine."""

    x: FloatVector
    reward: float


@dataclass(frozen=True)
class ModelState:
    model: HybridLinUCB
    features: MealFeatureMatrix
    last_interaction_id: int | None
    taught: int
    pseudo: int
    # Real events per user that taught at least one observation (pseudo rows not counted).
    user_events: Mapping[int, int] = field(default_factory=dict)

    def scorer(self) -> LearnedScorer:
        return LearnedScorer(self.model, self.features)


def replay_events(
    model: HybridLinUCB,
    features: MealFeatureMatrix,
    events: Iterable[InteractionEvent],
    active_plan_items: frozenset[int] | None = None,
    cold_start: Mapping[int, Sequence[PseudoObservation]] | None = None,
    user_events: Counter[int] | None = None,
) -> tuple[int, int]:
    """Apply events in the given order. Returns (observations taught, pseudo-observations).

    active_plan_items: plan items that still have a non-deleted log; None trusts every ACCEPT.
    A user's cold-start rows go in just before that user's first event; users with rows but
    no events get them at the end. user_events, when given, counts per user the real events
    that taught something.
    """
    cold_start = cold_start or {}
    started: set[int] = set()
    taught = 0
    pseudo = 0

    def start(user_id: int) -> None:
        nonlocal pseudo
        started.add(user_id)
        for row in cold_start.get(user_id, ()):
            model.update(user_id, row.x, row.reward, weight=COLD_START_WEIGHT)
            pseudo += 1

    for event in events:
        if event.user_id not in started:
            start(event.user_id)
        if event.event_type == InteractionEventType.ACCEPT.value and active_plan_items is not None:
            item = event.context.get("plan_item_id")
            if not isinstance(item, int) or item not in active_plan_items:
                continue
        learned = False
        for observation in observations(event):
            if observation.meal_id in features:
                model.update(event.user_id, features.row(observation.meal_id), observation.reward)
                taught += 1
                learned = True
        if learned and user_events is not None:
            user_events[event.user_id] += 1
    for user_id in sorted(set(cold_start) - started):
        start(user_id)
    return taught, pseudo


def _unit_body(vector: FloatVector) -> FloatVector:
    """Same geometry as a meal row: unit norm without the bias, bias 1."""
    out = vector.copy()
    norm = float(np.linalg.norm(out[:-1]))
    if norm > 0:
        out[:-1] /= norm
    out[-1] = 1.0
    return out


def load_cold_start(
    session: Session, features: MealFeatureMatrix, user_ids: Sequence[int] | None = None
) -> dict[int, list[PseudoObservation]]:
    """LIKE meal prefs (+1) and picked cuisines (+0.5, cuisine centroid), newest first, capped."""
    candidates: dict[int, list[tuple[datetime, int, int, PseudoObservation]]] = defaultdict(list)

    likes = select(UserMealPref.user_id, UserMealPref.meal_id, UserMealPref.created_at).where(
        UserMealPref.stance == MealStance.LIKE.value
    )
    if user_ids is not None:
        likes = likes.where(UserMealPref.user_id.in_(user_ids))
    for row in session.execute(likes):
        if row.meal_id in features:
            observation = PseudoObservation(features.row(row.meal_id), COLD_START_LIKE_REWARD)
            candidates[row.user_id].append((row.created_at, 0, row.meal_id, observation))

    columns = {name: index for index, name in enumerate(features.names)}
    cuisines = select(UserCuisinePref.user_id, Cuisine.cuisine_id, Cuisine.code).join(
        Cuisine, Cuisine.cuisine_id == UserCuisinePref.cuisine_id
    )
    cuisines = cuisines.add_columns(UserCuisinePref.created_at)
    if user_ids is not None:
        cuisines = cuisines.where(UserCuisinePref.user_id.in_(user_ids))
    for pick in session.execute(cuisines):
        column = columns.get(f"cuisine:{pick.code}")
        if column is None:
            continue
        members = features.matrix[features.matrix[:, column] > 0]
        if len(members) == 0:
            continue
        centroid = _unit_body(members.mean(axis=0))
        observation = PseudoObservation(centroid, COLD_START_CUISINE_REWARD)
        candidates[pick.user_id].append((pick.created_at, 1, pick.cuisine_id, observation))

    chosen: dict[int, list[PseudoObservation]] = {}
    for user_id, rows in candidates.items():
        newest = sorted(rows, key=lambda r: (r[0], -r[1], -r[2]), reverse=True)
        chosen[user_id] = [row[3] for row in newest[:COLD_START_CAP]]
    return chosen


def _active_plan_items(session: Session, user_ids: Sequence[int] | None) -> frozenset[int]:
    query = select(ConsumptionLog.plan_item_id).where(
        ConsumptionLog.plan_item_id.is_not(None), ConsumptionLog.deleted_at.is_(None)
    )
    if user_ids is not None:
        query = query.where(ConsumptionLog.user_id.in_(user_ids))
    return frozenset(item for item in session.scalars(query) if item is not None)


def _events(session: Session, user_ids: Sequence[int] | None) -> list[InteractionEvent]:
    query = select(
        UserInteraction.id,
        UserInteraction.user_id,
        UserInteraction.meal_id,
        UserInteraction.event_type,
        UserInteraction.created_at,
        UserInteraction.value,
        UserInteraction.context,
    ).order_by(UserInteraction.created_at, UserInteraction.id)
    if user_ids is not None:
        query = query.where(UserInteraction.user_id.in_(user_ids))
    return [
        InteractionEvent(
            id=row.id,
            user_id=row.user_id,
            meal_id=row.meal_id,
            event_type=row.event_type,
            created_at=row.created_at,
            value=row.value,
            context=row.context or {},
        )
        for row in session.execute(query)
    ]


def _state_key(
    session: Session,
    user_ids: Sequence[int] | None,
    alpha: float,
    ridge: float,
) -> tuple[object, ...]:
    last_event = session.execute(select(func.max(UserInteraction.id))).scalar_one()
    logs = session.execute(
        select(func.count(), func.max(ConsumptionLog.id)).where(
            ConsumptionLog.plan_item_id.is_not(None), ConsumptionLog.deleted_at.is_(None)
        )
    ).one()
    likes = session.execute(
        select(func.count(), func.max(UserMealPref.updated_at)).where(
            UserMealPref.stance == MealStance.LIKE.value
        )
    ).one()
    cuisines = session.execute(select(func.count(), func.max(UserCuisinePref.created_at))).one()
    scope = None if user_ids is None else tuple(sorted(set(user_ids)))
    return (
        FEATURE_VERSION,
        catalog_key(session),
        last_event,
        *logs,
        *likes,
        *cuisines,
        scope,
        alpha,
        ridge,
    )


_cache: dict[tuple[object, ...], ModelState] = {}


def clear_replay_cache() -> None:
    _cache.clear()


def replay(
    session: Session,
    user_ids: Sequence[int] | None = None,
    alpha: float = DEFAULT_ALPHA,
    ridge: float = RIDGE_LAMBDA,
) -> ModelState:
    """The hybrid model after every event of user_ids (None: all users), in event order."""
    key = _state_key(session, user_ids, alpha, ridge)
    cached = _cache.get(key)
    if cached is not None:
        return cached
    features = build_meal_features(session)
    model = HybridLinUCB(features.d, alpha=alpha, ridge=ridge)
    events = _events(session, user_ids)
    user_events: Counter[int] = Counter()
    taught, pseudo = replay_events(
        model,
        features,
        events,
        _active_plan_items(session, user_ids),
        load_cold_start(session, features, user_ids),
        user_events,
    )
    state = ModelState(
        model=model,
        features=features,
        last_interaction_id=max((event.id for event in events), default=None),
        taught=taught,
        pseudo=pseudo,
        user_events=dict(user_events),
    )
    _cache.clear()
    _cache[key] = state
    return state
