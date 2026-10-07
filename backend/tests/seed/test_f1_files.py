"""File models: the real F.1 files parse; bad types, enums and keys are rejected."""

from __future__ import annotations

import copy

import pytest
from pydantic import ValidationError

from app.seed.f1_files import ReferenceSeed, SliceFoods, SliceMeals, read_f1_files
from app.seed.f1_loader import DEFAULT_DATA_DIR
from tests.seed.test_quality_gates import FOODS, MEALS, SEED, meals_with


def test_real_files_parse_with_five_digit_text_ndb_numbers() -> None:
    files = read_f1_files(DEFAULT_DATA_DIR)
    assert len(files.foods.foods) == 62
    assert len(files.meals.meals) == 35
    ndbs = [f.ndb_number for f in files.foods.foods]
    ndbs += [i.ndb_number for m in files.meals.meals for i in m.ingredients]
    assert all(isinstance(n, str) and len(n) == 5 for n in ndbs)
    assert "01019" in ndbs and "08120" in ndbs
    assert all(isinstance(code, str) for code in files.seed.categories_ar)


def test_integer_ndb_number_rejected() -> None:
    data = copy.deepcopy(FOODS)
    data["foods"][0]["ndb_number"] = 1019
    with pytest.raises(ValidationError):
        SliceFoods.model_validate(data)


def test_state_outside_check_set_rejected() -> None:
    data = copy.deepcopy(FOODS)
    data["foods"][0]["state"] = "frozen"
    with pytest.raises(ValidationError):
        SliceFoods.model_validate(data)


def test_unknown_key_rejected() -> None:
    data = copy.deepcopy(FOODS)
    data["foods"][0]["calories"] = 265
    with pytest.raises(ValidationError):
        SliceFoods.model_validate(data)


def test_duplicate_ndb_number_rejected() -> None:
    data = copy.deepcopy(FOODS)
    data["foods"].append(copy.deepcopy(data["foods"][0]))
    with pytest.raises(ValidationError, match=r"duplicate foods\.ndb_number"):
        SliceFoods.model_validate(data)


def test_real_seed_has_upper_snake_codes() -> None:
    seed = read_f1_files(DEFAULT_DATA_DIR).seed
    assert [c.code for c in seed.cuisines] == ["LIBYAN", "LEVANTINE", "GENERAL"]
    assert "TREE_NUTS" in {a.code for a in seed.allergens}


@pytest.mark.parametrize("section", ["cuisines", "allergens"])
@pytest.mark.parametrize("code", ["Libyan", "TREE NUTS", "_GLUTEN", ""])
def test_reference_code_must_be_upper_snake_case(section: str, code: str) -> None:
    data = copy.deepcopy(SEED)
    data[section][0]["code"] = code
    with pytest.raises(ValidationError):
        ReferenceSeed.model_validate(data)


@pytest.mark.parametrize("section", ["cuisines", "allergens"])
def test_duplicate_reference_code_rejected(section: str) -> None:
    data = copy.deepcopy(SEED)
    data[section].append({**data[section][0], "name_en": "Other", "name_ar": "آخر"})
    with pytest.raises(ValidationError, match=rf"duplicate {section}\.code"):
        ReferenceSeed.model_validate(data)


@pytest.mark.parametrize("group", ["Couscous", "cous-cous", "couscous_", "2couscous"])
def test_variant_group_must_be_lower_snake_case(group: str) -> None:
    with pytest.raises(ValidationError):
        SliceMeals.model_validate(meals_with(variant_group=group))


def test_variant_group_and_optional_default_to_none_and_false() -> None:
    meal = SliceMeals.model_validate(MEALS).meals[0]
    assert meal.variant_group is None
    assert [item.optional for item in meal.ingredients] == [False]
    grouped = SliceMeals.model_validate(meals_with(variant_group="cheese_plate_2")).meals[0]
    assert grouped.variant_group == "cheese_plate_2"
