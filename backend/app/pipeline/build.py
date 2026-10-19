"""Build the catalog: read → validate → fill → gate → classify → report [→ load].

    uv run python -m app.pipeline.build [--data-dir PATH] [--load]

Regenerate the committed mini-catalog golden reports (never from pytest):

    uv run python -m app.pipeline.build --data-dir tests/fixtures/catalog_mini
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy.orm import Session

from app.pipeline.classify import Classification, classify, fill_foods
from app.pipeline.files import CatalogAuthoringError, CatalogFiles, read_catalog
from app.pipeline.gates import run_catalog_gates
from app.pipeline.load import CatalogLoadReport, load_catalog
from app.pipeline.report import write_reports
from app.seed.f1_loader import unseeded_condition_user_errors

DEFAULT_DATA_DIR = Path(__file__).resolve().parents[2] / "data" / "catalog"
AUTHORING_GATES = ("G7", "G9", "G13")


@dataclass
class BuildResult:
    files: CatalogFiles
    classified: Classification
    load: CatalogLoadReport | None
    run_report: Path
    records: Path


def build_catalog(
    data_dir: Path,
    *,
    session: Session | None = None,
    load: bool = False,
) -> BuildResult:
    files = read_catalog(data_dir)
    filled = fill_foods(files)
    amounts = {key: food.amounts for key, food in filled.items()}
    gates = run_catalog_gates(files, amounts)
    authoring = [str(f) for name in AUTHORING_GATES for f in gates.get(name, [])]
    if load and session is not None:
        authoring.extend(
            unseeded_condition_user_errors(session, {c.code for c in files.seed.health_conditions})
        )
    if authoring:
        raise CatalogAuthoringError(authoring)
    classified = classify(files, filled, gates)
    load_report = None
    if load:
        if session is None:
            raise ValueError("session is required when load=True")
        with session.begin_nested():
            load_report = load_catalog(session, files, classified)
    run_report, records = write_reports(data_dir, files, classified, load_report)
    return BuildResult(
        files=files,
        classified=classified,
        load=load_report,
        run_report=run_report,
        records=records,
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate, classify and optionally load the catalog."
    )
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    parser.add_argument("--load", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.load:
            from app.db.session import SessionLocal

            with SessionLocal() as session:
                result = build_catalog(args.data_dir, session=session, load=True)
                session.commit()
        else:
            result = build_catalog(args.data_dir)
    except CatalogAuthoringError as exc:
        print(exc.format(), file=sys.stderr)
        return 1
    accepted = sum(1 for r in result.classified.meals.values() if r.outcome.value == "accepted")
    print(f"wrote {result.run_report} and {result.records}; accepted meals: {accepted}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
