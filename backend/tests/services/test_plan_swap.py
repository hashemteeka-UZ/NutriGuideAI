"""swap_plan_item (§11.8, §11.9) on a stored greedy_v1 plan of the F.1 slice."""

from __future__ import annotations

from copy import deepcopy
from datetime import datetime
from decimal import Decimal
from uuid import uuid4
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import Allergen, Meal
from app.db.models.user import MealPlan, MealPlanItem, MealSlot
from app.services.common import to_decimal
from app.services.condition_limits import resolve_condition_limits
from app.services.consumption import PlanItemAlreadyLoggedError, log_plan_item
from app.services.meal_filter import evaluate_meal, load_meal_facts, load_user_preferences
from app.services.plan_swap import SwapRejectedError, swap_plan_item
from app.services.planner import (
    create_day_plan,
    placement_rejections,
    reason_codes,
    slot_target_kcal,
)
from tests.builders import make_user_allergen_pref
from tests.services.conftest import (
    NOW,
    PLAN_DATE,
    case_1_user,
    htn_dm2_plan,
    meal_id,
    plan_target,
)

EATEN = datetime(2026, 10, 7, 12, 0, tzinfo=ZoneInfo("Africa/Tripoli"))


def _item(session: Session, plan_id: int, slot: str) -> MealPlanItem:
    return session.execute(
        select(MealPlanItem)
        .where(MealPlanItem.plan_id == plan_id, MealPlanItem.slot == slot)
        .order_by(MealPlanItem.id)
        .limit(1)
    ).scalar_one()


def _items(session: Session, plan_id: int) -> list[MealPlanItem]:
    return list(
        session.execute(
            select(MealPlanItem).where(MealPlanItem.plan_id == plan_id).order_by(MealPlanItem.id)
        ).scalars()
    )


def _expected_reason_codes(
    session: Session, user: int, plan: MealPlan, item: MealPlanItem, new_meal_id: int
) -> list[str]:
    meals = {meal.meal_id: meal for meal in load_meal_facts(session)}
    others = [row for row in _items(session, plan.plan_id) if row.id != item.id]
    snack_count = sum(1 for row in others if row.slot == MealSlot.SNACK) + (
        item.slot == MealSlot.SNACK
    )
    target_kcal = to_decimal(plan.target_snapshot["target"]["kcal"])
    return list(
        reason_codes(
            meals[new_meal_id],
            to_decimal(item.servings_multiplier),
            slot_target_kcal(item.slot, target_kcal, snack_count),
            resolve_condition_limits(session, user, target_kcal),
            load_user_preferences(session, user),
        )
    )


def test_eligible_lunch_swap_sets_was_swapped_keeps_snapshot_and_recomputes_reason_codes(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    snapshot = deepcopy(plan.target_snapshot)
    lunch = _item(slice_session, plan.plan_id, "LUNCH")
    original_codes = list(lunch.reason_codes)
    replacement = meal_id(slice_session, "F1-L06")
    assert replacement not in {row.meal_id for row in _items(slice_session, plan.plan_id)}
    expected = _expected_reason_codes(slice_session, user, plan, lunch, replacement)
    swapped = swap_plan_item(slice_session, user, lunch.id, replacement, NOW)

    assert swapped.id == lunch.id
    assert swapped.meal_id == replacement
    assert swapped.was_swapped is True
    assert swapped.updated_at == NOW
    assert swapped.servings_multiplier == lunch.servings_multiplier
    assert swapped.reason_codes == expected
    assert swapped.reason_codes != original_codes
    slice_session.refresh(plan)
    assert plan.target_snapshot == snapshot


def test_swap_to_meal_with_user_allergen_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    lunch = _item(slice_session, plan.plan_id, "LUNCH")
    gluten = slice_session.execute(
        select(Allergen.allergen_id).where(Allergen.name_en == "Gluten")
    ).scalar_one()
    make_user_allergen_pref(integrity_conn, user_id=user, allergen_id=gluten)

    with pytest.raises(SwapRejectedError) as caught:
        swap_plan_item(slice_session, user, lunch.id, meal_id(slice_session, "F1-D01"), NOW)
    assert "ALLERGEN:Gluten" in caught.value.exclusion_codes
    slice_session.refresh(lunch)
    assert lunch.was_swapped is False


def test_swap_breakfast_only_meal_into_lunch_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    lunch = _item(slice_session, plan.plan_id, "LUNCH")

    with pytest.raises(SwapRejectedError) as caught:
        swap_plan_item(slice_session, user, lunch.id, meal_id(slice_session, "F1-B06"), NOW)
    assert "NO_OCCASION:LUNCH" in caught.value.exclusion_codes
    slice_session.refresh(lunch)
    assert lunch.was_swapped is False


def test_swap_to_other_member_of_a_variant_group_already_in_the_day_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    lunch = _item(slice_session, plan.plan_id, "LUNCH")
    dinner = _item(slice_session, plan.plan_id, "DINNER")
    dinner_ref = slice_session.execute(
        select(Meal.ref_external).where(Meal.meal_id == dinner.meal_id)
    ).scalar_one()
    sibling = meal_id(slice_session, f"{dinner_ref}-CH")

    with pytest.raises(SwapRejectedError) as caught:
        swap_plan_item(slice_session, user, lunch.id, sibling, NOW)
    assert "VARIANT_GROUP_USED" in caught.value.exclusion_codes
    slice_session.refresh(lunch)
    assert lunch.was_swapped is False


def test_swap_of_already_logged_item_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    lunch = _item(slice_session, plan.plan_id, "LUNCH")
    log_plan_item(slice_session, user, lunch.id, lunch.servings_multiplier, EATEN, uuid4(), NOW)

    with pytest.raises(PlanItemAlreadyLoggedError):
        swap_plan_item(slice_session, user, lunch.id, meal_id(slice_session, "F1-L06"), NOW)
    slice_session.refresh(lunch)
    assert lunch.was_swapped is False


def test_htn_dm2_swap_that_would_exceed_day_sodium_is_rejected(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    dinner = _item(slice_session, plan.plan_id, "DINNER")
    salty = meal_id(slice_session, "F1-L05")
    meals = {meal.meal_id: meal for meal in load_meal_facts(slice_session)}
    others = [
        (row.slot, meals[row.meal_id], Decimal(str(row.servings_multiplier)))
        for row in _items(slice_session, plan.plan_id)
        if row.id != dinner.id
    ]
    limits = resolve_condition_limits(
        slice_session, user, to_decimal(plan.target_snapshot["target"]["kcal"])
    )
    evaluation = evaluate_meal(
        meals[salty],
        load_user_preferences(slice_session, user),
        dinner.slot,
        limits,
        to_decimal(dinner.servings_multiplier),
    )
    predicted = placement_rejections(
        meals[salty], to_decimal(dinner.servings_multiplier), evaluation, others, limits
    )
    assert any(code.startswith("MAX_PER_DAY:sodium") for code in predicted)

    with pytest.raises(SwapRejectedError) as caught:
        swap_plan_item(slice_session, user, dinner.id, salty, NOW)
    assert "MAX_PER_DAY:sodium" in caught.value.exclusion_codes
    slice_session.refresh(dinner)
    assert dinner.was_swapped is False
    assert dinner.meal_id != salty
