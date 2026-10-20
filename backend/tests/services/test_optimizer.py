"""Pure tests for cpsat_v1. No database."""

from __future__ import annotations

import random
from datetime import date
from decimal import Decimal

import pytest

from app.db.models.user import MealSlot
from app.services.condition_limits import LimitSource, ResolvedLimit, ResolvedLimits
from app.services.meal_filter import SLOT_OCCASION, MealFacts, UserPreferences
from app.services.optimizer import _Choice, _verify, optimize_day
from app.services.planner import (
    NoFeasiblePlanError,
    PlanTarget,
    plan_day,
)

D = Decimal
PLAN_DATE = date(2026, 10, 12)
NUTRIENT_CODES = (
    "energy_kcal",
    "protein",
    "carbohydrate",
    "total_fat",
    "fiber",
    "sodium",
    "saturated_fat",
    "sugars",
)


def _amount(value: Decimal | int) -> Decimal:
    return value if isinstance(value, Decimal) else D(value)


def _meal(
    meal_id: int,
    slots: tuple[str, ...],
    *,
    ref: str,
    kcal: Decimal | int = 500,
    protein: Decimal | int = 20,
    carbohydrate: Decimal | int = 40,
    total_fat: Decimal | int = 15,
    fiber: Decimal | int = 5,
    sodium: Decimal | int = 100,
    saturated_fat: Decimal | int = 2,
    sugars: Decimal | int = 4,
    omit: frozenset[str] = frozenset(),
    extra_tags: frozenset[str] = frozenset(),
    allergens: dict[int, str] | None = None,
    ingredient_ids: frozenset[int] = frozenset(),
    variant_group: str | None = None,
) -> MealFacts:
    per_serving = {
        "energy_kcal": _amount(kcal),
        "protein": _amount(protein),
        "carbohydrate": _amount(carbohydrate),
        "total_fat": _amount(total_fat),
        "fiber": _amount(fiber),
        "sodium": _amount(sodium),
        "saturated_fat": _amount(saturated_fat),
        "sugars": _amount(sugars),
    }
    for code in omit:
        per_serving.pop(code, None)
    tags = frozenset(SLOT_OCCASION[MealSlot(slot)] for slot in slots) | extra_tags
    return MealFacts(
        meal_id=meal_id,
        ref_external=ref,
        name=ref,
        variant_group=variant_group,
        is_active=True,
        is_nutritionally_complete=True,
        per_serving=per_serving,
        per_100g=dict(per_serving),
        allergens=allergens or {},
        ingredient_ids=ingredient_ids,
        tags=tags,
    )


def _target(**overrides: Decimal | int | str) -> PlanTarget:
    values: dict[str, Decimal | str] = {
        "formula_version": "targets_v1",
        "kcal": D(2000),
        "protein_g": D(80),
        "carb_g": D(250),
        "fat_g": D(67),
        "fiber_g": D(28),
    }
    for key, value in overrides.items():
        values[key] = value if isinstance(value, str) else _amount(value)
    return PlanTarget(
        formula_version=str(values["formula_version"]),
        kcal=_amount(values["kcal"]),  # type: ignore[arg-type]
        protein_g=_amount(values["protein_g"]),  # type: ignore[arg-type]
        carb_g=_amount(values["carb_g"]),  # type: ignore[arg-type]
        fat_g=_amount(values["fat_g"]),  # type: ignore[arg-type]
        fiber_g=_amount(values["fiber_g"]),  # type: ignore[arg-type]
    )


def _prefs(
    *,
    allergen_ids: frozenset[int] = frozenset(),
    excluded_ingredient_ids: frozenset[int] = frozenset(),
    liked_ingredient_ids: frozenset[int] = frozenset(),
) -> UserPreferences:
    return UserPreferences(allergen_ids, excluded_ingredient_ids, liked_ingredient_ids)


def _cap(value: Decimal | int, condition: str = "COND") -> ResolvedLimit:
    amount = _amount(value)
    return ResolvedLimit(
        amount,
        (
            LimitSource(
                condition_code=condition,
                source_reference="test",
                limit_basis="ABSOLUTE",
                stated_value=amount,
                value=amount,
            ),
        ),
    )


