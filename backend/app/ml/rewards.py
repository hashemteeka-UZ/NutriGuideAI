"""Rewards from real behaviour (#286). Every reward is in [-1, 1]; no reward means no update.

| event        | reward                                           |
|--------------|--------------------------------------------------|
| ACCEPT       | 0.5 + 0.5 * clamp(servings_ratio, 0, 1)          |
| RATE         | (value - 3) / 2                                  |
| SWAP_OUT     | -0.6 for meal_id, +0.3 for context.replaced_by   |
| SKIP         | -0.3                                             |
| SAVE, COOK   | +0.5                                             |
| PREF_LIKE    | +1                                               |
| PREF_DISLIKE | -1                                               |
| PREF_CLEAR, IMPRESSION, VIEW | none                             |

Whether an ACCEPT still counts (its log not undone) is decided by replay, which reads the logs.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Final

from app.db.models.user import InteractionEventType

ACCEPT_BASE: Final = 0.5
ACCEPT_RATIO_WEIGHT: Final = 0.5
RATE_CENTER: Final = 3
RATE_HALF_RANGE: Final = 2
SWAP_OUT_REPLACED: Final = -0.6
SWAP_OUT_REPLACEMENT: Final = 0.3
FIXED_REWARDS: Final[Mapping[str, float]] = {
    InteractionEventType.SKIP.value: -0.3,
    InteractionEventType.SAVE.value: 0.5,
    InteractionEventType.COOK.value: 0.5,
    InteractionEventType.PREF_LIKE.value: 1.0,
    InteractionEventType.PREF_DISLIKE.value: -1.0,
    InteractionEventType.SWAP_OUT.value: SWAP_OUT_REPLACED,
}


@dataclass(frozen=True)
class InteractionEvent:
    """A user_interactions row as replay reads it."""

    id: int
    user_id: int
    meal_id: int
    event_type: str
    created_at: datetime
    value: int | None = None
    context: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class Observation:
    meal_id: int
    reward: float


def _clip(reward: float) -> float:
    return min(max(reward, -1.0), 1.0)


def _number(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, int | float):
        return None
    return float(value)


def reward_for(event: InteractionEvent) -> float | None:
    """Reward of the event's own meal_id, or None when the event teaches nothing."""
    kind = event.event_type
    if kind == InteractionEventType.ACCEPT.value:
        ratio = _number(event.context.get("servings_ratio"))
        # Written by every ACCEPT since I.4; a row without it was eaten as planned.
        ratio = 1.0 if ratio is None else min(max(ratio, 0.0), 1.0)
        return _clip(ACCEPT_BASE + ACCEPT_RATIO_WEIGHT * ratio)
    if kind == InteractionEventType.RATE.value:
        if event.value is None:
            return None
        return _clip((event.value - RATE_CENTER) / RATE_HALF_RANGE)
    reward = FIXED_REWARDS.get(kind)
    return None if reward is None else _clip(reward)


def observations(event: InteractionEvent) -> list[Observation]:
    """Every (meal, reward) the event teaches: SWAP_OUT also rewards its replacement."""
    found: list[Observation] = []
    reward = reward_for(event)
    if reward is not None:
        found.append(Observation(event.meal_id, reward))
    if event.event_type == InteractionEventType.SWAP_OUT.value:
        replacement = event.context.get("replaced_by")
        if isinstance(replacement, int) and not isinstance(replacement, bool):
            found.append(Observation(replacement, _clip(SWAP_OUT_REPLACEMENT)))
    return found
