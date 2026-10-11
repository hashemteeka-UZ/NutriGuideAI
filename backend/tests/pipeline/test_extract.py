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


def _parse_lookup(text: str) -> dict[str, tuple[list[str], list[str]]]:
    rows: dict[str, tuple[list[str], list[str]]] = {}
    current: str | None = None
    for line in text.splitlines():
        if not line.strip() or line.startswith("#") or line.startswith("code |"):
            continue
        if line.startswith("  "):
            assert current is not None
            rows[current][1].append(line.strip())
            continue
        cells = [cell.strip() for cell in line.split("|")]
        assert len(cells) == 8
        current = cells[0]
        rows[current] = (cells, [])
    return rows


def test_ingredient_lookup_ranks_only_complete_foods_and_is_stable(tmp_path: Path) -> None:
    raw_dir = tmp_path / "raw"
    data_dir = tmp_path / "catalog"
    _seed(data_dir)
    (data_dir / "ingredients.yaml").write_text(
        """
dataset_version: lookup_test_v1
ingredients:
- code: CAMEL_MEAT
  name_en: Camel meat
  name_ar: لحم جمل
  aliases_en: []
  aliases_ar: []
  food: {source: MANUAL, code: CAMEL_MEAT}
  state: raw
  allergens: []
  ingredient_tags: []
  review_status: APPROVED
- code: COUSCOUS_DRY
  name_en: Dry couscous
  name_ar: كسكس
  aliases_en: []
  aliases_ar: []
  food: {source: SR_LEGACY, code: '20028'}
  state: as_purchased
  allergens: []
  ingredient_tags: []
  review_status: APPROVED
- code: LAMB_LEG
  name_en: Lambs legs
  name_ar: فخذ
  aliases_en: []
  aliases_ar: []
  food: {source: SR_LEGACY, code: '22222'}
  state: raw
  allergens: []
  ingredient_tags: []
  review_status: PENDING
- code: RICE_WHITE
  name_en: White rice
  name_ar: أرز
  aliases_en: []
  aliases_ar: []
  food: {source: SR_LEGACY, code: '20037'}
  state: raw
  allergens: []
  ingredient_tags: []
  review_status: APPROVED
- code: UNKNOWN_LAMB
  name_en: Fresh lamb shoulder
  name_ar: كتف
  aliases_en: []
  aliases_ar: []
  food: {source: SR_LEGACY, code: '99999'}
  state: raw
  allergens: []
  ingredient_tags: []
  review_status: PENDING
- code: UNKNOWN_RICE
  name_en: White rice
  name_ar: أرز
  aliases_en: []
  aliases_ar: []
  food: {source: SR_LEGACY, code: '77777'}
  state: raw
  allergens: []
  ingredient_tags: []
  review_status: PENDING
""".lstrip(),
        encoding="utf-8",
    )
    categories = [
        (11, "1100", "Vegetables and Vegetable Products"),
        (17, "1700", "Lamb, Veal, and Game Products"),
        (20, "2000", "Cereal Grains and Pasta"),
        (50, "0500", "Poultry Products"),
        (90, "0900", "Fruits and Fruit Juices"),
    ]
    foods = [
        (910001, 10001, "Fresh peas, raw", 11),
        (910002, 17001, "Lamb, ground, raw", 17),
        (910003, 17002, "Lamb, leg, cooked", 17),
        (910004, 17003, "Lamb, shoulder, raw", 17),
        (910005, 17004, "Lamb, loin, raw", 17),
        (910006, 17005, "Fresh lamb, shoulder", 17),
        (910007, 18888, "Lamb, leg, raw", 17),
        (910008, 20028, "Couscous, dry", 20),
        (910009, 20037, "Rice, white, raw", 20),
        (910010, 22222, "Lamb, leg, raw", 17),
        (910011, 50620, "Chicken, breast, raw", 50),
        (910012, 90010, "Apple, raw", 90),
    ]
    nutrients = [
        *complete_nutrients(910001),
        *complete_nutrients(910002),
        *complete_nutrients(910003),
        *complete_nutrients(910004),
        *complete_nutrients(910005, skip={"269"}),
        *complete_nutrients(910006),
        *complete_nutrients(910007, skip={"307"}),
        *complete_nutrients(910008, skip={"291"}),
        *complete_nutrients(910009),
        *complete_nutrients(910010, skip={"269"}),
        *complete_nutrients(910011),
        *complete_nutrients(910012),
    ]
    write_sr_zip(raw_dir, foods=foods, food_nutrients=nutrients, categories=categories)
    write_fndds_dir(
        raw_dir,
        ingredient_nutrients=[[17004, 269, 0], [20028, 291, 4]],
    )
    report_path = data_dir / "reports" / "ingredient_lookup.md"

    def _run(extracted_on: str) -> bytes:
        with pytest.raises(ExtractError, match="NDB numbers not found") as exc:
            run_extract(data_dir, raw_dir, profile_only=False, extracted_on=extracted_on)
        message = str(exc.value)
        assert "[77777, 99999]" in message
        assert not (data_dir / SOURCES_DIR / SR_SUBSET_FILE).exists()
        return report_path.read_bytes()

    first = _run("2026-01-01")
    assert first == _run("2026-10-11")
    parsed = _parse_lookup(first.decode("utf-8"))
    assert list(parsed) == [
        "COUSCOUS_DRY",
        "LAMB_LEG",
        "RICE_WHITE",
        "UNKNOWN_LAMB",
        "UNKNOWN_RICE",
    ]
    assert "CAMEL_MEAT" not in first.decode("utf-8")

    couscous, _ = parsed["COUSCOUS_DRY"]
    assert couscous[3:8] == [
        "Couscous, dry",
        "Cereal Grains and Pasta",
        "fiber",
        "fiber",
        "COMPLETE",
    ]
    assert parsed["COUSCOUS_DRY"][1] == []
    assert parsed["RICE_WHITE"][1] == []
    assert parsed["RICE_WHITE"][0][7] == "COMPLETE"

    lamb, lamb_candidates = parsed["LAMB_LEG"]
    assert lamb[2:8] == [
        "22222",
        "Lamb, leg, raw",
        "Lamb, Veal, and Game Products",
        "sugars",
        "",
        "INCOMPLETE",
    ]
    unknown, unknown_candidates = parsed["UNKNOWN_LAMB"]
    assert unknown[2] == "99999" and unknown[3] == "" and unknown[7] == "NOT_FOUND"
    rice_unknown, rice_candidates = parsed["UNKNOWN_RICE"]
    assert rice_unknown[7] == "NOT_FOUND"

    complete = {
        "10001",
        "17001",
        "17002",
        "17003",
        "17004",
        "17005",
        "20028",
        "20037",
        "50620",
        "90010",
    }
    expected = {
        "LAMB_LEG": ["17002", "17001", "17003", "17004", "17005"],
        "UNKNOWN_LAMB": ["17003", "17005", "17001", "17002", "17004"],
        "UNKNOWN_RICE": ["20037", "10001", "17001", "17002", "17003"],
    }
    found = {
        "LAMB_LEG": lamb_candidates,
        "UNKNOWN_LAMB": unknown_candidates,
        "UNKNOWN_RICE": rice_candidates,
    }
    for code, lines in found.items():
        ndbs = [line.split(" | ", 1)[0] for line in lines]
        assert ndbs == expected[code]
        assert set(ndbs) <= complete
        assert "18888" not in ndbs and "22222" not in ndbs


def test_reference_seed_parses_uncertain_keywords() -> None:
    seed = read_catalog_reference_seed(MINI_CATALOG / REFERENCE_SEED_FILE)
    assert "gelatin" in seed.uncertain_keywords
    assert "gelatin" not in seed.excluded_keywords
