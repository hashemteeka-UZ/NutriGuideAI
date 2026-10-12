"""Criteria checks and the planner comparison report (#119, #120)."""

from __future__ import annotations

from decimal import Decimal
from pathlib import Path

from sqlalchemy.engine import Engine

from app.db.models.user import MealSlot
from app.services.condition_limits import LimitSource, ResolvedLimit, ResolvedLimits
from app.services.meal_filter import SLOT_OCCASION, MealFacts, UserPreferences
from scripts.f1_scenario_report import drop_f1_bench, setup_f1_bench
from scripts.planner_comparison_report import (
    C2_FAIL,
    C2_NA,
    C2_PASS,
    TIMING_HEADING,
    VERDICT_HEADING,
    Criteria,
    DayReport,
    PlannedItem,
    evaluate_criteria,
    verdict_lines,
    write_comparison_report,
)
from tests.scripts.test_f1_bench import _public_row_counts

D = Decimal


def _meal(
    meal_id: int,
    slot: str,
    *,
    kcal: int,
    protein: int = 20,
    fiber: int = 10,
    sodium: int = 200,
    saturated_fat: int = 2,
) -> MealFacts:
    per_serving = {
        "energy_kcal": D(kcal),
        "protein": D(protein),
        "carbohydrate": D(40),
        "total_fat": D(10),
        "fiber": D(fiber),
        "sodium": D(sodium),
        "saturated_fat": D(saturated_fat),
        "sugars": D(4),
    }
    return MealFacts(
        meal_id=meal_id,
        ref_external=f"M{meal_id}",
        name=f"M{meal_id}",
        variant_group=None,
        is_active=True,
        is_nutritionally_complete=True,
        per_serving=per_serving,
        per_100g=dict(per_serving),
        allergens={},
        ingredient_ids=frozenset(),
        tags=frozenset({SLOT_OCCASION[MealSlot(slot)]}),
    )


def _limit(value: int) -> ResolvedLimit:
    amount = D(value)
    return ResolvedLimit(
        amount,
        (
            LimitSource(
                condition_code="COND",
                source_reference="test",
                limit_basis="ABSOLUTE",
                stated_value=amount,
                value=amount,
            ),
        ),
    )


def _limits(*, max_sodium: int = 2000, min_fiber: int = 20) -> ResolvedLimits:
    return ResolvedLimits(
        target_kcal=D(2000),
        conditions=(),
        max_per_day={"sodium": _limit(max_sodium)},
        min_per_day={"fiber": _limit(min_fiber)},
        max_per_meal={},
        max_per_meal_percent_energy={},
        avoid_tags=frozenset(),
        limit_tags={},
        tag_restrictions=(),
    )


def _items(breakfast: MealFacts, lunch: MealFacts, dinner: MealFacts) -> tuple[PlannedItem, ...]:
    return (
        PlannedItem(breakfast, "BREAKFAST", D(1)),
        PlannedItem(lunch, "LUNCH", D(1)),
        PlannedItem(dinner, "DINNER", D(1)),
    )


def _prefs() -> UserPreferences:
    return UserPreferences(frozenset(), frozenset(), frozenset())


def _base_items() -> tuple[PlannedItem, ...]:
    return _items(
        _meal(1, "BREAKFAST", kcal=700),
        _meal(2, "LUNCH", kcal=700),
        _meal(3, "DINNER", kcal=600),
    )


def _evaluate(items: tuple[PlannedItem, ...], previous: frozenset[int] = frozenset()) -> Criteria:
    return evaluate_criteria(items, _prefs(), _limits(), D(2000), previous)


def test_criteria_pass_when_the_day_meets_every_rule() -> None:
    criteria = _evaluate(_base_items())
    assert criteria.passed
    assert criteria.c1_layer1_and_maxima
    assert criteria.c2_kcal_band
    assert criteria.c3_minima
    assert criteria.c4_no_repeat


def test_c1_fails_when_the_day_sodium_exceeds_its_maximum() -> None:
    items = _items(
        _meal(1, "BREAKFAST", kcal=700, sodium=900),
        _meal(2, "LUNCH", kcal=700, sodium=900),
        _meal(3, "DINNER", kcal=600, sodium=900),
    )
    criteria = _evaluate(items)
    assert criteria.c1_layer1_and_maxima is False
    assert criteria.c2_kcal_band
    assert criteria.c3_minima
    assert criteria.c4_no_repeat


