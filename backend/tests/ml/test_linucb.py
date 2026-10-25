"""Hybrid and disjoint LinUCB (#285) against closed-form ridge solutions."""

from __future__ import annotations

import numpy as np
import pytest

from app.ml.config import MAX_LEARNED_BONUS
from app.ml.features import MealFeatureMatrix
from app.ml.linucb import DisjointLinUCB, HybridLinUCB, LearnedScorer

D = 4


def _data(n: int, seed: int) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    x = rng.normal(size=(n, D))
    return x, rng.normal(size=n)


def test_disjoint_equals_closed_form_ridge() -> None:
    x, r = _data(12, 1)
    model = DisjointLinUCB(D, ridge=1.0)
    for row, reward in zip(x, r, strict=True):
        model.update("u", row, float(reward))
    expected = np.linalg.solve(np.eye(D) + x.T @ x, x.T @ r)
    assert np.allclose(model.theta("u"), expected)


def test_hybrid_equals_joint_ridge_over_users() -> None:
    """beta and theta_u minimise sum (r - x.beta - x.theta_u)^2 + |beta|^2 + sum |theta_u|^2."""
    x, r = _data(15, 2)
    users = [0, 1, 2] * 5
    weights = np.where(np.arange(15) % 4 == 0, 0.3, 1.0)
    model = HybridLinUCB(D, ridge=1.0)
    for row, reward, user, weight in zip(x, r, users, weights, strict=True):
        model.update(user, row, float(reward), weight=float(weight))

    design = np.zeros((15, D * 4))
    for i, user in enumerate(users):
        design[i, :D] = x[i]
        design[i, D * (1 + user) : D * (2 + user)] = x[i]
    w = np.diag(weights)
    solution = np.linalg.solve(np.eye(D * 4) + design.T @ w @ design, design.T @ w @ r)
    for user in range(3):
        beta, theta = model.coefficients(user)
        assert np.allclose(beta, solution[:D])
        assert np.allclose(theta, solution[D * (1 + user) : D * (2 + user)])
    assert model.observations == 15


def test_ucb_width_shrinks_as_an_arm_is_observed() -> None:
    model = HybridLinUCB(D, alpha=1.0)
    x = np.array([[1.0, 0.0, 0.0, 1.0]])
    widths = []
    for _ in range(4):
        mean, ucb = model.score(7, x)
        widths.append(float(ucb[0] - mean[0]))
        model.update(7, x[0], 1.0)
    assert widths == sorted(widths, reverse=True)
    assert widths[-1] < widths[0] / 2


def test_shared_part_learns_across_users() -> None:
    model = HybridLinUCB(D, alpha=0.0)
    liked = np.array([0.0, 1.0, 0.0, 1.0])
    for _ in range(10):
        model.update("first", liked, 1.0)
    mean, _ = model.score("second", liked[None, :])
    assert mean[0] > 0.3
    assert "second" not in model.users  # scoring never creates state


def test_alpha_zero_is_greedy() -> None:
    x, r = _data(6, 3)
    for model in (HybridLinUCB(D, alpha=0.0), DisjointLinUCB(D, alpha=0.0)):
        for row, reward in zip(x, r, strict=True):
            model.update("u", row, float(reward))
        mean, ucb = model.score("u", x)
        assert np.array_equal(mean, ucb)


def test_weight_must_be_positive() -> None:
    with pytest.raises(ValueError):
        HybridLinUCB(D).update("u", np.ones(D), 1.0, weight=0.0)


def test_scorer_ranks_and_bounds_the_bonus() -> None:
    matrix = np.array([[1.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 1.0], [0.0, 0.0, 1.0, 1.0]])
    features = MealFeatureMatrix(
        np.array([10, 20, 30], dtype=np.int64), matrix, ("a", "b", "c", "bias")
    )
    model = HybridLinUCB(D, alpha=0.0)
    for _ in range(5):
        model.update(1, matrix[1], 1.0)
        model.update(1, matrix[2], -1.0)
    ranked = LearnedScorer(model, features).rank(1, [30, 10, 20, 99])
    assert [meal.meal_id for meal in ranked] == [20, 10, 30]
    assert LearnedScorer.bounded_bonus(-5.0) == 0
    assert LearnedScorer.bounded_bonus(0.0) == MAX_LEARNED_BONUS // 2
    assert LearnedScorer.bounded_bonus(3.0) == MAX_LEARNED_BONUS
    bonuses = [LearnedScorer.bounded_bonus(meal.ucb) for meal in ranked]
    assert bonuses == sorted(bonuses, reverse=True)
