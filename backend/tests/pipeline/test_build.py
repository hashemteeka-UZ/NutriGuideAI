"""Catalog build: classification outcomes, authoring errors, report determinism."""

from __future__ import annotations

from pathlib import Path

import pytest

from app.pipeline.build import build_catalog
from app.pipeline.classify import Outcome
from app.pipeline.files import CatalogAuthoringError
from tests.pipeline.helpers import MINI_CATALOG, copy_mini

GOLDEN_REPORTS = MINI_CATALOG / "reports"


def _outcomes(result: object, kind: str) -> dict[str, tuple[str, str]]:
    mapping = getattr(result.classified, kind)
    return {key: (rec.outcome.value, rec.reason) for key, rec in mapping.items()}


def test_mini_catalog_classifies_the_required_cases(tmp_path: Path) -> None:
    result = build_catalog(copy_mini(tmp_path))
    foods = _outcomes(result, "foods")
    ingredients = _outcomes(result, "ingredients")
    meals = _outcomes(result, "meals")

    assert foods["99013"] == (Outcome.ACCEPTED.value, "")
    assert foods["20037"] == (Outcome.QUARANTINE.value, "missing_mandatory_nutrient")
    assert foods["10123"] == (Outcome.EXCLUDED.value, "non_permissible_ingredient")
    assert foods["19177"] == (Outcome.QUARANTINE.value, "ingredient_status_uncertain")
    assert foods["CAMEL_MEAT"] == (Outcome.ACCEPTED.value, "")

    assert ingredients["LAMB_LEG"][0] == Outcome.ACCEPTED.value
    assert ingredients["WHITE_RICE"] == (Outcome.QUARANTINE.value, "missing_mandatory_nutrient")
    assert ingredients["PORK_SHOULDER"] == (Outcome.EXCLUDED.value, "non_permissible_ingredient")
    assert ingredients["BEEF_GELATIN"] == (Outcome.QUARANTINE.value, "ingredient_status_uncertain")
    assert ingredients["CAMEL_MEAT"][0] == Outcome.ACCEPTED.value

    assert meals["NG-GOLD-01"] == (Outcome.ACCEPTED.value, "")
    assert meals["NG-SILVER-01"] == (Outcome.ACCEPTED.value, "")
    assert meals["NG-MISSNA-01"] == (Outcome.QUARANTINE.value, "uses_quarantined_ingredient")
    assert meals["NG-PORK-01"] == (Outcome.EXCLUDED.value, "uses_excluded_ingredient")
    assert meals["NG-GEL-01"] == (Outcome.QUARANTINE.value, "uses_quarantined_ingredient")
    assert meals["NG-DRAFT-01"] == (Outcome.QUARANTINE.value, "not_reviewed")
    assert meals["NG-HISOD-01"] == (Outcome.QUARANTINE.value, "G10")

    # 99013 / sugars=0 is synthetic fixture data, not a row from official FNDDS.
    fills = [fill for food in result.classified.filled.values() for fill in food.fills]
    assert [(f.ndb, f.nutrient_code, f.value) for f in fills] == [("99013", "sugars", 0)]
    assert "sugars from FNDDS 2021-2023 Ingredient Nutrient Values" in (
        result.classified.filled["99013"].source_reference
    )


def test_authoring_errors_are_all_reported_together(tmp_path: Path) -> None:
    data_dir = copy_mini(tmp_path)
    meals = data_dir / "meals" / "batch_01.yaml"
    text = meals.read_text(encoding="utf-8")
    text = text.replace("  yield_factor_kind: TEAM_ESTIMATE\n", "")
    text += """
- ref_external: NG-GOLD-01
  name_ar: مكرر
  name_en: Duplicate
  cuisine: LIBYAN
  servings: 1
  weight_method: SUM_OF_INGREDIENTS
  yield_factor: null
  yield_factor_source: null
  variant_group: null
  occasion_tags: [snack_suitable]
  dietary_tags: []
  reviewed_by: Hashem
  ingredients:
  - {code: YOGURT_PLAIN, grams: 50, label_ar: زبادي}
- ref_external: BAD-01
  name_ar: سيء
  name_en: Bad prefix
  cuisine: LIBYAN
  servings: 1
  weight_method: SUM_OF_INGREDIENTS
  yield_factor: null
  yield_factor_source: null
  variant_group: null
  occasion_tags: [snack_suitable]
  dietary_tags: []
  reviewed_by: Hashem
  ingredients:
  - {code: NOT_AN_INGREDIENT, grams: 10, label_ar: مجهول}
"""
    meals.write_text(text, encoding="utf-8")
    subset = data_dir / "sources" / "sr_legacy_subset.csv"
    edited = subset.read_text(encoding="utf-8").replace(",60\n", ",61\n", 1)
    subset.write_text(edited, encoding="utf-8")

    with pytest.raises(CatalogAuthoringError) as exc:
        build_catalog(data_dir)
    report = exc.value.format()
    assert "unknown ingredient code 'NOT_AN_INGREDIENT'" in report
    assert "duplicate ref_external" in report
    assert "must start with 'NG-'" in report
    assert "yield_factor_kind is required when weight_method is YIELD_FACTOR" in report
    assert "SHA-256" in report and "differs from source_manifest.yaml" in report


def test_reports_are_byte_identical_across_two_builds(tmp_path: Path) -> None:
    first = copy_mini(tmp_path / "a")
    second = copy_mini(tmp_path / "b")
    a = build_catalog(first)
    b = build_catalog(second)
    golden_report = (GOLDEN_REPORTS / "run_report.md").read_bytes()
    golden_records = (GOLDEN_REPORTS / "records.csv").read_bytes()
    assert a.run_report.read_bytes() == b.run_report.read_bytes() == golden_report
    assert a.records.read_bytes() == b.records.read_bytes() == golden_records
