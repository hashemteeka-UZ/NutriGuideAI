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
from typing import Final, cast

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.db.models import MealPlan, MealPlanItem
from app.db.models.user import MealSlot
from app.services.common import MealNotFoundError, require_aware, to_decimal
from app.services.condition_limits import (
    ResolvedLimits,
    apply_general_limits,
    resolve_condition_limits,
)
from app.services.consumption import (
    PlanItemAlreadyLoggedError,
    PlanItemNotFoundError,
    has_active_log,
)
from app.services.meal_filter import (
    MealFacts,
    UserPreferences,
    evaluate_meal,
    load_meal_facts,
    load_user_preferences,
)
from app.services.optimizer import (
    LEARNED_PLANNER_VERSION,
    is_cpsat_version,
    with_learned_reason,
)
from app.services.planner import placement_rejections, reason_codes, slot_target_kcal

SAME_MEAL: Final = "SAME_MEAL"


class SwapRejectedError(Exception):
    def __init__(self, exclusion_codes: Sequence[str]) -> None:
        self.exclusion_codes = list(exclusion_codes)
        super().__init__(f"swap rejected: {', '.join(self.exclusion_codes)}")


def plan_target_kcal(plan: MealPlan) -> Decimal:
    """target_kcal frozen in meal_plans.target_snapshot at generation time (§11.7)."""
    return Decimal(plan.target_snapshot["target"]["kcal"])


def _day_others(session: Session, item: MealPlanItem) -> list[tuple[str, int, float]]:
    """Other items of this plan day. Cached so alternatives do not query once per meal."""
    cache = session.info.setdefault("swap_day_others", {})
    key = (item.plan_id, item.day_index, item.id)
    if key not in cache:
        cache[key] = [
            (row.slot, row.meal_id, row.servings_multiplier)
            for row in session.execute(
                select(MealPlanItem.slot, MealPlanItem.meal_id, MealPlanItem.servings_multiplier)
                .where(
                    MealPlanItem.plan_id == item.plan_id,
                    MealPlanItem.day_index == item.day_index,
                    MealPlanItem.id != item.id,
                )
                .order_by(MealPlanItem.id)
            ).all()
        ]
    return cast("list[tuple[str, int, float]]", cache[key])


def swap_rejections(
    session: Session,
    user_id: int,
    item: MealPlanItem,
    plan: MealPlan,
    meal: MealFacts,
    *,
    meals: dict[int, MealFacts],
    preferences: UserPreferences,
    limits: ResolvedLimits,
) -> list[str]:
    """Read-only swap checks: same meal, Layer 1, and the planner's day rules (#194)."""
    if plan.user_id != user_id:
        raise PlanItemNotFoundError(f"plan {plan.plan_id} does not belong to user {user_id}")
    if meal.meal_id == item.meal_id:
        return [SAME_MEAL]
    multiplier = to_decimal(item.servings_multiplier)
    others = _day_others(session, item)
    day_items = [(slot, meals[meal_id], to_decimal(servings)) for slot, meal_id, servings in others]
    evaluation = evaluate_meal(meal, preferences, item.slot, limits, multiplier)
    return placement_rejections(meal, multiplier, evaluation, day_items, limits)


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
    loaded = load_meal_facts(session)
    meals = {meal.meal_id: meal for meal in loaded}
    meal = meals.get(new_meal_id)
    if meal is None:
        raise MealNotFoundError(f"meal {new_meal_id} does not exist")

    target_kcal = plan_target_kcal(plan)
    limits = resolve_condition_limits(session, user_id, target_kcal)
    if is_cpsat_version(plan.algorithm_version):
        limits = apply_general_limits(limits)
    preferences = load_user_preferences(session, user_id)
    rejected = swap_rejections(
        session,
        user_id,
        item,
        plan,
        meal,
        meals=meals,
        preferences=preferences,
        limits=limits,
    )
    if rejected:
        raise SwapRejectedError(rejected)

    multiplier = to_decimal(item.servings_multiplier)
    others = _day_others(session, item)
    snack_count = sum(1 for slot, _meal_id, _servings in others if slot == MealSlot.SNACK) + (
        item.slot == MealSlot.SNACK
    )
    codes = reason_codes(
        meal,
        multiplier,
        slot_target_kcal(item.slot, target_kcal, snack_count),
        limits,
        preferences,
    )
    if plan.algorithm_version == LEARNED_PLANNER_VERSION:
        # Local import: app.ml.planning imports the planner and the optimizer.
        from app.ml.planning import learned_reason

        codes = with_learned_reason(codes, learned_reason(session, user_id, new_meal_id))
    session.execute(
        update(MealPlanItem)
        .where(MealPlanItem.id == item.id)
        .values(
            meal_id=new_meal_id,
            was_swapped=True,
            reason_codes=list(codes),
            # ORM onupdate=now() would ignore a Python assignment (§15.10).
            updated_at=now,
        )
    )
    session.expire(item)
    return item
