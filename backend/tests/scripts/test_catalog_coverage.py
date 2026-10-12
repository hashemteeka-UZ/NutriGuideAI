"""The coverage report writes its file, stays byte-identical, and rolls back."""

from __future__ import annotations

from pathlib import Path

from sqlalchemy.engine import Engine

from scripts.catalog_coverage_report import OUTPUT_PATH, write_coverage_report
from scripts.f1_scenario_report import drop_f1_bench, setup_f1_bench
from tests.scripts.test_f1_bench import _public_row_counts


def test_coverage_report_is_deterministic_and_rolls_back(
    test_db_engine: Engine, tmp_path: Path
) -> None:
    source_before = _public_row_counts(test_db_engine)
    engine = setup_f1_bench(test_db_engine.url)
    first = tmp_path / OUTPUT_PATH.name
    second = tmp_path / "catalog_coverage_report_again.md"
    try:
        before = _public_row_counts(engine)
        assert write_coverage_report(engine, first) == 0
        assert write_coverage_report(engine, second) == 0
        assert first.name == OUTPUT_PATH.name
        assert first.resolve() != OUTPUT_PATH.resolve()
        text = first.read_text(encoding="utf-8")
        assert text == second.read_text(encoding="utf-8")
        assert "## 1. Data and versions" in text
        assert "dataset_version" in text
        assert "tag_rules_version" in text
        assert _public_row_counts(engine) == before
    finally:
        engine.dispose()
        drop_f1_bench(test_db_engine.url)
    assert _public_row_counts(test_db_engine) == source_before
