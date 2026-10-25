"""cpsat_v2_learned objective terms (#291, #292) on the pure optimizer. No database."""

from __future__ import annotations

from decimal import Decimal
from itertools import pairwise

import pytest

from app.services.optimizer import (
    LEARNED_PLANNER_VERSION,
    PLANNER_VERSION,
    is_cpsat_version,
    optimize_day,
    variety_penalty_for_age,
    with_learned_reason,
)
from tests.services.test_optimizer import (
    NUTRIENT_CODES,
    PLAN_DATE,
    _balanced,
    _limits,
    _meal,
    _prefs,
    _target,
)

D = Decimal


def _run(meals, **kwargs):  # type: ignore[no-untyped-def]
    excluded = kwargs.pop("excluded", frozenset())
    return optimize_day(
        meals, _prefs(), _limits(), _target(), PLAN_DATE, NUTRIENT_CODES, excluded, **kwargs
    )


FIXTURES = {
    "balanced": _balanced(),
    "two_breakfasts": [
        _meal(1, ("BREAKFAST",), ref="B1", kcal=500),
        _meal(4, ("BREAKFAST",), ref="B2", kcal=480),
        _meal(2, ("LUNCH",), ref="L", kcal=700),
        _meal(3, ("DINNER",), ref="D", kcal=800),
    ],
    "snacks": [
        _meal(1, ("BREAKFAST",), ref="B", kcal=200),
        _meal(2, ("LUNCH",), ref="L", kcal=200),
        _meal(3, ("DINNER",), ref="D", kcal=200),
        _meal(4, ("SNACK",), ref="S1", kcal=200),
        _meal(5, ("SNACK",), ref="S2", kcal=200),
    ],
}


@pytest.mark.parametrize("name", sorted(FIXTURES))
def test_empty_mappings_reproduce_cpsat_v1(name: str) -> None:
    meals = FIXTURES[name]
    v1 = _run(meals)
    for empty in ({}, None, {1: 0}):
        same = _run(meals, learned_bonus=empty, variety_penalty=empty)
        assert same.plan == v1.plan
        assert same.objective == v1.objective
        assert same.solver_status == v1.solver_status
    assert v1.plan.planner_version == PLANNER_VERSION


def _breakfasts(second_kcal: Decimal | int) -> list:  # type: ignore[type-arg]
    return [
        _meal(1, ("BREAKFAST",), ref="A", kcal=500),
        _meal(9, ("BREAKFAST",), ref="Z", kcal=second_kcal),
        _meal(2, ("LUNCH",), ref="L", kcal=700),
        _meal(3, ("DINNER",), ref="D", kcal=800),
    ]


def test_a_large_bonus_wins_between_equal_cost_meals() -> None:
    meals = _breakfasts(500)
    assert _run(meals).plan.items[0].meal_id == 1
    learned = _run(meals, learned_bonus={9: 60}, planner_version=LEARNED_PLANNER_VERSION)
    assert learned.plan.items[0].meal_id == 9
    assert learned.plan.planner_version == LEARNED_PLANNER_VERSION
    assert learned.plan.kcal_within_10pct


def test_the_bonus_is_worth_about_1_5_kcal_on_a_main_slot() -> None:
    # 1 kcal off on breakfast costs 30 (day energy) + 10 (slot) = 40 units.
    assert _run(_breakfasts(501), learned_bonus={9: 60}).plan.items[0].meal_id == 9
    assert _run(_breakfasts(502), learned_bonus={9: 60}).plan.items[0].meal_id == 1


def test_the_bonus_cannot_leave_the_kcal_band() -> None:
    # 800 kcal breakfast: 2300 kcal day, outside 2000 +- 10%. Any bonus is still refused.
    meals = _breakfasts(800)
    result = _run(meals, learned_bonus={9: 60})
    assert result.plan.items[0].meal_id == 1
    assert result.plan.kcal_within_10pct
    assert result.kcal_relaxed is False


