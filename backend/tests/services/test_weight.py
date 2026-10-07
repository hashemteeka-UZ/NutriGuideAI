"""Weight log upsert and WEIGHT_UPDATE recompute (§11.10, §30.6, §33.4)."""

from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import UserProfile, UserTarget, WeightLog
from app.db.models.user import PhysiologicalStatus
from app.services.targets import FORMULA_VERSION
from app.services.weight import (
    CLOCK_SKEW_TOLERANCE,
    ClockSkewError,
    TargetStatus,
    WeightStatus,
    record_weight,
)
from tests.builders import make_user_profile
from tests.services.conftest import NOW, case_2_user, plan_target

D = Decimal
TODAY = date(2026, 10, 6)  # NOW (09:00 UTC) is still 11:00 in Africa/Tripoli
LATER = NOW + timedelta(hours=2)


def _current(session: Session, user: int) -> UserTarget | None:
    return session.execute(
        select(UserTarget).where(UserTarget.user_id == user, UserTarget.valid_to.is_(None))
    ).scalar_one_or_none()


def _weight_on(session: Session, user: int, measured_on: date) -> Decimal:
    value = session.execute(
        select(WeightLog.weight_kg).where(
            WeightLog.user_id == user, WeightLog.measured_on == measured_on
        )
    ).scalar_one()
    return D(str(value))


