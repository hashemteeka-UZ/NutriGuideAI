"""Deterministic catalog run reports (no timestamps, stable ordering)."""

from __future__ import annotations

import csv
from collections import Counter
from collections.abc import Mapping
from pathlib import Path

from app.pipeline.classify import Classification, NutrientFill, Outcome
from app.pipeline.files import REPORTS_DIR, CatalogFiles
from app.pipeline.load import TABLES, CatalogLoadReport, quality_tier

OCCASION_CODES = (
    "breakfast_suitable",
    "lunch_suitable",
    "dinner_suitable",
    "snack_suitable",
)
RUN_REPORT_FILE = "run_report.md"
RECORDS_FILE = "records.csv"
RECORDS_COLUMNS = ("record_type", "key", "outcome", "reason", "detail")


def _count_outcomes(records: Mapping[str, object]) -> tuple[Counter[str], Counter[str]]:
    outcomes: Counter[str] = Counter()
    reasons: Counter[str] = Counter()
    for record in records.values():
        outcome = record.outcome.value  # type: ignore[attr-defined]
        outcomes[outcome] += 1
        reason = record.reason or "accepted"  # type: ignore[attr-defined]
        reasons[f"{outcome}:{reason}"] += 1
    return outcomes, reasons


def _format_counts(counter: Counter[str]) -> list[str]:
    if not counter:
        return ["  - (none)"]
    return [f"  - {key}: {counter[key]}" for key in sorted(counter)]


def format_run_report(
    files: CatalogFiles,
    classified: Classification,
    load: CatalogLoadReport | None,
) -> str:
    lines = ["# Catalog run report", ""]
    lines.append("## Input files")
    lines.append("")
    for path, digest in files.input_hashes.items():
        lines.append(f"- `{path}`: `{digest}`")
    lines.append("")

    for kind, mapping in (
        ("foods", classified.foods),
        ("ingredients", classified.ingredients),
        ("meals", classified.meals),
    ):
        outcomes, reasons = _count_outcomes(mapping)
        lines.append(f"## {kind}")
        lines.append("")
        lines.append(f"- total: {sum(outcomes.values())}")
        lines.append("- by outcome:")
        lines.extend(_format_counts(outcomes))
        lines.append("- by outcome and reason:")
        lines.extend(_format_counts(reasons))
        lines.append("")

    lines.append("## Nutrient fills (#93)")
    lines.append("")
    fills: list[NutrientFill] = []
    for food in classified.filled.values():
        fills.extend(food.fills)
    fills.sort(key=lambda f: (f.ndb, f.nutrient_code, f.source))
    if fills:
        lines.append("| ndb | nutrient | value | source |")
        lines.append("|---|---|---:|---|")
        for fill in fills:
            lines.append(f"| {fill.ndb} | {fill.nutrient_code} | {fill.value:g} | {fill.source} |")
    else:
        lines.append("No FNDDS fills.")
    lines.append("")

    accepted_meals = [
        meal
        for _, meal in files.meals
        if classified.meals[meal.ref_external].outcome is Outcome.ACCEPTED
    ]
    tiers: Counter[str] = Counter(quality_tier(meal).value for meal in accepted_meals)
    lines.append("## Meals by quality tier")
    lines.append("")
    lines.extend(_format_counts(tiers))
    lines.append("")

    occasion: Counter[str] = Counter()
    for meal in accepted_meals:
        for tag in meal.occasion_tags:
            if tag in OCCASION_CODES:
                occasion[tag] += 1
    lines.append("## Meals per occasion tag")
    lines.append("")
    for tag in OCCASION_CODES:
        lines.append(f"  - {tag}: {occasion[tag]}")
    lines.append("")

    cuisines: Counter[str] = Counter(meal.cuisine for meal in accepted_meals)
    total = sum(cuisines.values()) or 1
    lines.append("## Share per cuisine")
    lines.append("")
    for cuisine in sorted(cuisines):
        share = 100 * cuisines[cuisine] / total
        lines.append(f"  - {cuisine}: {cuisines[cuisine]} ({share:.1f}%)")
    if not cuisines:
        lines.append("  - (none)")
    lines.append("")

    if load is not None:
        lines.append("## Load counts (inserted / updated / unchanged / deactivated)")
        lines.append("")
        width = max(len(name) for name in TABLES)
        for name in TABLES:
            counts = load.tables[name]
            numbers = " / ".join(
                f"{n:>4}"
                for n in (counts.inserted, counts.updated, counts.unchanged, counts.deactivated)
            )
            lines.append(f"  {name:<{width}}  {numbers}")
        lines.append("")
        lines.append(f"- deactivated meals: {load.deactivated_meals}")
        lines.append(f"- reactivated meals: {load.reactivated_meals}")
        lines.append("")
    return "\n".join(lines)


def write_reports(
    data_dir: Path,
    files: CatalogFiles,
    classified: Classification,
    load: CatalogLoadReport | None,
) -> tuple[Path, Path]:
    reports_dir = data_dir / REPORTS_DIR
    reports_dir.mkdir(parents=True, exist_ok=True)
    run_path = reports_dir / RUN_REPORT_FILE
    records_path = reports_dir / RECORDS_FILE
    run_path.write_text(format_run_report(files, classified, load), encoding="utf-8")
    rows = [
        {
            "record_type": r.record_type,
            "key": r.key,
            "outcome": r.outcome.value,
            "reason": r.reason,
            "detail": r.detail,
        }
        for r in classified.all_records()
    ]
    with records_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(RECORDS_COLUMNS), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    return run_path, records_path