def test_negative_terms_are_rejected() -> None:
    with pytest.raises(ValueError):
        _run(_balanced(), learned_bonus={1: -1})


def test_variety_penalty_by_age() -> None:
    assert [variety_penalty_for_age(age) for age in range(1, 8)] == [0, 40, 32, 24, 16, 8, 0]


def _menus() -> list:  # type: ignore[type-arg]
    """Three menus; menu 1 is exact, menus 2 and 3 are 0.5 kcal off per meal."""
    meals = []
    for menu, extra in ((0, D(0)), (1, D("0.5")), (2, D("0.5"))):
        meals += [
            _meal(10 + menu, ("BREAKFAST",), ref=f"B{menu}", kcal=500 + extra),
            _meal(20 + menu, ("LUNCH",), ref=f"L{menu}", kcal=700 + extra),
            _meal(30 + menu, ("DINNER",), ref=f"D{menu}", kcal=800 + extra),
        ]
    return meals


def _week(learned: bool) -> list[frozenset[int]]:
    meals = _menus()
    days: list[frozenset[int]] = []
    for day in range(7):
        excluded = days[-1] if days else frozenset()
        penalty: dict[int, int] = {}
        if learned:
            for age in range(2, 7):
                if day - age >= 0:
                    for meal_id in days[day - age]:
                        penalty[meal_id] = penalty.get(meal_id, 0) + variety_penalty_for_age(age)
        result = _run(
            meals,
            excluded=excluded,
            variety_penalty=penalty,
            planner_version=LEARNED_PLANNER_VERSION if learned else PLANNER_VERSION,
        )
        assert result.plan.kcal_within_10pct
        days.append(frozenset(item.meal_id for item in result.plan.items))
    return days


def test_weekly_variety_breaks_the_two_menu_alternation() -> None:
    v1 = _week(learned=False)
    v2 = _week(learned=True)
    assert v1[0] == v1[2] == v1[4] == v1[6]  # cpsat_v1 alternates two menus
    assert len(set().union(*v1)) == 6
    assert len(set().union(*v2)) == 9
    assert len(v2) == 7
    for yesterday, today in pairwise(v2):
        assert not yesterday & today


def test_compare_week_script_on_the_menu_fixture() -> None:
    from scripts.ml_compare_week import Context, build_week

    context = Context(
        meals=_menus(),
        preferences=_prefs(),
        limits=_limits(),
        target=_target(),
        nutrient_codes=NUTRIENT_CODES,
        first_excluded=frozenset(),
    )
    v1 = build_week(context, PLAN_DATE, "fixture", None)
    v2 = build_week(context, PLAN_DATE, "fixture", ({}, frozenset()))
    assert (v1.distinct, v2.distinct) == (6, 9)
    assert v1.max_repeats == 4
    assert max(v2.deviations) <= 1.5
    assert all(day.status == "OPTIMAL" for day in v1.days + v2.days)


def test_version_helper_and_reason_order() -> None:
    assert is_cpsat_version("cpsat_v1")
    assert is_cpsat_version("cpsat_v2_learned")
    assert not is_cpsat_version("greedy_v1")
    assert with_learned_reason(("HIGH_PROTEIN", "LOW_SODIUM"), True) == (
        "LEARNED_PREFERENCE",
        "HIGH_PROTEIN",
        "LOW_SODIUM",
    )
    assert with_learned_reason(("HIGH_PROTEIN",), False) == ("HIGH_PROTEIN",)


def test_learned_reason_is_first_in_the_plan() -> None:
    result = _run(
        _balanced(),
        learned_reason_meal_ids=frozenset({2}),
        planner_version=LEARNED_PLANNER_VERSION,
    )
    lunch = next(item for item in result.plan.items if item.meal_id == 2)
    assert lunch.reason_codes[0] == "LEARNED_PREFERENCE"
    others = [item for item in result.plan.items if item.meal_id != 2]
    assert all("LEARNED_PREFERENCE" not in item.reason_codes for item in others)