def test_c2_fails_when_day_kcal_is_outside_the_band() -> None:
    items = _items(
        _meal(1, "BREAKFAST", kcal=400),
        _meal(2, "LUNCH", kcal=400),
        _meal(3, "DINNER", kcal=400),
    )
    criteria = _evaluate(items)
    assert criteria.c1_layer1_and_maxima
    assert criteria.c2_kcal_band is False
    assert criteria.c3_minima
    assert criteria.c4_no_repeat


def test_c3_fails_when_a_minimum_is_unmet() -> None:
    items = _items(
        _meal(1, "BREAKFAST", kcal=700, fiber=1),
        _meal(2, "LUNCH", kcal=700, fiber=1),
        _meal(3, "DINNER", kcal=600, fiber=1),
    )
    criteria = _evaluate(items)
    assert criteria.c1_layer1_and_maxima
    assert criteria.c2_kcal_band
    assert criteria.c3_minima is False
    assert criteria.c4_no_repeat


def _outside_band() -> tuple[PlannedItem, ...]:
    return _items(
        _meal(1, "BREAKFAST", kcal=400),
        _meal(2, "LUNCH", kcal=400),
        _meal(3, "DINNER", kcal=400),
    )


def test_c2_is_na_when_the_relaxed_cpsat_day_is_outside_the_band() -> None:
    criteria = evaluate_criteria(
        _outside_band(), _prefs(), _limits(), D(2000), frozenset(), kcal_relaxed=True
    )
    assert criteria.c2 == C2_NA
    assert criteria.c2_kcal_band is False
    assert criteria.passed
    assert criteria.passed_strict is False


def test_c2_stays_fail_for_a_greedy_day_outside_the_band() -> None:
    criteria = evaluate_criteria(_outside_band(), _prefs(), _limits(), D(2000), frozenset())
    assert criteria.c2 == C2_FAIL
    assert criteria.passed is False


def test_c2_passes_when_a_relaxed_cpsat_day_is_inside_the_band() -> None:
    criteria = evaluate_criteria(
        _base_items(), _prefs(), _limits(), D(2000), frozenset(), kcal_relaxed=True
    )
    assert criteria.c2 == C2_PASS
    assert criteria.c2_kcal_band
    assert criteria.passed
    assert criteria.passed_strict


def _na_day() -> DayReport:
    return DayReport(
        persona="P2",
        planner="cpsat",
        day=0,
        feasible=True,
        error_slot="",
        error_reasons="",
        items=(),
        criteria=Criteria(True, False, True, True, C2_NA),
        kcal=D(1474),
        target_kcal=D(1738),
        protein_g=None,
        sodium_mg=None,
        fiber_g=None,
        sat_fat_g=None,
        solver_status="OPTIMAL",
        kcal_relaxed="true",
        sodium_within_general=None,
        sat_fat_within_general=None,
        sat_fat_limit_g=None,
        elapsed_ms=1,
    )


def test_verdict_counts_one_na_day_as_passing_under_121() -> None:
    lines = verdict_lines("F.1 benchmark", [_na_day()])
    assert lines == (
        "cpsat_v1 meets all #88 criteria on the F.1 benchmark: YES",
        "strict reading (N/A counted as FAIL): NO",
    )


def test_c4_fails_when_a_meal_repeats_the_previous_day() -> None:
    criteria = _evaluate(_base_items(), frozenset({2}))
    assert criteria.c1_layer1_and_maxima
    assert criteria.c2_kcal_band
    assert criteria.c3_minima
    assert criteria.c4_no_repeat is False


def _strip_timing(text: str) -> str:
    start = text.index(TIMING_HEADING)
    end = text.index(VERDICT_HEADING)
    return text[:start] + text[end:]


def test_comparison_report_is_deterministic_and_rolls_back(
    test_db_engine: Engine, tmp_path: Path
) -> None:
    source_before = _public_row_counts(test_db_engine)
    engine = setup_f1_bench(test_db_engine.url)
    first = tmp_path / "planner_comparison_report.md"
    second = tmp_path / "planner_comparison_report_again.md"
    try:
        before = _public_row_counts(engine)
        assert write_comparison_report(engine.url, first) == 0
        assert write_comparison_report(engine.url, second) == 0
        assert _strip_timing(first.read_text(encoding="utf-8")) == _strip_timing(
            second.read_text(encoding="utf-8")
        )
        text = first.read_text(encoding="utf-8")
        assert "## 0. Versions and solver" in text
        assert "criteria 1-4 passed on" in text
        assert VERDICT_HEADING in text
        assert _public_row_counts(engine) == before
    finally:
        engine.dispose()
        drop_f1_bench(test_db_engine.url)
    assert _public_row_counts(test_db_engine) == source_before
