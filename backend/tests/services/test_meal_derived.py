"""meal_allergens and DERIVED meal_tags (§10.4, §10.5, rule R1) on the recomputed F.1 slice."""

from __future__ import annotations

from typing import Any

import pytest
from sqlalchemy import delete, insert, select, update
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    DietaryTag,
    FoodNutrient,
    Ingredient,
    IngredientAllergen,
    IngredientTag,
    Meal,
    MealAllergen,
    MealIngredient,
    MealNutrient,
    MealTag,
    Nutrient,
)
from app.services.meal_derived import TagRuleError, recompute_meal_derived
from app.services.recompute_meals import (
    MealRecompute,
    format_results,
    recompute_active_meals,
    recompute_meal,
)
from app.services.tag_rules import TAG_RULES_VERSION, THRESHOLD_TAGS
from tests.services.conftest import NOW, clear_derived_meal_data, meal_id


def _tags(session: Session, source: str | None = None) -> dict[str, set[str]]:
    query = (
        select(Meal.ref_external, DietaryTag.code)
        .join(MealTag, MealTag.meal_id == Meal.meal_id)
        .join(DietaryTag, DietaryTag.tag_id == MealTag.tag_id)
    )
    if source is not None:
        query = query.where(MealTag.source == source)
    result: dict[str, set[str]] = {}
    for ref, code in session.execute(query):
        result.setdefault(ref, set()).add(code)
    return result


def _allergens(session: Session, ref: str) -> set[str]:
    return set(
        session.execute(
            select(Allergen.name_en)
            .join(MealAllergen, MealAllergen.allergen_id == Allergen.allergen_id)
            .where(MealAllergen.meal_id == meal_id(session, ref))
        ).scalars()
    )


def _snapshot(session: Session) -> dict[str, list[Any]]:
    return {
        name: sorted(session.execute(select(model.__table__)).all())
        for name, model in (
            ("meal_nutrients", MealNutrient),
            ("meal_allergens", MealAllergen),
            ("meal_tags", MealTag),
        )
    }


def _tag_id(session: Session, code: str) -> int:
    return session.execute(select(DietaryTag.tag_id).where(DietaryTag.code == code)).scalar_one()


def _ingredient_id(session: Session, name_en: str) -> int:
    return session.execute(
        select(Ingredient.ingredient_id).where(Ingredient.canonical_name == name_en)
    ).scalar_one()


@pytest.mark.usefixtures("recomputed")
def test_expected_derived_tags_on_the_slice(slice_session: Session) -> None:
    derived = _tags(slice_session, "DERIVED")
    assert "high_sodium" in derived["F1-S06"]
    assert "high_sugar" in derived["F1-S01"]
    assert "added_sugar" in derived["F1-B07"]
    assert "added_sugar" in derived["F1-S02"]


@pytest.mark.usefixtures("recomputed")
def test_threshold_tags_follow_meal_amount_per_100g(slice_session: Session) -> None:
    per_100g = {
        (ref, code): amount
        for ref, code, amount in slice_session.execute(
            select(Meal.ref_external, Nutrient.code, MealNutrient.amount_per_100g)
            .join(MealNutrient, MealNutrient.meal_id == Meal.meal_id)
            .join(Nutrient, Nutrient.nutrient_id == MealNutrient.nutrient_id)
        )
    }
    derived = _tags(slice_session, "DERIVED")
    refs = set(slice_session.execute(select(Meal.ref_external)).scalars())
    assert len(refs) == 35
    tagged = set()
    for ref in refs:
        for tag, (nutrient, threshold) in THRESHOLD_TAGS.items():
            expected = per_100g[(ref, nutrient)] > threshold
            assert (tag in derived.get(ref, set())) == expected, (ref, tag)
            if expected:
                tagged.add((ref, tag))
    assert tagged == {("F1-S06", "high_sodium"), ("F1-S01", "high_sugar")}


@pytest.mark.usefixtures("recomputed")
def test_presence_tags_are_the_union_of_condition_ingredient_tags(slice_session: Session) -> None:
    with_tag = set(
        slice_session.execute(
            select(Meal.ref_external)
            .join(MealIngredient, MealIngredient.meal_id == Meal.meal_id)
            .join(IngredientTag, IngredientTag.ingredient_id == MealIngredient.ingredient_id)
            .join(DietaryTag, DietaryTag.tag_id == IngredientTag.tag_id)
            .where(DietaryTag.code == "added_sugar")
        ).scalars()
    )
    derived = _tags(slice_session, "DERIVED")
    assert {ref for ref, tags in derived.items() if "added_sugar" in tags} == with_tag
    assert {"F1-B07", "F1-S02"} <= with_tag


def test_dietary_ingredient_tags_are_not_unioned(slice_session: Session) -> None:
    slice_session.execute(
        insert(IngredientTag).values(
            ingredient_id=_ingredient_id(slice_session, "Honey"),
            tag_id=_tag_id(slice_session, "vegetarian"),
        )
    )
    recompute_active_meals(slice_session, NOW)
    assert all("vegetarian" not in tags for tags in _tags(slice_session, "DERIVED").values())


