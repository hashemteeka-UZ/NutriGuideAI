"""cpsat_v1: one-day CP-SAT plan (Step H.0; §28.4, §28.4b, #109-#115).

optimize_day is pure: it does not read the database and it does not add the #87 general
limits. The caller passes the ResolvedLimits it wants (H.1 passes them through
apply_general_limits). Layer 1 is not re-modelled; a candidate exists only when
evaluate_meal says it is eligible.

Objective unit is kcal-equivalent x 10 (one unit = 0.1 kcal). Nutrient amounts enter the
model as integers of thousandths (SCALE). Constraints round outward (ceil on an upper-bound
coefficient, floor on its bound, and the opposite for a lower bound). The objective uses
half-up scaled amounts. Its weighted sum — kcal, macro and fiber deviations already
multiplied by their kcal per gram — is integer-divided by SCALE // 10, so a remainder below
0.1 kcal is dropped. LIKED_BONUS is already in that unit.
"""

from __future__ import annotations

import time
from collections import Counter, defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date
from decimal import ROUND_CEILING, ROUND_FLOOR, ROUND_HALF_UP, Decimal
from typing import Any, Final

from ortools.sat.python import cp_model
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Nutrient
from app.db.models.user import MealSlot
from app.services.condition_limits import ENERGY_NUTRIENT, ResolvedLimits
from app.services.meal_filter import (
    MealFacts,
    UserPreferences,
    evaluate_meal,
    load_meal_facts,
    load_user_preferences,
)
from app.services.planner import (
    KCAL_TOLERANCE,
    LIMIT_TAG,
    MAIN_SLOTS,
    MAX_PER_DAY,
    MAX_SNACKS,
    MULTIPLIERS,
    PROTEIN_NUTRIENT,
    SLOT_ENERGY_SHARE,
    DayPlan,
    NoFeasiblePlanError,
    PlanError,
    PlanItem,
    PlanTarget,
    reason_codes,
    slot_target_kcal,
    unmet_minimums,
)
from app.services.targets import KCAL_PER_G_CARB, KCAL_PER_G_FAT, KCAL_PER_G_PROTEIN

PLANNER_VERSION: Final = "cpsat_v1"
GENERATED_BY: Final = "cpsat"

# Positions. Snack positions both use MealSlot.SNACK for Layer 1 and in the plan items.
MAIN_POSITIONS: Final = tuple(slot.name.lower() for slot in MAIN_SLOTS)
SNACK_POSITIONS: Final = tuple(f"snack_{index}" for index in range(1, MAX_SNACKS + 1))
POSITIONS: Final = MAIN_POSITIONS + SNACK_POSITIONS

# Rejection rules counted when a main position has no candidate (#109).
PREVIOUS_DAY: Final = "PREVIOUS_DAY"
UNKNOWN_AMOUNT: Final = "UNKNOWN_AMOUNT"
MIN_PER_DAY: Final = "MIN_PER_DAY"

# Nutrient codes shared with targets_v1 / greedy_v1 (PlanTarget fields, KCAL_PER_GRAM).
CARBOHYDRATE_NUTRIENT: Final = "carbohydrate"
FAT_NUTRIENT: Final = "total_fat"
FIBER_NUTRIENT: Final = "fiber"
# Macros the objective always needs, on top of energy and every daily limit (#113, #114).
_OBJECTIVE_NUTRIENTS: Final = (
    ENERGY_NUTRIENT,
    PROTEIN_NUTRIENT,
    CARBOHYDRATE_NUTRIENT,
    FAT_NUTRIENT,
    FIBER_NUTRIENT,
)

SCALE: Final = 1000
_TENTH_DIVISOR: Final = SCALE // 10  # thousandths to tenths of a kcal

# Objective weights in kcal-equivalent x 10 (#113). Phase 2 replaces W_KCAL (#112).
W_KCAL: Final = 3
W_KCAL_RELAXED: Final = 50
W_MACRO: Final = 1
W_FIBER: Final = 1
W_SLOT: Final = 1
LIKED_BONUS: Final = 10
# Fiber's shortfall is converted at the carbohydrate energy factor (4 kcal/g, §30.4b).
_FIBER_KCAL_PER_G: Final = int(KCAL_PER_G_CARB)

