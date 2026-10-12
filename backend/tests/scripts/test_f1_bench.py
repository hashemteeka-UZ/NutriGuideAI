"""The F.1 benchmark database holds the slice alone and does not change its source."""

from __future__ import annotations

from pathlib import Path

from sqlalchemy import func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.db.models import Food, Meal
from scripts.f1_scenario_report import (
    CATALOG_OUTPUT_PATH,
    OUTPUT_PATH,
    drop_f1_bench,
    f1_bench_name,
    setup_f1_bench,
    write_scenario_report,
)


def _public_row_counts(engine: Engine) -> list[tuple[str, int]]:
    with engine.connect() as conn:
        names = list(
            conn.execute(
                text(
                    "SELECT c.relname FROM pg_class c "
                    "JOIN pg_namespace n ON n.oid = c.relnamespace "
                    "WHERE n.nspname = 'public' AND c.relkind = 'r' "
                    "ORDER BY c.relname"
                )
            ).scalars()
        )
        counts: list[tuple[str, int]] = []
        for name in names:
            if not name.isidentifier():
                raise AssertionError(name)
            count = conn.execute(text(f"SELECT count(*) FROM {name}")).scalar_one()
            counts.append((name, int(count)))
        return counts


def test_f1_bench_holds_the_slice_and_leaves_the_source(test_db_engine: Engine) -> None:
    before = _public_row_counts(test_db_engine)
    engine = setup_f1_bench(test_db_engine.url)
    try:
        assert engine.url.database == f1_bench_name(test_db_engine.url.database)
        assert engine.url.database != test_db_engine.url.database
        with Session(engine) as session:
            meals = session.execute(select(func.count()).select_from(Meal)).scalar_one()
            foods = session.execute(select(func.count()).select_from(Food)).scalar_one()
        assert meals == 35
        assert foods == 62
    finally:
        engine.dispose()
        drop_f1_bench(test_db_engine.url)
    assert _public_row_counts(test_db_engine) == before


def test_catalog_report_writes_its_file_and_rolls_back(
    test_db_engine: Engine, tmp_path: Path
) -> None:
    """The catalog report path writes its own file and leaves the database it reads unchanged."""
    source_before = _public_row_counts(test_db_engine)
    engine = setup_f1_bench(test_db_engine.url)
    output = tmp_path / CATALOG_OUTPUT_PATH.name
    try:
        before = _public_row_counts(engine)
        code = write_scenario_report(engine, output)
        assert code == 0
        assert output.name == CATALOG_OUTPUT_PATH.name
        assert output.resolve() != OUTPUT_PATH.resolve()
        text = output.read_text(encoding="utf-8")
        assert "## 1. Data and versions" in text
        assert "dataset_version" in text
        assert _public_row_counts(engine) == before
    finally:
        engine.dispose()
        drop_f1_bench(test_db_engine.url)
    assert _public_row_counts(test_db_engine) == source_before
