"""HTTP-facing plan reads and the day generation request (#192 to #195).

create_day_plan still owns generation. This module checks the date window, builds the
view, lists alternatives with the swap checks, and writes the SWAP_OUT event.
"""

from __future__ import annotations

import logging
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text, pick_name
from app.db.models import (
    Ingredient,
    Meal,
    MealIngredient,
    MealPlan,
    MealPlanItem,
    UserInteraction,
    UserProfile,
)
from app.db.models.user import InteractionEventType, WaterLog
from app.ml.planning import learned_means
from app.services.adherence import DayAdherence, daily_adherence
from app.services.common import round_half_up, to_decimal, zone
from app.services.condition_limits import (
    ENERGY_NUTRIENT,
    apply_general_limits,
    resolve_condition_limits,
)
from app.services.consumption import PlanItemNotFoundError, has_active_log
from app.services.meal_catalog import MealSummaryData, summaries_for
from app.services.meal_filter import load_meal_facts, load_user_preferences
from app.services.meal_windows import MealWindow, meal_windows
from app.services.optimizer import is_cpsat_version
from app.services.plan_swap import plan_target_kcal, swap_plan_item, swap_rejections
from app.services.plan_view import PlanItemData, PlanViewData, plan_view
from app.services.planner import create_day_plan, current_plan_id
from app.services.screening import ProfileNotFoundError
from app.services.water import WaterGoalResult, water_day

logger = logging.getLogger("nutriguide.api")

_PAST_DAYS = 1
_FUTURE_DAYS = 13
_ALTERNATIVE_LIMIT = 10
_GRAM_PLACES = 1
# Ingredients never listed for shopping (#317). The reference data has no drinking-water tag.
SHOPPING_EXCLUDED_CODES = ("WATER",)


class PlanDateOutOfRangeError(ValueError):
    """The date is outside the user's local today - 1 through today + 13."""

    def __init__(self, plan_date: date, earliest: date, latest: date) -> None:
        self.plan_date = plan_date
        self.earliest = earliest
        self.latest = latest
        super().__init__(
            f"plan date {plan_date.isoformat()} is outside "
            f"{earliest.isoformat()} to {latest.isoformat()} "
            "(local today minus 1 day through today plus 13 days)"
        )


@dataclass(frozen=True)
class DayViewData:
    day: date
    plan: PlanViewData | None
    meal_windows: tuple[MealWindow, ...]
    adherence: DayAdherence
    water_total_ml: int
    water_goal: WaterGoalResult
    water_logs: tuple[WaterLog, ...]


@dataclass(frozen=True)
class AlternativeData:
    meal: MealSummaryData
    servings_multiplier: float
    kcal: float
    kcal_delta: float


@dataclass(frozen=True)
class ShoppingLine:
    ingredient_id: int
    name: str
    grams: float
    meals: int


def _profile(session: Session, user_id: int) -> UserProfile:
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    return profile


def _local_today(profile: UserProfile, now: datetime) -> date:
    return now.astimezone(zone(profile.timezone)).date()


def _current_plans(
    session: Session, user_id: int, date_from: date, date_to: date
) -> list[tuple[date, MealPlan]]:
    """Newest plan covering each day in the inclusive range, ordered by date (#72)."""
    plans = list(
        session.scalars(
            select(MealPlan)
            .where(
                MealPlan.user_id == user_id,
                MealPlan.date_from <= date_to,
                MealPlan.date_to >= date_from,
            )
            .order_by(MealPlan.created_at.desc(), MealPlan.plan_id.desc())
        ).all()
    )
    chosen: dict[date, MealPlan] = {}
    for plan in plans:
        day = max(plan.date_from, date_from)
        last = min(plan.date_to, date_to)
        while day <= last:
            if day not in chosen:
                chosen[day] = plan
            day += timedelta(days=1)
    return [(day, chosen[day]) for day in sorted(chosen)]


def current_plans(
    session: Session, user_id: int, date_from: date, date_to: date
) -> list[tuple[date, MealPlan]]:
    """Newest plan covering each day in the inclusive range, ordered by date (#72)."""
    return _current_plans(session, user_id, date_from, date_to)


