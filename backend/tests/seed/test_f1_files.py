"""File models: the real F.1 files parse; bad types, enums and keys are rejected."""

from __future__ import annotations

import copy

import pytest
from pydantic import ValidationError

from app.seed.f1_files import SliceFoods, read_f1_files
from app.seed.f1_loader import DEFAULT_DATA_DIR
from tests.seed.test_quality_gates import FOODS


def test_real_files_parse_with_five_digit_text_ndb_numbers() -> None:
    files = read_f1_files(DEFAULT_DATA_DIR)
    assert len(files.foods.foods) == 60
    assert len(files.meals.meals) == 30
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