def _limits(
    *,
    max_per_day: dict[str, ResolvedLimit] | None = None,
    min_per_day: dict[str, ResolvedLimit] | None = None,
    avoid_tags: frozenset[str] = frozenset(),
    limit_tags: dict[str, int | None] | None = None,
) -> ResolvedLimits:
    return ResolvedLimits(
        target_kcal=D(2000),
        conditions=(),
        max_per_day=max_per_day or {},
        min_per_day=min_per_day or {},
        max_per_meal={},
        max_per_meal_percent_energy={},
        avoid_tags=avoid_tags,
        limit_tags=limit_tags or {},
        tag_restrictions=(),
    )


def _optimize(
    meals: list[MealFacts],
    *,
    preferences: UserPreferences | None = None,
    limits: ResolvedLimits | None = None,
    target: PlanTarget | None = None,
    excluded: frozenset[int] = frozenset(),
):
    return optimize_day(
        meals,
        preferences or _prefs(),
        limits or _limits(),
        target or _target(),
        PLAN_DATE,
        NUTRIENT_CODES,
        excluded,
    )


def _balanced() -> list[MealFacts]:
    """One meal per main slot. Only the 1.0 steps sum to 2000 kcal."""
    return [
        _meal(1, ("BREAKFAST",), ref="B", kcal=500),
        _meal(2, ("LUNCH",), ref="L", kcal=700),
        _meal(3, ("DINNER",), ref="D", kcal=800),
    ]


def _ids(result) -> list[int]:
    return [item.meal_id for item in result.plan.items]


def test_healthy_day_is_optimal_and_inside_the_kcal_band() -> None:
    result = _optimize(_balanced())
    assert result.solver_status == "OPTIMAL"
    assert result.kcal_relaxed is False
    assert result.plan.planner_version == "cpsat_v1"
    assert result.plan.kcal_within_10pct
    assert [item.slot for item in result.plan.items] == ["BREAKFAST", "LUNCH", "DINNER"]
    assert [(item.meal_id, item.multiplier) for item in result.plan.items] == [
        (1, D("1.0")),
        (2, D("1.0")),
        (3, D("1.0")),
    ]
    assert result.plan.totals["energy_kcal"] == D(2000)
    assert result.plan.unmet_minimums == ()


def test_optimizer_does_not_add_general_population_limits() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=500, sodium=1500),
        _meal(2, ("LUNCH",), ref="L", kcal=700, sodium=1500),
        _meal(3, ("DINNER",), ref="D", kcal=800, sodium=1500),
    ]
    result = _optimize(meals)
    assert result.plan.totals["sodium"] == D(4500)
    assert result.plan.kcal_within_10pct


def test_optimizer_keeps_sodium_when_the_greedy_breakfast_spends_the_budget() -> None:
    """B-SALTY matches the breakfast kcal and protein targets and passes the greedy lookahead.

    After it is taken, lunch at 1.0 fails the lookahead (600 + 200 + 125 > 900), so greedy
    keeps lunch and dinner at 0.5 and finishes at 1100 kcal. A plain breakfast at 1.5 leaves
    room for full lunch and dinner inside both the sodium cap and the ±10% band.
    """
    zeros = {"carbohydrate": 0, "total_fat": 0, "fiber": 0, "saturated_fat": 0, "sugars": 0}
    meals = [
        _meal(1, ("BREAKFAST",), ref="B-SALTY", kcal=500, protein=20, sodium=600, **zeros),
        _meal(2, ("BREAKFAST",), ref="B-PLAIN", kcal=500, protein=5, sodium=100, **zeros),
        _meal(3, ("LUNCH",), ref="L1", kcal=700, protein=28, sodium=200, **zeros),
        _meal(4, ("DINNER",), ref="D1", kcal=500, protein=20, sodium=250, **zeros),
    ]
    limits = _limits(max_per_day={"sodium": _cap(900)})
    target = _target()
    greedy = plan_day(meals, _prefs(), limits, target, PLAN_DATE, NUTRIENT_CODES)
    assert [(item.ref_external, item.multiplier) for item in greedy.items] == [
        ("B-SALTY", D("1.0")),
        ("L1", D("0.5")),
        ("D1", D("0.5")),
    ]
    assert greedy.totals["energy_kcal"] == D(1100)
    assert greedy.kcal_within_10pct is False

    result = _optimize(meals, limits=limits, target=target)
    sodium = result.plan.totals["sodium"]
    assert sodium is not None and sodium <= D(900)
    assert result.plan.kcal_within_10pct
    assert result.kcal_relaxed is False
    assert result.solver_status == "OPTIMAL"
    assert result.plan.totals["energy_kcal"] != greedy.totals["energy_kcal"]


