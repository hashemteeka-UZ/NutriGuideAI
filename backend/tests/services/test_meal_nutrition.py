"""calc_v1 (§10.3) on the F.1 slice; missing ≠ zero (§9.8)."""

from __future__ import annotations

import pytest
from sqlalchemy import delete, func, select, update
from sqlalchemy.orm import Session

from app.db.models import Food, FoodNutrient, MealIngredient, MealNutrient, Nutrient
from app.seed.f1_files import read_f1_files
from app.seed.f1_loader import DEFAULT_DATA_DIR
from app.services.common import MealNotFoundError
from app.services.meal_nutrition import (
    COMPUTATION_VERSION,
    compute_meal_nutrients,
    is_meal_nutritionally_complete,
)
from app.services.recompute_meals import MealRecompute
from tests.services.conftest import NOW, meal_id

FILES = read_f1_files(DEFAULT_DATA_DIR)
TOLERANCE = 0.001


def _stored(session: Session, meal: int) -> dict[str, tuple[float, float]]:
    rows = session.execute(
        select(Nutrient.code, MealNutrient.amount_per_serving, MealNutrient.amount_per_100g)
        .join(Nutrient, Nutrient.nutrient_id == MealNutrient.nutrient_id)
        .where(MealNutrient.meal_id == meal)
    )
    return {code: (serving, per_100g) for code, serving, per_100g in rows}


def _food_id(session: Session, ndb: str) -> int:
    return session.execute(
        select(Food.food_id).where(Food.external_source == "FDC", Food.external_code == ndb)
    ).scalar_one()


def test_f1_b03_matches_the_fdc_subset(slice_session: Session) -> None:
    meal = next(m for m in FILES.meals.meals if m.ref_external == "F1-B03")
    grams = {i.ndb_number: i.grams for i in meal.ingredients}
    assert grams == {"08120": 50, "01082": 200, "09087": 25, "02010": 1}
    assert meal.servings == 1
    total_grams = 276 * 0.95
    code_by_nbr = {n.source_code: n.code for n in FILES.seed.nutrients}
    expected: dict[str, float] = {}
    for row in FILES.subset:
        if row.ndb_number in grams:
            code = code_by_nbr[row.nutrient_nbr]
            expected[code] = (
                expected.get(code, 0.0) + grams[row.ndb_number] / 100 * row.amount_per_100g
            )
    assert len(expected) == len(FILES.seed.nutrients)

    b03 = meal_id(slice_session, "F1-B03")
    result = compute_meal_nutrients(slice_session, b03, NOW)
    stored = _stored(slice_session, b03)

    assert result.is_complete
    assert result.unknown == ()
    assert set(stored) == set(expected)
    for code, total in expected.items():
        per_serving, per_100g = stored[code]
        assert per_serving == pytest.approx(total / meal.servings, abs=TOLERANCE), code
        assert per_100g == pytest.approx(total / total_grams * 100, abs=TOLERANCE), code
        assert float(result.amounts[code].per_100g) == pytest.approx(per_100g, abs=TOLERANCE)
    versions = slice_session.execute(
        select(MealNutrient.computation_version, MealNutrient.computed_at).where(
            MealNutrient.meal_id == b03
        )
    ).all()
    assert set(versions) == {(COMPUTATION_VERSION, NOW)}


def test_missing_food_nutrient_row_makes_the_meal_nutrient_unknown(slice_session: Session) -> None:
    b03 = meal_id(slice_session, "F1-B03")
    assert compute_meal_nutrients(slice_session, b03, NOW).is_complete
    assert "sugars" in _stored(slice_session, b03)

    sugars_id = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "sugars")
    ).scalar_one()
    slice_session.execute(
        delete(FoodNutrient).where(
            FoodNutrient.food_id == _food_id(slice_session, "09087"),
            FoodNutrient.nutrient_id == sugars_id,
        )
    )
    result = compute_meal_nutrients(slice_session, b03, NOW)

    assert result.missing_mandatory == ("sugars",)
    assert result.unknown == ("sugars",)
    assert not result.is_complete
    assert result.changes.deleted == 1
    stored = _stored(slice_session, b03)
    assert "sugars" not in stored
    assert len(stored) == len(FILES.seed.nutrients) - 1
    assert not is_meal_nutritionally_complete(slice_session, b03)


def test_unmapped_ingredient_makes_every_nutrient_unknown(slice_session: Session) -> None:
    b03 = meal_id(slice_session, "F1-B03")
    slice_session.execute(
        update(MealIngredient)
        .where(MealIngredient.meal_id == b03, MealIngredient.position == 4)
        .values(food_id=None)
    )
    result = compute_meal_nutrients(slice_session, b03, NOW)

    assert result.unmapped_positions == (4,)
    assert len(result.unknown) == len(FILES.seed.nutrients)
    assert len(result.missing_mandatory) == 9
    assert _stored(slice_session, b03) == {}
    assert not is_meal_nutritionally_complete(slice_session, b03)


def test_all_slice_meals_are_complete_after_recompute(
    slice_session: Session, recomputed: list[MealRecompute]
) -> None:
    assert len(recomputed) == 30
    assert all(r.nutrition.is_complete for r in recomputed)
    assert all(is_meal_nutritionally_complete(slice_session, r.meal_id) for r in recomputed)
    rows = slice_session.execute(select(func.count()).select_from(MealNutrient)).scalar_one()
    assert rows == 30 * len(FILES.seed.nutrients)


def test_meal_without_rows_is_not_complete(slice_session: Session) -> None:
    assert not is_meal_nutritionally_complete(slice_session, meal_id(slice_session, "F1-B03"))


def test_recompute_keeps_unchanged_rows(slice_session: Session) -> None:
    b03 = meal_id(slice_session, "F1-B03")
    compute_meal_nutrients(slice_session, b03, NOW)
    before = slice_session.execute(
        select(MealNutrient.__table__).where(MealNutrient.meal_id == b03)
    ).all()
    later = NOW.replace(hour=10)
    again = compute_meal_nutrients(slice_session, b03, later)
    after = slice_session.execute(
        select(MealNutrient.__table__).where(MealNutrient.meal_id == b03)
    ).all()
    assert not again.changes.changed
    assert again.changes.unchanged == len(FILES.seed.nutrients)
    assert sorted(after) == sorted(before)


def test_unknown_meal_raises(session: Session) -> None:
    with pytest.raises(MealNotFoundError):
        compute_meal_nutrients(session, 999_999_999, NOW)
