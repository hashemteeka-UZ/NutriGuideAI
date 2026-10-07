"""F.1 loader on the migrated integrity database (each test rolled back, tests/conftest.py)."""

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
    Allergen,
    Cuisine,
    Food,
    FoodNutrient,
    Ingredient,
    IngredientAlias,
    Meal,
    MealIngredient,
    MealTag,
    MealTranslation,
    Nutrient,
)
from app.seed import f1_loader
from app.seed.f1_files import (
    REFERENCE_SEED_FILE,
    SLICE_FOODS_FILE,
    SLICE_MEALS_FILE,
    read_f1_files,
)
from app.seed.f1_loader import DEFAULT_DATA_DIR, TABLES, F1LoadError, load_f1_slice
from app.services.meal_derived import TagRuleError
from app.services.meal_nutrition import is_meal_nutritionally_complete
from app.services.tag_rules import TAG_RULES_VERSION

FILES = read_f1_files(DEFAULT_DATA_DIR)
# Recipes changed or added in the team review of 2026-10-06 (all reviewed by the user).
REVIEWED_2026_10_06 = (
    "F1-L01-CH",
    "F1-L02",
    "F1-L02-CH",
    "F1-L03-CH",
    "F1-L05-CH",
    "F1-L06-CH",
    "F1-L08",
    "F1-D01",
    "F1-D01-CH",
    "F1-D06",
)
EXTRA_MEAL = """\
- ref_external: F1-X99
  name_ar: طبق تمر
  name_en: Plate of dates
  cuisine: LIBYAN
  servings: 1
  weight_method: SUM_OF_INGREDIENTS
  yield_factor: null
  yield_factor_source: null
  variant_group: null
  occasion_tags:
  - snack_suitable
  dietary_tags:
  - vegan
  reviewed_by: Hashem
  ingredients:
  - {ndb_number: '09087', grams: 50, label_ar: تمر}
"""


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


def _meal(session: Session, ref: str) -> Meal:
    return session.execute(select(Meal).where(Meal.ref_external == ref)).scalar_one()


def _meal_ingredients(session: Session, ref: str) -> list[tuple[str, bool, str | None]]:
    """(NDB number, is_optional, text_original) in recipe order."""
    rows = session.execute(
        select(Food.external_code, MealIngredient.is_optional, MealIngredient.text_original)
        .join(Food, Food.food_id == MealIngredient.food_id)
        .where(MealIngredient.meal_id == _meal(session, ref).meal_id)
        .order_by(MealIngredient.position)
    )
    return [(ndb, is_optional, label) for ndb, is_optional, label in rows]


def test_real_files_load_without_gate_failures(session: Session) -> None:
    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert report.ok, report.format()
    assert set(report.gates) == {f"G{n}" for n in range(1, 10)}
    counts = _row_counts(session)
    assert counts["meals"] == 35
    assert counts["foods"] == 62
    assert counts["ingredients"] == 62
    assert counts["food_nutrients"] == len(FILES.subset) == 620
    assert counts["ingredient_aliases"] == 124
    assert counts["meal_translations"] == 35
    assert counts["meal_ingredients"] == sum(len(m.ingredients) for m in FILES.meals.meals)
    derived_tags = report.recompute_changes["meal_tags (DERIVED)"].inserted
    assert counts.pop("meal_tags") == report.tables["meal_tags"].inserted + derived_tags
    assert {name: c.inserted for name, c in report.tables.items() if name != "meal_tags"} == counts
    assert report.unverified_meals == 0
    assert report.deactivated_meals == report.reactivated_meals == []
    assert not any("§9.1-§9.3" in f or "§10.1/§31.4" in f for f in report.findings)


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
    assert len(per_food) == 62
    assert {n for _, n in per_food} == {9}