def test_max_per_day_excludes_the_salty_breakfast() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B-SALTY", kcal=500, sodium=800),
        _meal(2, ("BREAKFAST",), ref="B-PLAIN", kcal=500, sodium=100),
        _meal(3, ("LUNCH",), ref="L", kcal=700, sodium=100),
        _meal(4, ("DINNER",), ref="D", kcal=800, sodium=100),
    ]
    result = _optimize(meals, limits=_limits(max_per_day={"sodium": _cap(500)}))
    assert 1 not in _ids(result)
    assert result.plan.totals["sodium"] <= D(500)


def test_min_per_day_selects_the_high_fiber_breakfast() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B-LOW", kcal=500, fiber=0),
        _meal(2, ("BREAKFAST",), ref="B-HIGH", kcal=400, fiber=30),
        _meal(3, ("LUNCH",), ref="L", kcal=700, fiber=0),
        _meal(4, ("DINNER",), ref="D", kcal=800, fiber=0),
    ]
    result = _optimize(meals, limits=_limits(min_per_day={"fiber": _cap(25)}))
    assert 2 in _ids(result)
    assert 1 not in _ids(result)
    assert result.plan.totals["fiber"] >= D(25)
    assert result.plan.unmet_minimums == ()


def test_a_meal_is_used_once() -> None:
    meals = [
        _meal(1, ("BREAKFAST", "LUNCH"), ref="SHARED", kcal=500),
        _meal(2, ("LUNCH",), ref="L-ONLY", kcal=100),
        _meal(3, ("DINNER",), ref="D", kcal=500),
    ]
    result = _optimize(meals)
    assert _ids(result).count(1) == 1
    assert 2 in _ids(result)


def test_a_variant_group_is_used_once() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B-VAR", kcal=500, protein=20, variant_group="stew"),
        _meal(2, ("BREAKFAST",), ref="B-PLAIN", kcal=500, protein=5),
        _meal(3, ("LUNCH",), ref="L", kcal=700),
        _meal(4, ("DINNER",), ref="D-VAR", kcal=500, protein=20, variant_group="stew"),
    ]
    result = _optimize(meals)
    assert 1 not in _ids(result)
    assert 2 in _ids(result)
    assert 4 in _ids(result)


def test_limit_tag_servings_stay_within_the_weekly_number() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=500, extra_tags=frozenset({"high_sodium"})),
        _meal(
            2,
            ("LUNCH",),
            ref="L-TAG",
            kcal=700,
            extra_tags=frozenset({"high_sodium"}),
            ingredient_ids=frozenset({9}),
        ),
        _meal(3, ("LUNCH",), ref="L-PLAIN", kcal=700),
        _meal(4, ("DINNER",), ref="D", kcal=800),
    ]
    result = _optimize(
        meals,
        preferences=_prefs(liked_ingredient_ids=frozenset({9})),
        limits=_limits(limit_tags={"high_sodium": 1}),
    )
    tagged = sum((item.multiplier for item in result.plan.items if item.meal_id in {1, 2}), D(0))
    assert tagged <= D(1)
    assert 2 not in _ids(result)
    assert 3 in _ids(result)


def test_layer1_allergen_and_avoid_tag_are_never_selected() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="NUTS", allergens={7: "Peanut"}),
        _meal(2, ("BREAKFAST",), ref="SUGAR", extra_tags=frozenset({"added_sugar"})),
        _meal(3, ("BREAKFAST",), ref="PLAIN"),
        _meal(4, ("LUNCH",), ref="L", kcal=700),
        _meal(5, ("DINNER",), ref="D", kcal=800),
    ]
    result = _optimize(
        meals,
        preferences=_prefs(allergen_ids=frozenset({7})),
        limits=_limits(avoid_tags=frozenset({"added_sugar"})),
    )
    assert _ids(result)[0] == 3
    assert 1 not in _ids(result)
    assert 2 not in _ids(result)


