"""The F.1 benchmark database holds the slice alone and does not change its source."""

from __future__ import annotations

from sqlalchemy import func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.db.models import Food, Meal
from scripts.f1_scenario_report import drop_f1_bench, f1_bench_name, setup_f1_bench


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
