"""Swapping the meal of a plan item (§11.8, §10.1 "switch meat", §11.9 application rule).

The new meal must pass every Layer 1 rule for the item's slot at the item's multiplier and
every day rule of the planner (no repeated meal or variant_group, max_per_day, LIMIT-tag
servings), checked with the planner's own helpers against the other items of that plan day.
Limits are re-resolved for the user's current conditions at the plan's frozen target kcal.
"""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from decimal import Decimal
from typing import Final

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.db.models import MealPlan, MealPlanItem
from app.db.models.user import MealSlot
from app.services.common import MealNotFoundError, require_aware, to_decimal
from app.services.condition_limits import resolve_condition_limits
from app.services.consumption import (
    PlanItemAlreadyLoggedError,
    PlanItemNotFoundError,
    has_active_log,
)
from app.services.meal_filter import evaluate_meal, load_meal_facts, load_user_preferences
from app.services.planner import placement_rejections, reason_codes, slot_target_kcal

SAME_MEAL: Final = "SAME_MEAL"


class SwapRejectedError(Exception):
    def __init__(self, exclusion_codes: Sequence[str]) -> None:
        self.exclusion_codes = list(exclusion_codes)
        super().__init__(f"swap rejected: {', '.join(self.exclusion_codes)}")


def plan_target_kcal(plan: MealPlan) -> Decimal:
    """target_kcal frozen in meal_plans.target_snapshot at generation time (§11.7)."""
    return Decimal(plan.target_snapshot["target"]["kcal"])


def swap_plan_item(
    session: Session, user_id: int, plan_item_id: int, new_meal_id: int, now: datetime
) -> MealPlanItem:
    require_aware(now, "now")
    row = session.execute(
        select(MealPlanItem, MealPlan)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlanItem.id == plan_item_id, MealPlan.user_id == user_id)
        .with_for_update(of=MealPlanItem)
    ).one_or_none()
    if row is None:
        raise PlanItemNotFoundError(f"plan item {plan_item_id} is not in a plan of user {user_id}")
    item, plan = row._tuple()
    if has_active_log(session, item.id):
        raise PlanItemAlreadyLoggedError(
            f"plan item {item.id} has an active log that points at its current meal"
        )
    meals = {meal.meal_id: meal for meal in load_meal_facts(session)}
    meal = meals.get(new_meal_id)
    if meal is None:
        raise MealNotFoundError(f"meal {new_meal_id} does not exist")
    if new_meal_id == item.meal_id:
        raise SwapRejectedError([SAME_MEAL])

    target_kcal = plan_target_kcal(plan)
    limits = resolve_condition_limits(session, user_id, target_kcal)
    preferences = load_user_preferences(session, user_id)
    multiplier = to_decimal(item.servings_multiplier)
    others = session.execute(
        select(MealPlanItem.slot, MealPlanItem.meal_id, MealPlanItem.servings_multiplier)
        .where(
            MealPlanItem.plan_id == item.plan_id,
            MealPlanItem.day_index == item.day_index,
            MealPlanItem.id != item.id,
        )
        .order_by(MealPlanItem.id)
    ).all()
    day_items = [(o.slot, meals[o.meal_id], to_decimal(o.servings_multiplier)) for o in others]
    evaluation = evaluate_meal(meal, preferences, item.slot, limits, multiplier)
    rejected = placement_rejections(meal, multiplier, evaluation, day_items, limits)
    if rejected:
        raise SwapRejectedError(rejected)

    snack_count = sum(1 for slot, _m, _x in day_items if slot == MealSlot.SNACK) + (
        item.slot == MealSlot.SNACK
    )
    session.execute(
        update(MealPlanItem)
        .where(MealPlanItem.id == item.id)
        .values(
            meal_id=new_meal_id,
            was_swapped=True,
            reason_codes=list(
                reason_codes(
                    meal,
                    multiplier,
                    slot_target_kcal(item.slot, target_kcal, snack_count),
                    limits,
                    preferences,
                )
            ),
            # ORM onupdate=now() would ignore a Python assignment (§15.10).
            updated_at=now,
        )
    )
    session.expire(item)
    return item
