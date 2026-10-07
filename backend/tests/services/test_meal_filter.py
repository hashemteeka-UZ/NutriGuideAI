"""Layer 1 hard filtering (§28.1) on the loaded F.1 slice: one test per rule, exact codes."""

from __future__ import annotations

from decimal import Decimal

import pytest
from sqlalchemy import delete, func, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    DietaryTag,
    Food,
    Ingredient,
    Meal,
    MealAllergen,
    MealIngredient,
    MealNutrient,
    MealTag,
    Nutrient,
)
from app.services.condition_limits import ResolvedLimits, resolve_condition_limits
from app.services.meal_filter import (
    SLOT_OCCASION,
    MealEvaluation,
    eligible_meal_ids,
    evaluate_meals,
)
from app.services.meal_nutrition import is_meal_nutritionally_complete
from tests.builders import (
    make_condition_nutrient_limit,
    make_health_condition,
    make_user_allergen_pref,
    make_user_health_condition,
    make_user_ingredient_pref,
    make_user_profile,
)
from tests.services.conftest import add_conditions, meal_id

D = Decimal
GARLIC_NDB = "11215"
# The assistant's offline estimate of the slice meals with carbohydrate > 60 g per serving.
ESTIMATED_HIGH_CARB = {
    "F1-B03",
    "F1-L01",
    "F1-L01-CH",
    "F1-L02",
    "F1-L02-CH",
    "F1-L03",
    "F1-L03-CH",
    "F1-L04",
    "F1-L08",
    "F1-D05",
}


def _limits(session: Session, user: int, target_kcal: int = 2000) -> ResolvedLimits:
    return resolve_condition_limits(session, user, target_kcal)


def _by_ref(evaluations: list[MealEvaluation]) -> dict[str, MealEvaluation]:
    return {str(e.ref_external): e for e in evaluations}


def _with_code(evaluations: list[MealEvaluation], code: str) -> set[str]:
    return {str(e.ref_external) for e in evaluations if code in e.exclusion_codes}


def _allergen_id(session: Session, name_en: str) -> int:
    return session.execute(
        select(Allergen.allergen_id).where(Allergen.name_en == name_en)
    ).scalar_one()


def _meals_with_allergen(session: Session, name_en: str) -> set[str]:
    return set(
        session.execute(
            select(Meal.ref_external)
            .join(MealAllergen, MealAllergen.meal_id == Meal.meal_id)
            .where(MealAllergen.allergen_id == _allergen_id(session, name_en))
        ).scalars()
    )


def _per_serving(session: Session, nutrient: str) -> dict[str, Decimal]:
    return {
        ref: D(str(amount))
        for ref, amount in session.execute(
            select(Meal.ref_external, MealNutrient.amount_per_serving)
            .join(MealNutrient, MealNutrient.meal_id == Meal.meal_id)
            .join(Nutrient, Nutrient.nutrient_id == MealNutrient.nutrient_id)
            .where(Nutrient.code == nutrient)
        ).tuples()
    }


def _garlic(session: Session) -> int:
    return session.execute(
        select(Ingredient.ingredient_id)
        .join(Food, Food.food_id == Ingredient.default_food_id)
        .where(Food.external_code == GARLIC_NDB)
    ).scalar_one()


