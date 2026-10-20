"""Plans, the home day view, swaps, and the shopping list (I.5, #171)."""

from datetime import date
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request

from app.api.deps import CurrentUser, DbSession, Lang, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import PLAN_GENERATION_RATE_LIMIT, limiter, plan_generation_key
from app.api.planner_limit import planner_slot
from app.api.schemas.adherence import DayAdherenceOut
from app.api.schemas.common import ExceededLimitOut, NutrientTotals, PlanDateRange, UnmetMinimumOut
from app.api.schemas.meals import MealSummary
from app.api.schemas.plans import (
    Alternative,
    DayPlanOut,
    DayView,
    MealWindow,
    PlanDayRequest,
    PlanItemOut,
    PlanStats,
    PlanTargetOut,
    ShoppingItem,
    ShoppingList,
    SwapRequest,
)
from app.api.schemas.profile import WaterGoal
from app.api.schemas.water import WaterDay, WaterLogOut
from app.db.models.catalog import DishForm
from app.db.models.user import MealSlot, MealStance
from app.services.adherence import DayAdherence
from app.services.common import round_half_up, to_decimal
from app.services.meal_catalog import MealSummaryData
from app.services.plan_requests import (
    AlternativeData,
    DayViewData,
    ShoppingLine,
)
from app.services.plan_requests import generate_day as generate_plan_day
from app.services.plan_requests import list_alternatives as read_alternatives
from app.services.plan_requests import list_plans as read_plans
from app.services.plan_requests import read_day as read_day_view
from app.services.plan_requests import shopping_list as read_shopping_list
from app.services.plan_requests import swap_item as swap_stored_item
from app.services.plan_view import PlanItemData, PlanViewData

router = APIRouter(tags=["plans"], dependencies=[Depends(get_current_user)])

_PLAN_DAY_CODES = error_codes(
    "UNAUTHORIZED",
    "PROFILE_NOT_FOUND",
    "NOT_ELIGIBLE",
    "NO_TARGET",
    "CONDITION_CONFLICT",
    "NO_FEASIBLE_PLAN",
    "PLANNER_BUSY",
    "RATE_LIMITED",
    "VALIDATION_ERROR",
)


def _amount(value: Decimal | int | float | None) -> float | None:
    if value is None:
        return None
    return float(round_half_up(to_decimal(value), 3))


def _summary(data: MealSummaryData) -> MealSummary:
    return MealSummary(
        meal_id=data.meal_id,
        name=data.name,
        cuisine=data.cuisine,
        dish_form=None if data.dish_form is None else DishForm(data.dish_form),
        serving_grams=data.serving_grams,
        kcal=data.kcal,
        protein_g=data.protein_g,
        carb_g=data.carb_g,
        fat_g=data.fat_g,
        allergens=list(data.allergens),
        tags=list(data.tags),
        my_stance=None if data.my_stance is None else MealStance(data.my_stance),
    )


def _item(data: PlanItemData) -> PlanItemOut:
    return PlanItemOut(
        plan_item_id=data.plan_item_id,
        slot=MealSlot(data.slot),
        meal=_summary(data.meal),
        servings_multiplier=data.servings_multiplier,
        grams=data.grams,
        kcal=data.kcal,
        protein_g=data.protein_g,
        carb_g=data.carb_g,
        fat_g=data.fat_g,
        reason_codes=list(data.reason_codes),
        was_swapped=data.was_swapped,
        logged=data.logged,
    )


def _totals(values: dict[str, Decimal | float | None] | object) -> NutrientTotals:
    raw = values if isinstance(values, dict) else {}
    return NutrientTotals(
        kcal=_amount(raw.get("kcal")),
        protein_g=_amount(raw.get("protein_g")),
        carb_g=_amount(raw.get("carb_g")),
        fat_g=_amount(raw.get("fat_g")),
        fiber_g=_amount(raw.get("fiber_g")),
        sodium_mg=_amount(raw.get("sodium_mg")),
        sugars_g=_amount(raw.get("sugars_g")),
        saturated_fat_g=_amount(raw.get("saturated_fat_g")),
    )


