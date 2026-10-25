"""Hybrid LinUCB (#285): Li, Chu, Langford, Schapire, WWW 2010, Algorithm 2.

The paper keeps one model per arm (article). Here the arm-specific part is per user, and both
feature vectors are the meal vector: z = x = mf_v1. The expected reward of meal x for user u is

    r = z.beta + x.theta_u

beta is shared by every user (what people accept in general) and theta_u is the user's own
deviation. The update keeps the exact joint ridge solution of that model (penalty lambda on
beta and on every theta_u). Linear systems are solved with numpy.linalg.solve; the paper's
formulas are written with inverses, and A^-1 v is always computed as solve(A, v).

DisjointLinUCB is Algorithm 1 with one ridge model per user and no shared part; the simulation
compares both.
"""

from __future__ import annotations

from collections.abc import Hashable, Sequence
from dataclasses import dataclass, field

import numpy as np

from app.ml.config import DEFAULT_ALPHA, MAX_LEARNED_BONUS, RIDGE_LAMBDA
from app.ml.features import FloatMatrix, FloatVector, MealFeatureMatrix


@dataclass
class _UserPart:
    a: FloatMatrix  # A_u, d x d
    b_cross: FloatMatrix  # B_u, d x k
    b: FloatVector  # b_u, d


@dataclass
class HybridLinUCB:
    d: int
    alpha: float = DEFAULT_ALPHA
    ridge: float = RIDGE_LAMBDA
    a0: FloatMatrix = field(init=False)
    b0: FloatVector = field(init=False)
    users: dict[Hashable, _UserPart] = field(init=False, default_factory=dict)
    observations: int = field(init=False, default=0)

    def __post_init__(self) -> None:
        self.a0 = self.ridge * np.eye(self.d)
        self.b0 = np.zeros(self.d)

    def _user(self, user: Hashable) -> _UserPart:
        part = self.users.get(user)
        if part is None:
            part = _UserPart(
                a=self.ridge * np.eye(self.d),
                b_cross=np.zeros((self.d, self.d)),
                b=np.zeros(self.d),
            )
            self.users[user] = part
        return part

    def coefficients(self, user: Hashable) -> tuple[FloatVector, FloatVector]:
        """(beta, theta_u) of the current ridge solution."""
        beta = np.linalg.solve(self.a0, self.b0)
        part = self.users.get(user)
        if part is None:
            return beta, np.zeros(self.d)
        theta = np.linalg.solve(part.a, part.b - part.b_cross @ beta)
        return beta, theta

    def score(self, user: Hashable, x: FloatMatrix) -> tuple[FloatVector, FloatVector]:
        """(mean, ucb) for each row of x, without creating state for an unknown user."""
        x = np.atleast_2d(x)
        beta, theta = self.coefficients(user)
        mean = x @ beta + x @ theta
        part = self.users.get(user)
        z_t = x.T
        a0_inv_z = np.linalg.solve(self.a0, z_t)
        width = np.einsum("ij,ij->j", z_t, a0_inv_z)
        if part is None:
            width += np.einsum("ij,ij->j", z_t, z_t) / self.ridge
        else:
            au_inv_x = np.linalg.solve(part.a, z_t)
            bt_au_inv_x = part.b_cross.T @ au_inv_x
            width -= 2.0 * np.einsum("ij,ij->j", a0_inv_z, bt_au_inv_x)
            width += np.einsum("ij,ij->j", z_t, au_inv_x)
            width += np.einsum("ij,ij->j", bt_au_inv_x, np.linalg.solve(self.a0, bt_au_inv_x))
        ucb = mean + self.alpha * np.sqrt(np.maximum(width, 0.0))
        return mean, ucb

    def update(self, user: Hashable, x: FloatVector, reward: float, weight: float = 1.0) -> None:
        """Algorithm 2, lines 17-23. weight scales the observation (cold-start pseudo-rows)."""
        if weight <= 0:
            raise ValueError("weight must be positive")
        scale = float(np.sqrt(weight))
        x = scale * np.asarray(x, dtype=np.float64)
        r = scale * reward
        part = self._user(user)
        # One solve gives A_u^-1 [B_u | b_u]: the last column is A_u^-1 b_u.
        solved = np.linalg.solve(part.a, np.column_stack([part.b_cross, part.b]))
        self.a0 += part.b_cross.T @ solved[:, :-1]
        self.b0 += part.b_cross.T @ solved[:, -1]
        xx = np.outer(x, x)
        part.a += xx
        part.b_cross += xx
        part.b += r * x
        solved = np.linalg.solve(part.a, np.column_stack([part.b_cross, part.b]))
        self.a0 += xx - part.b_cross.T @ solved[:, :-1]
        self.b0 += r * x - part.b_cross.T @ solved[:, -1]
        self.observations += 1


@dataclass
class DisjointLinUCB:
    """Algorithm 1 with one ridge model per user (no shared part)."""

    d: int
    alpha: float = DEFAULT_ALPHA
    ridge: float = RIDGE_LAMBDA
    users: dict[Hashable, tuple[FloatMatrix, FloatVector]] = field(default_factory=dict)

    def _user(self, user: Hashable) -> tuple[FloatMatrix, FloatVector]:
        found = self.users.get(user)
        if found is None:
            found = (self.ridge * np.eye(self.d), np.zeros(self.d))
            self.users[user] = found
        return found

    def theta(self, user: Hashable) -> FloatVector:
        found = self.users.get(user)
        if found is None:
            return np.zeros(self.d)
        return np.linalg.solve(found[0], found[1])

    def score(self, user: Hashable, x: FloatMatrix) -> tuple[FloatVector, FloatVector]:
        x = np.atleast_2d(x)
        a, b = self.users.get(user) or (self.ridge * np.eye(self.d), np.zeros(self.d))
        mean = x @ np.linalg.solve(a, b)
        width = np.einsum("ij,ij->j", x.T, np.linalg.solve(a, x.T))
        return mean, mean + self.alpha * np.sqrt(np.maximum(width, 0.0))

    def update(self, user: Hashable, x: FloatVector, reward: float, weight: float = 1.0) -> None:
        a, b = self._user(user)
        a += weight * np.outer(x, x)
        b += weight * reward * np.asarray(x, dtype=np.float64)


@dataclass(frozen=True)
class RankedMeal:
    meal_id: int
    mean: float
    ucb: float


@dataclass(frozen=True)
class LearnedScorer:
    """What L.2 calls: a ranking of already-safe meals and an integer objective bonus."""

    model: HybridLinUCB
    features: MealFeatureMatrix

    def rank(self, user_id: int, meal_ids: Sequence[int]) -> list[RankedMeal]:
        """Highest ucb first, then lowest meal_id. Meals without features are left out."""
        known = sorted({meal_id for meal_id in meal_ids if meal_id in self.features})
        if not known:
            return []
        mean, ucb = self.model.score(user_id, self.features.rows(known))
        ranked = [
            RankedMeal(meal_id, float(m), float(u))
            for meal_id, m, u in zip(known, mean, ucb, strict=True)
        ]
        return sorted(ranked, key=lambda meal: (-meal.ucb, meal.meal_id))

    @staticmethod
    def bounded_bonus(ucb: float) -> int:
        """Linear map of ucb clipped to the reward range [-1, 1] onto [0, MAX_LEARNED_BONUS].

        -1 (sure rejection) gives 0, 0 (no information) gives half, and 1 or more gives the
        maximum. The cap keeps the learned part from outweighing the nutrition terms (#283).
        """
        clipped = min(max(ucb, -1.0), 1.0)
        return round((clipped + 1.0) / 2.0 * MAX_LEARNED_BONUS)