def test_every_meal_is_returned(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    evaluations = evaluate_meals(slice_session, user, "LUNCH", _limits(slice_session, user))
    total = slice_session.execute(select(func.count()).select_from(Meal)).scalar_one()
    assert len(evaluations) == total == 35
    assert all(e.eligible == (not e.exclusion_codes) for e in evaluations)
    lunch = {
        ref
        for ref in slice_session.execute(
            select(Meal.ref_external)
            .join(MealTag, MealTag.meal_id == Meal.meal_id)
            .join(DietaryTag, DietaryTag.tag_id == MealTag.tag_id)
            .where(DietaryTag.code == SLOT_OCCASION["LUNCH"])
        ).scalars()
    }
    assert {str(e.ref_external) for e in evaluations if e.eligible} == lunch


@pytest.mark.parametrize("severity", ["AVOID", "SEVERE"])
def test_allergen_gluten(slice_session: Session, integrity_conn: Connection, severity: str) -> None:
    user = make_user_profile(integrity_conn)
    make_user_allergen_pref(
        integrity_conn,
        user_id=user,
        allergen_id=_allergen_id(slice_session, "Gluten"),
        severity=severity,
    )
    limits = _limits(slice_session, user)
    gluten = _meals_with_allergen(slice_session, "Gluten")
    assert gluten
    for slot in SLOT_OCCASION:
        evaluations = evaluate_meals(slice_session, user, slot, limits)
        assert _with_code(evaluations, "ALLERGEN:Gluten") == gluten
        assert not {str(e.ref_external) for e in evaluations if e.eligible} & gluten


def test_allergen_peanut(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    make_user_allergen_pref(
        integrity_conn, user_id=user, allergen_id=_allergen_id(slice_session, "Peanut")
    )
    evaluations = evaluate_meals(slice_session, user, "SNACK", _limits(slice_session, user))
    assert _with_code(evaluations, "ALLERGEN:Peanut") == {"F1-B08"}
    assert _meals_with_allergen(slice_session, "Peanut") == {"F1-B08"}


def test_excluded_ingredient_garlic(slice_session: Session, integrity_conn: Connection) -> None:
    garlic = _garlic(slice_session)
    with_garlic = set(
        slice_session.execute(
            select(Meal.ref_external)
            .join(MealIngredient, MealIngredient.meal_id == Meal.meal_id)
            .where(MealIngredient.ingredient_id == garlic)
        ).scalars()
    )
    assert with_garlic
    excluding = make_user_profile(integrity_conn)
    make_user_ingredient_pref(
        integrity_conn, user_id=excluding, ingredient_id=garlic, stance="EXCLUDE"
    )
    evaluations = evaluate_meals(
        slice_session, excluding, "DINNER", _limits(slice_session, excluding)
    )
    assert _with_code(evaluations, f"EXCLUDED_INGREDIENT:{garlic}") == with_garlic
    assert not [
        e
        for e in evaluations
        if any(c.startswith("EXCLUDED_INGREDIENT:") for c in e.exclusion_codes)
        and e.ref_external not in with_garlic
    ]


@pytest.mark.parametrize("stance", ["DISLIKE", "LIKE"])
def test_dislike_and_like_never_exclude(
    slice_session: Session, integrity_conn: Connection, stance: str
) -> None:
    plain = make_user_profile(integrity_conn)
    user = make_user_profile(integrity_conn)
    make_user_ingredient_pref(
        integrity_conn, user_id=user, ingredient_id=_garlic(slice_session), stance=stance
    )
    for slot in SLOT_OCCASION:
        assert evaluate_meals(slice_session, user, slot, _limits(slice_session, user)) == (
            evaluate_meals(slice_session, plain, slot, _limits(slice_session, plain))
        )


def test_diabetes_avoid_tag_and_carbohydrate_per_meal(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "DIABETES_T2")
    limits = _limits(slice_session, user)
    carbohydrate = _per_serving(slice_session, "carbohydrate")
    assert len(carbohydrate) == 35

    evaluations = evaluate_meals(slice_session, user, "LUNCH", limits)
    assert _with_code(evaluations, "AVOID_TAG:added_sugar") == {"F1-B07", "F1-S02"}
    high_carb = {ref for ref, amount in carbohydrate.items() if amount > 60}
    assert _with_code(evaluations, "MAX_PER_MEAL:carbohydrate") == high_carb
    assert high_carb == ESTIMATED_HIGH_CARB

    for multiplier in (D("0.5"), D("1.5"), D("2.0")):
        at_multiplier = evaluate_meals(slice_session, user, "LUNCH", limits, multiplier)
        assert _with_code(at_multiplier, "MAX_PER_MEAL:carbohydrate") == {
            ref for ref, amount in carbohydrate.items() if amount * multiplier > 60
        }


def test_percent_energy_per_meal_uses_the_meal_energy(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    condition = make_health_condition(integrity_conn, is_supported=True)
    saturated_id = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "saturated_fat")
    ).scalar_one()
    make_condition_nutrient_limit(
        integrity_conn,
        condition_id=condition,
        nutrient_id=saturated_id,
        limit_basis="PERCENT_ENERGY",
        max_per_day=None,
        max_per_meal=7,
    )
    make_user_health_condition(integrity_conn, user_id=user, condition_id=condition)
    saturated = _per_serving(slice_session, "saturated_fat")
    energy = _per_serving(slice_session, "energy_kcal")
    expected = {ref for ref in saturated if saturated[ref] * 9 / energy[ref] * 100 > 7}
    assert expected
    for target_kcal in (1200, 3000):
        limits = _limits(slice_session, user, target_kcal)
        for multiplier in (D("0.5"), D("2.0")):
            evaluations = evaluate_meals(slice_session, user, "DINNER", limits, multiplier)
            assert _with_code(evaluations, "MAX_PER_MEAL:saturated_fat") == expected


def test_slot_occasion(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    limits = _limits(slice_session, user)
    breakfast = _by_ref(evaluate_meals(slice_session, user, "BREAKFAST", limits))
    assert breakfast["F1-L03"].exclusion_codes == ["NO_OCCASION:BREAKFAST"]
    lunch = _by_ref(evaluate_meals(slice_session, user, "LUNCH", limits))
    assert lunch["F1-L03"].eligible
    snack = evaluate_meals(slice_session, user, "SNACK", limits)
    assert "F1-S05" in {e.ref_external for e in snack if e.eligible}


def test_inactive_meal(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    slice_session.execute(update(Meal).where(Meal.ref_external == "F1-L07").values(is_active=False))
    evaluations = _by_ref(
        evaluate_meals(slice_session, user, "LUNCH", _limits(slice_session, user))
    )
    assert evaluations["F1-L07"].exclusion_codes == ["INACTIVE"]
    assert not evaluations["F1-L07"].eligible
    assert eligible_meal_ids(slice_session, user, "LUNCH", _limits(slice_session, user)) == [
        e.meal_id for e in evaluations.values() if e.eligible
    ]


def test_incomplete_nutrients(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-D02")
    sodium = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "sodium", Nutrient.is_mandatory)
    ).scalar_one()
    slice_session.execute(
        delete(MealNutrient).where(MealNutrient.meal_id == meal, MealNutrient.nutrient_id == sodium)
    )
    assert not is_meal_nutritionally_complete(slice_session, meal)
    evaluations = _by_ref(
        evaluate_meals(slice_session, user, "DINNER", _limits(slice_session, user))
    )
    assert evaluations["F1-D02"].exclusion_codes == ["INCOMPLETE_NUTRIENTS"]
    others = [e for ref, e in evaluations.items() if ref != "F1-D02"]
    assert not [e for e in others if "INCOMPLETE_NUTRIENTS" in e.exclusion_codes]


def test_incomplete_meal_with_a_per_meal_limit_on_the_missing_nutrient(
    slice_session: Session, integrity_conn: Connection
) -> None:
    """Missing ≠ zero: an unknown amount cannot be shown to respect a per-meal limit."""
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "DIABETES_T2")
    meal = meal_id(slice_session, "F1-D02")
    carbohydrate = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "carbohydrate")
    ).scalar_one()
    slice_session.execute(
        delete(MealNutrient).where(
            MealNutrient.meal_id == meal, MealNutrient.nutrient_id == carbohydrate
        )
    )
    evaluations = _by_ref(
        evaluate_meals(slice_session, user, "DINNER", _limits(slice_session, user))
    )
    assert evaluations["F1-D02"].exclusion_codes == [
        "INCOMPLETE_NUTRIENTS",
        "MAX_PER_MEAL:carbohydrate",
    ]


