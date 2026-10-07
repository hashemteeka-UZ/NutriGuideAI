"""Multi-condition limit resolution (§28.2, §9.5b, §9.5c) on the loaded F.1 slice."""

from __future__ import annotations

import json
from decimal import Decimal
from typing import Any

import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import (
    ConditionNutrientLimit,
    DietaryTag,
    HealthCondition,
    MealPlan,
    MealPlanItem,
    Nutrient,
)
from app.services.condition_limits import (
    ConditionConflictError,
    ConditionLimitError,
    resolve_condition_limits,
)
from app.services.planner import create_day_plan
from tests.builders import (
    make_condition_nutrient_limit,
    make_condition_tag_restriction,
    make_dietary_tag,
    make_health_condition,
    make_user_health_condition,
    make_user_profile,
)
from tests.services.conftest import (
    NOW,
    PLAN_DATE,
    add_conditions,
    case_1_user,
    plan_target,
)

D = Decimal


def _nutrient_id(session: Session, code: str) -> int:
    return session.execute(select(Nutrient.nutrient_id).where(Nutrient.code == code)).scalar_one()


def _seed_limit(session: Session, condition: str, nutrient: str) -> ConditionNutrientLimit:
    return session.execute(
        select(ConditionNutrientLimit)
        .join(HealthCondition, HealthCondition.condition_id == ConditionNutrientLimit.condition_id)
        .where(
            HealthCondition.code == condition,
            ConditionNutrientLimit.nutrient_id == _nutrient_id(session, nutrient),
        )
    ).scalar_one()


def _floats(value: Any) -> list[Any]:
    if isinstance(value, float):
        return [value]
    if isinstance(value, dict):
        return [f for v in value.values() for f in _floats(v)]
    if isinstance(value, list):
        return [f for v in value for f in _floats(v)]
    return []


def _supported_condition(conn: Connection) -> int:
    return make_health_condition(conn, is_supported=True)


