"""Read a stored plan the way every plan route returns it (#190).

The target, limits, and solver stats come from the plan's snapshot, never from the
user's current target. Totals are the stored per-serving amounts times each item's
multiplier. A nutrient missing on any item makes that total null, not a partial sum.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import case, select
from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, MealPlan, MealPlanItem
from app.db.models.user import MealSlot
from app.services.common import round_half_up
from app.services.condition_limits import ENERGY_NUTRIENT, ResolvedLimits
from app.services.meal_catalog import MealSummaryData, summaries_for
from app.services.planner import KCAL_TOLERANCE, UnmetMinimum, unmet_minimums

_SLOT_RANK = case(
    (MealPlanItem.slot == MealSlot.BREAKFAST.value, 0),
    (MealPlanItem.slot == MealSlot.LUNCH.value, 1),
    (MealPlanItem.slot == MealSlot.SNACK.value, 2),
    (MealPlanItem.slot == MealSlot.DINNER.value, 3),
    else_=4,
)

# Response fields and the nutrient codes they sum (#190, NutrientTotals).
TOTAL_FIELDS: tuple[tuple[str, str], ...] = (
    ("kcal", ENERGY_NUTRIENT),
    ("protein_g", "protein"),
    ("carb_g", "carbohydrate"),
    ("fat_g", "total_fat"),
    ("fiber_g", "fiber"),
    ("sodium_mg", "sodium"),
    ("sugars_g", "sugars"),
    ("saturated_fat_g", "saturated_fat"),
)
_PLACES = 3
_CPSAT = "cpsat_v1"
_STATS_KEYS = ("solver_status", "kcal_relaxed", "solve_seconds", "candidate_meals")


@dataclass(frozen=True)
class PlanTargetData:
    kcal: int
    protein_g: float
    carb_g: float
    fat_g: float
    fiber_g: int


@dataclass(frozen=True)
class PlanItemData:
    plan_item_id: int
    slot: str
    meal: MealSummaryData
    servings_multiplier: float
    grams: float
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    reason_codes: tuple[str, ...]
    was_swapped: bool
    logged: bool


@dataclass(frozen=True)
class PlanStatsData:
    solver_status: str
    kcal_relaxed: bool
    solve_seconds: float
    candidate_meals: int


@dataclass(frozen=True)
class PlanViewData:
    plan_id: int
    date: date
    algorithm_version: str
    created_at: datetime
    target: PlanTargetData
    items: tuple[PlanItemData, ...]
    totals: Mapping[str, float | None]
    kcal_within_10pct: bool
    unmet_minimums: tuple[UnmetMinimum, ...]
    stats: PlanStatsData | None


def _shown(value: Decimal) -> float:
    return float(round_half_up(value, _PLACES))


def _whole(value: Decimal) -> int:
    return int(round_half_up(value, 0))


def _target(snapshot: Mapping[str, object]) -> tuple[PlanTargetData, Decimal]:
    raw = snapshot["target"]
    if not isinstance(raw, Mapping):
        raise ValueError("plan target_snapshot target is not a mapping")
    kcal = Decimal(str(raw["kcal"]))
    protein = Decimal(str(raw["protein_g"]))
    carb = Decimal(str(raw["carb_g"]))
    fat = Decimal(str(raw["fat_g"]))
    fiber = Decimal(str(raw["fiber_g"]))
    shown = PlanTargetData(
        kcal=_whole(kcal),
        protein_g=_shown(protein),
        carb_g=_shown(carb),
        fat_g=_shown(fat),
        fiber_g=_whole(fiber),
    )
    return shown, kcal


def _stats(plan: MealPlan) -> PlanStatsData | None:
    if plan.algorithm_version != _CPSAT:
        return None
    solver = plan.target_snapshot.get("solver")
    if not isinstance(solver, Mapping) or any(key not in solver for key in _STATS_KEYS):
        return None
    return PlanStatsData(
        solver_status=str(solver["solver_status"]),
        kcal_relaxed=bool(solver["kcal_relaxed"]),
        solve_seconds=float(solver["solve_seconds"]),
        candidate_meals=int(solver["candidate_meals"]),
    )


def _logged(session: Session, item_ids: list[int]) -> set[int]:
    if not item_ids:
        return set()
    found = session.scalars(
        select(ConsumptionLog.plan_item_id).where(
            ConsumptionLog.plan_item_id.in_(item_ids),
            ConsumptionLog.deleted_at.is_(None),
        )
    ).all()
    return {item_id for item_id in found if item_id is not None}


def plan_view(session: Session, user_id: int, plan: MealPlan, lang: str) -> PlanViewData:
    """One plan. The number of queries does not grow with the number of items."""
    items = list(
        session.scalars(
            select(MealPlanItem)
            .where(MealPlanItem.plan_id == plan.plan_id)
            .order_by(_SLOT_RANK, MealPlanItem.id)
        ).all()
    )
    stored = summaries_for(session, user_id, [item.meal_id for item in items], lang)
    logged = _logged(session, [item.id for item in items])
    target, target_kcal = _target(plan.target_snapshot)
    limits = ResolvedLimits.from_snapshot(plan.target_snapshot["limits"])

    built: list[PlanItemData] = []
    per_item: list[Mapping[str, Decimal]] = []
    for item in items:
        meal = stored.get(item.meal_id)
        if meal is None:
            raise ValueError(
                f"plan item {item.id} meal {item.meal_id} has no complete nutrition to show"
            )
        multiplier = Decimal(str(item.servings_multiplier))
        amounts = meal.per_serving
        summary = meal.summary
        built.append(
            PlanItemData(
                plan_item_id=item.id,
                slot=item.slot,
                meal=summary,
                servings_multiplier=float(multiplier),
                grams=_shown(Decimal(str(summary.serving_grams)) * multiplier),
                kcal=_shown(amounts[ENERGY_NUTRIENT] * multiplier),
                protein_g=_shown(amounts["protein"] * multiplier),
                carb_g=_shown(amounts["carbohydrate"] * multiplier),
                fat_g=_shown(amounts["total_fat"] * multiplier),
                reason_codes=tuple(item.reason_codes),
                was_swapped=item.was_swapped,
                logged=item.id in logged,
            )
        )
        per_item.append(amounts)

    needed = {code for _field, code in TOTAL_FIELDS}
    needed.update(limits.min_per_day)
    exact: dict[str, Decimal | None] = {}
    for code in needed:
        if any(code not in amounts for amounts in per_item):
            exact[code] = None
            continue
        exact[code] = sum(
            (
                amounts[code] * Decimal(str(item.servings_multiplier))
                for item, amounts in zip(items, per_item, strict=True)
            ),
            Decimal(0),
        )
    totals: dict[str, float | None] = {}
    for field, code in TOTAL_FIELDS:
        amount = exact.get(code)
        totals[field] = None if amount is None else _shown(amount)
    kcal_total = exact.get(ENERGY_NUTRIENT)
    within = (
        kcal_total is not None and abs(kcal_total - target_kcal) <= KCAL_TOLERANCE * target_kcal
    )
    return PlanViewData(
        plan_id=plan.plan_id,
        date=plan.date_from,
        algorithm_version=plan.algorithm_version,
        created_at=plan.created_at,
        target=target,
        items=tuple(built),
        totals=totals,
        kcal_within_10pct=within,
        unmet_minimums=unmet_minimums(exact, limits),
        stats=_stats(plan),
    )