def generate_day(
    session: Session, user_id: int, plan_date: date, now: datetime, lang: str
) -> PlanViewData:
    """Store a cpsat day inside the allowed window and return its view (#192)."""
    profile = _profile(session, user_id)
    today = _local_today(profile, now)
    earliest = today - timedelta(days=_PAST_DAYS)
    latest = today + timedelta(days=_FUTURE_DAYS)
    if plan_date < earliest or plan_date > latest:
        raise PlanDateOutOfRangeError(plan_date, earliest, latest)
    plan = create_day_plan(session, user_id, plan_date, now)
    solver = plan.target_snapshot.get("solver")
    solver = solver if isinstance(solver, dict) else {}
    logger.info(
        "plan generated user_id=%s date=%s algorithm=%s solver_status=%s "
        "solve_seconds=%s candidate_meals=%s",
        user_id,
        plan_date.isoformat(),
        plan.algorithm_version,
        solver.get("solver_status"),
        solver.get("solve_seconds"),
        solver.get("candidate_meals"),
    )
    return plan_view(session, user_id, plan, lang)


def list_plans(
    session: Session, user_id: int, date_from: date, date_to: date, lang: str
) -> list[PlanViewData]:
    """The current plan of each day in the range that has one, ordered by date."""
    return [
        plan_view(session, user_id, plan, lang)
        for _day, plan in _current_plans(session, user_id, date_from, date_to)
    ]


def read_day(session: Session, user_id: int, day: date, lang: str) -> DayViewData:
    """Home screen for one local date (#193, #196)."""
    profile = _profile(session, user_id)
    plan_id = current_plan_id(session, user_id, day)
    plan = None if plan_id is None else session.get(MealPlan, plan_id)
    total_ml, goal, logs = water_day(session, user_id, day)
    return DayViewData(
        day=day,
        plan=None if plan is None else plan_view(session, user_id, plan, lang),
        meal_windows=tuple(meal_windows(profile.wake_time, profile.sleep_time)),
        adherence=daily_adherence(session, user_id, day),
        water_total_ml=total_ml,
        water_goal=goal,
        water_logs=tuple(logs),
    )


def _owned_item(session: Session, user_id: int, plan_item_id: int) -> tuple[MealPlanItem, MealPlan]:
    row = session.execute(
        select(MealPlanItem, MealPlan)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlanItem.id == plan_item_id, MealPlan.user_id == user_id)
    ).one_or_none()
    if row is None:
        raise PlanItemNotFoundError(f"plan item {plan_item_id} is not in a plan of user {user_id}")
    item, plan = row._tuple()
    return item, plan


def _shown_kcal(amount: Decimal) -> float:
    return float(round_half_up(amount, 3))


def list_alternatives(
    session: Session, user_id: int, plan_item_id: int, lang: str
) -> list[AlternativeData]:
    """Up to 10 meals swap_plan_item would accept (#194).

    Ordered by the learned mean (no exploration term), highest first, then nearest in kcal
    (#293). A user with no events of their own gets the kcal order alone.
    """
    item, plan = _owned_item(session, user_id, plan_item_id)
    if has_active_log(session, item.id):
        return []
    loaded = load_meal_facts(session)
    meals = {meal.meal_id: meal for meal in loaded}
    current = meals.get(item.meal_id)
    if current is None or ENERGY_NUTRIENT not in current.per_serving:
        raise ValueError(f"plan item {item.id} meal {item.meal_id} has no stored energy")
    multiplier = to_decimal(item.servings_multiplier)
    current_kcal = current.per_serving[ENERGY_NUTRIENT] * multiplier
    limits = resolve_condition_limits(session, user_id, plan_target_kcal(plan))
    if is_cpsat_version(plan.algorithm_version):
        limits = apply_general_limits(limits)
    preferences = load_user_preferences(session, user_id)
    accepted: list[tuple[Decimal, int, Decimal]] = []
    for meal in loaded:
        if not meal.is_active or not meal.is_nutritionally_complete:
            continue
        if swap_rejections(
            session,
            user_id,
            item,
            plan,
            meal,
            meals=meals,
            preferences=preferences,
            limits=limits,
        ):
            continue
        energy = meal.per_serving.get(ENERGY_NUTRIENT)
        if energy is None:
            continue
        kcal = energy * multiplier
        accepted.append((abs(kcal - current_kcal), meal.meal_id, kcal))
    means = learned_means(session, user_id, [meal_id for _gap, meal_id, _kcal in accepted])
    accepted.sort(key=lambda row: (-means.get(row[1], 0.0), row[0], row[1]))
    chosen = accepted[:_ALTERNATIVE_LIMIT]
    summaries = summaries_for(session, user_id, [meal_id for _gap, meal_id, _kcal in chosen], lang)
    alternatives: list[AlternativeData] = []
    for _gap, meal_id, kcal in chosen:
        stored = summaries.get(meal_id)
        if stored is None:
            continue
        alternatives.append(
            AlternativeData(
                meal=stored.summary,
                servings_multiplier=float(multiplier),
                kcal=_shown_kcal(kcal),
                kcal_delta=_shown_kcal(kcal - current_kcal),
            )
        )
    return alternatives


