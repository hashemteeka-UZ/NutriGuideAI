"""Water goal: user amount, clinician flag from data, then the EFSA default (#179)."""

from sqlalchemy.orm import Session

from app.db.models.user import Sex
from app.services.screening import ScreeningResult
from app.services.water import water_goal
from tests.builders import make_health_condition, make_user, make_user_health_condition


def test_defaults_are_1600_for_women_and_2000_for_men(session: Session, integrity_conn) -> None:
    user = make_user(integrity_conn)
    eligible = ScreeningResult(True, [])
    female = water_goal(session, user, eligible, Sex.FEMALE, None)
    male = water_goal(session, user, eligible, "MALE", None)
    assert (female.goal_ml, female.source, female.requires_clinician) == (1600, "DEFAULT", False)
    assert female.reminders_default_off is False
    assert (male.goal_ml, male.source) == (2000, "DEFAULT")


def test_user_amount_wins_and_a_clinician_flag_suppresses_the_default(
    session: Session, integrity_conn
) -> None:
    user = make_user(integrity_conn)
    heart = make_health_condition(
        integrity_conn,
        code="HEART_DISEASE",
        is_supported=True,
        fluid_goal_requires_clinician=True,
    )
    make_user_health_condition(integrity_conn, user_id=user, condition_id=heart)
    eligible = ScreeningResult(True, [])
    blocked = water_goal(session, user, eligible, Sex.FEMALE, None)
    assert blocked.goal_ml is None
    assert blocked.source == "NONE"
    assert blocked.requires_clinician is True
    assert blocked.reminders_default_off is True
    entered = water_goal(session, user, eligible, Sex.FEMALE, 1800)
    assert (entered.goal_ml, entered.source) == (1800, "USER")
    assert entered.requires_clinician is True
    assert entered.reminders_default_off is True


def test_ineligible_user_gets_no_default(session: Session, integrity_conn) -> None:
    user = make_user(integrity_conn)
    result = water_goal(session, user, ScreeningResult(False, ["UNDER_18"]), Sex.MALE, None)
    assert result.goal_ml is None
    assert result.source == "NONE"
    assert result.requires_clinician is False
    assert result.reminders_default_off is False