def test_all_failing_rules_are_listed(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "DIABETES_T2")
    for allergen in ("Gluten", "Egg"):
        make_user_allergen_pref(
            integrity_conn, user_id=user, allergen_id=_allergen_id(slice_session, allergen)
        )
    l03 = meal_id(slice_session, "F1-L03")
    first_ingredient = slice_session.execute(
        select(MealIngredient.ingredient_id).where(
            MealIngredient.meal_id == l03, MealIngredient.position == 1
        )
    ).scalar_one()
    make_user_ingredient_pref(
        integrity_conn, user_id=user, ingredient_id=first_ingredient, stance="EXCLUDE"
    )
    slice_session.execute(update(Meal).where(Meal.meal_id == l03).values(is_active=False))

    evaluations = _by_ref(
        evaluate_meals(slice_session, user, "BREAKFAST", _limits(slice_session, user))
    )
    assert evaluations["F1-L03"].exclusion_codes == [
        "INACTIVE",
        "ALLERGEN:Egg",
        "ALLERGEN:Gluten",
        f"EXCLUDED_INGREDIENT:{first_ingredient}",
        "MAX_PER_MEAL:carbohydrate",
        "NO_OCCASION:BREAKFAST",
    ]
    assert evaluations["F1-B07"].exclusion_codes == ["ALLERGEN:Gluten", "AVOID_TAG:added_sugar"]
