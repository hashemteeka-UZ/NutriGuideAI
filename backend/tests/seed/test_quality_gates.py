"""Quality gates G1-G9 on small in-memory fixtures: no database, not the real files."""

from __future__ import annotations

import copy
from typing import Any

import pytest

from app.seed.f1_files import F1Files, ReferenceSeed, SliceFoods, SliceMeals, SubsetRow
from app.seed.quality_gates import (
    gate_energy_consistency,
    gate_excluded_ingredients,
    gate_mandatory_nutrients,
    gate_optional_ingredients,
    gate_percent_energy_limits,
    gate_references,
    gate_tag_groups,
    gate_variant_groups,
    gate_weight_method,
    run_all_gates,
)

SEED: dict[str, Any] = {
    "seed_version": "test_seed",
    "categories_ar": {"0100": "الألبان والبيض"},
    "cuisines": [{"code": "GENERAL", "name_en": "General", "name_ar": "عام"}],
    "allergens": [{"code": "MILK", "name_en": "Milk", "name_ar": "الحليب"}],
    "dietary_tags": [
        {"code": "breakfast_suitable", "tag_group": "OCCASION", "name_en": "b", "name_ar": "ف"},
        {"code": "vegetarian", "tag_group": "DIETARY", "name_en": "v", "name_ar": "ن"},
        {"code": "high_sodium", "tag_group": "CONDITION", "name_en": "h", "name_ar": "ص"},
    ],
    "nutrients": [
        {
            "code": "energy_kcal",
            "source_code": "208",
            "name": "E",
            "unit": "kcal",
            "is_mandatory": True,
        },
        {"code": "protein", "source_code": "203", "name": "P", "unit": "g", "is_mandatory": True},
        {"code": "total_fat", "source_code": "204", "name": "F", "unit": "g", "is_mandatory": True},
        {
            "code": "carbohydrate",
            "source_code": "205",
            "name": "C",
            "unit": "g",
            "is_mandatory": True,
        },
        {"code": "fiber", "source_code": "291", "name": "Fi", "unit": "g", "is_mandatory": True},
        {
            "code": "saturated_fat",
            "source_code": "606",
            "name": "S",
            "unit": "g",
            "is_mandatory": False,
        },
        {"code": "sodium", "source_code": "307", "name": "Na", "unit": "mg", "is_mandatory": False},
    ],
    "health_conditions": [
        {
            "code": "HYPERTENSION",
            "name_en": "Hypertension",
            "name_ar": "ضغط",
            "is_supported": True,
            "fluid_goal_requires_clinician": False,
        }
    ],
    "condition_nutrient_limits": [
        {
            "condition": "HYPERTENSION",
            "nutrient": "sodium",
            "limit_basis": "ABSOLUTE",
            "max_per_day": 2000,
            "source_reference": "test",
        }
    ],
    "condition_tag_restrictions": [
        {
            "condition": "HYPERTENSION",
            "tag": "high_sodium",
            "restriction_type": "LIMIT",
            "max_servings_per_week": 3,
        }
    ],
    "excluded_keywords": ["pork", "ham"],
}

FOODS: dict[str, Any] = {
    "source": "test",
    "foods": [
        {
            "ndb_number": "01019",
            "sr_description": "Cheese, feta",
            "ingredient_en": "Feta cheese",
            "ingredient_ar": "جبن فيتا",
            "state": "as_purchased",
            "allergens": ["Milk"],
            "ingredient_tags": ["high_sodium"],
        }
    ],
}

MEALS: dict[str, Any] = {
    "dataset_version": "test_v0",
    "source": "test",
    "source_license": "test",
    "quality_tier": "SILVER",
    "default_lang": "ar",
    "meals": [
        {
            "ref_external": "T-01",
            "name_ar": "جبن",
            "name_en": "Cheese plate",
            "cuisine": "GENERAL",
            "servings": 1,
            "weight_method": "YIELD_FACTOR",
            "yield_factor": 0.9,
            "yield_factor_source": "test",
            "occasion_tags": ["breakfast_suitable"],
            "dietary_tags": ["vegetarian"],
            "reviewed_by": None,
            "ingredients": [{"ndb_number": "01019", "grams": 40}],
        }
    ],
}

# Feta: 4*14.21 + 4*(3.88 - 0) + 2*0 + 9*21.49 = 265.8 kcal vs 265 reported.
AMOUNTS = {"208": 265.0, "203": 14.21, "204": 21.49, "205": 3.88, "291": 0.0, "307": 1139.0}