def swap_item(
    session: Session,
    user_id: int,
    plan_item_id: int,
    new_meal_id: int,
    now: datetime,
    lang: str,
) -> PlanItemData:
    """Swap, then write SWAP_OUT for the old meal (#169, #194)."""
    item, plan = _owned_item(session, user_id, plan_item_id)
    old_meal_id = item.meal_id
    plan_id = plan.plan_id
    algorithm_version = plan.algorithm_version
    swapped = swap_plan_item(session, user_id, plan_item_id, new_meal_id, now)
    session.add(
        UserInteraction(
            user_id=user_id,
            meal_id=old_meal_id,
            event_type=InteractionEventType.SWAP_OUT.value,
            context={
                "replaced_by": new_meal_id,
                "plan_id": plan_id,
                "plan_item_id": swapped.id,
                "algorithm_version": algorithm_version,
            },
            created_at=now,
        )
    )
    session.flush()
    stored = session.get(MealPlan, plan_id)
    if stored is None:
        raise PlanItemNotFoundError(f"plan {plan_id} disappeared during swap")
    view = plan_view(session, user_id, stored, lang)
    for built in view.items:
        if built.plan_item_id == swapped.id:
            return built
    raise PlanItemNotFoundError(f"plan item {swapped.id} is missing from its plan view")


def shopping_list(
    session: Session, user_id: int, date_from: date, date_to: date, lang: str
) -> list[ShoppingLine]:
    """Non-optional ingredient grams of the current plans in the range (#195).

    Tap water (ingredient code WATER) is cooking water, not something to buy (#317).
    """
    plan_ids = [plan.plan_id for _day, plan in _current_plans(session, user_id, date_from, date_to)]
    if not plan_ids:
        return []
    rows = session.execute(
        select(
            MealPlanItem.id,
            MealIngredient.ingredient_id,
            MealIngredient.grams,
            Meal.servings,
            MealPlanItem.servings_multiplier,
            Ingredient.canonical_name_ar,
            Ingredient.canonical_name,
        )
        .join(Meal, Meal.meal_id == MealPlanItem.meal_id)
        .join(MealIngredient, MealIngredient.meal_id == Meal.meal_id)
        .join(Ingredient, Ingredient.ingredient_id == MealIngredient.ingredient_id)
        .where(
            MealPlanItem.plan_id.in_(plan_ids),
            MealIngredient.is_optional.is_(False),
            Ingredient.code.not_in(SHOPPING_EXCLUDED_CODES),
        )
    ).all()
    grams: dict[int, Decimal] = defaultdict(lambda: Decimal(0))
    used: dict[int, set[int]] = defaultdict(set)
    names: dict[int, str] = {}
    for item_id, ingredient_id, amount, servings, multiplier, name_ar, name_en in rows:
        grams[ingredient_id] += to_decimal(amount) / Decimal(servings) * to_decimal(multiplier)
        used[ingredient_id].add(item_id)
        names[ingredient_id] = pick_name(lang, name_ar, name_en)
    lines = [
        ShoppingLine(
            ingredient_id=ingredient_id,
            name=names[ingredient_id],
            grams=float(round_half_up(grams[ingredient_id], _GRAM_PLACES)),
            meals=len(used[ingredient_id]),
        )
        for ingredient_id in names
    ]
    lines.sort(key=lambda line: (normalize_search_text(line.name), line.ingredient_id))
    return lines
