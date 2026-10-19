"""Recipe steps file, authoring gate, and catalog load (§10.7, #166)."""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterator
from pathlib import Path

import pytest
import yaml
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Meal, MealStep
from app.pipeline.build import DEFAULT_DATA_DIR, build_catalog
from app.pipeline.files import CatalogAuthoringError, read_catalog
from app.pipeline.load import CatalogLoadReport
from tests.pipeline.helpers import copy_mini

STEPS_NAME = "team_recipe_steps_batch_02.yaml"
FIVE_STEP_MEAL = "NG-B12"


@pytest.fixture
def session(integrity_conn: Connection) -> Iterator[Session]:
    with Session(bind=integrity_conn) as bound:
        yield bound


def test_real_steps_file_parses() -> None:
    files = read_catalog(DEFAULT_DATA_DIR)
    by_version = {batch.dataset_version: batch for batch in files.step_files}
    assert set(by_version) == {
        "team_recipe_steps_v2",
        "team_recipe_steps_v3",
        "team_recipe_steps_v4",
        "team_recipe_steps_v5",
    }
    batch = by_version["team_recipe_steps_v2"]
    assert batch.default_lang == "ar"
    assert len(batch.meals) == 38
    assert sum(len(meal.steps_ar) for meal in batch.meals) == 163
    assert {meal.dish_form.value for meal in batch.meals} == {"ONE_DISH", "PLATE"}
    assert f"steps/{STEPS_NAME}" in files.input_hashes


def test_step_problems_are_reported_together(tmp_path: Path) -> None:
    data_dir = copy_mini(tmp_path)
    steps = data_dir / "steps"
    steps.mkdir()
    long_step = "x" * 501
    (steps / "bad.yaml").write_text(
        f"""\
dataset_version: team_recipe_steps_v2
default_lang: ar
note: one bad copy
meals:
- ref_external: NG-NO-SUCH
  dish_form: ONE_DISH
  steps_ar:
  - boil water
- ref_external: NG-GOLD-01
  dish_form: ONE_DISH
  steps_ar:
  - first step
- ref_external: NG-GOLD-01
  dish_form: BOWL
  steps_ar:
  - "  "
  - "{long_step}"
""",
        encoding="utf-8",
    )
    with pytest.raises(CatalogAuthoringError) as exc:
        read_catalog(data_dir)
    report = exc.value.format()
    assert "unknown ref_external 'NG-NO-SUCH'" in report
    assert "duplicate ref_external 'NG-GOLD-01'" in report
    assert "step 1 is blank" in report
    assert "step 2 is longer than 500 characters" in report
    assert "dish_form 'BOWL'" in report


def test_catalog_without_steps_directory_builds(tmp_path: Path) -> None:
    data_dir = copy_mini(tmp_path)
    assert not (data_dir / "steps").exists()
    result = build_catalog(data_dir)
    assert result.files.step_files == []


def _copy_catalog(tmp_path: Path) -> Path:
    import shutil

    target = tmp_path / "catalog"
    shutil.copytree(DEFAULT_DATA_DIR, target)
    return target


def _load(session: Session, data_dir: Path) -> CatalogLoadReport:
    result = build_catalog(data_dir, session=session, load=True)
    assert result.load is not None
    return result.load


def _steps_of(session: Session, ref: str) -> list[tuple[int, str]]:
    meal_id = session.execute(select(Meal.meal_id).where(Meal.ref_external == ref)).scalar_one()
    rows = session.execute(
        select(MealStep.position, MealStep.text)
        .where(MealStep.meal_id == meal_id)
        .order_by(MealStep.position)
    ).all()
    return [(int(position), text) for position, text in rows]


def _rewrite_steps(path: Path, ref: str, steps: list[str] | None) -> None:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    meals = document["meals"]
    if steps is None:
        document["meals"] = [meal for meal in meals if meal["ref_external"] != ref]
    else:
        matched = [meal for meal in meals if meal["ref_external"] == ref]
        assert len(matched) == 1
        matched[0]["steps_ar"] = steps
    path.write_text(
        yaml.safe_dump(document, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )


def test_real_catalog_loads_steps_and_second_run_is_unchanged(
    session: Session, tmp_path: Path
) -> None:
    data_dir = _copy_catalog(tmp_path)
    _load(session, data_dir)

    step_rows = session.execute(select(func.count()).select_from(MealStep)).scalar_one()
    assert step_rows == 477
    with_form = session.execute(
        select(func.count()).select_from(Meal).where(Meal.dish_form.is_not(None))
    ).scalar_one()
    assert with_form == 121

    positions: dict[int, list[int]] = defaultdict(list)
    for meal_id, position in session.execute(
        select(MealStep.meal_id, MealStep.position).order_by(MealStep.meal_id, MealStep.position)
    ):
        positions[meal_id].append(position)
    assert len(positions) == 121
    assert all(found == list(range(1, len(found) + 1)) for found in positions.values())

    batch_01 = session.execute(
        select(Meal.meal_id, Meal.dish_form).where(Meal.dataset_version == "team_recipes_v1")
    ).all()
    assert batch_01
    assert all(dish_form is None for _meal_id, dish_form in batch_01)
    batch_01_steps = session.execute(
        select(func.count())
        .select_from(MealStep)
        .join(Meal, Meal.meal_id == MealStep.meal_id)
        .where(Meal.dataset_version == "team_recipes_v1")
    ).scalar_one()
    assert batch_01_steps == 0

    second = _load(session, data_dir)
    steps = second.tables["meal_steps"]
    assert (steps.inserted, steps.updated, steps.deactivated) == (0, 0, 0)
    assert steps.unchanged == 477
    assert second.recomputed
    assert all(not item.changed for item in second.recomputed)


def test_steps_sync_shortens_updates_and_clears(session: Session, tmp_path: Path) -> None:
    data_dir = _copy_catalog(tmp_path)
    _load(session, data_dir)
    original = _steps_of(session, FIVE_STEP_MEAL)
    assert [position for position, _text in original] == [1, 2, 3, 4, 5]
    path = data_dir / "steps" / STEPS_NAME

    _rewrite_steps(path, FIVE_STEP_MEAL, [text for _position, text in original[:3]])
    shortened = _load(session, data_dir)
    assert _steps_of(session, FIVE_STEP_MEAL) == original[:3]
    counts = shortened.tables["meal_steps"]
    assert (counts.inserted, counts.updated, counts.deactivated) == (0, 0, 2)
    assert counts.unchanged == 475

    changed = [text for _position, text in original[:3]]
    changed[0] = changed[0] + " edited"
    _rewrite_steps(path, FIVE_STEP_MEAL, changed)
    edited = _load(session, data_dir)
    assert _steps_of(session, FIVE_STEP_MEAL) == [(1, changed[0]), (2, changed[1]), (3, changed[2])]
    edited_counts = edited.tables["meal_steps"]
    assert (edited_counts.inserted, edited_counts.updated, edited_counts.deactivated) == (0, 1, 0)

    _rewrite_steps(path, FIVE_STEP_MEAL, None)
    removed = _load(session, data_dir)
    assert _steps_of(session, FIVE_STEP_MEAL) == []
    meal = session.execute(select(Meal).where(Meal.ref_external == FIVE_STEP_MEAL)).scalar_one()
    assert meal.dish_form is None
    assert removed.tables["meals"].updated == 1
    assert removed.tables["meal_steps"].deactivated == 3
