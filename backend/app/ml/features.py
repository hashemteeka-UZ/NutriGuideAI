"""Meal feature vectors mf_v1 (#284), built only from catalog data the server already has.

Columns, in order:
- energy_share:<protein|carbohydrate|total_fat>: the nutrient's share of the meal's energy,
  with the factors of condition_limits.energy_share_percent (targets_v1: 4, 4, 9), in [0, 1].
- per_serving:<fiber|sodium|sugars>: per-serving amount, min-max scaled over the active
  catalog to [0, 1] (a constant column is 0).
- cuisine:<code>: one-hot over every row of the cuisines table.
- dish_form:<value>: one-hot over DishForm.
- tag:<code>: multi-hot over the tags active meals carry, without the four slot tags.
- slot:<code>: multi-hot over the slot tags of meal_filter.SLOT_OCCASION.
- bias: always 1.0.

Every row except the bias column has unit L2 norm. Without it, a meal with many tags would
get a larger vector, a larger score, and a narrower confidence bound only because it has more
tags. The bias stays 1.0 so the shared intercept means the same for every meal. A missing
nutrient amount is 0 in its column (it is never guessed); Layer 1 already drops such meals.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Final, cast

import numpy as np
from numpy.typing import NDArray
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import Cuisine, Meal, MealNutrient
from app.db.models.catalog import DishForm
from app.db.models.user import MealSlot
from app.services.condition_limits import ENERGY_NUTRIENT, energy_share_percent
from app.services.meal_filter import SLOT_OCCASION, load_meal_facts

FEATURE_VERSION: Final = "mf_v1"
ENERGY_SHARE_NUTRIENTS: Final = ("protein", "carbohydrate", "total_fat")
SCALED_NUTRIENTS: Final = ("fiber", "sodium", "sugars")
SLOT_TAGS: Final = tuple(SLOT_OCCASION[slot] for slot in MealSlot)
BIAS: Final = "bias"
_PERCENT: Final = Decimal(100)

FloatMatrix = NDArray[np.float64]
FloatVector = NDArray[np.float64]


@dataclass(frozen=True)
class MealFeatureMatrix:
    meal_ids: NDArray[np.int64]
    matrix: FloatMatrix
    names: tuple[str, ...]
    version: str = FEATURE_VERSION
    _index: dict[int, int] = field(default_factory=dict, repr=False, compare=False)

    def __post_init__(self) -> None:
        self._index.update({int(meal_id): row for row, meal_id in enumerate(self.meal_ids)})

    @property
    def d(self) -> int:
        return int(self.matrix.shape[1])

    def __contains__(self, meal_id: object) -> bool:
        return meal_id in self._index

    def row(self, meal_id: int) -> FloatVector:
        return cast(FloatVector, self.matrix[self._index[meal_id]])

    def rows(self, meal_ids: Sequence[int]) -> FloatMatrix:
        return self.matrix[[self._index[meal_id] for meal_id in meal_ids]]


@dataclass(frozen=True)
class MealRaw:
    """One active meal before scaling: what build_feature_matrix needs."""

    meal_id: int
    per_serving: Mapping[str, Decimal]
    cuisine: str | None
    dish_form: str | None
    tags: frozenset[str]


def _energy_shares(per_serving: Mapping[str, Decimal]) -> list[float]:
    energy = per_serving.get(ENERGY_NUTRIENT)
    shares: list[float] = []
    for nutrient in ENERGY_SHARE_NUTRIENTS:
        amount = per_serving.get(nutrient)
        if energy is None or energy <= 0 or amount is None:
            shares.append(0.0)
            continue
        share = float(energy_share_percent(nutrient, amount, energy) / _PERCENT)
        shares.append(min(max(share, 0.0), 1.0))
    return shares


def build_feature_matrix(meals: Sequence[MealRaw], cuisines: Sequence[str]) -> MealFeatureMatrix:
    """Pure part of build_meal_features: rows in meal_id order."""
    ordered = sorted(meals, key=lambda meal: meal.meal_id)
    tags = sorted({tag for meal in ordered for tag in meal.tags} - set(SLOT_TAGS))
    cuisine_codes = sorted(cuisines)
    dish_forms = [form.value for form in DishForm]
    names = (
        [f"energy_share:{n}" for n in ENERGY_SHARE_NUTRIENTS]
        + [f"per_serving:{n}" for n in SCALED_NUTRIENTS]
        + [f"cuisine:{c}" for c in cuisine_codes]
        + [f"dish_form:{f}" for f in dish_forms]
        + [f"tag:{t}" for t in tags]
        + [f"slot:{s}" for s in SLOT_TAGS]
        + [BIAS]
    )
    matrix = np.zeros((len(ordered), len(names)), dtype=np.float64)
    if not ordered:
        return MealFeatureMatrix(np.zeros(0, dtype=np.int64), matrix, tuple(names))

    raw_amounts = np.array(
        [[float(meal.per_serving.get(n, 0)) for n in SCALED_NUTRIENTS] for meal in ordered],
        dtype=np.float64,
    )
    low = raw_amounts.min(axis=0)
    span = raw_amounts.max(axis=0) - low
    scaled = np.divide(raw_amounts - low, span, out=np.zeros_like(raw_amounts), where=span > 0)

    column = {name: index for index, name in enumerate(names)}
    for row, meal in enumerate(ordered):
        matrix[row, 0:3] = _energy_shares(meal.per_serving)
        matrix[row, 3:6] = scaled[row]
        if meal.cuisine is not None:
            matrix[row, column[f"cuisine:{meal.cuisine}"]] = 1.0
        if meal.dish_form is not None:
            matrix[row, column[f"dish_form:{meal.dish_form}"]] = 1.0
        for tag in meal.tags:
            key = f"slot:{tag}" if tag in SLOT_TAGS else f"tag:{tag}"
            matrix[row, column[key]] = 1.0

    body = matrix[:, :-1]
    norms = np.linalg.norm(body, axis=1, keepdims=True)
    matrix[:, :-1] = np.divide(body, norms, out=np.zeros_like(body), where=norms > 0)
    matrix[:, -1] = 1.0
    meal_ids = np.array([meal.meal_id for meal in ordered], dtype=np.int64)
    return MealFeatureMatrix(meal_ids, matrix, tuple(names))


def catalog_key(session: Session) -> tuple[object, ...]:
    """Changes whenever the active catalog or its computed nutrients change."""
    meals = session.execute(
        select(func.count(), func.max(Meal.updated_at), func.max(Meal.meal_id)).where(
            Meal.is_active.is_(True)
        )
    ).one()
    versions = tuple(
        sorted(
            session.scalars(select(Meal.dataset_version).where(Meal.is_active.is_(True)).distinct())
        )
    )
    computed = session.execute(select(func.max(MealNutrient.computed_at))).scalar_one()
    return (FEATURE_VERSION, versions, *meals, computed)


_cache: dict[tuple[object, ...], MealFeatureMatrix] = {}


def clear_feature_cache() -> None:
    _cache.clear()


def build_meal_features(session: Session) -> MealFeatureMatrix:
    """mf_v1 for every active meal, cached in process per catalog version."""
    key = catalog_key(session)
    cached = _cache.get(key)
    if cached is not None:
        return cached
    meal_rows = session.execute(
        select(Meal.meal_id, Cuisine.code, Meal.dish_form)
        .outerjoin(Cuisine, Cuisine.cuisine_id == Meal.cuisine_id)
        .where(Meal.is_active.is_(True))
    ).all()
    facts = {fact.meal_id: fact for fact in load_meal_facts(session)}
    meals = [
        MealRaw(
            meal_id=row.meal_id,
            per_serving=facts[row.meal_id].per_serving,
            cuisine=row.code,
            dish_form=row.dish_form,
            tags=facts[row.meal_id].tags,
        )
        for row in meal_rows
    ]
    cuisines = list(session.scalars(select(Cuisine.code)))
    features = build_feature_matrix(meals, cuisines)
    _cache.clear()
    _cache[key] = features
    return features