def test_reference_rows_carry_the_seed_codes(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    cuisines = set(session.execute(select(Cuisine.code)).scalars())
    assert cuisines == {"LIBYAN", "LEVANTINE", "GENERAL"}
    allergens = dict(session.execute(select(Allergen.code, Allergen.name_en)).tuples().all())
    assert allergens["TREE_NUTS"] == "Tree nuts"
    assert len(allergens) == 9


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


def test_meal_f1_b01_total_grams_and_qc_columns(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    b01 = _meal(session, "F1-B01")
    assert b01.total_grams == 810.05
    assert b01.default_lang == "ar"
    assert b01.yield_factor == 0.85
    assert b01.yield_factor_source == (
        "team estimate pending weighing (Step G replaces with WEIGHED)"
    )
    assert b01.reviewed_by == "Hashem"
    s01 = _meal(session, "F1-S01")
    assert (s01.weight_method, s01.yield_factor, s01.yield_factor_source) == (
        "SUM_OF_INGREDIENTS",
        None,
        None,
    )
    yield_meals = session.execute(
        select(Meal.yield_factor).where(Meal.weight_method == "YIELD_FACTOR")
    ).scalars()
    assert None not in set(yield_meals)


def _verified_by_ref(session: Session) -> dict[str | None, bool]:
    return dict(session.execute(select(Meal.ref_external, Meal.is_verified)).tuples().all())


def test_all_35_meals_verified_including_the_reviewed_recipes(session: Session) -> None:
    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    expected = {m.ref_external: m.reviewed_by is not None for m in FILES.meals.meals}
    verified = _verified_by_ref(session)
    assert verified == expected
    assert len(verified) == 35
    assert all(verified.values())
    assert set(REVIEWED_2026_10_06) <= set(verified)
    reviewers = session.execute(
        select(Meal.reviewed_by).where(Meal.ref_external.in_(REVIEWED_2026_10_06))
    ).scalars()
    assert list(reviewers) == ["Hashem"] * len(REVIEWED_2026_10_06)
    assert report.unverified_meals == 0


def test_meal_without_reviewer_loads_unverified(session: Session, tmp_path: Path) -> None:
    data_dir = _copy_data_dir(tmp_path)
    _replace_once(data_dir / SLICE_MEALS_FILE, "  reviewed_by: Hashem\n", "  reviewed_by: null\n")
    report = load_f1_slice(session, data_dir)
    verified = _verified_by_ref(session)
    assert verified.pop("F1-B01") is False
    assert _meal(session, "F1-B01").reviewed_by is None
    assert all(verified.values())
    assert report.unverified_meals == 1
    assert any("1 meals have no reviewer" in f for f in report.findings)

    reviewed = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert _verified_by_ref(session)["F1-B01"] is True
    assert reviewed.tables["meals"].updated == 1
    assert reviewed.unverified_meals == 0


def test_every_meal_is_complete_right_after_the_loader(session: Session) -> None:
    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    meal_ids = list(session.execute(select(Meal.meal_id)).scalars())
    assert len(meal_ids) == len(report.recomputed) == 35
    assert all(is_meal_nutritionally_complete(session, meal_id) for meal_id in meal_ids)
    assert report.incomplete_meals == []
    changes = report.recompute_changes
    assert changes["meal_nutrients"].inserted == 35 * len(FILES.seed.nutrients)
    assert changes["meal_tags (DERIVED)"].inserted > 0
    assert changes["meal_allergens"].inserted > 0


def test_optional_ingredients_and_recipe_wording(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    b02 = _meal_ingredients(session, "F1-B02")
    optional = {ndb for ndb, is_optional, _ in b02 if is_optional}
    assert optional == {"09152", "11529", "11297"}  # lemon juice, tomato, parsley
    assert len(b02) == 9

    d01 = _meal_ingredients(session, "F1-D01")
    pasta = [text_original for ndb, _, text_original in d01 if ndb == "20120"]
    assert pasta == ["حبوب الشربة (لسان العصفور)"]
    assert "16358" not in {ndb for ndb, _, _ in _meal_ingredients(session, "F1-L02")}

    texts = session.execute(select(MealIngredient.text_original)).scalars()
    assert None not in set(texts)


def test_variant_groups(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    groups: dict[str, set[str | None]] = {}
    for group, ref in session.execute(
        select(Meal.variant_group, Meal.ref_external).where(Meal.variant_group.is_not(None))
    ).tuples():
        assert group is not None
        groups.setdefault(group, set()).add(ref)
    assert groups["couscous"] == {"F1-L01", "F1-L01-CH"}
    assert set(groups) == {"couscous", "mbakbaka", "bazeen", "fasolia", "bamia", "sharba"}
    assert all(len(refs) == 2 for refs in groups.values())


def test_rule_version_on_derived_rows_only(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    versions: dict[str, set[str | None]] = {}
    for source, version in session.execute(select(MealTag.source, MealTag.rule_version)):
        versions.setdefault(source, set()).add(version)
    assert versions == {"DERIVED": {TAG_RULES_VERSION}, "MANUAL": {None}}


def test_meal_removed_from_the_file_is_deactivated_then_reactivated(
    session: Session, tmp_path: Path
) -> None:
    data_dir = _copy_data_dir(tmp_path)
    meals_file = data_dir / SLICE_MEALS_FILE
    content = meals_file.read_text(encoding="utf-8").rstrip("\n")
    meals_file.write_text(f"{content}\n{EXTRA_MEAL}", encoding="utf-8")

    with_extra = load_f1_slice(session, data_dir)
    assert with_extra.total_meals == 36
    assert _meal(session, "F1-X99").is_active is True

    real = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert real.deactivated_meals == ["F1-X99"]
    assert real.tables["meals"].updated == 1
    assert len(real.recomputed) == 35
    extra = _meal(session, "F1-X99")
    assert extra.is_active is False
    ingredients = session.execute(
        select(func.count()).where(MealIngredient.meal_id == extra.meal_id)
    ).scalar_one()
    assert ingredients == 1
    active = session.execute(select(func.count()).select_from(Meal).where(Meal.is_active))
    assert active.scalar_one() == 35
    assert session.execute(select(func.count()).select_from(Meal)).scalar_one() == 36

    again = load_f1_slice(session, data_dir)
    assert again.reactivated_meals == ["F1-X99"]
    assert again.deactivated_meals == []
    assert _meal(session, "F1-X99").is_active is True


def _aliases(session: Session, ndb: str) -> set[tuple[str, str, str | None]]:
    rows = session.execute(
        select(IngredientAlias.alias_text, IngredientAlias.lang, IngredientAlias.source)
        .join(Ingredient, Ingredient.ingredient_id == IngredientAlias.ingredient_id)
        .join(Food, Food.food_id == Ingredient.default_food_id)
        .where(Food.external_code == ndb)
    )
    return {(alias, lang, source) for alias, lang, source in rows}


def test_renamed_ingredient_loses_its_old_seed_alias(session: Session, tmp_path: Path) -> None:
    data_dir = _copy_data_dir(tmp_path)
    _replace_once(
        data_dir / REFERENCE_SEED_FILE, "seed_version: f1_seed_v1", "seed_version: f1_seed_v0"
    )
    _replace_once(
        data_dir / SLICE_FOODS_FILE,
        "  ingredient_ar: لحم ضأن\n",
        "  ingredient_ar: كتف ضأن صافٍ\n",
    )
    load_f1_slice(session, data_dir)
    assert ("كتف ضأن صافٍ", "ar", "f1_seed_v0") in _aliases(session, "17039")

    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert _aliases(session, "17039") == {
        ("Lamb shoulder, lean", "en", "f1_seed_v1"),
        ("لحم ضأن", "ar", "f1_seed_v1"),
    }
    aliases = report.tables["ingredient_aliases"]
    assert (aliases.inserted, aliases.deleted, aliases.updated) == (1, 1, 123)
    assert session.execute(select(func.count()).select_from(IngredientAlias)).scalar_one() == 124


def test_alias_from_another_source_is_kept(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    lamb = session.execute(
        select(Ingredient.ingredient_id)
        .join(Food, Food.food_id == Ingredient.default_food_id)
        .where(Food.external_code == "17039")
    ).scalar_one()
    session.add(
        IngredientAlias(
            ingredient_id=lamb,
            alias_text="لحم غنم",
            lang="ar",
            alias_normalized=normalize_search_text("لحم غنم"),
            source="curator",
        )
    )
    session.flush()
    report = load_f1_slice(session, DEFAULT_DATA_DIR)
    assert ("لحم غنم", "ar", "curator") in _aliases(session, "17039")
    assert report.all_unchanged, report.format()


def test_normalized_columns_use_normalize_search_text(session: Session) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    for alias in session.execute(select(IngredientAlias)).scalars():
        assert alias.alias_normalized == normalize_search_text(alias.alias_text)
    for meal in session.execute(select(Meal)).scalars():
        assert meal.name_normalized == normalize_search_text(meal.name)
    for translation in session.execute(select(MealTranslation)).scalars():
        assert translation.lang == "en"
        assert translation.name_normalized == normalize_search_text(translation.name)


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
    for name, changes in second.recompute_changes.items():
        assert not changes.changed, name
        assert changes.unchanged == first.recompute_changes[name].inserted, name


def test_gate_failure_writes_nothing_and_reports_every_failure(
    session: Session, tmp_path: Path
) -> None:
    data_dir = _copy_data_dir(tmp_path)
    meals = data_dir / SLICE_MEALS_FILE
    _replace_once(meals, "{ndb_number: '01123', grams: 200", "{ndb_number: '99999', grams: 200")
    _replace_once(meals, "  - vegetarian\n", "  - paleo\n")
    _replace_once(
        meals,
        "{ndb_number: '02047', grams: 3, label_ar: ملح}",
        "{ndb_number: '02047', grams: 3, label_ar: ملح, optional: true}",
    )
    _replace_once(meals, "  variant_group: sharba\n", "  variant_group: null\n")
    with pytest.raises(F1LoadError) as caught:
        load_f1_slice(session, data_dir)
    report = caught.value.report
    failures = report.failures
    assert any("F1-B01" in f and "99999" in f for f in failures), failures
    assert any("'paleo'" in f for f in failures), failures
    assert [str(f) for f in report.gates["G8"]] == ["G8 F1-B01: salt (02047) is never optional"]
    assert [str(f) for f in report.gates["G9"]] == [
        "G9 sharba: only one meal in the group: ['F1-D01-CH']"
    ]
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


def test_recompute_failure_rolls_back_the_whole_load(
    session: Session, monkeypatch: pytest.MonkeyPatch
) -> None:
    def broken_recompute(*_args: object, **_kwargs: object) -> None:
        raise TagRuleError("injected failure in the recompute")

    monkeypatch.setattr(f1_loader._Loader, "_recompute", broken_recompute)
    with pytest.raises(F1LoadError) as caught:
        load_f1_slice(session, DEFAULT_DATA_DIR)
    assert caught.value.report.recomputed == []
    assert set(_row_counts(session).values()) == {0}
    assert session.execute(text("SELECT count(*) FROM meal_nutrients")).scalar_one() == 0
