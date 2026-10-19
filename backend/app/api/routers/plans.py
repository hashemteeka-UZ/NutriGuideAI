"""Plans, the home day view, swaps, and the shopping list (I.5, #171)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.common import PlanDateRange
from app.api.schemas.plans import (
    Alternative,
    DayPlanOut,
    DayView,
    PlanDayRequest,
    PlanItemOut,
    ShoppingList,
    SwapRequest,
)

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
)


@router.post(
    "/plans/days",
    status_code=201,
    response_model=DayPlanOut,
    responses=PROBLEM_RESPONSES,
    description=(
        "Generate and store that day's plan with the default planner. "
        "PLANNER_BUSY is 503 and carries Retry-After. NOT_ELIGIBLE includes reasons.\n"
        + _PLAN_DAY_CODES
    ),
)
def create_plan_day(body: PlanDayRequest) -> DayPlanOut:
    raise not_implemented()


@router.get(
    "/plans",
    response_model=list[DayPlanOut],
    responses=PROBLEM_RESPONSES,
    description=(
        "The current plan of each day in the inclusive range that has one. Maximum 31 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def list_plans(span: Annotated[PlanDateRange, Query()]) -> list[DayPlanOut]:
    raise not_implemented()


@router.get(
    "/days/{date}",
    response_model=DayView,
    responses=PROBLEM_RESPONSES,
    description=(
        "Home screen: that day's plan, meal windows, adherence, and water.\n"
        + error_codes("UNAUTHORIZED", "PROFILE_NOT_FOUND")
    ),
)
def get_day_view(date: date) -> DayView:
    raise not_implemented()


@router.get(
    "/plan-items/{plan_item_id}/alternatives",
    response_model=list[Alternative],
    responses=PROBLEM_RESPONSES,
    description=(
        "Up to 10 meals that can replace this item. kcal_delta is the alternative minus the item.\n"
        + error_codes("UNAUTHORIZED", "PLAN_ITEM_NOT_FOUND")
    ),
)
def list_alternatives(plan_item_id: int) -> list[Alternative]:
    raise not_implemented()


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
def swap_plan_item(plan_item_id: int, body: SwapRequest) -> PlanItemOut:
    raise not_implemented()


@router.get(
    "/shopping-list",
    response_model=ShoppingList,
    responses=PROBLEM_RESPONSES,
    description=(
        "Ingredient grams summed from the current plans in the inclusive range. Maximum 31 days.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def get_shopping_list(span: Annotated[PlanDateRange, Query()]) -> ShoppingList:
    raise not_implemented()