_INFEASIBLE: Final = "INFEASIBLE"
_OPTIMAL: Final = "OPTIMAL"
_FEASIBLE: Final = "FEASIBLE"
_ACCEPTED: Final = frozenset({_OPTIMAL, _FEASIBLE})


@dataclass(frozen=True)
class OptimizedDay:
    plan: DayPlan
    solver_status: str
    kcal_relaxed: bool
    objective: int
    solve_seconds: float


@dataclass(frozen=True)
class _Choice:
    position: str
    slot: str
    meal: MealFacts
    step: Decimal
    amounts: Mapping[str, Decimal]
    var: Any


def optimize_day(
    meals: Sequence[MealFacts],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target: PlanTarget,
    plan_date: date,
    nutrient_codes: Sequence[str],
    excluded_meal_ids: frozenset[int] = frozenset(),
) -> OptimizedDay:
    """One day from the CP-SAT model. Raises NoFeasiblePlanError or PlanError.

    Phase 1 keeps day energy inside ±KCAL_TOLERANCE. If that model is infeasible, phase 2
    drops only the energy band (kcal_relaxed) and weights the energy deviation more. No
    nutrient limit is relaxed and no main position is dropped.
    """
    required = _required_nutrients(limits)
    specs = _specs(meals, preferences, limits, excluded_meal_ids, required)
    seconds = 0.0

    solved, elapsed = _solve(specs, preferences, limits, target, True, W_KCAL)
    seconds += elapsed
    relaxed = False
    if solved.status == _INFEASIBLE:
        solved, elapsed = _solve(specs, preferences, limits, target, False, W_KCAL_RELAXED)
        seconds += elapsed
        relaxed = True
        if solved.status == _INFEASIBLE:
            raise NoFeasiblePlanError("day", solved.reasons, len(specs))
    if solved.status not in _ACCEPTED:
        raise PlanError(f"cpsat solver status {solved.status}")

    chosen = solved.chosen
    _verify(
        chosen,
        preferences,
        limits,
        target,
        excluded_meal_ids,
        required,
        nutrient_codes,
        kcal_band=not relaxed,
    )
    return OptimizedDay(
        plan=_plan(chosen, preferences, limits, target, plan_date, nutrient_codes),
        solver_status=solved.status,
        kcal_relaxed=relaxed,
        objective=solved.objective,
        solve_seconds=seconds,
    )


@dataclass(frozen=True)
class _PhaseResult:
    status: str
    chosen: tuple[_Choice, ...]
    objective: int
    reasons: Mapping[str, int]


def _required_nutrients(limits: ResolvedLimits) -> tuple[str, ...]:
    required = list(_OBJECTIVE_NUTRIENTS)
    for code in (*limits.max_per_day, *limits.min_per_day):
        if code not in required:
            required.append(code)
    return tuple(required)


def _layer1_slot(position: str) -> MealSlot:
    if position in SNACK_POSITIONS:
        return MealSlot.SNACK
    return MealSlot[position.upper()]


def _rules_for(
    meal: MealFacts,
    step: Decimal,
    slot: str,
    preferences: UserPreferences,
    limits: ResolvedLimits,
    excluded_meal_ids: frozenset[int],
    required: Sequence[str],
) -> list[str]:
    rules = list(evaluate_meal(meal, preferences, slot, limits, step).exclusion_codes)
    if meal.meal_id in excluded_meal_ids:
        rules.append(PREVIOUS_DAY)
    for nutrient in required:
        if meal.amount(nutrient, step) is None:
            rules.append(f"{UNKNOWN_AMOUNT}:{nutrient}")
    return rules


