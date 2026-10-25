"""mf_v1 meal features (#284)."""

from __future__ import annotations

from decimal import Decimal

import numpy as np
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import Meal
from app.ml.features import (
    BIAS,
    FEATURE_VERSION,
    SLOT_TAGS,
    MealRaw,
    build_feature_matrix,
    build_meal_features,
)


def _meal(meal_id: int, **overrides: object) -> MealRaw:
    values: dict[str, object] = {
        "meal_id": meal_id,
        "per_serving": {
            "energy_kcal": Decimal(400),
            "protein": Decimal(20),
            "carbohydrate": Decimal(50),
            "total_fat": Decimal(10),
            "fiber": Decimal(meal_id),
            "sodium": Decimal(100 * meal_id),
            "sugars": Decimal(5),
        },
        "cuisine": "LIBYAN",
        "dish_form": "PLATE",
        "tags": frozenset({"vegan", "lunch_suitable"}),
        **overrides,
    }
    return MealRaw(**values)  # type: ignore[arg-type]


MEALS = [
    _meal(3),
    _meal(1, cuisine="LEVANTINE", dish_form=None, tags=frozenset({"breakfast_suitable"})),
    _meal(2, cuisine=None, tags=frozenset({"high_sodium", "dinner_suitable"})),
]
CUISINES = ["LIBYAN", "LEVANTINE", "EGYPTIAN"]


def test_shape_names_and_bias() -> None:
    features = build_feature_matrix(MEALS, CUISINES)
    assert features.version == FEATURE_VERSION
    assert list(features.meal_ids) == [1, 2, 3]
    assert features.matrix.shape == (3, features.d)
    assert len(features.names) == features.d == 6 + 3 + 2 + 2 + 4 + 1
    assert features.names[:3] == (
        "energy_share:protein",
        "energy_share:carbohydrate",
        "energy_share:total_fat",
    )
    assert features.names[-1] == BIAS
    assert [n for n in features.names if n.startswith("tag:")] == ["tag:high_sodium", "tag:vegan"]
    assert [n for n in features.names if n.startswith("slot:")] == [f"slot:{s}" for s in SLOT_TAGS]
    assert np.all(features.matrix[:, -1] == 1.0)


def test_unit_rows_and_scaling_bounds() -> None:
    features = build_feature_matrix(MEALS, CUISINES)
    body = features.matrix[:, :-1]
    assert np.allclose(np.linalg.norm(body, axis=1), 1.0)
    assert not np.isnan(features.matrix).any()
    assert features.matrix.min() >= 0.0
    assert features.matrix.max() <= 1.0


def test_energy_shares_use_the_server_factors() -> None:
    one = build_feature_matrix([_meal(1)], CUISINES)
    shares = np.array([20 * 4 / 400, 50 * 4 / 400, 10 * 9 / 400])
    row = one.matrix[0, :-1]
    # Unit scaling keeps the ratios of the first three columns (the energy shares).
    assert np.allclose(row[:3] / row[:3].sum(), shares / shares.sum())


def test_min_max_scaling_over_the_catalog() -> None:
    meals = [_meal(i, cuisine=None, dish_form=None, tags=frozenset()) for i in (1, 2, 3)]
    features = build_feature_matrix(meals, [])
    fiber = features.names.index("per_serving:fiber")
    sugars = features.names.index("per_serving:sugars")
    assert features.matrix[0, fiber] == 0.0
    assert features.matrix[2, fiber] > features.matrix[1, fiber] > 0.0
    assert np.all(features.matrix[:, sugars] == 0.0)  # constant column


def test_missing_nutrient_is_zero_not_guessed() -> None:
    meal = _meal(1, per_serving={"energy_kcal": Decimal(300), "protein": Decimal(15)})
    features = build_feature_matrix([meal], CUISINES)
    carb = features.names.index("energy_share:carbohydrate")
    assert features.matrix[0, carb] == 0.0


def test_deterministic_and_order_independent() -> None:
    first = build_feature_matrix(MEALS, CUISINES)
    second = build_feature_matrix(list(reversed(MEALS)), list(reversed(CUISINES)))
    assert first.names == second.names
    assert np.array_equal(first.matrix, second.matrix)
    assert np.array_equal(first.rows([3, 1]), first.matrix[[2, 0]])


def test_catalog_features_from_the_database(slice_session: Session) -> None:
    features = build_meal_features(slice_session)
    active = slice_session.execute(
        select(func.count()).select_from(Meal).where(Meal.is_active.is_(True))
    ).scalar_one()
    assert len(features.meal_ids) == active > 0
    assert features.matrix.shape == (active, features.d)
    assert not np.isnan(features.matrix).any()
    assert np.all(features.matrix[:, -1] == 1.0)
    assert np.allclose(np.linalg.norm(features.matrix[:, :-1], axis=1), 1.0)
    assert build_meal_features(slice_session) is features