def test_excluded_meal_ids_are_never_selected() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="YESTERDAY"),
        _meal(2, ("BREAKFAST",), ref="TODAY"),
        _meal(3, ("LUNCH",), ref="L", kcal=700),
        _meal(4, ("DINNER",), ref="D", kcal=800),
    ]
    result = _optimize(meals, excluded=frozenset({1}))
    assert 1 not in _ids(result)
    assert 2 in _ids(result)


def test_unknown_sodium_is_never_selected_and_empties_a_slot() -> None:
    missing = _meal(1, ("BREAKFAST",), ref="MISSING", kcal=500, omit=frozenset({"sodium"}))
    known = _meal(2, ("BREAKFAST",), ref="KNOWN", kcal=400, sodium=100)
    lunch = _meal(3, ("LUNCH",), ref="L", kcal=700, sodium=100)
    dinner = _meal(4, ("DINNER",), ref="D", kcal=800, sodium=100)
    limits = _limits(max_per_day={"sodium": _cap(5000)})
    result = _optimize([missing, known, lunch, dinner], limits=limits)
    assert 1 not in _ids(result)
    assert 2 in _ids(result)

    with pytest.raises(NoFeasiblePlanError) as caught:
        _optimize([missing, lunch, dinner], limits=limits)
    error = caught.value
    assert error.slot == "breakfast"
    assert error.candidates == 12
    assert error.reasons["UNKNOWN_AMOUNT:sodium"] == 4
    assert error.reasons["NO_OCCASION:BREAKFAST"] == 8


def test_phase2_relaxes_only_the_kcal_band() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=100, sodium=10, fiber=1),
        _meal(2, ("LUNCH",), ref="L", kcal=100, sodium=10, fiber=1),
        _meal(3, ("DINNER",), ref="D", kcal=100, sodium=10, fiber=1),
    ]
    result = _optimize(
        meals,
        limits=_limits(max_per_day={"sodium": _cap(5000)}, min_per_day={"fiber": _cap(1)}),
    )
    assert result.kcal_relaxed
    assert result.plan.kcal_within_10pct is False
    assert result.solver_status == "OPTIMAL"
    assert result.plan.totals["energy_kcal"] == D(600)
    assert result.plan.totals["sodium"] <= D(5000)
    assert result.plan.totals["fiber"] >= D(1)
    assert result.plan.unmet_minimums == ()


def test_infeasible_minimum_raises() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=500, fiber=1),
        _meal(2, ("LUNCH",), ref="L", kcal=700, fiber=1),
        _meal(3, ("DINNER",), ref="D", kcal=800, fiber=1),
    ]
    with pytest.raises(NoFeasiblePlanError) as caught:
        _optimize(meals, limits=_limits(min_per_day={"fiber": _cap(100)}))
    error = caught.value
    assert error.slot == "day"
    assert error.reasons["INFEASIBLE"] == 1
    assert any(rule.startswith("MIN_PER_DAY") for rule in error.reasons)


def test_empty_breakfast_reports_reason_counts() -> None:
    meals = [
        _meal(1, ("LUNCH",), ref="L", kcal=700),
        _meal(2, ("DINNER",), ref="D", kcal=800),
    ]
    with pytest.raises(NoFeasiblePlanError) as caught:
        _optimize(meals)
    error = caught.value
    assert error.slot == "breakfast"
    assert error.candidates == 8
    assert error.reasons == {"NO_OCCASION:BREAKFAST": 8}


def test_the_same_input_always_returns_the_same_plan() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B1", kcal=500),
        _meal(4, ("BREAKFAST",), ref="B2", kcal=480),
        _meal(2, ("LUNCH",), ref="L", kcal=700),
        _meal(3, ("DINNER",), ref="D", kcal=800),
    ]
    first = _optimize(meals)
    second = _optimize(meals)
    shuffled = list(meals)
    random.Random(1).shuffle(shuffled)
    third = _optimize(shuffled)
    assert first.plan == second.plan == third.plan
    assert first.solver_status == third.solver_status
    assert first.objective == third.objective
    assert first.kcal_relaxed == third.kcal_relaxed