def _specs(
    meals: Sequence[MealFacts],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    excluded_meal_ids: frozenset[int],
    required: Sequence[str],
) -> tuple[_Choice, ...]:
    """Candidate rows in position, sort_key, step order. `var` is filled in _solve."""
    ordered = sorted(meals, key=lambda meal: meal.sort_key)
    specs: list[_Choice] = []
    for position in POSITIONS:
        slot = _layer1_slot(position)
        kept: list[_Choice] = []
        removed: Counter[str] = Counter()
        considered = 0
        for meal in ordered:
            for step in MULTIPLIERS:
                considered += 1
                rules = _rules_for(
                    meal, step, slot, preferences, limits, excluded_meal_ids, required
                )
                if rules:
                    removed.update(set(rules))
                    continue
                amounts: dict[str, Decimal] = {}
                for nutrient in required:
                    amount = meal.amount(nutrient, step)
                    if amount is None:
                        raise AssertionError(f"{UNKNOWN_AMOUNT}:{nutrient}")
                    amounts[nutrient] = amount
                kept.append(_Choice(position, slot, meal, step, amounts, None))
        if position in MAIN_POSITIONS and not kept:
            raise NoFeasiblePlanError(position, removed, considered)
        specs.extend(kept)
    return tuple(specs)


def _configure(solver: Any) -> None:
    solver.parameters.num_workers = 1
    solver.parameters.random_seed = 0
    solver.parameters.max_deterministic_time = 10.0
    solver.parameters.log_search_progress = False


def _solve(
    specs: Sequence[_Choice],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target: PlanTarget,
    kcal_band: bool,
    kcal_weight: int,
) -> tuple[_PhaseResult, float]:
    model = cp_model.CpModel()
    choices = tuple(
        _Choice(
            spec.position,
            spec.slot,
            spec.meal,
            spec.step,
            spec.amounts,
            model.new_bool_var(f"x_{spec.position}_{spec.meal.meal_id}_{spec.step}"),
        )
        for spec in specs
    )
    names: dict[int, str] = {}
    zero = model.new_int_var(0, 0, "zero")
    _add_structure(model, choices, zero)
    _add_nutrient_limits(model, choices, limits, names)
    _add_limit_tags(model, choices, limits, names)
    if kcal_band:
        _add_kcal_band(model, choices, target, zero)
    _add_objective(model, choices, preferences, target, kcal_weight, zero)

    solver = cp_model.CpSolver()
    _configure(solver)
    started = time.perf_counter()
    status_code = solver.Solve(model)
    elapsed = time.perf_counter() - started
    status = solver.StatusName(status_code)
    if status == _INFEASIBLE:
        return _PhaseResult(status, (), 0, _core_reasons(solver, names)), elapsed
    if status not in _ACCEPTED:
        return _PhaseResult(status, (), 0, {}), elapsed
    chosen = tuple(choice for choice in choices if solver.BooleanValue(choice.var))
    objective = round(solver.ObjectiveValue())
    return _PhaseResult(status, chosen, objective, {}), elapsed


def _core_reasons(solver: Any, names: Mapping[int, str]) -> dict[str, int]:
    reasons: dict[str, int] = {_INFEASIBLE: 1}
    for index in solver.SufficientAssumptionsForInfeasibility():
        rule = names.get(index)
        if rule is None:
            continue
        reasons[rule] = reasons.get(rule, 0) + 1
    return reasons


def _assume(model: Any, names: dict[int, str], rule: str) -> Any:
    literal = model.new_bool_var(f"assume_{len(names)}")
    names[literal.Index()] = rule
    model.add_assumption(literal)
    return literal


def _enforce(constraint: Any, assumption: Any | None) -> None:
    if assumption is not None:
        constraint.OnlyEnforceIf(assumption)


def _sum_vars(variables: Sequence[Any], zero: Any) -> Any:
    if not variables:
        return zero
    return cp_model.LinearExpr.Sum(variables)


