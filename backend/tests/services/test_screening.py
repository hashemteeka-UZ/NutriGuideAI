"""Screening (§30.1): one case per reason plus an eligible adult."""

from __future__ import annotations

from datetime import date

import pytest
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.services.screening import ProfileNotFoundError, age_in_years, screen_user
from tests.builders import make_health_condition, make_user_health_condition, make_user_profile

AS_OF = date(2026, 10, 6)


def test_eligible_adult(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn, birth_date=date(1990, 1, 1))
    supported = make_health_condition(integrity_conn, code="HYPERTENSION", is_supported=True)
    make_user_health_condition(integrity_conn, user_id=user, condition_id=supported)
    result = screen_user(session, user, AS_OF)
    assert result.eligible
    assert result.reasons == []


@pytest.mark.parametrize(
    ("birth_date", "eligible"),
    [(date(2008, 10, 7), False), (date(2008, 10, 6), True)],
    ids=["day-before-18th-birthday", "18th-birthday"],
)
def test_under_18(
    session: Session, integrity_conn: Connection, birth_date: date, eligible: bool
) -> None:
    user = make_user_profile(integrity_conn, birth_date=birth_date)
    result = screen_user(session, user, AS_OF)
    assert result.eligible is eligible
    assert result.reasons == ([] if eligible else ["UNDER_18"])


@pytest.mark.parametrize("status", ["PREGNANT", "LACTATING"])
def test_pregnant_or_lactating(session: Session, integrity_conn: Connection, status: str) -> None:
    user = make_user_profile(integrity_conn, sex="FEMALE", physiological_status=status)
    result = screen_user(session, user, AS_OF)
    assert not result.eligible
    assert result.reasons == ["PREGNANT_OR_LACTATING"]


def test_unsupported_condition(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    for code, supported in (("CKD", False), ("DIABETES_T2", True), ("DIABETES_INSULIN", False)):
        condition = make_health_condition(integrity_conn, code=code, is_supported=supported)
        make_user_health_condition(integrity_conn, user_id=user, condition_id=condition)
    result = screen_user(session, user, AS_OF)
    assert not result.eligible
    assert result.reasons == [
        "UNSUPPORTED_CONDITION:CKD",
        "UNSUPPORTED_CONDITION:DIABETES_INSULIN",
    ]


def test_all_reasons_are_reported(session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(
        integrity_conn, birth_date=date(2010, 1, 1), physiological_status="PREGNANT"
    )
    ckd = make_health_condition(integrity_conn, code="CKD", is_supported=False)
    make_user_health_condition(integrity_conn, user_id=user, condition_id=ckd)
    assert screen_user(session, user, AS_OF).reasons == [
        "UNDER_18",
        "PREGNANT_OR_LACTATING",
        "UNSUPPORTED_CONDITION:CKD",
    ]


def test_missing_profile_raises(session: Session) -> None:
    with pytest.raises(ProfileNotFoundError):
        screen_user(session, 999_999_999, AS_OF)


@pytest.mark.parametrize(
    ("birth_date", "on", "age"),
    [
        (date(1990, 6, 15), date(2026, 6, 14), 35),
        (date(1990, 6, 15), date(2026, 6, 15), 36),
        (date(2000, 2, 29), date(2026, 2, 28), 25),
        (date(2000, 2, 29), date(2026, 3, 1), 26),
    ],
)
def test_age_in_full_years(birth_date: date, on: date, age: int) -> None:
    assert age_in_years(birth_date, on) == age
