"""Service tests run on the migrated integrity database; each test is rolled back."""

from __future__ import annotations

from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from sqlalchemy import delete, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Meal, MealAllergen, MealNutrient, MealTag
from app.db.models.catalog import MealTagSource
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.recompute_meals import MealRecompute, recompute_active_meals

NOW = datetime(2026, 10, 6, 9, 0, tzinfo=UTC)


@pytest.fixture
def session(integrity_conn: Connection) -> Iterator[Session]:
    with Session(bind=integrity_conn) as s:
        yield s


@pytest.fixture
def slice_session(session: Session) -> Session:
    """The F.1 slice as loaded by the loader, which recomputes every meal at NOW."""
    load_f1_slice(session, DEFAULT_DATA_DIR, now=NOW)
    return session


def clear_derived_meal_data(session: Session) -> None:
    """Back to the state before any recompute: no meal_nutrients, allergens or DERIVED tags."""
    session.execute(delete(MealNutrient))
    session.execute(delete(MealAllergen))
    session.execute(delete(MealTag).where(MealTag.source == MealTagSource.DERIVED.value))


@pytest.fixture
def recomputed(slice_session: Session) -> list[MealRecompute]:
    return recompute_active_meals(slice_session, NOW)


def meal_id(session: Session, ref_external: str) -> int:
    return session.execute(
        select(Meal.meal_id).where(Meal.ref_external == ref_external)
    ).scalar_one()
