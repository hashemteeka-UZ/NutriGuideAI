"""F.1-a loader on the migrated integrity database (each test rolled back, tests/conftest.py)."""

from __future__ import annotations

import shutil
from collections.abc import Iterator
from pathlib import Path

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.engine import Connection
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text
from app.db.models import (
    Food,
    FoodNutrient,
    IngredientAlias,
    Meal,
    MealTag,
    MealTranslation,
    Nutrient,
)
from app.seed import f1_loader
from app.seed.f1_files import REFERENCE_SEED_FILE, SLICE_MEALS_FILE, read_f1_files
from app.seed.f1_loader import DEFAULT_DATA_DIR, TABLES, F1LoadError, load_f1_slice

FILES = read_f1_files(DEFAULT_DATA_DIR)


@pytest.fixture
def session(integrity_conn: Connection) -> Iterator[Session]:
    with Session(bind=integrity_conn) as s:
        yield s


def _row_counts(session: Session) -> dict[str, int]:
    return {
        name: session.execute(text(f"SELECT count(*) FROM {name}")).scalar_one() for name in TABLES
    }


def _copy_data_dir(tmp_path: Path) -> Path:
    target = tmp_path / "f1_slice"
    shutil.copytree(DEFAULT_DATA_DIR, target)
    return target


def _replace_once(path: Path, old: str, new: str) -> None:
    content = path.read_text(encoding="utf-8")
    assert old in content, f"{old!r} not in {path.name}"
    path.write_text(content.replace(old, new, 1), encoding="utf-8")


def test_real_files_load_without_gate_failures(session: Session) -> None:
    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert report.ok, report.format()
    assert set(report.gates) == {f"G{n}" for n in range(1, 8)}
    counts = _row_counts(session)
    assert counts["meals"] == 30
    assert counts["foods"] == 60
    assert counts["ingredients"] == 60
    assert counts["food_nutrients"] == len(FILES.subset)
    assert counts["ingredient_aliases"] == 120
    assert counts["meal_translations"] == 30
    assert counts["meal_ingredients"] == sum(len(m.ingredients) for m in FILES.meals.meals)
    assert {name: c.inserted for name, c in report.tables.items()} == counts
    assert report.unverified_meals == 0


