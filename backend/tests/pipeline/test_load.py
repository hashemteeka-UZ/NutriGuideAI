"""Catalog load: tiers, idempotence, deactivation, isolation from the F.1 slice."""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

import pytest
from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Food, FoodNutrient, Meal, MealNutrient
from app.pipeline.build import build_catalog
from app.pipeline.classify import Outcome
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from tests.pipeline.helpers import copy_mini


@pytest.fixture
def session(integrity_conn: Connection) -> Iterator[Session]:
    with Session(bind=integrity_conn) as s:
        yield s


def _meal(session: Session, ref: str) -> Meal:
    return session.execute(select(Meal).where(Meal.ref_external == ref)).scalar_one()


def test_load_writes_accepted_rows_and_computed_tiers(session: Session, tmp_path: Path) -> None:
    result = build_catalog(copy_mini(tmp_path), session=session, load=True)
    assert result.load is not None
    gold = _meal(session, "NG-GOLD-01")
    silver = _meal(session, "NG-SILVER-01")
    assert gold.quality_tier == "GOLD"
    assert gold.is_verified is True
    assert gold.is_active is True
    assert gold.dataset_version == "team_recipes_v1"
    assert silver.quality_tier == "SILVER"
    assert silver.yield_factor == 0.85
    draft = session.execute(select(Meal).where(Meal.ref_external == "NG-DRAFT-01"))
    assert draft.scalar_one_or_none() is None
    lamb = session.execute(
        select(Food).where(Food.external_source == "FDC", Food.external_code == "99013")
    ).scalar_one()
    assert "sugars from FNDDS 2021-2023 Ingredient Nutrient Values" in lamb.source_reference
    lamb_sugars = (
        session.execute(
            select(FoodNutrient.amount_per_100g)
            .join(Food, Food.food_id == FoodNutrient.food_id)
            .where(Food.external_code == "99013")
        )
        .scalars()
        .all()
    )
    assert 0.0 in lamb_sugars
    camel = session.execute(
        select(Food).where(Food.external_source == "MANUAL", Food.external_code == "CAMEL_MEAT")
    ).scalar_one()
    assert camel.fdc_id is None
    assert result.classified.meals["NG-GOLD-01"].outcome is Outcome.ACCEPTED


def test_second_load_is_unchanged(session: Session, tmp_path: Path) -> None:
    data_dir = copy_mini(tmp_path)
    build_catalog(data_dir, session=session, load=True)
    second = build_catalog(data_dir, session=session, load=True)
    assert second.load is not None
    assert second.load.all_unchanged


def test_removed_meal_is_deactivated_then_restored(session: Session, tmp_path: Path) -> None:
    build_catalog(copy_mini(tmp_path / "full"), session=session, load=True)
    data_dir = copy_mini(tmp_path / "removed")
    meals = data_dir / "meals" / "batch_01.yaml"
    text = meals.read_text(encoding="utf-8")
    start = text.index("- ref_external: NG-SILVER-01")
    end = text.index("- ref_external: NG-MISSNA-01")
    meals.write_text(text[:start] + text[end:], encoding="utf-8")
    removed = build_catalog(data_dir, session=session, load=True)
    assert removed.load is not None
    assert removed.load.deactivated_meals == ["NG-SILVER-01"]
    assert _meal(session, "NG-SILVER-01").is_active is False

    restored = build_catalog(copy_mini(tmp_path / "restored"), session=session, load=True)
    assert restored.load is not None
    assert restored.load.reactivated_meals == ["NG-SILVER-01"]
    assert _meal(session, "NG-SILVER-01").is_active is True


def test_previously_loaded_quarantined_meal_is_deactivated(
    session: Session, tmp_path: Path
) -> None:
    data_dir = copy_mini(tmp_path / "reviewed")
    meals = data_dir / "meals" / "batch_01.yaml"
    meals.write_text(
        meals.read_text(encoding="utf-8").replace(
            "  reviewed_by: null\n", "  reviewed_by: Hashem\n", 1
        ),
        encoding="utf-8",
    )
    build_catalog(data_dir, session=session, load=True)
    assert _meal(session, "NG-DRAFT-01").is_active is True

    again = build_catalog(copy_mini(tmp_path / "clean"), session=session, load=True)
    assert again.load is not None
    assert "NG-DRAFT-01" in again.load.deactivated_meals
    assert _meal(session, "NG-DRAFT-01").is_active is False


def test_catalog_load_does_not_touch_f1_meal_nutrients_or_flags(
    session: Session, tmp_path: Path
) -> None:
    load_f1_slice(session, DEFAULT_DATA_DIR)
    f1_flags = session.execute(
        select(
            Meal.ref_external,
            Meal.is_active,
            Meal.is_verified,
            Meal.quality_tier,
            Meal.dataset_version,
            Meal.source,
        )
        .where(Meal.dataset_version == "f1_slice_v1")
        .order_by(Meal.ref_external)
    ).all()
    f1_nutrients = session.execute(
        select(
            Meal.ref_external,
            MealNutrient.nutrient_id,
            MealNutrient.amount_per_100g,
            MealNutrient.amount_per_serving,
        )
        .join(Meal, Meal.meal_id == MealNutrient.meal_id)
        .where(Meal.dataset_version == "f1_slice_v1")
        .order_by(Meal.ref_external, MealNutrient.nutrient_id)
    ).all()
    assert len(f1_flags) == 35
    assert f1_nutrients

    build_catalog(copy_mini(tmp_path), session=session, load=True)

    after_flags = session.execute(
        select(
            Meal.ref_external,
            Meal.is_active,
            Meal.is_verified,
            Meal.quality_tier,
            Meal.dataset_version,
            Meal.source,
        )
        .where(Meal.dataset_version == "f1_slice_v1")
        .order_by(Meal.ref_external)
    ).all()
    after_nutrients = session.execute(
        select(
            Meal.ref_external,
            MealNutrient.nutrient_id,
            MealNutrient.amount_per_100g,
            MealNutrient.amount_per_serving,
        )
        .join(Meal, Meal.meal_id == MealNutrient.meal_id)
        .where(Meal.dataset_version == "f1_slice_v1")
        .order_by(Meal.ref_external, MealNutrient.nutrient_id)
    ).all()
    assert after_flags == f1_flags
    assert after_nutrients == f1_nutrients
    assert _meal(session, "NG-GOLD-01").dataset_version == "team_recipes_v1"
    assert session.execute(select(Meal).where(Meal.ref_external == "F1-B01")).scalar_one().is_active