def _add_structure(model: Any, choices: Sequence[_Choice], zero: Any) -> None:
    for position in POSITIONS:
        variables = [choice.var for choice in choices if choice.position == position]
        if position in MAIN_POSITIONS:
            model.add(_sum_vars(variables, zero) == 1)
        elif variables:
            model.add(_sum_vars(variables, zero) <= 1)
    snack_1 = [choice.var for choice in choices if choice.position == "snack_1"]
    snack_2 = [choice.var for choice in choices if choice.position == "snack_2"]
    if snack_2:
        model.add(_sum_vars(snack_2, zero) <= _sum_vars(snack_1, zero))

    by_meal: dict[int, list[Any]] = defaultdict(list)
    by_group: dict[str, list[Any]] = defaultdict(list)
    for choice in choices:
        by_meal[choice.meal.meal_id].append(choice.var)
        if choice.meal.variant_group is not None:
            by_group[choice.meal.variant_group].append(choice.var)
    for meal_id in sorted(by_meal):
        variables = by_meal[meal_id]
        if len(variables) > 1:
            model.add(cp_model.LinearExpr.Sum(variables) <= 1)
    for group in sorted(by_group):
        variables = by_group[group]
        if len(variables) > 1:
            model.add(cp_model.LinearExpr.Sum(variables) <= 1)


def _coeff_terms(
    choices: Sequence[_Choice], nutrient: str, rounding: str
) -> tuple[list[Any], list[int]]:
    variables: list[Any] = []
    coefficients: list[int] = []
    for choice in choices:
        coefficient = _scale(choice.amounts[nutrient], rounding)
        if coefficient == 0:
            continue
        variables.append(choice.var)
        coefficients.append(coefficient)
    return variables, coefficients


def _add_bounded_sum(
    model: Any,
    choices: Sequence[_Choice],
    nutrient: str,
    bound: int,
    *,
    upper: bool,
    zero: Any,
    assumption: Any | None,
) -> None:
    rounding = ROUND_CEILING if upper else ROUND_FLOOR
    variables, coefficients = _coeff_terms(choices, nutrient, rounding)
    expr = cp_model.LinearExpr.WeightedSum(variables, coefficients) if variables else zero
    if upper:
        _enforce(model.add(expr <= bound), assumption)
    else:
        _enforce(model.add(expr >= bound), assumption)


def _add_nutrient_limits(
    model: Any, choices: Sequence[_Choice], limits: ResolvedLimits, names: dict[int, str]
) -> None:
    zero = model.new_int_var(0, 0, "nutrient_zero")
    for nutrient in sorted(limits.max_per_day):
        literal = _assume(model, names, f"{MAX_PER_DAY}:{nutrient}")
        bound = _scale(limits.max_per_day[nutrient].value, ROUND_FLOOR)
        _add_bounded_sum(model, choices, nutrient, bound, upper=True, zero=zero, assumption=literal)
    for nutrient in sorted(limits.min_per_day):
        literal = _assume(model, names, f"{MIN_PER_DAY}:{nutrient}")
        bound = _scale(limits.min_per_day[nutrient].value, ROUND_CEILING)
        _add_bounded_sum(
            model, choices, nutrient, bound, upper=False, zero=zero, assumption=literal
        )


def _half_servings(step: Decimal) -> int:
    halves = step * 2
    integral = halves.to_integral_value()
    if halves != integral:
        raise AssertionError("STEP")
    return int(integral)


def _add_limit_tags(
    model: Any, choices: Sequence[_Choice], limits: ResolvedLimits, names: dict[int, str]
) -> None:
    for tag in sorted(limits.limit_tags):
        weekly = limits.limit_tags[tag]
        if weekly is None:
            continue
        variables: list[Any] = []
        coefficients: list[int] = []
        for choice in choices:
            if tag not in choice.meal.tags:
                continue
            variables.append(choice.var)
            coefficients.append(_half_servings(choice.step))
        if not variables:
            continue
        literal = _assume(model, names, f"{LIMIT_TAG}:{tag}")
        expr = cp_model.LinearExpr.WeightedSum(variables, coefficients)
        _enforce(model.add(expr <= weekly * 2), literal)


