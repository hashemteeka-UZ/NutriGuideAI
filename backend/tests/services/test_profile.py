"""Profile save: one target per save, children by difference, goal checked before screening."""

import logging
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import (
    UserAllergenPref,
    UserCuisinePref,
    UserHealthCondition,
    UserIngredientPref,
    UserProfile,
    UserTarget,
    WeightLog,
)
from app.db.models.user import ActivityLevel, GoalType, Sex, TargetReason
from app.services.common import InvalidTimezoneError
from app.services.profile import (
    AllergenInput,
    ConditionInput,
    IngredientInput,
    ProfileInput,
    UnknownCodeError,
    load_profile,
    save_profile,
)
from app.services.screening import ProfileNotFoundError
from app.services.targets import (
    MissingWeightError,
    TargetInputs,
    TargetValidationError,
    compute_targets,
)
from tests.builders import (
    make_allergen,
    make_cuisine,
    make_health_condition,
    make_ingredient,
    make_user,
)

NOW = datetime(2026, 10, 12, 9, 0, tzinfo=UTC)
LATER = NOW + timedelta(minutes=5)


def _input(conn: Connection, **overrides: object) -> ProfileInput:
    values: dict[str, object] = {
        "sex": "MALE",
        "birth_date": date(1996, 1, 15),
        "height_cm": 180.0,
        "activity_level": "MODERATE",
        "goal_type": "LOSE",
        "target_weight_kg": 80.0,
        "weekly_rate_kg": 0.5,
        "timezone": "Africa/Tripoli",
        "wake_time": time(7, 0),
        "sleep_time": time(23, 0),
        "water_goal_ml": None,
        "current_weight_kg": 90.0,
        "conditions": (),
        "allergens": (),
        "ingredient_prefs": (),
        "cuisines": (),
    }
    values.update(overrides)
    return ProfileInput(**values)  # type: ignore[arg-type]


def _catalog(conn: Connection) -> dict[str, int]:
    return {
        "hypertension": make_health_condition(
            conn, code="HYPERTENSION", is_supported=True, fluid_goal_requires_clinician=False
        ),
        "insulin": make_health_condition(conn, code="DIABETES_INSULIN", is_supported=False),
        "heart": make_health_condition(
            conn, code="HEART_DISEASE", is_supported=True, fluid_goal_requires_clinician=True
        ),
        "gluten": make_allergen(conn, code="GLUTEN"),
        "libyan": make_cuisine(conn, code="LIBYAN"),
        "ingredient": make_ingredient(conn),
    }


def _fields(data: ProfileInput, **overrides: object) -> dict[str, object]:
    values = {
        "sex": data.sex,
        "birth_date": data.birth_date,
        "height_cm": data.height_cm,
        "activity_level": data.activity_level,
        "goal_type": data.goal_type,
        "target_weight_kg": data.target_weight_kg,
        "weekly_rate_kg": data.weekly_rate_kg,
        "timezone": data.timezone,
        "wake_time": data.wake_time,
        "sleep_time": data.sleep_time,
        "water_goal_ml": data.water_goal_ml,
        "current_weight_kg": data.current_weight_kg,
        "conditions": data.conditions,
        "allergens": data.allergens,
        "ingredient_prefs": data.ingredient_prefs,
        "cuisines": data.cuisines,
    }
    values.update(overrides)
    return values


def _counts(session: Session) -> dict[str, int]:
    models = (
        UserProfile,
        UserHealthCondition,
        UserAllergenPref,
        UserIngredientPref,
        UserCuisinePref,
        WeightLog,
        UserTarget,
    )
    return {
        model.__tablename__: int(session.scalar(select(func.count()).select_from(model)) or 0)
        for model in models
    }