@pytest.mark.usefixtures("recomputed")
def test_meal_allergens(slice_session: Session) -> None:
    assert _allergens(slice_session, "F1-D04") == {"Gluten"}
    assert _allergens(slice_session, "F1-S04") == {"Sesame"}
    assert _allergens(slice_session, "F1-B08") == {"Gluten", "Peanut"}
    # #75: the egg in bazeen is optional and still counts.
    assert _allergens(slice_session, "F1-L03") == {"Gluten", "Egg"}
    for ref in slice_session.execute(select(Meal.ref_external)).scalars():
        union = set(
            slice_session.execute(
                select(Allergen.name_en)
                .join(IngredientAllergen, IngredientAllergen.allergen_id == Allergen.allergen_id)
                .join(
                    MealIngredient,
                    MealIngredient.ingredient_id == IngredientAllergen.ingredient_id,
                )
                .where(MealIngredient.meal_id == meal_id(slice_session, ref))
            ).scalars()
        )
        assert _allergens(slice_session, ref) == union, ref


def test_manual_tags_survive_and_recompute_is_idempotent(slice_session: Session) -> None:
    manual = _tags(slice_session, "MANUAL")
    assert sum(len(t) for t in manual.values()) == 77
    clear_derived_meal_data(slice_session)

    first = recompute_active_meals(slice_session, NOW)
    after_first = _snapshot(slice_session)
    second = recompute_active_meals(slice_session, NOW.replace(hour=12))

    assert _tags(slice_session, "MANUAL") == manual
    assert _snapshot(slice_session) == after_first
    assert any(r.changed for r in first)
    assert not any(r.changed for r in second)
    assert format_results(second).endswith("No changes.")


def test_manual_row_for_a_derived_tag_becomes_derived(slice_session: Session) -> None:
    s06 = meal_id(slice_session, "F1-S06")
    high_sodium = _tag_id(slice_session, "high_sodium")
    slice_session.execute(
        update(MealTag)
        .where(MealTag.meal_id == s06, MealTag.tag_id == high_sodium)
        .values(source="MANUAL", rule_version=None)
    )
    _, derived = recompute_meal(slice_session, s06, NOW)

    assert derived.replaced_manual_tags == ("high_sodium",)
    rows = slice_session.execute(
        select(MealTag.source, MealTag.rule_version).where(
            MealTag.meal_id == s06, MealTag.tag_id == high_sodium
        )
    ).all()
    assert [tuple(row) for row in rows] == [("DERIVED", TAG_RULES_VERSION)]


def test_rule_version_on_derived_rows_only(slice_session: Session) -> None:
    rows = slice_session.execute(select(MealTag.source, MealTag.rule_version)).all()
    versions: dict[str, set[str | None]] = {}
    for source, version in rows:
        versions.setdefault(source, set()).add(version)
    assert versions == {"DERIVED": {TAG_RULES_VERSION}, "MANUAL": {None}}


def test_derived_row_without_rule_version_is_updated(slice_session: Session) -> None:
    s06 = meal_id(slice_session, "F1-S06")
    slice_session.execute(
        update(MealTag)
        .where(MealTag.meal_id == s06, MealTag.source == "DERIVED")
        .values(rule_version=None)
    )
    derived = recompute_meal_derived(slice_session, s06)
    assert derived.tag_changes.updated == len(derived.derived_tags) > 0
    assert derived.replaced_manual_tags == ()
    versions = slice_session.execute(
        select(MealTag.rule_version).where(MealTag.meal_id == s06, MealTag.source == "DERIVED")
    ).scalars()
    assert set(versions) == {TAG_RULES_VERSION}


def test_stale_derived_tags_are_removed(
    slice_session: Session, recomputed: list[MealRecompute]
) -> None:
    b07 = meal_id(slice_session, "F1-B07")
    slice_session.execute(
        delete(IngredientTag).where(
            IngredientTag.ingredient_id == _ingredient_id(slice_session, "Honey")
        )
    )
    derived = recompute_meal_derived(slice_session, b07)
    assert derived.derived_tags == ()
    assert derived.tag_changes.deleted == 1
    assert "F1-B07" not in _tags(slice_session, "DERIVED")


def test_unknown_nutrient_does_not_derive_the_threshold_tag(slice_session: Session) -> None:
    s06 = meal_id(slice_session, "F1-S06")
    sodium = select(Nutrient.nutrient_id).where(Nutrient.code == "sodium").scalar_subquery()
    food = select(MealIngredient.food_id).where(MealIngredient.meal_id == s06).limit(1)
    slice_session.execute(
        delete(FoodNutrient).where(
            FoodNutrient.nutrient_id == sodium, FoodNutrient.food_id == food.scalar_subquery()
        )
    )
    nutrition, derived = recompute_meal(slice_session, s06, NOW)

    assert nutrition.missing_mandatory == ("sodium",)
    assert derived.unknown_threshold_tags == ("high_sodium",)
    assert "high_sodium" not in derived.derived_tags


def test_threshold_tag_in_ingredient_tags_raises(slice_session: Session) -> None:
    slice_session.execute(
        insert(IngredientTag).values(
            ingredient_id=_ingredient_id(slice_session, "Honey"),
            tag_id=_tag_id(slice_session, "high_sugar"),
        )
    )
    with pytest.raises(TagRuleError, match="must not be in ingredient_tags"):
        recompute_meal_derived(slice_session, meal_id(slice_session, "F1-S02"))