def _add_kcal_band(model: Any, choices: Sequence[_Choice], target: PlanTarget, zero: Any) -> None:
    low = target.kcal * (Decimal(1) - KCAL_TOLERANCE)
    high = target.kcal * (Decimal(1) + KCAL_TOLERANCE)
    _add_bounded_sum(
        model,
        choices,
        ENERGY_NUTRIENT,
        _scale(low, ROUND_CEILING),
        upper=False,
        zero=zero,
        assumption=None,
    )
    _add_bounded_sum(
        model,
        choices,
        ENERGY_NUTRIENT,
        _scale(high, ROUND_FLOOR),
        upper=True,
        zero=zero,
        assumption=None,
    )


def _scale(amount: Decimal, rounding: str) -> int:
    return int((amount * SCALE).to_integral_value(rounding=rounding))


def _nutrient_expr(choices: Sequence[_Choice], nutrient: str, zero: Any) -> Any:
    variables, coefficients = _coeff_terms(choices, nutrient, ROUND_HALF_UP)
    if not variables:
        return zero
    return cp_model.LinearExpr.WeightedSum(variables, coefficients)


def _position_bound(choices: Sequence[_Choice], nutrient: str) -> int:
    per_position: dict[str, int] = {}
    for choice in choices:
        coefficient = abs(_scale(choice.amounts[nutrient], ROUND_HALF_UP))
        if coefficient > per_position.get(choice.position, 0):
            per_position[choice.position] = coefficient
    return sum(per_position.values())


def _abs_deviation(model: Any, expr: Any, target_scaled: int, bound: int, name: str) -> Any:
    deviation = model.new_int_var(0, max(bound, 0), name)
    model.add(deviation >= expr - target_scaled)
    model.add(deviation >= target_scaled - expr)
    return deviation


def _add_objective(
    model: Any,
    choices: Sequence[_Choice],
    preferences: UserPreferences,
    target: PlanTarget,
    kcal_weight: int,
    zero: Any,
) -> None:
    kcal_target = _scale(target.kcal, ROUND_HALF_UP)
    kcal_bound = _position_bound(choices, ENERGY_NUTRIENT) + abs(kcal_target)
    kcal_abs = _abs_deviation(
        model,
        _nutrient_expr(choices, ENERGY_NUTRIENT, zero),
        kcal_target,
        kcal_bound,
        "kcal_abs",
    )

    macro_abs: list[tuple[Any, int]] = []
    macro_bound = 0
    for nutrient, goal, per_gram in (
        (PROTEIN_NUTRIENT, target.protein_g, int(KCAL_PER_G_PROTEIN)),
        (CARBOHYDRATE_NUTRIENT, target.carb_g, int(KCAL_PER_G_CARB)),
        (FAT_NUTRIENT, target.fat_g, int(KCAL_PER_G_FAT)),
    ):
        goal_scaled = _scale(goal, ROUND_HALF_UP)
        bound = _position_bound(choices, nutrient) + abs(goal_scaled)
        deviation = _abs_deviation(
            model,
            _nutrient_expr(choices, nutrient, zero),
            goal_scaled,
            bound,
            f"{nutrient}_abs",
        )
        macro_abs.append((deviation, per_gram))
        macro_bound += bound * per_gram
    macro_kcal = model.new_int_var(0, macro_bound, "macro_kcal")
    model.add(
        macro_kcal
        == cp_model.LinearExpr.WeightedSum(
            [deviation for deviation, _per_gram in macro_abs],
            [per_gram for _deviation, per_gram in macro_abs],
        )
    )

    fiber_goal = _scale(target.fiber_g, ROUND_HALF_UP)
    fiber_bound = max(fiber_goal, _position_bound(choices, FIBER_NUTRIENT))
    fiber_short = model.new_int_var(0, fiber_bound, "fiber_short")
    fiber_expr = _nutrient_expr(choices, FIBER_NUTRIENT, zero)
    model.add(fiber_short >= fiber_goal - fiber_expr)
    model.add(fiber_short >= 0)

    slot_vars: list[Any] = []
    slot_bound = 0
    for position in MAIN_POSITIONS:
        slot = _layer1_slot(position)
        slot_kcal = SLOT_ENERGY_SHARE[slot] * target.kcal
        slot_target = _scale(slot_kcal, ROUND_HALF_UP)
        position_choices = [choice for choice in choices if choice.position == position]
        bound = _position_bound(position_choices, ENERGY_NUTRIENT) + abs(slot_target)
        deviation = _abs_deviation(
            model,
            _nutrient_expr(position_choices, ENERGY_NUTRIENT, zero),
            slot_target,
            bound,
            f"slot_{position}",
        )
        slot_vars.append(deviation)
        slot_bound += bound
    slot_sum = model.new_int_var(0, slot_bound, "slot_sum")
    model.add(slot_sum == cp_model.LinearExpr.Sum(slot_vars))

    weighted_bound = (
        kcal_weight * kcal_bound
        + W_MACRO * macro_bound
        + W_FIBER * _FIBER_KCAL_PER_G * fiber_bound
        + W_SLOT * slot_bound
    )
    weighted = model.new_int_var(0, weighted_bound, "weighted")
    model.add(
        weighted
        == kcal_abs * kcal_weight
        + macro_kcal * W_MACRO
        + fiber_short * (W_FIBER * _FIBER_KCAL_PER_G)
        + slot_sum * W_SLOT
    )
    tenths_bound = weighted_bound // _TENTH_DIVISOR + 1
    tenths = model.new_int_var(0, tenths_bound, "tenths")
    model.add_division_equality(tenths, weighted, _TENTH_DIVISOR)

    liked = [
        choice.var
        for choice in choices
        if choice.meal.ingredient_ids & preferences.liked_ingredient_ids
    ]
    bonus_bound = LIKED_BONUS * max(len(liked), 1)
    objective = model.new_int_var(-bonus_bound, tenths_bound, "objective")
    if liked:
        bonus = cp_model.LinearExpr.WeightedSum(liked, [LIKED_BONUS] * len(liked))
        model.add(objective == tenths - bonus)
    else:
        model.add(objective == tenths)
    model.minimize(objective)


