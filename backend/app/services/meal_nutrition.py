"""calc_v1: meal nutrients from ingredient grams and food nutrients per 100 g (§10.3).

Missing ≠ zero (§9.8): a nutrient is unknown for a meal when any ingredient has no food or its
food has no food_nutrients row for it; an unknown nutrient gets no meal_nutrients row.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import delete, exists, func, insert, select, update
from sqlalchemy.orm import Session

from app.db.models import FoodNutrient, Meal, MealIngredient, MealNutrient, Nutrient
from app.services.common import MealNotFoundError, RowChanges, round_half_up, to_decimal

COMPUTATION_VERSION = "calc_v1"
STORED_SCALE = 3  # meal_nutrients amounts are NUMERIC(12,3)


@dataclass(frozen=True)
class NutrientAmount:
    per_serving: Decimal
    per_100g: Decimal


@dataclass(frozen=True)
class MealNutritionResult:
    meal_id: int
    amounts: Mapping[str, NutrientAmount]
    unknown: tuple[str, ...]
    missing_mandatory: tuple[str, ...]
    unmapped_positions: tuple[int, ...]
    changes: RowChanges

    @property
    def is_complete(self) -> bool:
        return not self.missing_mandatory


@dataclass(frozen=True)
class _Ingredient:
    position: int
    food_id: int | None
    grams: Decimal


def _meal_total(
    ingredients: Sequence[_Ingredient],
    amounts: Mapping[tuple[int, int], Decimal],
    nutrient_id: int,
) -> Decimal | None:
    if not ingredients:
        return None
    total = Decimal(0)
    for ingredient in ingredients:
        if ingredient.food_id is None:
            return None
        amount = amounts.get((ingredient.food_id, nutrient_id))
        if amount is None:
            return None
        total += ingredient.grams / 100 * amount
    return total


def compute_meal_nutrients(session: Session, meal_id: int, now: datetime) -> MealNutritionResult:
    meal = session.execute(
        select(Meal.servings, Meal.total_grams).where(Meal.meal_id == meal_id)
    ).one_or_none()
    if meal is None:
        raise MealNotFoundError(f"meal {meal_id} does not exist")
    servings = Decimal(meal.servings)
    total_grams = to_decimal(meal.total_grams)

    ingredients = [
        _Ingredient(row.position, row.food_id, to_decimal(row.grams))
        for row in session.execute(
            select(MealIngredient.position, MealIngredient.food_id, MealIngredient.grams)
            .where(MealIngredient.meal_id == meal_id)
            .order_by(MealIngredient.position)
        )
    ]
    food_ids = {i.food_id for i in ingredients if i.food_id is not None}
    amounts = {
        (row.food_id, row.nutrient_id): to_decimal(row.amount_per_100g)
        for row in session.execute(
            select(
                FoodNutrient.food_id, FoodNutrient.nutrient_id, FoodNutrient.amount_per_100g
            ).where(FoodNutrient.food_id.in_(food_ids))
        )
    }
    nutrients = session.execute(
        select(Nutrient.nutrient_id, Nutrient.code, Nutrient.is_mandatory).order_by(
            Nutrient.nutrient_id
        )
    ).all()

    computed: dict[int, NutrientAmount] = {}
    by_code: dict[str, NutrientAmount] = {}
    unknown: list[str] = []
    missing_mandatory: list[str] = []
    for nutrient in nutrients:
        total = _meal_total(ingredients, amounts, nutrient.nutrient_id)
        if total is None:
            unknown.append(nutrient.code)
            if nutrient.is_mandatory:
                missing_mandatory.append(nutrient.code)
            continue
        amount = NutrientAmount(per_serving=total / servings, per_100g=total / total_grams * 100)
        computed[nutrient.nutrient_id] = amount
        by_code[nutrient.code] = amount

    return MealNutritionResult(
        meal_id=meal_id,
        amounts=by_code,
        unknown=tuple(unknown),
        missing_mandatory=tuple(missing_mandatory),
        unmapped_positions=tuple(i.position for i in ingredients if i.food_id is None),
        changes=_replace_meal_nutrients(session, meal_id, computed, now),
    )


def _replace_meal_nutrients(
    session: Session, meal_id: int, computed: Mapping[int, NutrientAmount], now: datetime
) -> RowChanges:
    """Diff against the stored rows; a row whose stored value would not change is left as is."""
    changes = RowChanges()
    existing = {
        row.nutrient_id: row
        for row in session.execute(
            select(
                MealNutrient.nutrient_id,
                MealNutrient.amount_per_serving,
                MealNutrient.amount_per_100g,
                MealNutrient.computation_version,
            ).where(MealNutrient.meal_id == meal_id)
        )
    }
    inserts: list[dict[str, Any]] = []
    for nutrient_id, amount in computed.items():
        values = {
            "amount_per_serving": amount.per_serving,
            "amount_per_100g": amount.per_100g,
            "computed_at": now,
            "computation_version": COMPUTATION_VERSION,
        }
        row = existing.pop(nutrient_id, None)
        if row is None:
            inserts.append({"meal_id": meal_id, "nutrient_id": nutrient_id, **values})
            changes.inserted += 1
        elif (
            to_decimal(row.amount_per_serving) == round_half_up(amount.per_serving, STORED_SCALE)
            and to_decimal(row.amount_per_100g) == round_half_up(amount.per_100g, STORED_SCALE)
            and row.computation_version == COMPUTATION_VERSION
        ):
            changes.unchanged += 1
        else:
            session.execute(
                update(MealNutrient)
                .where(MealNutrient.meal_id == meal_id, MealNutrient.nutrient_id == nutrient_id)
                .values(**values)
            )
            changes.updated += 1
    if existing:
        session.execute(
            delete(MealNutrient).where(
                MealNutrient.meal_id == meal_id, MealNutrient.nutrient_id.in_(list(existing))
            )
        )
        changes.deleted = len(existing)
    if inserts:
        session.execute(insert(MealNutrient), inserts)
    return changes


def is_meal_nutritionally_complete(session: Session, meal_id: int) -> bool:
    """True iff the meal has a meal_nutrients row for every mandatory nutrient (§10.3)."""
    has_row = exists().where(
        MealNutrient.meal_id == meal_id, MealNutrient.nutrient_id == Nutrient.nutrient_id
    )
    missing = session.execute(
        select(func.count()).select_from(Nutrient).where(Nutrient.is_mandatory, ~has_row)
    ).scalar_one()
    return missing == 0
