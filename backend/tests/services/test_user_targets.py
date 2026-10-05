"""create_user_target (§11.11, §30.6) on the migrated integrity database."""

from __future__ import annotations

import logging
import re
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import UserTarget
from app.db.models.user import TargetReason
from app.services.screening import ProfileNotFoundError
from app.services.targets import (
    MissingWeightError,
    TargetError,
    TargetValidationError,
    UserNotEligibleError,
    create_user_target,
)
from tests.builders import (
    make_health_condition,
    make_user_health_condition,
    make_user_profile,
    make_weight_log,
)

NOW = datetime(2026, 10, 6, 9, 0, tzinfo=UTC)


def _case_1_user(conn: Connection) -> int:
    """Case 1 of the targets tests: male, 30 y on NOW's local date, 180 cm, 90 kg, LOSE 0.5."""
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
    make_weight_log(conn, user_id=user, measured_on=date(2026, 9, 1), weight_kg=95)
    make_weight_log(conn, user_id=user, measured_on=date(2026, 10, 1), weight_kg=90)
    return user


def _current(session: Session, user: int) -> list[UserTarget]:
    return list(
        session.execute(
            select(UserTarget).where(UserTarget.user_id == user, UserTarget.valid_to.is_(None))
        ).scalars()
    )


def test_first_call_inserts_the_current_target(
    session: Session, integrity_conn: Connection
) -> None:
    user = _case_1_user(integrity_conn)
    target = create_user_target(session, user, TargetReason.INITIAL, NOW)

    assert _current(session, user) == [target]
    session.refresh(target)
    assert target.valid_from == NOW
    assert target.based_on_weight_kg == 90
    assert (target.bmr_kcal, target.tdee_kcal, target.target_kcal) == (1880.0, 2914.0, 2364.0)
    assert (target.target_protein_g, target.target_fat_g, target.target_carb_g) == (
        126.0,
        78.8,
        287.7,
    )
    assert target.formula_version == "targets_v1"
    assert target.reason == "INITIAL"
    assert target.was_floor_applied is False


def test_second_call_closes_the_first(session: Session, integrity_conn: Connection) -> None:
    user = _case_1_user(integrity_conn)
    first = create_user_target(session, user, TargetReason.INITIAL, NOW)
    make_weight_log(integrity_conn, user_id=user, measured_on=date(2026, 10, 20), weight_kg=88)
    later = NOW + timedelta(days=14)
    second = create_user_target(session, user, TargetReason.WEIGHT_UPDATE, later)

    session.refresh(first)
    assert first.valid_to == second.valid_from == later
    assert _current(session, user) == [second]
    assert second.based_on_weight_kg == 88
    assert second.reason == "WEIGHT_UPDATE"
    total = session.execute(
        select(func.count()).select_from(UserTarget).where(UserTarget.user_id == user)
    ).scalar_one()
    assert total == 2


def test_age_uses_the_local_date_in_the_profile_timezone(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(
        integrity_conn, birth_date=date(2008, 10, 7), timezone="Africa/Tripoli"
    )
    make_weight_log(integrity_conn, user_id=user, weight_kg=60)
    with pytest.raises(UserNotEligibleError, match="UNDER_18"):
        create_user_target(
            session, user, TargetReason.INITIAL, datetime(2026, 10, 6, 21, 59, tzinfo=UTC)
        )
    target = create_user_target(
        session, user, TargetReason.INITIAL, datetime(2026, 10, 6, 22, 0, tzinfo=UTC)
    )
    assert _current(session, user) == [target]


def test_unmet_carb_minimum_is_logged_without_health_values(
    session: Session, integrity_conn: Connection, caplog: pytest.LogCaptureFixture
) -> None:
    """Case (c) of §30.4: 80 y, 150 cm, 120 kg; none of these values may reach the log."""
    user = make_user_profile(
        integrity_conn,
        sex="FEMALE",
        birth_date=date(1946, 1, 1),
        height_cm=150,
        activity_level="SEDENTARY",
        goal_type="LOSE",
        target_weight_kg=90,
        weekly_rate_kg=1.0,
    )
    make_weight_log(integrity_conn, user_id=user, weight_kg=120)
    with caplog.at_level(logging.DEBUG, logger="app.services.targets"):
        target = create_user_target(session, user, TargetReason.INITIAL, NOW)

    assert target.target_carb_g == 126.9
    [record] = [r for r in caplog.records if r.name == "app.services.targets"]
    assert record.levelno == logging.WARNING
    assert record.args == ("targets_v1", user, "LOSE", "SEDENTARY", Decimal("126.9"))
    message = record.getMessage()
    assert f"user_id={user} " in message
    assert "carb_g=126.9" in message
    health_value = re.compile(r"(?<![\d.])(150|120|80)(\.0+)?(?![\d.])")
    assert not health_value.search(message.replace(f"user_id={user} ", ""))
    other_args = [str(arg) for i, arg in enumerate(record.args) if i != 1]
    assert not [arg for arg in other_args if health_value.search(arg)]


def test_missing_weight_raises(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    with pytest.raises(MissingWeightError, match="no weight_logs row"):
        create_user_target(session, user, TargetReason.INITIAL, NOW)


def test_ineligible_user_raises(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    make_weight_log(integrity_conn, user_id=user, weight_kg=70)
    ckd = make_health_condition(integrity_conn, code="CKD", is_supported=False)
    make_user_health_condition(integrity_conn, user_id=user, condition_id=ckd)
    with pytest.raises(UserNotEligibleError) as caught:
        create_user_target(session, user, TargetReason.INITIAL, NOW)
    assert caught.value.reasons == ["UNSUPPORTED_CONDITION:CKD"]
    assert _current(session, user) == []


def test_target_weight_direction_is_validated(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(
        integrity_conn, goal_type="GAIN", target_weight_kg=65, weekly_rate_kg=0.25
    )
    make_weight_log(integrity_conn, user_id=user, weight_kg=70)
    with pytest.raises(TargetValidationError, match="GAIN requires target_weight_kg"):
        create_user_target(session, user, TargetReason.INITIAL, NOW)


def test_missing_profile_raises(session: Session) -> None:
    with pytest.raises(ProfileNotFoundError):
        create_user_target(session, 999_999_999, TargetReason.INITIAL, NOW)


def test_new_target_must_start_after_the_current_one(
    session: Session, integrity_conn: Connection
) -> None:
    user = _case_1_user(integrity_conn)
    create_user_target(session, user, TargetReason.INITIAL, NOW)
    with pytest.raises(TargetError, match="must be after"):
        create_user_target(session, user, TargetReason.PROFILE_CHANGE, NOW)


def test_naive_now_is_rejected(session: Session, integrity_conn: Connection) -> None:
    user = _case_1_user(integrity_conn)
    with pytest.raises(ValueError, match="timezone-aware"):
        create_user_target(session, user, TargetReason.INITIAL, NOW.replace(tzinfo=None))