def _plan(data: PlanViewData) -> DayPlanOut:
    return DayPlanOut(
        plan_id=data.plan_id,
        date=data.date,
        algorithm_version=data.algorithm_version,
        created_at=data.created_at,
        target=PlanTargetOut(
            kcal=data.target.kcal,
            protein_g=data.target.protein_g,
            carb_g=data.target.carb_g,
            fat_g=data.target.fat_g,
            fiber_g=data.target.fiber_g,
        ),
        items=[_item(item) for item in data.items],
        totals=_totals(data.totals),
        kcal_within_10pct=data.kcal_within_10pct,
        unmet_minimums=[
            UnmetMinimumOut(
                nutrient=row.nutrient,
                minimum=float(row.minimum),
                total=None if row.total is None else float(row.total),
            )
            for row in data.unmet_minimums
        ],
        stats=None
        if data.stats is None
        else PlanStats(
            solver_status=data.stats.solver_status,
            kcal_relaxed=data.stats.kcal_relaxed,
            solve_seconds=data.stats.solve_seconds,
            candidate_meals=data.stats.candidate_meals,
        ),
    )


def _adherence_totals(day: DayAdherence) -> NutrientTotals:
    codes = {
        "kcal": "energy_kcal",
        "protein_g": "protein",
        "carb_g": "carbohydrate",
        "fat_g": "total_fat",
        "fiber_g": "fiber",
        "sodium_mg": "sodium",
        "sugars_g": "sugars",
        "saturated_fat_g": "saturated_fat",
    }
    return NutrientTotals(**{field: _amount(day.totals.get(code)) for field, code in codes.items()})


def day_adherence_out(day: DayAdherence) -> DayAdherenceOut:
    return DayAdherenceOut(
        date=day.log_date,
        status=None if day.status is None else day.status.value,
        reason=day.reason,
        target_kcal=None if day.target_kcal is None else float(day.target_kcal),
        totals=_adherence_totals(day),
        log_count=day.log_count,
        exceeded_limits=[
            ExceededLimitOut(
                nutrient=row.nutrient,
                total=None if row.total is None else float(row.total),
                limit=float(row.limit),
            )
            for row in day.exceeded_max_per_day
        ],
        unmet_minimums=[
            UnmetMinimumOut(
                nutrient=row.nutrient,
                minimum=float(row.minimum),
                total=None if row.total is None else float(row.total),
            )
            for row in day.unmet_minimums
        ],
        fiber_target_g=day.fiber_target_g,
        plan_items_total=day.plan_items_total,
        plan_items_consumed=day.plan_items_consumed,
        completion=None if day.completion is None else float(day.completion),
    )


def _day(data: DayViewData) -> DayView:
    return DayView(
        date=data.day,
        plan=None if data.plan is None else _plan(data.plan),
        meal_windows=[
            MealWindow(slot=MealSlot(window.slot), start=window.start, end=window.end)
            for window in data.meal_windows
        ],
        adherence=day_adherence_out(data.adherence),
        water=WaterDay(
            date=data.day,
            total_ml=data.water_total_ml,
            goal=WaterGoal(
                goal_ml=data.water_goal.goal_ml,
                source=data.water_goal.source,
                requires_clinician=data.water_goal.requires_clinician,
                reminders_default_off=data.water_goal.reminders_default_off,
            ),
            logs=[
                WaterLogOut(log_id=log.id, amount_ml=log.amount_ml, consumed_at=log.consumed_at)
                for log in data.water_logs
            ],
        ),
    )


def _alternative(data: AlternativeData) -> Alternative:
    return Alternative(
        meal=_summary(data.meal),
        servings_multiplier=data.servings_multiplier,
        kcal=data.kcal,
        kcal_delta=data.kcal_delta,
    )


def _shopping_item(line: ShoppingLine) -> ShoppingItem:
    return ShoppingItem(
        ingredient_id=line.ingredient_id,
        name=line.name,
        grams=line.grams,
        meals=line.meals,
    )