def subset_rows(
    amounts: dict[str, float] = AMOUNTS,
    *,
    ndb: str = "01019",
    description: str = "Cheese, feta",
    category: str = "0100",
) -> list[SubsetRow]:
    return [
        SubsetRow(
            ndb_number=ndb,
            fdc_id=173420,
            description=description,
            food_category_code=category,
            food_category_description="Dairy and Egg Products",
            nutrient_nbr=nbr,
            amount_per_100g=amount,
        )
        for nbr, amount in amounts.items()
    ]


def make_files(
    *,
    seed: dict[str, Any] | None = None,
    foods: dict[str, Any] | None = None,
    meals: dict[str, Any] | None = None,
    subset: list[SubsetRow] | None = None,
) -> F1Files:
    return F1Files(
        seed=ReferenceSeed.model_validate(seed or SEED),
        foods=SliceFoods.model_validate(foods or FOODS),
        meals=SliceMeals.model_validate(meals or MEALS),
        subset=subset if subset is not None else subset_rows(),
    )


def meals_with(**changes: Any) -> dict[str, Any]:
    data = copy.deepcopy(MEALS)
    data["meals"][0].update(changes)
    return data


def foods_with(**changes: Any) -> dict[str, Any]:
    data = copy.deepcopy(FOODS)
    data["foods"][0].update(changes)
    return data


def seed_with(**changes: Any) -> dict[str, Any]:
    data = copy.deepcopy(SEED)
    data.update(changes)
    return data


def test_fixture_passes_every_gate() -> None:
    assert all(failures == [] for failures in run_all_gates(make_files()).values())


# --- G1 mandatory nutrients ----------------------------------------------------------


def test_g1_passes_when_every_mandatory_nutrient_present() -> None:
    files = make_files()
    assert gate_mandatory_nutrients(files.foods.foods, files.seed.nutrients, files.subset) == []


def test_g1_fails_when_a_mandatory_nutrient_is_absent() -> None:
    files = make_files(subset=subset_rows({k: v for k, v in AMOUNTS.items() if k != "291"}))
    failures = gate_mandatory_nutrients(files.foods.foods, files.seed.nutrients, files.subset)
    assert [(f.gate, f.subject) for f in failures] == [("G1", "01019")]
    assert "fiber" in failures[0].message


def test_g1_zero_counts_as_present() -> None:
    files = make_files(subset=subset_rows({**AMOUNTS, "291": 0.0}))
    assert gate_mandatory_nutrients(files.foods.foods, files.seed.nutrients, files.subset) == []


# --- G2 energy consistency -----------------------------------------------------------


def test_g2_passes_within_20_percent() -> None:
    files = make_files()
    assert gate_energy_consistency(files.seed.nutrients, files.subset) == []


def test_g2_fails_beyond_20_percent() -> None:
    files = make_files(subset=subset_rows({**AMOUNTS, "208": 400.0}))
    failures = gate_energy_consistency(files.seed.nutrients, files.subset)
    assert [(f.gate, f.subject) for f in failures] == [("G2", "01019")]


def test_g2_low_energy_uses_absolute_15_kcal() -> None:
    # calc = 4 * 5 = 20 kcal
    low = {"208": 10.0, "203": 5.0, "204": 0.0, "205": 0.0, "291": 0.0}
    files = make_files(subset=subset_rows(low))
    assert gate_energy_consistency(files.seed.nutrients, files.subset) == []
    files = make_files(subset=subset_rows({**low, "208": 4.0}))
    assert len(gate_energy_consistency(files.seed.nutrients, files.subset)) == 1


def test_g2_counts_fiber_at_2_kcal() -> None:
    # Carbohydrate 20 g including 10 g fiber: 4*10 + 2*10 = 60 kcal.
    fiber = {"208": 60.0, "203": 0.0, "204": 0.0, "205": 20.0, "291": 10.0}
    files = make_files(subset=subset_rows(fiber))
    assert gate_energy_consistency(files.seed.nutrients, files.subset) == []


# --- G3 excluded ingredients ---------------------------------------------------------


def test_g3_passes_without_excluded_keyword() -> None:
    files = make_files()
    assert (
        gate_excluded_ingredients(files.seed.excluded_keywords, files.foods.foods, files.subset)
        == []
    )


@pytest.mark.parametrize("name", ["Ham slices", "smoked HAM", "ham"])
def test_g3_fails_on_whole_word_case_insensitive(name: str) -> None:
    files = make_files(foods=foods_with(ingredient_en=name))
    failures = gate_excluded_ingredients(
        files.seed.excluded_keywords, files.foods.foods, files.subset
    )
    assert [(f.gate, f.subject) for f in failures] == [("G3", "01019")]