def test_no_condition_gives_no_limit(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    limits = resolve_condition_limits(slice_session, user, 2000)
    assert limits.is_empty
    assert limits.conditions == ()
    assert limits.avoid_tags == frozenset()
    assert dict(limits.limit_tags) == {}
    snapshot = limits.to_snapshot()
    assert snapshot["max_per_day"] == snapshot["min_per_day"] == snapshot["max_per_meal"] == {}


def test_strictest_sodium_wins_and_both_sources_are_kept(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HYPERTENSION", "HEART_DISEASE")
    limits = resolve_condition_limits(slice_session, user, 2000)

    hypertension = _seed_limit(slice_session, "HYPERTENSION", "sodium")
    heart = _seed_limit(slice_session, "HEART_DISEASE", "sodium")
    sodium = limits.max_per_day["sodium"]
    assert sodium.value == min(D(str(hypertension.max_per_day)), D(str(heart.max_per_day)))
    assert sodium.value == 2000
    assert [(s.condition_code, s.source_reference, s.value) for s in sodium.sources] == [
        ("HEART_DISEASE", heart.source_reference, D(str(heart.max_per_day))),
        ("HYPERTENSION", hypertension.source_reference, D(str(hypertension.max_per_day))),
    ]
    assert limits.limit_tags == {"high_sodium": 3}


def test_percent_energy_per_day_is_converted_with_target_kcal(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HEART_DISEASE")
    limits = resolve_condition_limits(slice_session, user, 2000)
    saturated = limits.max_per_day["saturated_fat"]
    assert abs(saturated.value - D(6) / 100 * 2000 / 9) < D("0.001")
    assert abs(saturated.value - D("13.333")) < D("0.001")
    [source] = saturated.sources
    assert (source.limit_basis, source.stated_value) == ("PERCENT_ENERGY", D(6))
    assert limits.max_per_day["cholesterol"].value == D(
        str(_seed_limit(slice_session, "HEART_DISEASE", "cholesterol").max_per_day)
    )


def test_diabetes_limits_and_tags(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "DIABETES_T2", "HYPERTENSION")
    target_kcal = D(1800)
    limits = resolve_condition_limits(slice_session, user, target_kcal)

    carbohydrate = limits.max_per_meal["carbohydrate"]
    assert carbohydrate.value == 60
    assert [s.limit_basis for s in carbohydrate.sources] == ["ABSOLUTE"]
    sugars_percent = D(str(_seed_limit(slice_session, "DIABETES_T2", "sugars").max_per_day))
    assert sugars_percent == 10
    assert limits.max_per_day["sugars"].value == sugars_percent / 100 * target_kcal / 4
    assert limits.min_per_day["fiber"].value == 25
    assert limits.avoid_tags == frozenset({"added_sugar"})
    assert limits.limit_tags == {"high_sodium": 3, "high_sugar": 3}
    assert limits.max_per_meal_percent_energy == {}
    assert limits.conditions == ("DIABETES_T2", "HYPERTENSION")


def test_percent_energy_per_meal_stays_a_percentage(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    strict, loose = _supported_condition(integrity_conn), _supported_condition(integrity_conn)
    saturated = _nutrient_id(slice_session, "saturated_fat")
    for condition, percent in ((strict, 8), (loose, 12)):
        make_condition_nutrient_limit(
            integrity_conn,
            condition_id=condition,
            nutrient_id=saturated,
            limit_basis="PERCENT_ENERGY",
            max_per_day=None,
            max_per_meal=percent,
        )
        make_user_health_condition(integrity_conn, user_id=user, condition_id=condition)
    limits = resolve_condition_limits(slice_session, user, 2000)
    assert limits.max_per_meal == {}
    assert limits.max_per_meal_percent_energy["saturated_fat"].value == 8
    assert len(limits.max_per_meal_percent_energy["saturated_fat"].sources) == 2


def test_limit_tags_take_the_smallest_number_and_keep_null_only_tags(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    first, second = _supported_condition(integrity_conn), _supported_condition(integrity_conn)
    numbered = make_dietary_tag(integrity_conn, tag_group="CONDITION")
    unnumbered = make_dietary_tag(integrity_conn, tag_group="CONDITION")
    for condition, tag, weekly in (
        (first, numbered, None),
        (second, numbered, 5),
        (first, unnumbered, None),
        (second, unnumbered, None),
    ):
        make_condition_tag_restriction(
            integrity_conn,
            condition_id=condition,
            tag_id=tag,
            restriction_type="LIMIT",
            max_servings_per_week=weekly,
        )
    for condition in (first, second):
        make_user_health_condition(integrity_conn, user_id=user, condition_id=condition)
    codes = dict(
        slice_session.execute(
            select(DietaryTag.tag_id, DietaryTag.code).where(
                DietaryTag.tag_id.in_([numbered, unnumbered])
            )
        )
        .tuples()
        .all()
    )
    limits = resolve_condition_limits(slice_session, user, 2000)
    assert limits.limit_tags == {codes[numbered]: 5, codes[unnumbered]: None}
    assert limits.avoid_tags == frozenset()


def test_percent_energy_on_a_non_energy_nutrient_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    condition = _supported_condition(integrity_conn)
    make_condition_nutrient_limit(
        integrity_conn,
        condition_id=condition,
        nutrient_id=_nutrient_id(slice_session, "sodium"),
        limit_basis="PERCENT_ENERGY",
        max_per_day=5,
    )
    make_user_health_condition(integrity_conn, user_id=user, condition_id=condition)
    with pytest.raises(ConditionLimitError, match="sodium"):
        resolve_condition_limits(slice_session, user, 2000)


def test_snapshot_is_json_with_exact_decimal_strings(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    add_conditions(
        slice_session, integrity_conn, user, "DIABETES_T2", "HYPERTENSION", "HEART_DISEASE"
    )
    limits = resolve_condition_limits(slice_session, user, 2000)
    snapshot = limits.to_snapshot()
    assert json.loads(json.dumps(snapshot)) == snapshot
    assert _floats(snapshot) == []
    saturated = snapshot["max_per_day"]["saturated_fat"]
    assert D(saturated["value"]) == limits.max_per_day["saturated_fat"].value
    assert saturated["sources"][0]["condition"] == "HEART_DISEASE"
    assert [s["condition"] for s in snapshot["max_per_day"]["sodium"]["sources"]] == [
        "HEART_DISEASE",
        "HYPERTENSION",
    ]
    assert snapshot["avoid_tags"] == {"added_sugar": ["DIABETES_T2"]}
    assert snapshot["limit_tags"]["high_sodium"] == {
        "max_servings_per_week": 3,
        "conditions": ["HEART_DISEASE", "HYPERTENSION"],
    }
    assert snapshot["conditions"] == ["DIABETES_T2", "HEART_DISEASE", "HYPERTENSION"]


def _conflicting_user(session: Session, conn: Connection) -> tuple[int, str, str]:
    """Two test-only supported conditions: fiber min 30 and fiber max 20."""
    fiber = _nutrient_id(session, "fiber")
    minimum, maximum = _supported_condition(conn), _supported_condition(conn)
    make_condition_nutrient_limit(
        conn, condition_id=minimum, nutrient_id=fiber, max_per_day=None, min_per_day=30
    )
    make_condition_nutrient_limit(conn, condition_id=maximum, nutrient_id=fiber, max_per_day=20)
    user = case_1_user(conn)
    for condition in (minimum, maximum):
        make_user_health_condition(conn, user_id=user, condition_id=condition)
    codes = dict(
        session.execute(
            select(HealthCondition.condition_id, HealthCondition.code).where(
                HealthCondition.condition_id.in_([minimum, maximum])
            )
        )
        .tuples()
        .all()
    )
    return user, codes[minimum], codes[maximum]


def test_conflicting_limits_raise(slice_session: Session, integrity_conn: Connection) -> None:
    user, minimum, maximum = _conflicting_user(slice_session, integrity_conn)
    with pytest.raises(ConditionConflictError) as caught:
        resolve_condition_limits(slice_session, user, 2000)
    error = caught.value
    assert error.nutrient == "fiber"
    assert (error.min_per_day, error.max_per_day) == (30, 20)
    assert error.conditions == tuple(sorted((minimum, maximum)))
    assert minimum in str(error) and maximum in str(error)


def test_conflict_writes_no_plan(slice_session: Session, integrity_conn: Connection) -> None:
    user, _minimum, _maximum = _conflicting_user(slice_session, integrity_conn)
    plan_target(slice_session, user)
    with pytest.raises(ConditionConflictError):
        create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert slice_session.execute(select(func.count()).select_from(MealPlan)).scalar_one() == 0
    assert slice_session.execute(select(func.count()).select_from(MealPlanItem)).scalar_one() == 0