def test_liked_ingredient_bonus_breaks_a_kcal_tie() -> None:
    # 0.1 kcal costs 4 objective units (day energy weight 3 plus the breakfast slot, each
    # 0.1 kcal x 10). The liked bonus is 10, so the 500.1 kcal breakfast wins.
    meals = [
        _meal(1, ("BREAKFAST",), ref="A", kcal=500),
        _meal(2, ("BREAKFAST",), ref="B", kcal=D("500.1"), ingredient_ids=frozenset({9})),
        _meal(3, ("LUNCH",), ref="L", kcal=700),
        _meal(4, ("DINNER",), ref="D", kcal=800),
    ]
    result = _optimize(meals, preferences=_prefs(liked_ingredient_ids=frozenset({9})))
    assert result.plan.items[0].meal_id == 2
    assert result.plan.kcal_within_10pct


def test_two_snacks_when_one_cannot_reach_the_band() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=200),
        _meal(2, ("LUNCH",), ref="L", kcal=200),
        _meal(3, ("DINNER",), ref="D", kcal=200),
        _meal(4, ("SNACK",), ref="S1", kcal=200),
        _meal(5, ("SNACK",), ref="S2", kcal=200),
    ]
    result = _optimize(meals)
    assert result.kcal_relaxed is False
    assert result.plan.kcal_within_10pct
    assert [item.slot for item in result.plan.items] == [
        "BREAKFAST",
        "LUNCH",
        "DINNER",
        "SNACK",
        "SNACK",
    ]


def test_snack_2_without_snack_1_fails_verification() -> None:
    breakfast = _meal(1, ("BREAKFAST",), ref="B", kcal=500)
    lunch = _meal(2, ("LUNCH",), ref="L", kcal=700)
    dinner = _meal(3, ("DINNER",), ref="D", kcal=800)
    snack = _meal(4, ("SNACK",), ref="S", kcal=100)
    chosen = (
        _Choice("breakfast", MealSlot.BREAKFAST, breakfast, D("1.0"), {}, None),
        _Choice("lunch", MealSlot.LUNCH, lunch, D("1.0"), {}, None),
        _Choice("dinner", MealSlot.DINNER, dinner, D("1.0"), {}, None),
        _Choice("snack_2", MealSlot.SNACK, snack, D("1.0"), {}, None),
    )
    with pytest.raises(AssertionError, match="SNACK_ORDER"):
        _verify(
            chosen,
            _prefs(),
            _limits(),
            _target(),
            frozenset(),
            NUTRIENT_CODES,
            NUTRIENT_CODES,
            kcal_band=False,
        )


def test_exact_sodium_total_equal_to_the_limit_is_accepted() -> None:
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=500, sodium=200),
        _meal(2, ("LUNCH",), ref="L", kcal=700, sodium=200),
        _meal(3, ("DINNER",), ref="D", kcal=800, sodium=200),
    ]
    result = _optimize(meals, limits=_limits(max_per_day={"sodium": _cap(600)}))
    assert result.kcal_relaxed is False
    assert result.plan.kcal_within_10pct
    assert result.plan.totals["sodium"] == D(600)
    assert result.solver_status == "OPTIMAL"


def test_slot_band_prefers_balanced_mains_over_an_exact_lopsided_day() -> None:
    """A 2.0/2.0/2.0 day plus two snacks totals 2000 kcal and misses every main-slot band.

    The balanced meals sit on the only in-band step of each main position and total 2000.
    """
    balanced = [
        _meal(
            1,
            ("BREAKFAST",),
            ref="B",
            kcal=560,
            protein=20,
            carbohydrate=70,
            total_fat=17,
            fiber=8,
        ),
        _meal(
            2,
            ("LUNCH",),
            ref="L",
            kcal=760,
            protein=30,
            carbohydrate=90,
            total_fat=25,
            fiber=10,
        ),
        _meal(
            3,
            ("DINNER",),
            ref="D",
            kcal=680,
            protein=30,
            carbohydrate=90,
            total_fat=25,
            fiber=10,
        ),
    ]
    lopsided = [
        _meal(4, ("BREAKFAST",), ref="B-LOP", kcal=150),
        _meal(5, ("LUNCH",), ref="L-LOP", kcal=200),
        _meal(6, ("DINNER",), ref="D-LOP", kcal=150),
        _meal(7, ("SNACK",), ref="S1", kcal=250),
        _meal(8, ("SNACK",), ref="S2", kcal=250),
    ]
    assert D(150) * 2 + D(200) * 2 + D(150) * 2 + D(250) * 2 + D(250) * 2 == D(2000)
    result = _optimize(balanced + lopsided)
    assert result.slot_band_pass is True
    target = _target()
    shares = {"BREAKFAST": D("0.25"), "LUNCH": D("0.35"), "DINNER": D("0.25")}
    for item in result.plan.items:
        if item.slot == "SNACK":
            continue
        low = D("0.7") * shares[item.slot] * target.kcal
        high = D("1.4") * shares[item.slot] * target.kcal
        assert low <= item.nutrients["energy_kcal"] <= high
    assert [(item.meal_id, item.multiplier) for item in result.plan.items] == [
        (1, D("1.0")),
        (2, D("1.0")),
        (3, D("1.0")),
    ]