def test_first_save_without_weight_writes_nothing(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    before = _counts(session)
    with pytest.raises(MissingWeightError):
        save_profile(session, user, _input(integrity_conn, current_weight_kg=None), NOW)
    assert _counts(session) == before
    with pytest.raises(ProfileNotFoundError):
        load_profile(session, user, NOW)


def test_first_save_matches_compute_targets_and_stores_children(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    catalog = _catalog(integrity_conn)
    outcome = save_profile(
        session,
        user,
        _input(
            integrity_conn,
            conditions=(ConditionInput("HYPERTENSION", "MODERATE"),),
            allergens=(AllergenInput("GLUTEN", "AVOID"),),
            ingredient_prefs=(IngredientInput(catalog["ingredient"], "LIKE"),),
            cuisines=("LIBYAN",),
        ),
        NOW,
    )
    expected = compute_targets(
        TargetInputs(
            sex=Sex.MALE,
            age_years=30,
            height_cm=Decimal(180),
            weight_kg=Decimal(90),
            activity_level=ActivityLevel.MODERATE,
            goal_type=GoalType.LOSE,
            weekly_rate_kg=Decimal("0.5"),
            target_weight_kg=Decimal(80),
        )
    )
    assert outcome.target is not None
    assert outcome.target.reason == TargetReason.INITIAL.value
    assert int(outcome.target.target_kcal) == expected.target_kcal
    assert outcome.target.target_protein_g == float(expected.protein_g)
    assert outcome.target.target_carb_g == float(expected.carb_g)
    assert outcome.target.target_fat_g == float(expected.fat_g)
    assert outcome.screening.eligible is True
    assert outcome.latest_weight == (date(2026, 10, 12), Decimal("90.000"))
    assert outcome.conditions[0].code == "HYPERTENSION"
    assert outcome.conditions[0].severity == "MODERATE"
    assert outcome.allergens[0].code == "GLUTEN"
    assert outcome.ingredient_prefs[0].ingredient_id == catalog["ingredient"]
    assert outcome.cuisines == ("LIBYAN",)
    weights = session.scalars(select(WeightLog).where(WeightLog.user_id == user)).all()
    assert len(weights) == 1
    assert weights[0].measured_on == date(2026, 10, 12)
    assert session.scalar(select(func.count()).select_from(UserTarget)) == 1


def test_target_reason_priority(session: Session, integrity_conn: Connection) -> None:
    user = make_user(integrity_conn)
    _catalog(integrity_conn)
    first = save_profile(session, user, _input(integrity_conn), NOW)
    assert first.target is not None
    maintained = _input(
        integrity_conn,
        goal_type="MAINTAIN",
        target_weight_kg=None,
        weekly_rate_kg=None,
        current_weight_kg=None,
    )
    goal = save_profile(session, user, maintained, LATER)
    assert goal.target is not None
    assert goal.target.reason == TargetReason.GOAL_CHANGE.value
    assert first.target.valid_to == LATER

    height_at = LATER + timedelta(minutes=5)
    height = save_profile(
        session, user, _input(integrity_conn, **_fields(maintained, height_cm=181)), height_at
    )
    assert height.target is not None
    assert height.target.reason == TargetReason.PROFILE_CHANGE.value
    assert goal.target.valid_to == height_at

    weight_at = height_at + timedelta(minutes=5)
    weight = save_profile(
        session,
        user,
        _input(integrity_conn, **_fields(maintained, height_cm=181, current_weight_kg=92)),
        weight_at,
    )
    assert weight.target is not None
    assert weight.target.reason == TargetReason.WEIGHT_UPDATE.value
    assert height.target.valid_to == weight_at

    small_at = weight_at + timedelta(minutes=5)
    small = save_profile(
        session,
        user,
        _input(integrity_conn, **_fields(maintained, height_cm=181, current_weight_kg=92.3)),
        small_at,
    )
    assert small.target is not None
    assert small.target.target_id == weight.target.target_id
    assert small.target.valid_to is None

    both_at = small_at + timedelta(minutes=5)
    both = save_profile(
        session,
        user,
        _input(
            integrity_conn,
            goal_type="GAIN",
            target_weight_kg=100,
            weekly_rate_kg=0.25,
            height_cm=182,
            current_weight_kg=92.3,
        ),
        both_at,
    )
    assert both.target is not None
    assert both.target.reason == TargetReason.GOAL_CHANGE.value
    assert (
        session.scalar(
            select(func.count()).select_from(UserTarget).where(UserTarget.user_id == user)
        )
        == 5
    )

    prefs = save_profile(
        session,
        user,
        _input(
            integrity_conn,
            goal_type="GAIN",
            target_weight_kg=100,
            weekly_rate_kg=0.25,
            height_cm=182,
            current_weight_kg=None,
            conditions=(ConditionInput("HYPERTENSION", "MILD"),),
            allergens=(AllergenInput("GLUTEN", "AVOID"),),
            cuisines=("LIBYAN",),
            wake_time=time(6, 30),
            water_goal_ml=2200,
        ),
        both_at + timedelta(minutes=5),
    )
    assert prefs.target is not None
    assert prefs.target.target_id == both.target.target_id


def test_invalid_goal_rolls_the_save_back(session: Session, integrity_conn: Connection) -> None:
    user = make_user(integrity_conn)
    _catalog(integrity_conn)
    save_profile(session, user, _input(integrity_conn), NOW)
    session.commit()
    before = _counts(session)
    profile_before = session.get(UserProfile, user)
    assert profile_before is not None
    goal_before = profile_before.goal_type
    target_before = profile_before.target_weight_kg
    with pytest.raises(TargetValidationError):
        save_profile(
            session,
            user,
            _input(integrity_conn, target_weight_kg=95, current_weight_kg=90),
            LATER,
        )
    session.rollback()
    session.expire_all()
    restored = session.get(UserProfile, user)
    assert restored is not None
    assert restored.goal_type == goal_before
    assert restored.target_weight_kg == target_before
    assert _counts(session) == before


def test_ineligible_save_at_the_current_instant_closes_the_target(
    session: Session, integrity_conn: Connection, caplog: pytest.LogCaptureFixture
) -> None:
    user = make_user(integrity_conn)
    _catalog(integrity_conn)
    first = save_profile(session, user, _input(integrity_conn), NOW)
    assert first.target is not None
    with caplog.at_level(logging.WARNING, logger="app.services.profile"):
        blocked = save_profile(
            session,
            user,
            _input(integrity_conn, conditions=(ConditionInput("DIABETES_INSULIN", None),)),
            NOW,
        )
    assert blocked.screening.eligible is False
    assert blocked.target is None
    session.refresh(first.target)
    assert first.target.valid_to == NOW + timedelta(microseconds=1)
    advanced = [r for r in caplog.records if "advanced" in r.getMessage()]
    assert len(advanced) == 1
    assert advanced[0].args == (user,)


def test_unsupported_condition_closes_the_target_and_removing_it_reopens(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    _catalog(integrity_conn)
    first = save_profile(session, user, _input(integrity_conn), NOW)
    assert first.target is not None
    blocked = save_profile(
        session,
        user,
        _input(integrity_conn, conditions=(ConditionInput("DIABETES_INSULIN", None),)),
        LATER,
    )
    assert blocked.screening.eligible is False
    assert blocked.screening.reasons == ["UNSUPPORTED_CONDITION:DIABETES_INSULIN"]
    assert blocked.target is None
    assert first.target.valid_to == LATER
    restored_at = LATER + timedelta(minutes=5)
    restored = save_profile(session, user, _input(integrity_conn, conditions=()), restored_at)
    assert restored.screening.eligible is True
    assert restored.target is not None
    assert restored.target.reason == TargetReason.PROFILE_CHANGE.value


def test_under_18_stores_the_profile_without_a_target(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    outcome = save_profile(session, user, _input(integrity_conn, birth_date=date(2010, 1, 1)), NOW)
    assert outcome.screening.eligible is False
    assert outcome.screening.reasons == ["UNDER_18"]
    assert outcome.target is None
    assert session.get(UserProfile, user) is not None


def test_unknown_codes_name_the_kind(session: Session, integrity_conn: Connection) -> None:
    user = make_user(integrity_conn)
    catalog = _catalog(integrity_conn)
    cases = [
        _input(integrity_conn, conditions=(ConditionInput("hypertension", None),)),
        _input(integrity_conn, allergens=(AllergenInput("gluten", "AVOID"),)),
        _input(integrity_conn, cuisines=("libyan",)),
        _input(
            integrity_conn,
            ingredient_prefs=(IngredientInput(catalog["ingredient"] + 99, "LIKE"),),
        ),
    ]
    kinds = ["condition", "allergen", "cuisine", "ingredient"]
    for data, kind in zip(cases, kinds, strict=True):
        with pytest.raises(UnknownCodeError) as caught:
            save_profile(session, user, data, NOW)
        assert caught.value.kind == kind
    with pytest.raises(InvalidTimezoneError):
        save_profile(session, user, _input(integrity_conn, timezone="Not/AZone"), NOW)


def test_unchanged_children_keep_their_timestamps(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    _catalog(integrity_conn)
    save_profile(
        session,
        user,
        _input(
            integrity_conn,
            conditions=(
                ConditionInput("HYPERTENSION", "MILD"),
                ConditionInput("HEART_DISEASE", "MODERATE"),
            ),
        ),
        NOW,
    )
    session.flush()
    kept = session.execute(
        select(UserHealthCondition, UserHealthCondition.severity).where(
            UserHealthCondition.user_id == user
        )
    ).all()
    by_severity = {severity: row for row, severity in kept}
    mild_created = by_severity["MILD"].created_at
    mild_updated = by_severity["MILD"].updated_at
    heart_created = by_severity["MODERATE"].created_at
    save_profile(
        session,
        user,
        _input(
            integrity_conn,
            conditions=(
                ConditionInput("HYPERTENSION", "MILD"),
                ConditionInput("HEART_DISEASE", "SEVERE"),
            ),
            current_weight_kg=None,
        ),
        LATER,
    )
    session.expire_all()
    rows = session.scalars(
        select(UserHealthCondition).where(UserHealthCondition.user_id == user)
    ).all()
    found = {row.severity: row for row in rows}
    assert found["MILD"].created_at == mild_created
    assert found["MILD"].updated_at == mild_updated
    assert found["SEVERE"].created_at == heart_created
    assert found["SEVERE"].severity == "SEVERE"
    assert all(row.diagnosed is False for row in rows)


def test_weight_uses_the_new_timezone_local_date(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    when = datetime(2026, 10, 12, 23, 30, tzinfo=UTC)
    save_profile(
        session,
        user,
        _input(integrity_conn, timezone="Asia/Tokyo", current_weight_kg=90),
        when,
    )
    measured = session.scalar(select(WeightLog.measured_on).where(WeightLog.user_id == user))
    assert measured == date(2026, 10, 13)
