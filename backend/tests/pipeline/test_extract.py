"""Extraction: subsets, manifest hashes, profile-only, feasibility, pandera failures."""

from __future__ import annotations

from pathlib import Path

import pytest
import yaml

from app.pipeline.extract import FNDDS_FILENAMES, ExtractError, run_extract
from app.pipeline.files import (
    FNDDS_SUBSET_FILE,
    REFERENCE_SEED_FILE,
    SOURCE_MANIFEST_FILE,
    SOURCES_DIR,
    SR_SUBSET_FILE,
    read_catalog_reference_seed,
    sha256_file,
)
from tests.pipeline.helpers import (
    MINI_CATALOG,
    complete_nutrients,
    write_fndds_dir,
    write_sr_zip,
)


def _seed(data_dir: Path) -> None:
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / REFERENCE_SEED_FILE).write_text(
        (MINI_CATALOG / REFERENCE_SEED_FILE).read_text(encoding="utf-8"), encoding="utf-8"
    )


def test_profile_only_works_without_ingredients_yaml(tmp_path: Path) -> None:
    raw_dir = tmp_path / "raw"
    data_dir = tmp_path / "catalog"
    _seed(data_dir)
    write_sr_zip(
        raw_dir,
        foods=[(910001, 17013, "Lamb, leg, raw", 17), (910002, 20028, "Couscous, dry", 17)],
        food_nutrients=[
            *complete_nutrients(910001, skip={"269"}),
            *complete_nutrients(910002),
        ],
    )
    write_fndds_dir(
        raw_dir,
        ingredient_nutrients=[[17013, 269, 0], [20028, 208, 80]],
    )
    result = run_extract(data_dir, raw_dir, profile_only=True, extracted_on="2026-10-11")
    assert not (data_dir / SOURCES_DIR / SR_SUBSET_FILE).exists()
    assert result.feasibility.sr_foods == 2
    assert result.feasibility.foods_missing_any == 1
    assert result.feasibility.gaps_filled == 1
    lamb = next(c for c in result.feasibility.cases if c.ndb == "17013")
    assert lamb.sr_missing == ["sugars"]
    assert lamb.fndds_values == {"sugars": 0}
    profile = (data_dir / "reports" / "raw_profile.md").read_text(encoding="utf-8")
    assert "schema errors: 0 (expected: none)" in profile
    assert "#93 Feasibility" in profile
    manifest_path = data_dir / SOURCES_DIR / SOURCE_MANIFEST_FILE
    manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
    assert manifest["subsets"] == {}
    expected_raw = {
        "FoodData_Central_sr_legacy_food_csv_2018-04.zip": (
            raw_dir / "FoodData_Central_sr_legacy_food_csv_2018-04.zip"
        ),
        **{name: raw_dir / "fndds" / name for name in FNDDS_FILENAMES},
    }
    recorded = {entry["name"]: entry for entry in manifest["raw_files"]}
    assert set(recorded) == set(expected_raw)
    for name, path in expected_raw.items():
        assert recorded[name]["sha256"] == sha256_file(path)


def test_extract_writes_subsets_and_manifest_hashes(tmp_path: Path) -> None:
    raw_dir = tmp_path / "raw"
    data_dir = tmp_path / "catalog"
    _seed(data_dir)
    (data_dir / "ingredients.yaml").write_text(
        (MINI_CATALOG / "ingredients.yaml").read_text(encoding="utf-8"), encoding="utf-8"
    )
    write_sr_zip(
        raw_dir,
        foods=[
            (910001, 99013, "Synthetic test food", 17),
            (910002, 20028, "Couscous, dry", 17),
            (910003, 1217, "Yogurt, plain, whole milk", 17),
            (910004, 20037, "Rice, white, raw", 17),
            (910005, 10123, "Pork, shoulder, raw", 17),
            (910006, 19177, "Gelatin, dry powder", 17),
            (910007, 14429, "Water, bottled, generic", 17),
        ],
        food_nutrients=[
            *complete_nutrients(910001, skip={"269"}),
            *complete_nutrients(910002),
            *complete_nutrients(910003),
            *complete_nutrients(910004, skip={"307"}),
            *complete_nutrients(910005),
            *complete_nutrients(910006),
            *complete_nutrients(910007),
        ],
    )
    write_fndds_dir(raw_dir, ingredient_nutrients=[[99013, 269, 0], [20028, 208, 376]])
    result = run_extract(data_dir, raw_dir, profile_only=False, extracted_on="2026-10-11")
    sr_path = data_dir / SOURCES_DIR / SR_SUBSET_FILE
    fndds_path = data_dir / SOURCES_DIR / FNDDS_SUBSET_FILE
    assert sr_path.is_file()
    assert fndds_path.is_file()
    fndds_text = fndds_path.read_text(encoding="utf-8")
    assert "99013,269,0" in fndds_text.replace(" ", "")
    assert "20037,307" not in fndds_text
    subsets = result.manifest["subsets"]
    assert set(subsets) == {SR_SUBSET_FILE, FNDDS_SUBSET_FILE}
    for name, path in ((SR_SUBSET_FILE, sr_path), (FNDDS_SUBSET_FILE, fndds_path)):
        assert subsets[name]["sha256"] == sha256_file(path)
        assert subsets[name]["row_count"] == result.subset_rows[name]


def test_pandera_reports_negative_amount_with_its_row(tmp_path: Path) -> None:
    raw_dir = tmp_path / "raw"
    data_dir = tmp_path / "catalog"
    _seed(data_dir)
    write_sr_zip(
        raw_dir,
        foods=[(910001, 17013, "Lamb, leg, raw", 17)],
        food_nutrients=[*complete_nutrients(910001, skip={"208"}), (910001, 1008, -5.0)],
    )
    write_fndds_dir(raw_dir, ingredient_nutrients=[[17013, 269, -1]])
    result = run_extract(data_dir, raw_dir, profile_only=True, extracted_on="2026-10-11")
    issues = [issue.format() for prof in result.profiles for issue in prof.issues]
    assert any("food_nutrient.csv" in text and "row" in text and "-5" in text for text in issues)
    assert any(
        "Ingredient Nutrient Values" in text and "row" in text and "-1" in text for text in issues
    )


def test_extract_requires_named_fndds_files(tmp_path: Path) -> None:
    raw_dir = tmp_path / "raw"
    data_dir = tmp_path / "catalog"
    _seed(data_dir)
    write_sr_zip(
        raw_dir,
        foods=[(910001, 17013, "Lamb", 17)],
        food_nutrients=complete_nutrients(910001),
    )
    (raw_dir / "fndds").mkdir(parents=True)
    with pytest.raises(ExtractError, match="FNDDS files missing"):
        run_extract(data_dir, raw_dir, profile_only=True)


def test_reference_seed_parses_uncertain_keywords() -> None:
    seed = read_catalog_reference_seed(MINI_CATALOG / REFERENCE_SEED_FILE)
    assert "gelatin" in seed.uncertain_keywords
    assert "gelatin" not in seed.excluded_keywords