def _sum_amount(chosen: Sequence[_Choice], nutrient: str) -> Decimal | None:
    total = Decimal(0)
    for choice in chosen:
        amount = choice.meal.amount(nutrient, choice.step)
        if amount is None:
            return None
        total += amount
    return total


def _verify(
    chosen: Sequence[_Choice],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target: PlanTarget,
    excluded_meal_ids: frozenset[int],
    required: Sequence[str],
    nutrient_codes: Sequence[str],
    *,
    kcal_band: bool,
) -> None:
    """Re-check every hard rule on exact Decimal amounts. Failure is a programming error."""
    by_position: dict[str, list[_Choice]] = defaultdict(list)
    for choice in chosen:
        by_position[choice.position].append(choice)
    for position in MAIN_POSITIONS:
        if len(by_position[position]) != 1:
            raise AssertionError(f"EXACTLY_ONE:{position}")
    for position in SNACK_POSITIONS:
        if len(by_position[position]) > 1:
            raise AssertionError(f"AT_MOST_ONE:{position}")
    if by_position["snack_2"] and not by_position["snack_1"]:
        raise AssertionError("SNACK_ORDER")

    meal_ids = [choice.meal.meal_id for choice in chosen]
    if len(meal_ids) != len(set(meal_ids)):
        raise AssertionError("MEAL_ONCE")
    groups = [
        choice.meal.variant_group for choice in chosen if choice.meal.variant_group is not None
    ]
    if len(groups) != len(set(groups)):
        raise AssertionError("VARIANT_GROUP")

    for choice in chosen:
        evaluation = evaluate_meal(choice.meal, preferences, choice.slot, limits, choice.step)
        if not evaluation.eligible:
            raise AssertionError("LAYER_1")
        if choice.meal.meal_id in excluded_meal_ids:
            raise AssertionError(PREVIOUS_DAY)
        for nutrient in required:
            if choice.meal.amount(nutrient, choice.step) is None:
                raise AssertionError(f"{UNKNOWN_AMOUNT}:{nutrient}")

    for nutrient, limit in limits.max_per_day.items():
        total = _sum_amount(chosen, nutrient)
        if total is None or total > limit.value:
            raise AssertionError(f"{MAX_PER_DAY}:{nutrient}")
    for nutrient, limit in limits.min_per_day.items():
        total = _sum_amount(chosen, nutrient)
        if total is None or total < limit.value:
            raise AssertionError(f"{MIN_PER_DAY}:{nutrient}")
    for tag, weekly in limits.limit_tags.items():
        if weekly is None:
            continue
        servings = sum((choice.step for choice in chosen if tag in choice.meal.tags), Decimal(0))
        if servings > Decimal(weekly):
            raise AssertionError(f"{LIMIT_TAG}:{tag}")
    if kcal_band:
        kcal = _sum_amount(chosen, ENERGY_NUTRIENT)
        low = target.kcal * (Decimal(1) - KCAL_TOLERANCE)
        high = target.kcal * (Decimal(1) + KCAL_TOLERANCE)
        if kcal is None or kcal < low or kcal > high:
            raise AssertionError("KCAL_BAND")

    totals = {code: _sum_amount(chosen, code) for code in nutrient_codes}
    if unmet_minimums(totals, limits):
        raise AssertionError("UNMET_MINIMUMS")