def test_g3_ignores_keyword_inside_another_word() -> None:
    files = make_files(foods=foods_with(ingredient_en="Graham crackers", sr_description="Shampoo"))
    assert (
        gate_excluded_ingredients(files.seed.excluded_keywords, files.foods.foods, files.subset)
        == []
    )


def test_g3_checks_the_fdc_description() -> None:
    files = make_files(subset=subset_rows(description="Pork, fresh, loin, raw"))
    failures = gate_excluded_ingredients(
        files.seed.excluded_keywords, files.foods.foods, files.subset
    )
    assert len(failures) == 1
    assert "pork" in failures[0].message


# --- G4 references -------------------------------------------------------------------


def test_g4_passes_when_all_references_resolve() -> None:
    assert gate_references(make_files()) == []


def test_g4_fails_on_unknown_meal_ingredient_ndb() -> None:
    files = make_files(meals=meals_with(ingredients=[{"ndb_number": "99999", "grams": 10}]))
    failures = gate_references(files)
    assert [(f.gate, f.subject) for f in failures] == [("G4", "T-01")]
    assert "99999" in failures[0].message


def test_g4_reports_every_unresolved_reference() -> None:
    files = make_files(
        foods=foods_with(allergens=["Milk", "Lupin"]),
        meals=meals_with(cuisine="MARTIAN", dietary_tags=["vegetarian", "paleo"]),
    )
    messages = sorted(f.message for f in gate_references(files))
    assert messages == [
        "unknown allergen 'Lupin'",
        "unknown cuisine 'MARTIAN'",
        "unknown tag 'paleo'",
    ]


def test_g4_resolves_cuisines_by_code_not_by_name() -> None:
    failures = gate_references(make_files(meals=meals_with(cuisine="General")))
    assert [f.message for f in failures] == ["unknown cuisine 'General'"]


def test_g4_fails_when_food_category_has_no_arabic_name() -> None:
    files = make_files(subset=subset_rows(category="1300"))
    failures = gate_references(files)
    assert [(f.subject, f.message) for f in failures] == [
        ("1300", "FDC food category has no Arabic name in categories_ar")
    ]


def test_g4_fails_on_unknown_limit_and_restriction_references() -> None:
    seed = seed_with(
        condition_nutrient_limits=[
            {
                "condition": "GOUT",
                "nutrient": "purines",
                "limit_basis": "ABSOLUTE",
                "max_per_day": 1,
                "source_reference": "x",
            }
        ],
        condition_tag_restrictions=[
            {"condition": "HYPERTENSION", "tag": "unknown_tag", "restriction_type": "AVOID"}
        ],
    )
    messages = sorted(f.message for f in gate_references(make_files(seed=seed)))
    assert messages == [
        "unknown condition 'GOUT'",
        "unknown nutrient 'purines'",
        "unknown tag 'unknown_tag'",
    ]


def test_g4_fails_when_food_has_no_subset_rows() -> None:
    failures = gate_references(make_files(subset=[]))
    assert ("01019", "food has no rows in the FDC subset") in [
        (f.subject, f.message) for f in failures
    ]


# --- G5 tag groups -------------------------------------------------------------------


def test_g5_passes_with_tags_in_their_groups() -> None:
    assert gate_tag_groups(make_files()) == []


def test_g5_fails_on_dietary_tag_used_as_occasion_and_vice_versa() -> None:
    files = make_files(
        meals=meals_with(
            occasion_tags=["breakfast_suitable", "vegetarian"], dietary_tags=["breakfast_suitable"]
        )
    )
    assert sorted(f.message for f in gate_tag_groups(files)) == [
        "tag 'breakfast_suitable' is OCCASION, expected DIETARY",
        "tag 'vegetarian' is DIETARY, expected OCCASION",
    ]


def test_g5_fails_when_meal_has_no_occasion_tag() -> None:
    failures = gate_tag_groups(make_files(meals=meals_with(occasion_tags=[])))
    assert [(f.subject, f.message) for f in failures] == [("T-01", "meal has no occasion tag")]


def test_g5_fails_on_occasion_tag_on_ingredient() -> None:
    failures = gate_tag_groups(make_files(foods=foods_with(ingredient_tags=["breakfast_suitable"])))
    assert [(f.subject, f.message) for f in failures] == [
        ("01019", "tag 'breakfast_suitable' is OCCASION, expected not OCCASION")
    ]


def test_g5_fails_on_non_condition_tag_in_restriction() -> None:
    seed = seed_with(
        condition_tag_restrictions=[
            {"condition": "HYPERTENSION", "tag": "vegetarian", "restriction_type": "AVOID"}
        ]
    )
    failures = gate_tag_groups(make_files(seed=seed))
    assert [f.message for f in failures] == ["tag 'vegetarian' is DIETARY, expected CONDITION"]


