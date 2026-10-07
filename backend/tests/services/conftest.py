"""Service tests run on the migrated integrity database; each test is rolled back."""

from __future__ import annotations

from collections.abc import Iterator
from datetime import UTC, date, datetime

import pytest
from sqlalchemy import delete, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import HealthCondition, Meal, MealAllergen, MealNutrient, MealTag
from app.db.models.catalog import MealTagSource
from app.db.models.user import TargetReason
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.planner import PlanTarget
from app.services.recompute_meals import MealRecompute, recompute_active_meals
from app.services.targets import create_user_target
from tests.builders import make_user_health_condition, make_user_profile, make_weight_log

NOW = datetime(2026, 10, 6, 9, 0, tzinfo=UTC)
PLAN_DATE = date(2026, 10, 7)


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


def condition_id(session: Session, code: str) -> int:
    return session.execute(
        select(HealthCondition.condition_id).where(HealthCondition.code == code)
    ).scalar_one()


def add_conditions(session: Session, conn: Connection, user: int, *codes: str) -> None:
    for code in codes:
        make_user_health_condition(conn, user_id=user, condition_id=condition_id(session, code))


def case_1_user(conn: Connection) -> int:
    """Targets case 1 of F.1-b: male, 30 y, 180 cm, 90 kg, MODERATE, LOSE 0.5 (2364 kcal)."""
    user = make_user_profile(
        conn,
        sex="MALE",
        birth_date=date(1996, 1, 15),
        height_cm=180,
        activity_level="MODERATE",
        goal_type="LOSE",
        target_weight_kg=80,
        weekly_rate_kg=0.5,
        timezone="Africa/Tripoli",
    )
    make_weight_log(conn, user_id=user, measured_on=date(2026, 10, 1), weight_kg=90)
    return user


def case_2_user(conn: Connection) -> int:
    """Targets case 2 of F.1-b: female, 25 y, 155 cm, 50 kg, SEDENTARY, LOSE 0.5 (floor 1200)."""
    user = make_user_profile(
        conn,
        sex="FEMALE",
        birth_date=date(2001, 1, 15),
        height_cm=155,
        activity_level="SEDENTARY",
        goal_type="LOSE",
        target_weight_kg=48,
        weekly_rate_kg=0.5,
        timezone="Africa/Tripoli",
    )
    make_weight_log(conn, user_id=user, measured_on=date(2026, 10, 1), weight_kg=50)
    return user


def plan_target(session: Session, user: int) -> PlanTarget:
    """Creates the user's current user_targets row (targets_v1) at NOW."""
    return PlanTarget.from_user_target(create_user_target(session, user, TargetReason.INITIAL, NOW))