def test_a_main_slot_outside_the_band_uses_phase1() -> None:
    from app.services.optimizer import W_KCAL, _required_nutrients, _solve, _specs

    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=600),
        _meal(2, ("LUNCH",), ref="L", kcal=800),
        _meal(3, ("DINNER",), ref="D", kcal=100),
    ]
    result = _optimize(meals)
    assert result.slot_band_pass is False
    limits = _limits()
    specs = _specs(meals, _prefs(), limits, frozenset(), _required_nutrients(limits))
    phase1, _elapsed = _solve(specs, _prefs(), limits, _target(), True, W_KCAL)
    assert sorted((item.meal_id, item.multiplier) for item in result.plan.items) == sorted(
        (choice.meal.meal_id, choice.step) for choice in phase1.chosen
    )


def test_unknown_status_retries_once(monkeypatch: pytest.MonkeyPatch) -> None:
    from ortools.sat.python import cp_model

    from app.services.optimizer import SOLVER_DETERMINISTIC_TIME, SOLVER_RETRY_DETERMINISTIC_TIME

    seen: list[float] = []
    real_solve = cp_model.CpSolver.Solve

    def solve(self: cp_model.CpSolver, model: cp_model.CpModel) -> cp_model.CpSolverStatus:
        seen.append(self.parameters.max_deterministic_time)
        if len(seen) == 1:
            return cp_model.UNKNOWN
        return real_solve(self, model)

    monkeypatch.setattr(cp_model.CpSolver, "Solve", solve)
    meals = [
        _meal(1, ("BREAKFAST",), ref="B", kcal=560),
        _meal(2, ("LUNCH",), ref="L", kcal=760),
        _meal(3, ("DINNER",), ref="D", kcal=680),
    ]
    result = _optimize(meals)
    assert seen == [SOLVER_DETERMINISTIC_TIME, SOLVER_RETRY_DETERMINISTIC_TIME]
    assert [(item.meal_id, item.multiplier) for item in result.plan.items] == [
        (1, D("1.0")),
        (2, D("1.0")),
        (3, D("1.0")),
    ]


def _in_band_mains() -> list[MealFacts]:
    return [
        _meal(1, ("BREAKFAST",), ref="B", kcal=560),
        _meal(2, ("LUNCH",), ref="L", kcal=760),
        _meal(3, ("DINNER",), ref="D", kcal=680),
    ]


def test_unknown_banded_pass_continues_unbanded(monkeypatch: pytest.MonkeyPatch) -> None:
    import app.services.optimizer as optimizer

    real = optimizer._solve
    calls = 0

    def wrapped(*args: object, **kwargs: object):
        nonlocal calls
        calls += 1
        if calls == 1:
            return optimizer._PhaseResult("UNKNOWN", (), 0, {}), 0.0
        return real(*args, **kwargs)

    monkeypatch.setattr(optimizer, "_solve", wrapped)
    result = _optimize(_in_band_mains())
    assert calls >= 2
    assert result.slot_band_pass is False
    assert result.solver_status in {"OPTIMAL", "FEASIBLE"}
    assert result.plan.items


def test_every_pass_unknown_raises_planner_timeout(monkeypatch: pytest.MonkeyPatch) -> None:
    import app.services.optimizer as optimizer
    from app.services.planner import PlannerTimeoutError

    def unknown(*args: object, **kwargs: object):
        return optimizer._PhaseResult("UNKNOWN", (), 0, {}), 0.0

    monkeypatch.setattr(optimizer, "_solve", unknown)
    with pytest.raises(PlannerTimeoutError, match="UNKNOWN"):
        _optimize(_in_band_mains())
