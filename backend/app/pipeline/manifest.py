"""Frozen catalog manifest (`catalog_v3`, Decision #99).

`catalog_v3` is a new frozen catalog version. `catalog_v2` stays reachable through the
`dataset-v2` git tag.

    uv run python -m app.pipeline.manifest --write
    uv run python -m app.pipeline.manifest --check

`--write` records hashes, rule versions, and classification counts.
`--check` exits non-zero and prints every mismatch. Generated reports are not hashed.
"""

from __future__ import annotations

import argparse
import sys
from collections.abc import Mapping
from pathlib import Path
from typing import Any

import yaml

from app.db.models.catalog import QualityTier
from app.pipeline.build import AUTHORING_GATES, DEFAULT_DATA_DIR
from app.pipeline.classify import Classification, ClassifiedRecord, Outcome, classify, fill_foods
from app.pipeline.files import MEALS_DIR, CatalogAuthoringError, CatalogFiles, read_catalog
from app.pipeline.gates import run_catalog_gates
from app.pipeline.load import quality_tier
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.planner import PLANNER_VERSION
from app.services.tag_rules import TAG_RULES_VERSION

DATASET_VERSION = "catalog_v3"
MANIFEST_FILE = "DATASET_MANIFEST.yaml"
CHECK_MESSAGE = (
    'catalog files changed: run "uv run python -m app.pipeline.manifest --write" '
    "and review the diff"
)


def manifest_path(data_dir: Path) -> Path:
    return data_dir / MANIFEST_FILE


def _classify(data_dir: Path) -> tuple[CatalogFiles, Classification]:
    files = read_catalog(data_dir)
    filled = fill_foods(files)
    amounts = {key: food.amounts for key, food in filled.items()}
    gates = run_catalog_gates(files, amounts)
    authoring = [str(failure) for name in AUTHORING_GATES for failure in gates.get(name, [])]
    if authoring:
        raise CatalogAuthoringError(authoring)
    return files, classify(files, filled, gates)


def _outcome_counts(records: Mapping[str, ClassifiedRecord]) -> dict[str, int]:
    counts = {outcome.value: 0 for outcome in Outcome}
    for record in records.values():
        counts[record.outcome.value] += 1
    return counts


def _tier_counts(files: CatalogFiles, classified: Classification) -> dict[str, int]:
    counts = {tier.value: 0 for tier in QualityTier}
    for _batch, meal in files.meals:
        if classified.meals[meal.ref_external].outcome is Outcome.ACCEPTED:
            counts[quality_tier(meal).value] += 1
    return counts


def _meal_batches(data_dir: Path, files: CatalogFiles) -> dict[str, dict[str, object]]:
    paths = sorted((data_dir / MEALS_DIR).glob("*.yaml"))
    if len(paths) != len(files.meal_files):
        raise CatalogAuthoringError(["meal file count does not match parsed batches"])
    batches: dict[str, dict[str, object]] = {}
    for path, batch in zip(paths, files.meal_files, strict=True):
        batches[path.relative_to(data_dir).as_posix()] = {
            "dataset_version": batch.dataset_version,
            "meal_count": len(batch.meals),
        }
    return batches


def build_document(data_dir: Path) -> dict[str, Any]:
    """Manifest body from the catalog files and the same classification the build uses."""
    files, classified = _classify(data_dir)
    return {
        "dataset_version": DATASET_VERSION,
        "rule_versions": {
            "computation_version": COMPUTATION_VERSION,
            "tag_rules_version": TAG_RULES_VERSION,
            "planner_version": PLANNER_VERSION,
        },
        "curated_files": dict(files.input_hashes),
        "raw_files": [
            {"name": raw.name, "sha256": raw.sha256, "download_page": raw.download_page}
            for raw in files.manifest.raw_files
        ],
        "counts": {
            "foods": _outcome_counts(classified.foods),
            "ingredients": _outcome_counts(classified.ingredients),
            "meals": _outcome_counts(classified.meals),
            "meal_tiers": _tier_counts(files, classified),
        },
        "meal_batches": _meal_batches(data_dir, files),
    }


def render_manifest(document: Mapping[str, Any]) -> str:
    text = yaml.safe_dump(
        document,
        sort_keys=True,
        allow_unicode=True,
        default_flow_style=False,
        width=4096,
    )
    if not text.endswith("\n"):
        text += "\n"
    return text


def write_manifest(data_dir: Path) -> Path:
    path = manifest_path(data_dir)
    path.write_text(render_manifest(build_document(data_dir)), encoding="utf-8")
    return path


def _walk(stored: Any, fresh: Any, path: str) -> list[str]:
    if stored == fresh:
        return []
    prefix = path[:-1] if path.endswith(".") else path
    if isinstance(stored, dict) and isinstance(fresh, dict):
        lines: list[str] = []
        for key in sorted(set(stored) | set(fresh)):
            lines.extend(_walk(stored.get(key), fresh.get(key), f"{path}{key}."))
        return lines
    if isinstance(stored, list) and isinstance(fresh, list) and len(stored) == len(fresh):
        lines = []
        for index, (left, right) in enumerate(zip(stored, fresh, strict=True)):
            lines.extend(_walk(left, right, f"{path}[{index}]."))
        return lines
    return [f"{prefix}: {fresh!r} != {stored!r}"]


def check_manifest(data_dir: Path) -> list[str]:
    """Differences between the written manifest and a fresh classification. Empty means match."""
    path = manifest_path(data_dir)
    fresh = build_document(data_dir)
    rendered = render_manifest(fresh)
    if not path.is_file():
        return [f"{MANIFEST_FILE}: missing"]
    stored_text = path.read_text(encoding="utf-8")
    if stored_text == rendered:
        return []
    try:
        stored = yaml.safe_load(stored_text)
    except yaml.YAMLError as exc:
        return [f"{MANIFEST_FILE}: {exc}"]
    mismatches = _walk(stored, fresh, "")
    if not mismatches:
        return [f"{MANIFEST_FILE}: contents differ"]
    return mismatches


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Write or check the catalog_v3 dataset manifest.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true", help="Write DATASET_MANIFEST.yaml.")
    group.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero when the manifest differs.",
    )
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    args = parser.parse_args(argv)
    try:
        if args.write:
            path = write_manifest(args.data_dir)
            print(path)
            return 0
        mismatches = check_manifest(args.data_dir)
    except CatalogAuthoringError as exc:
        print(exc.format(), file=sys.stderr)
        return 1
    if not mismatches:
        print(manifest_path(args.data_dir))
        return 0
    print(CHECK_MESSAGE)
    for line in mismatches:
        print(line)
    return 1


if __name__ == "__main__":
    sys.exit(main())
