"""Supervised meal-slot tag classifier tf_v1 (Step L.3, #297-#300).

The team labelled every catalog meal with its slot (occasion) tags. This module learns those
labels from the rest of the meal's data, to suggest tags for a new meal and to audit the
existing labels. It only suggests: nothing here writes meal_tags or any other table.

Targets (Y): the MANUAL breakfast_suitable, lunch_suitable, dinner_suitable and
snack_suitable rows of active meals.

Features (X), with no leakage of the targets:
- mf_v1 (#284) without its slot:* columns, its bias, and every tag:* column whose tag is in
  the OCCASION group (beverage, nuts_seeds_snack, ...): occasion tags are labels too;
- kcal per serving, min-max scaled over the active catalog;
- ingredient gram shares (an ingredient's grams / the meal's total ingredient grams) for the
  ingredient codes used by at least MIN_INGREDIENT_MEALS active meals.
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Final

import numpy as np
from numpy.typing import NDArray
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV, KFold
from sklearn.multiclass import OneVsRestClassifier
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import DietaryTag, Ingredient, Meal, MealIngredient, MealTag
from app.db.models.catalog import MealTagSource
from app.db.models.reference import TagGroup
from app.ml.features import BIAS, SLOT_TAGS, FloatMatrix, build_meal_features, catalog_key
from app.services.common import MealNotFoundError
from app.services.condition_limits import ENERGY_NUTRIENT
from app.services.meal_filter import load_meal_facts

TAG_FEATURE_VERSION: Final = "tf_v1"
TARGET_TAGS: Final = SLOT_TAGS  # breakfast, lunch, dinner, snack
MIN_INGREDIENT_MEALS: Final = 2
RANDOM_STATE: Final = 42
C_GRID: Final = (0.1, 1.0, 10.0)
INNER_FOLDS: Final = 3


@dataclass(frozen=True)
class TagDataset:
    meal_ids: NDArray[np.int64]
    X: FloatMatrix
    Y: NDArray[np.int64]
    feature_names: tuple[str, ...]
    target_names: tuple[str, ...]
    ingredient_codes: tuple[str, ...]
    refs: tuple[str, ...]
    names: tuple[str, ...]
    version: str = TAG_FEATURE_VERSION


def ingredient_shares(
    rows: Sequence[tuple[int, str, float]],
) -> dict[int, dict[str, float]]:
    """Per meal: ingredient code -> grams / the meal's total ingredient grams (sums to 1)."""
    grams: dict[int, dict[str, float]] = defaultdict(lambda: defaultdict(float))
    for meal_id, code, amount in rows:
        grams[meal_id][code] += float(amount)
    shares: dict[int, dict[str, float]] = {}
    for meal_id, by_code in grams.items():
        total = sum(by_code.values())
        shares[meal_id] = {code: g / total for code, g in by_code.items()} if total > 0 else {}
    return shares


