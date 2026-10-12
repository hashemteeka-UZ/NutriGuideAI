"""catalog_v1 manifest matches the committed catalog and notices a changed meal file."""

from __future__ import annotations

from pathlib import Path

import pytest

from app.pipeline.build import DEFAULT_DATA_DIR
from app.pipeline.manifest import CHECK_MESSAGE, check_manifest, main
from tests.pipeline.helpers import copy_mini


def test_committed_catalog_matches_manifest() -> None:
    assert check_manifest(DEFAULT_DATA_DIR) == []


def test_changed_meal_file_fails_check_until_rewritten(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    data_dir = copy_mini(tmp_path)
    meal = data_dir / "meals" / "batch_01.yaml"
    assert main(["--data-dir", str(data_dir), "--write"]) == 0
    assert main(["--data-dir", str(data_dir), "--check"]) == 0

    text = meal.read_text(encoding="utf-8")
    meal.write_text(text.replace("Hashem", "HasheN", 1), encoding="utf-8")
    code = main(["--data-dir", str(data_dir), "--check"])
    captured = capsys.readouterr()
    assert code == 1
    assert CHECK_MESSAGE in captured.out
    assert "meals/batch_01.yaml" in captured.out

    assert main(["--data-dir", str(data_dir), "--write"]) == 0
    assert main(["--data-dir", str(data_dir), "--check"]) == 0