@router.post(
    "/plans/days",
    status_code=201,
    response_model=DayPlanOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Generate and store that day's plan with the default planner (cpsat). "
        "The date must fall on the user's local today minus 1 day through today plus 13 days; "
        "anything else is VALIDATION_ERROR. At most 20 generations per user per hour. "
        "PLANNER_BUSY is 503 and carries Retry-After. NOT_ELIGIBLE includes reasons.\n"
        + _PLAN_DAY_CODES
    ),
)
@limiter.limit(PLAN_GENERATION_RATE_LIMIT, key_func=plan_generation_key)
def create_plan_day(
    request: Request,
    body: PlanDayRequest,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
    _slot: Annotated[None, Depends(planner_slot)],
) -> DayPlanOut:
    del request, _slot
    view = generate_plan_day(session, user_id, body.date, now, lang)
    session.commit()
    return _plan(view)


@router.get(
    "/plans",
    response_model=list[DayPlanOut],
    responses=PROBLEM_RESPONSES,
    description=(
        "The current plan of each day in the inclusive range that has one. Maximum 31 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_plans(
    span: Annotated[PlanDateRange, Query()],
    session: DbSession,
    user_id: CurrentUser,
    lang: Lang,
) -> list[DayPlanOut]:
    return [
        _plan(plan) for plan in read_plans(session, user_id, span.date_from, span.date_to, lang)
    ]


@router.get(
    "/days/{date}",
    response_model=DayView,
    responses=PROBLEM_RESPONSES,
    description=(
        "Home screen: that day's plan, meal windows, adherence, and water. "
        "Breakfast runs from 30 minutes to 2 hours 30 minutes after waking. "
        "Lunch and the snack scale a 16-hour awake day (6 to 8 hours, and 9.5 to 10.5 hours). "
        "Dinner ends 2 hours 30 minutes before sleep. "
        "Windows are empty when the awake span is under 10 hours.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_day_view(date: date, session: DbSession, user_id: CurrentUser, lang: Lang) -> DayView:
    return _day(read_day_view(session, user_id, date, lang))


@router.get(
    "/plan-items/{plan_item_id}/alternatives",
    response_model=list[Alternative],
    responses=PROBLEM_RESPONSES,
    description=(
        "Up to 10 meals that can replace this item, nearest in kcal first. "
        "kcal_delta is the alternative minus the item. "
        "Empty when the item has an active log.\n"
        + error_codes("UNAUTHORIZED", "PLAN_ITEM_NOT_FOUND")
    ),
)
def list_alternatives(
    plan_item_id: int, session: DbSession, user_id: CurrentUser, lang: Lang
) -> list[Alternative]:
    return [_alternative(item) for item in read_alternatives(session, user_id, plan_item_id, lang)]


@router.post(
    "/plan-items/{plan_item_id}/swap",
    response_model=PlanItemOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Replace the item's meal. Writes SWAP_OUT for the old meal with context.replaced_by. "
        "SWAP_REJECTED includes reasons.\n"
        + error_codes(
            "UNAUTHORIZED",
            "PLAN_ITEM_NOT_FOUND",
            "MEAL_NOT_FOUND",
            "SWAP_REJECTED",
            "PLAN_ITEM_ALREADY_LOGGED",
        )
    ),
)
def swap_plan_item(
    plan_item_id: int,
    body: SwapRequest,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
    lang: Lang,
) -> PlanItemOut:
    item = swap_stored_item(session, user_id, plan_item_id, body.meal_id, now, lang)
    session.commit()
    return _item(item)


@router.get(
    "/shopping-list",
    response_model=ShoppingList,
    responses=PROBLEM_RESPONSES,
    description=(
        "Ingredient grams summed from the current plans in the inclusive range. "
        "Optional ingredients are excluded; the meal page lists them. Maximum 31 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def get_shopping_list(
    span: Annotated[PlanDateRange, Query()],
    session: DbSession,
    user_id: CurrentUser,
    lang: Lang,
) -> ShoppingList:
    return ShoppingList(
        date_from=span.date_from,
        date_to=span.date_to,
        items=[
            _shopping_item(line)
            for line in read_shopping_list(session, user_id, span.date_from, span.date_to, lang)
        ],
    )