def test_every_food_has_the_nine_mandatory_nutrients(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    mandatory = session.execute(
        select(func.count()).select_from(Nutrient).where(Nutrient.is_mandatory)
    ).scalar_one()
    assert mandatory == 9
    per_food = session.execute(
        select(FoodNutrient.food_id, func.count())
        .join(Nutrient, Nutrient.nutrient_id == FoodNutrient.nutrient_id)
        .where(Nutrient.is_mandatory)
        .group_by(FoodNutrient.food_id)
    ).all()
    assert len(per_food) == 60
    assert {n for _, n in per_food} == {9}


def test_spot_check_lamb_17039_fdc_id_and_sodium(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    rows = [r for r in FILES.subset if r.ndb_number == "17039"]
    sodium_csv = next(r.amount_per_100g for r in rows if r.nutrient_nbr == "307")
    food = session.execute(
        select(Food).where(Food.external_source == "FDC", Food.external_code == "17039")
    ).scalar_one()
    assert food.fdc_id == rows[0].fdc_id
    assert food.description == rows[0].description
    assert food.data_type == "sr_legacy_food"
    assert food.basis_grams == 100
    assert food.source_reference == (
        f"USDA FoodData Central, SR Legacy (2018-04); FDC ID {food.fdc_id}; NDB 17039"
    )
    sodium = session.execute(
        select(FoodNutrient.amount_per_100g)
        .join(Nutrient, Nutrient.nutrient_id == FoodNutrient.nutrient_id)
        .where(FoodNutrient.food_id == food.food_id, Nutrient.code == "sodium")
    ).scalar_one()
    assert sodium == sodium_csv


def test_meal_f1_b01_total_grams(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    b01 = session.execute(select(Meal).where(Meal.ref_external == "F1-B01")).scalar_one()
    assert b01.total_grams == 810.05
    assert b01.default_lang == "ar"


def _verified_by_ref(session: Session) -> dict[str | None, bool]:
    return dict(session.execute(select(Meal.ref_external, Meal.is_verified)).tuples().all())


def test_is_verified_follows_reviewed_by(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    expected = {m.ref_external: m.reviewed_by is not None for m in FILES.meals.meals}
    assert _verified_by_ref(session) == expected
    assert len(expected) == 30
    assert all(expected.values())


def test_meal_without_reviewer_loads_unverified(session: Session, tmp_path: Path) -> None:
    data_dir = _copy_data_dir(tmp_path)
    _replace_once(data_dir / SLICE_MEALS_FILE, "  reviewed_by: Hashem\n", "  reviewed_by: null\n")
    report = load_f1_slice(session, data_dir)
    verified = _verified_by_ref(session)
    assert verified.pop("F1-B01") is False
    assert all(verified.values())
    assert report.unverified_meals == 1
    assert any("1 meals have no reviewer" in f for f in report.findings)

    reviewed = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert _verified_by_ref(session)["F1-B01"] is True
    assert reviewed.tables["meals"].updated == 1
    assert reviewed.unverified_meals == 0


def test_normalized_columns_use_normalize_search_text(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    for alias in session.execute(select(IngredientAlias)).scalars():
        assert alias.alias_normalized == normalize_search_text(alias.alias_text)
    for meal in session.execute(select(Meal)).scalars():
        assert meal.name_normalized == normalize_search_text(meal.name)
    for translation in session.execute(select(MealTranslation)).scalars():
        assert translation.lang == "en"
        assert translation.name_normalized == normalize_search_text(translation.name)


def test_no_derived_rows_after_pass_f1_a(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    assert session.execute(text("SELECT count(*) FROM meal_nutrients")).scalar_one() == 0
    assert session.execute(text("SELECT count(*) FROM meal_allergens")).scalar_one() == 0
    sources = set(session.execute(select(MealTag.source)).scalars())
    assert sources == {"MANUAL"}


def test_loading_twice_is_idempotent(session: Session) -> None:
    first = load_f1_slice(session, DEFAULT_DATA_DIR)
    counts = _row_counts(session)
    second = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert _row_counts(session) == counts
    assert second.ok
    assert second.all_unchanged, second.format()
    assert {n: c.unchanged for n, c in second.tables.items()} == {
        n: c.inserted for n, c in first.tables.items()
    }


def test_gate_failure_writes_nothing_and_reports_every_failure(
    session: Session, tmp_path: Path
) -> None:
    data_dir = _copy_data_dir(tmp_path)
    meals = data_dir / SLICE_MEALS_FILE
    _replace_once(meals, "{ndb_number: '01123', grams: 200", "{ndb_number: '99999', grams: 200")
    _replace_once(meals, "  - vegetarian\n", "  - paleo\n")
    with pytest.raises(F1LoadError) as caught:
        load_f1_slice(session, data_dir)
    failures = caught.value.report.failures
    assert any("F1-B01" in f and "99999" in f for f in failures), failures
    assert any("'paleo'" in f for f in failures), failures
    assert set(_row_counts(session).values()) == {0}


def test_category_without_arabic_name_fails(session: Session, tmp_path: Path) -> None:
    data_dir = _copy_data_dir(tmp_path)
    _replace_once(data_dir / REFERENCE_SEED_FILE, "  '1300': لحم البقر\n", "")
    with pytest.raises(F1LoadError) as caught:
        load_f1_slice(session, data_dir)
    assert caught.value.report.gates["G4"][0].subject == "1300"
    assert set(_row_counts(session).values()) == {0}


def test_failure_after_partial_writes_rolls_everything_back(
    session: Session, monkeypatch: pytest.MonkeyPatch
) -> None:
    def broken_load_meals(*_args: object, **_kwargs: object) -> None:
        raise SQLAlchemyError("injected failure after foods were written")

    monkeypatch.setattr(f1_loader._Loader, "_load_meals", broken_load_meals)
    with pytest.raises(F1LoadError) as caught:
        load_f1_slice(session, DEFAULT_DATA_DIR)
    assert any("rolled back" in e for e in caught.value.report.errors)
    assert set(_row_counts(session).values()) == {0}
