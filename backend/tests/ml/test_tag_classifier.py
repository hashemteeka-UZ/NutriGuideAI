"""Slot tag classifier (#297-#300) on the F.1 slice."""

from __future__ import annotations

import numpy as np
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import DietaryTag, Meal, MealTag
from app.db.models.reference import TagGroup
from app.ml.tag_classifier import (
    TAG_FEATURE_VERSION,
    TARGET_TAGS,
    build_tag_dataset,
    clear_tag_cache,
    ingredient_shares,
    suggest_slot_tags,
)
from scripts.ml_tag_eval import MODELS, evaluate, review_candidates


def test_shapes_names_and_version(slice_session: Session) -> None:
    dataset = build_tag_dataset(slice_session)
    active = slice_session.execute(
        select(func.count()).select_from(Meal).where(Meal.is_active.is_(True))
    ).scalar_one()
    assert dataset.version == TAG_FEATURE_VERSION
    assert dataset.X.shape == (active, len(dataset.feature_names))
    assert dataset.Y.shape == (active, 4)
    assert dataset.target_names == tuple(TARGET_TAGS)
    assert "kcal_per_serving" in dataset.feature_names
    assert sum(n.startswith("ingredient:") for n in dataset.feature_names) == len(
        dataset.ingredient_codes
    )
    assert not np.isnan(dataset.X).any()
    assert set(np.unique(dataset.Y)) <= {0, 1}


def test_no_label_leaks_into_the_features(slice_session: Session) -> None:
    dataset = build_tag_dataset(slice_session)
    occasion = set(
        slice_session.scalars(
            select(DietaryTag.code).where(DietaryTag.tag_group == TagGroup.OCCASION)
        )
    )
    assert set(TARGET_TAGS) <= occasion
    for name in dataset.feature_names:
        assert not name.startswith("slot:")
        assert name != "bias"
        assert name.removeprefix("tag:") not in occasion
        assert not any(tag in name for tag in TARGET_TAGS)


def test_gram_shares() -> None:
    shares = ingredient_shares([(1, "A", 30), (1, "B", 70), (1, "A", 0), (2, "A", 50)])
    assert shares[1] == {"A": 0.3, "B": 0.7}
    assert sum(shares[1].values()) == 1.0
    assert shares[2] == {"A": 1.0}


def test_gram_share_rows_sum_to_at_most_one(slice_session: Session) -> None:
    dataset = build_tag_dataset(slice_session)
    columns = [i for i, n in enumerate(dataset.feature_names) if n.startswith("ingredient:")]
    sums = dataset.X[:, columns].sum(axis=1)
    assert np.all(sums <= 1.0 + 1e-9)
    assert np.all(sums >= 0.0)


def test_deterministic(slice_session: Session) -> None:
    first = build_tag_dataset(slice_session)
    second = build_tag_dataset(slice_session)
    assert first.feature_names == second.feature_names
    assert np.array_equal(first.X, second.X)
    assert np.array_equal(first.Y, second.Y)
    a = evaluate(first, outer_folds=2, repeats=1, inner_folds=2)
    b = evaluate(second, outer_folds=2, repeats=1, inner_folds=2)
    for name in MODELS:
        assert a.scores[name].macro == b.scores[name].macro


def test_small_evaluation_has_finite_metrics(slice_session: Session) -> None:
    dataset = build_tag_dataset(slice_session)
    evaluation = evaluate(dataset, outer_folds=2, repeats=1, inner_folds=2)
    assert evaluation.folds == 2
    for name in MODELS:
        scores = evaluation.scores[name]
        for values in (scores.micro, scores.macro, scores.hamming, scores.subset):
            assert len(values) == 2
            assert all(np.isfinite(v) and 0.0 <= v <= 1.0 for v in values)
        assert evaluation.oof[name].shape == dataset.Y.shape
    candidates = review_candidates(dataset, evaluation.oof[MODELS[-1]])
    assert all(c.tag in TARGET_TAGS for c in candidates)


def test_suggestions_are_probabilities_and_write_nothing(slice_session: Session) -> None:
    clear_tag_cache()
    before = slice_session.execute(select(func.count()).select_from(MealTag)).scalar_one()
    meal_id = int(build_tag_dataset(slice_session).meal_ids[0])
    suggestion = suggest_slot_tags(slice_session, meal_id)
    assert list(suggestion) == list(TARGET_TAGS)
    assert all(0.0 <= p <= 1.0 for p in suggestion.values())
    assert suggest_slot_tags(slice_session, meal_id) == suggestion  # cached, same answer
    after = slice_session.execute(select(func.count()).select_from(MealTag)).scalar_one()
    assert after == before
    clear_tag_cache()