def _ordered(chosen: Sequence[_Choice]) -> tuple[_Choice, ...]:
    by_position = {choice.position: choice for choice in chosen}
    return tuple(by_position[position] for position in POSITIONS if position in by_position)


def _plan(
    chosen: Sequence[_Choice],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target: PlanTarget,
    plan_date: date,
    nutrient_codes: Sequence[str],
) -> DayPlan:
    ordered = _ordered(chosen)
    snack_count = sum(1 for choice in ordered if choice.slot == MealSlot.SNACK)
    items = tuple(
        PlanItem(
            slot=str(choice.slot),
            meal_id=choice.meal.meal_id,
            ref_external=choice.meal.ref_external,
            name=choice.meal.name,
            multiplier=choice.step,
            nutrients={
                code: amount
                for code in nutrient_codes
                if (amount := choice.meal.amount(code, choice.step)) is not None
            },
            reason_codes=reason_codes(
                choice.meal,
                choice.step,
                slot_target_kcal(choice.slot, target.kcal, snack_count),
                limits,
                preferences,
            ),
        )
        for choice in ordered
    )
    totals = {code: _sum_amount(ordered, code) for code in nutrient_codes}
    kcal = _sum_amount(ordered, ENERGY_NUTRIENT)
    if kcal is None:
        raise AssertionError("UNKNOWN_AMOUNT:energy_kcal")
    return DayPlan(
        plan_date=plan_date,
        target=target,
        items=items,
        totals=totals,
        kcal_within_10pct=abs(kcal - target.kcal) <= KCAL_TOLERANCE * target.kcal,
        unmet_minimums=unmet_minimums(totals, limits),
        planner_version=PLANNER_VERSION,
    )


def build_optimized_day_plan(
    session: Session,
    user_id: int,
    limits: ResolvedLimits,
    target: PlanTarget,
    plan_date: date,
    excluded_meal_ids: frozenset[int],
) -> OptimizedDay:
    """One optimized day for the user (no writes); raises NoFeasiblePlanError.

    Meal facts, preferences and nutrient codes are loaded the same way as build_day_plan.
    Limits are used as given: this function does not add the #87 general limits.
    """
    nutrient_codes = tuple(
        session.execute(select(Nutrient.code).order_by(Nutrient.nutrient_id)).scalars()
    )
    return optimize_day(
        load_meal_facts(session),
        load_user_preferences(session, user_id),
        limits,
        target,
        plan_date,
        nutrient_codes,
        excluded_meal_ids=excluded_meal_ids,
    )