def test_first_entry_is_created(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    first = record_weight(session, user, TODAY, 70, NOW, NOW)
    assert first.status is WeightStatus.CREATED
    assert first.target_status is TargetStatus.NO_CURRENT_TARGET
    assert first.new_target_id is None
    assert _weight_on(session, user, TODAY) == 70
    assert (
        session.execute(
            select(func.count()).select_from(WeightLog).where(WeightLog.user_id == user)
        ).scalar_one()
        == 1
    )


def test_newer_updated_at_updates_the_same_day(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    record_weight(session, user, TODAY, 70, NOW, NOW)
    newer = NOW + timedelta(minutes=1)
    updated = record_weight(session, user, TODAY, 71, newer, LATER)
    assert updated.status is WeightStatus.UPDATED
    assert _weight_on(session, user, TODAY) == 71
    assert updated.weight_log.updated_at == newer


def test_older_updated_at_is_stale_ignored(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    newer = NOW + timedelta(minutes=1)
    record_weight(session, user, TODAY, 71, newer, LATER)
    stale = record_weight(session, user, TODAY, 90, NOW, LATER)
    assert stale.status is WeightStatus.STALE_IGNORED
    assert _weight_on(session, user, TODAY) == 71


def test_equal_updated_at_is_stale_ignored(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    newer = NOW + timedelta(minutes=1)
    record_weight(session, user, TODAY, 71, newer, LATER)
    equal = record_weight(session, user, TODAY, 90, newer, LATER)
    assert equal.status is WeightStatus.STALE_IGNORED
    assert _weight_on(session, user, TODAY) == 71


def test_updated_at_beyond_clock_skew_raises(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    record_weight(session, user, TODAY, 70, NOW + CLOCK_SKEW_TOLERANCE, NOW)
    with pytest.raises(ClockSkewError):
        record_weight(
            session, user, TODAY, 70, NOW + CLOCK_SKEW_TOLERANCE + timedelta(seconds=1), NOW
        )


def test_one_kg_on_the_latest_day_creates_a_weight_update_target(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    old = plan_target(slice_session, user)
    assert old.kcal == 1200
    previous = _current(slice_session, user)
    assert previous is not None

    created = record_weight(slice_session, user, TODAY, 50, NOW, LATER)
    assert created.status is WeightStatus.CREATED
    assert created.target_status is TargetStatus.NOT_TRIGGERED

    triggering = record_weight(slice_session, user, TODAY, 52, LATER, LATER)
    assert triggering.status is WeightStatus.UPDATED
    assert triggering.target_status is TargetStatus.CREATED
    assert triggering.new_target_id is not None
    new = _current(slice_session, user)
    assert new is not None and new.target_id == triggering.new_target_id
    slice_session.refresh(previous)
    assert previous.valid_to == LATER
    assert new.valid_from == LATER
    assert new.reason == "WEIGHT_UPDATE"
    assert new.based_on_weight_kg == 52
    assert new.formula_version == FORMULA_VERSION
    currents = slice_session.execute(
        select(func.count())
        .select_from(UserTarget)
        .where(UserTarget.user_id == user, UserTarget.valid_to.is_(None))
    ).scalar_one()
    assert currents == 1


def test_point_nine_kg_creates_no_target(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    plan_target(slice_session, user)
    small = record_weight(slice_session, user, TODAY, D("50.9"), NOW, LATER)
    assert small.target_status is TargetStatus.NOT_TRIGGERED
    current = _current(slice_session, user)
    assert current is not None
    assert current.based_on_weight_kg == 50
    assert current.reason == "INITIAL"


def test_back_dated_entry_three_kg_lower_creates_no_target(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    plan_target(slice_session, user)
    record_weight(slice_session, user, TODAY, 50, NOW, LATER)
    back = record_weight(slice_session, user, date(2026, 10, 2), 47, NOW, LATER)
    assert back.status is WeightStatus.CREATED
    assert back.target_status is TargetStatus.NOT_TRIGGERED
    current = _current(slice_session, user)
    assert current is not None
    assert current.reason == "INITIAL"
    assert current.based_on_weight_kg == 50


def test_user_without_a_current_target_gets_none(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    result = record_weight(session, user, TODAY, 80, NOW, NOW)
    assert result.status is WeightStatus.CREATED
    assert result.target_status is TargetStatus.NO_CURRENT_TARGET
    assert result.new_target_id is None
    assert _current(session, user) is None
    week = NOW + timedelta(days=2)
    later = record_weight(session, user, TODAY + timedelta(days=1), 85, week, week)
    assert later.target_status is TargetStatus.NO_CURRENT_TARGET
    assert _current(session, user) is None


def test_goal_reached_within_one_kg_of_target_weight(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    plan_target(slice_session, user)
    far = record_weight(slice_session, user, TODAY, 50, NOW, LATER)
    assert far.goal_reached is False
    near = record_weight(slice_session, user, TODAY, 48, LATER, LATER)
    assert near.goal_reached is True
    edge = record_weight(
        slice_session, user, TODAY, 49, LATER + timedelta(minutes=1), LATER + timedelta(hours=1)
    )
    assert edge.goal_reached is True


def test_ineligible_path_keeps_the_weight_row_and_the_old_target(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    plan_target(slice_session, user)
    previous = _current(slice_session, user)
    assert previous is not None
    profile = slice_session.get(UserProfile, user)
    assert profile is not None
    profile.physiological_status = PhysiologicalStatus.PREGNANT
    slice_session.flush()

    result = record_weight(slice_session, user, TODAY, 52, LATER, LATER)
    assert result.status is WeightStatus.CREATED
    assert result.target_status is TargetStatus.INELIGIBLE
    assert result.new_target_id is None
    assert _weight_on(slice_session, user, TODAY) == 52
    current = _current(slice_session, user)
    assert current is not None
    assert current.target_id == previous.target_id
    assert current.reason == "INITIAL"
    assert current.valid_to is None
    assert current.based_on_weight_kg == 50


def test_out_of_range_weight_is_rejected_before_the_check(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    with pytest.raises(ValueError, match="weight_kg"):
        record_weight(session, user, TODAY, 19, NOW, NOW)
    with pytest.raises(ValueError, match="weight_kg"):
        record_weight(session, user, TODAY, 401, NOW, NOW)
    assert session.execute(select(func.count()).select_from(WeightLog)).scalar_one() == 0