# --- G6 weight method ----------------------------------------------------------------


def test_g6_passes_for_yield_factor_and_sum_of_ingredients() -> None:
    meals = SliceMeals.model_validate(MEALS).meals
    sums = SliceMeals.model_validate(
        meals_with(weight_method="SUM_OF_INGREDIENTS", yield_factor=None, yield_factor_source=None)
    ).meals
    assert gate_weight_method([*meals, *sums]) == []


@pytest.mark.parametrize(
    ("changes", "expected"),
    [
        ({"yield_factor": 3.5}, "YIELD_FACTOR needs 0 < yield_factor <= 3, got 3.5"),
        ({"yield_factor": 0}, "YIELD_FACTOR needs 0 < yield_factor <= 3, got 0.0"),
        ({"yield_factor": None}, "YIELD_FACTOR needs 0 < yield_factor <= 3, got None"),
        ({"yield_factor_source": None}, "YIELD_FACTOR needs yield_factor_source"),
        ({"weight_method": "SUM_OF_INGREDIENTS"}, "SUM_OF_INGREDIENTS needs yield_factor null"),
        ({"weight_method": "WEIGHED"}, "WEIGHED is not used in F.1"),
    ],
)
def test_g6_fails(changes: dict[str, Any], expected: str) -> None:
    meals = SliceMeals.model_validate(meals_with(**changes)).meals
    assert [f.message for f in gate_weight_method(meals)] == [expected]


# --- G7 percent-energy limits --------------------------------------------------------


def _limit(nutrient: str) -> dict[str, Any]:
    return {
        "condition": "HYPERTENSION",
        "nutrient": nutrient,
        "limit_basis": "PERCENT_ENERGY",
        "max_per_day": 6,
        "source_reference": "x",
    }


def test_g7_passes_for_energy_yielding_nutrient() -> None:
    seed = ReferenceSeed.model_validate(
        seed_with(condition_nutrient_limits=[_limit("saturated_fat")])
    )
    assert gate_percent_energy_limits(seed.condition_nutrient_limits) == []


def test_g7_fails_for_sodium() -> None:
    seed = ReferenceSeed.model_validate(seed_with(condition_nutrient_limits=[_limit("sodium")]))
    failures = gate_percent_energy_limits(seed.condition_nutrient_limits)
    assert [(f.gate, f.subject) for f in failures] == [("G7", "HYPERTENSION/sodium")]


# --- G8 optional ingredients ---------------------------------------------------------


def _ingredients(*items: tuple[str, bool]) -> list[dict[str, Any]]:
    return [{"ndb_number": ndb, "grams": 10, "optional": optional} for ndb, optional in items]


def test_g8_passes_with_an_optional_garnish() -> None:
    meals = SliceMeals.model_validate(
        meals_with(ingredients=_ingredients(("01019", False), ("02047", False), ("11297", True)))
    ).meals
    assert gate_optional_ingredients(meals) == []


def test_g8_fails_on_optional_salt_and_on_all_optional() -> None:
    meals = SliceMeals.model_validate(
        meals_with(ingredients=_ingredients(("02047", True), ("11297", True)))
    ).meals
    failures = gate_optional_ingredients(meals)
    assert [(f.gate, f.subject, f.message) for f in failures] == [
        ("G8", "T-01", "salt (02047) is never optional"),
        ("G8", "T-01", "every ingredient is optional"),
    ]


# --- G9 variant groups ---------------------------------------------------------------


def _meals_in_group(*changes: dict[str, Any]) -> list[Any]:
    data = copy.deepcopy(MEALS)
    base = data["meals"][0]
    data["meals"] = [
        {**base, "ref_external": f"T-{n:02}", "variant_group": "cheese_plate", **change}
        for n, change in enumerate(changes, start=1)
    ]
    return SliceMeals.model_validate(data).meals


def test_g9_passes_for_two_matching_variants() -> None:
    meals = _meals_in_group({}, {"name_en": "Cheese plate, chicken"})
    assert gate_variant_groups(meals) == []


def test_g9_fails_on_a_single_meal_group_and_on_different_servings() -> None:
    single = _meals_in_group({})
    assert [(f.gate, f.subject, f.message) for f in gate_variant_groups(single)] == [
        ("G9", "cheese_plate", "only one meal in the group: ['T-01']")
    ]
    differing = _meals_in_group({}, {"servings": 2, "occasion_tags": ["breakfast_suitable"]})
    assert [f.message for f in gate_variant_groups(differing)] == [
        "servings differs: {'T-01': 1, 'T-02': 2}"
    ]