def build_tag_dataset(session: Session) -> TagDataset:
    features = build_meal_features(session)
    occasion = set(
        session.scalars(select(DietaryTag.code).where(DietaryTag.tag_group == TagGroup.OCCASION))
    )
    keep = [
        index
        for index, name in enumerate(features.names)
        if not name.startswith("slot:")
        and name != BIAS
        and not (name.startswith("tag:") and name.removeprefix("tag:") in occasion)
    ]
    meal_ids = [int(m) for m in features.meal_ids]
    active = set(meal_ids)

    labels: dict[int, set[str]] = defaultdict(set)
    for meal_id, code in session.execute(
        select(MealTag.meal_id, DietaryTag.code)
        .join(DietaryTag, DietaryTag.tag_id == MealTag.tag_id)
        .where(MealTag.source == MealTagSource.MANUAL.value, DietaryTag.code.in_(TARGET_TAGS))
    ).tuples():
        labels[meal_id].add(code)

    facts = {fact.meal_id: fact for fact in load_meal_facts(session)}
    kcal = np.array(
        [float(facts[m].per_serving.get(ENERGY_NUTRIENT, 0)) for m in meal_ids], dtype=np.float64
    )
    span = float(kcal.max() - kcal.min()) if len(kcal) else 0.0
    kcal_scaled = (kcal - kcal.min()) / span if span > 0 else np.zeros_like(kcal)

    shares = ingredient_shares(
        [
            (row.meal_id, row.code, row.grams)
            for row in session.execute(
                select(MealIngredient.meal_id, Ingredient.code, MealIngredient.grams).join(
                    Ingredient, Ingredient.ingredient_id == MealIngredient.ingredient_id
                )
            )
            if row.meal_id in active
        ]
    )
    usage: dict[str, int] = defaultdict(int)
    for by_code in shares.values():
        for code in by_code:
            usage[code] += 1
    codes = sorted(code for code, count in usage.items() if count >= MIN_INGREDIENT_MEALS)
    share_matrix = np.array(
        [[shares.get(m, {}).get(code, 0.0) for code in codes] for m in meal_ids],
        dtype=np.float64,
    ).reshape(len(meal_ids), len(codes))

    X = np.hstack([features.matrix[:, keep], kcal_scaled[:, None], share_matrix])
    Y = np.array(
        [[int(tag in labels[m]) for tag in TARGET_TAGS] for m in meal_ids], dtype=np.int64
    ).reshape(len(meal_ids), len(TARGET_TAGS))
    meta = {
        row.meal_id: row
        for row in session.execute(select(Meal.meal_id, Meal.ref_external, Meal.name))
    }
    return TagDataset(
        meal_ids=np.array(meal_ids, dtype=np.int64),
        X=X,
        Y=Y,
        feature_names=(
            *(features.names[i] for i in keep),
            "kcal_per_serving",
            *(f"ingredient:{code}" for code in codes),
        ),
        target_names=tuple(TARGET_TAGS),
        ingredient_codes=tuple(codes),
        refs=tuple(meta[m].ref_external or "" for m in meal_ids),
        names=tuple(meta[m].name for m in meal_ids),
    )


def logistic_search(inner_folds: int = INNER_FOLDS) -> GridSearchCV:
    """One-vs-rest logistic regression; C chosen by an inner shuffled K-fold (macro-F1)."""
    model = OneVsRestClassifier(
        LogisticRegression(solver="liblinear", class_weight="balanced", random_state=RANDOM_STATE)
    )
    return GridSearchCV(
        model,
        {"estimator__C": list(C_GRID)},
        cv=KFold(n_splits=inner_folds, shuffle=True, random_state=RANDOM_STATE),
        scoring="f1_macro",
    )


def positive_probabilities(model: Any, X: FloatMatrix) -> FloatMatrix:
    """P(tag present) per column, for one-vs-rest models and multi-output forests alike."""
    raw = model.predict_proba(X)
    if isinstance(raw, list):
        columns = []
        for output_classes, probabilities in zip(model.classes_, raw, strict=True):
            classes = [int(c) for c in output_classes]
            columns.append(probabilities[:, classes.index(1)] if 1 in classes else np.zeros(len(X)))
        return np.column_stack(columns)
    return np.asarray(raw, dtype=np.float64)


@dataclass(frozen=True)
class _Fitted:
    model: GridSearchCV
    rows: dict[int, int]
    X: FloatMatrix


_cache: dict[tuple[object, ...], _Fitted] = {}


def clear_tag_cache() -> None:
    _cache.clear()


def suggest_slot_tags(session: Session, meal_id: int) -> dict[str, float]:
    """Probability of each slot tag for an active meal, from the model fit on the catalog.

    A suggestion only (#300): nothing is written, and the team decides. Cached in process per
    (catalog version, TAG_FEATURE_VERSION).
    """
    key = (catalog_key(session), TAG_FEATURE_VERSION)
    fitted = _cache.get(key)
    if fitted is None:
        dataset = build_tag_dataset(session)
        fitted = _Fitted(
            model=logistic_search().fit(dataset.X, dataset.Y),
            rows={int(m): index for index, m in enumerate(dataset.meal_ids)},
            X=dataset.X,
        )
        _cache.clear()
        _cache[key] = fitted
    if meal_id not in fitted.rows:
        raise MealNotFoundError(f"meal {meal_id} is not an active catalog meal")
    x = fitted.X[fitted.rows[meal_id]][None, :]
    probabilities = positive_probabilities(fitted.model, x)[0]
    return {tag: float(p) for tag, p in zip(TARGET_TAGS, probabilities, strict=True)}
