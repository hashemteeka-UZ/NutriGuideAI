"""F.1-e end-to-end invariants on the loaded slice. Expectations come from the database."""

from __future__ import annotations

from collections.abc import Iterator
from datetime import UTC, date, datetime
from decimal import Decimal

import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, MealPlan, MealPlanItem, Nutrient, UserTarget
from app.db.models.user import MealSlot
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from app.services.adherence import COMPLETION_PLACES, NO_TARGET, DayStatus, day_status
from app.services.common import round_half_up, to_decimal
from app.services.condition_limits import resolve_condition_limits
from app.services.consumption import SNAPSHOT_NUTRIENTS_KEY
from app.services.meal_filter import evaluate_meal, load_meal_facts, load_user_preferences
from app.services.planner import MULTIPLIERS, PlanTarget, build_day_plan
from tests.scenario.f1_scenario import PersonaDay, PersonaResult, ScenarioResult, run_f1_scenario

START_DATE = date(2026, 10, 7)
START_NOW = datetime(2026, 10, 7, 5, 0, tzinfo=UTC)
SNAPSHOT_KEYS = {
    "formula_version",
    "target",
    "limits",
    "tag_rules_version",
    "planner_version",
    "computation_version",
}
MAIN = {MealSlot.BREAKFAST, MealSlot.LUNCH, MealSlot.DINNER}
D = Decimal


@pytest.fixture(scope="module")
def scenario_bundle(integrity_engine: Engine) -> Iterator[tuple[ScenarioResult, Session]]:
    connection = integrity_engine.connect()
    trans = connection.begin()
    session = Session(bind=connection)
    try:
        load_f1_slice(session, DEFAULT_DATA_DIR, now=START_NOW)
        result = run_f1_scenario(session, connection, START_DATE, START_NOW)
        yield result, session
    finally:
        session.close()
        trans.rollback()
        connection.close()


@pytest.fixture
def scenario(scenario_bundle: tuple[ScenarioResult, Session]) -> ScenarioResult:
    return scenario_bundle[0]


@pytest.fixture
def session(scenario_bundle: tuple[ScenarioResult, Session]) -> Session:
    return scenario_bundle[1]


def _planned(scenario: ScenarioResult) -> list[tuple[PersonaResult, PersonaDay]]:
    return [
        (persona, day)
        for key in ("P1", "P2")
        for persona in (scenario.personas[key],)
        for day in persona.days
    ]


def _mandatory(session: Session) -> list[str]:
    return list(
        session.execute(
            select(Nutrient.code).where(Nutrient.is_mandatory).order_by(Nutrient.code)
        ).scalars()
    )


def test_every_plan_has_required_slots_unique_meals_and_allowed_multipliers(
    scenario: ScenarioResult,
) -> None:
    for persona, day in _planned(scenario):
        slots = [item.slot for item in day.items]
        assert slots.count(MealSlot.BREAKFAST) == 1
        assert slots.count(MealSlot.LUNCH) == 1
        assert slots.count(MealSlot.DINNER) == 1
        snacks = [item for item in day.items if item.slot == MealSlot.SNACK]
        assert 0 <= len(snacks) <= 2
        assert set(slots) <= MAIN | {MealSlot.SNACK}
        meal_ids = [item.meal_id for item in day.items]
        assert len(set(meal_ids)) == len(meal_ids)
        groups = [item.variant_group for item in day.items if item.variant_group is not None]
        assert len(set(groups)) == len(groups)
        for item in day.items:
            assert item.multiplier in MULTIPLIERS, (persona.key, day.offset, item.ref_external)


def test_every_plan_item_passes_layer1_at_its_multiplier(
    scenario: ScenarioResult, session: Session
) -> None:
    facts = {meal.meal_id: meal for meal in load_meal_facts(session)}
    for persona, day in _planned(scenario):
        assert day.limits is not None
        preferences = load_user_preferences(session, persona.user_id)
        for item in day.items:
            evaluation = evaluate_meal(
                facts[item.meal_id], preferences, item.slot, day.limits, item.multiplier
            )
            assert evaluation.eligible, (
                persona.key,
                day.offset,
                item.ref_external,
                evaluation.exclusion_codes,
            )


def test_p2_plans_respect_resolved_limits_and_snapshot_matches_fresh_resolve(
    scenario: ScenarioResult, session: Session
) -> None:
    p2 = scenario.personas["P2"]
    facts = {meal.meal_id: meal for meal in load_meal_facts(session)}
    for day in p2.days:
        assert day.limits is not None
        assert day.target is not None
        assert day.target_snapshot is not None
        fresh = resolve_condition_limits(session, p2.user_id, day.target.kcal)
        assert day.target_snapshot["limits"] == fresh.to_snapshot()
        for nutrient, limit in day.limits.max_per_day.items():
            total = day.plan_totals[nutrient]
            assert total is not None and total <= limit.value, (day.offset, nutrient, total)
        carb_max = day.limits.max_per_meal["carbohydrate"].value
        peanut_id = next(
            allergen_id
            for meal in facts.values()
            for allergen_id, name in meal.allergens.items()
            if name == "Peanut"
        )
        for item in day.items:
            assert item.nutrients["carbohydrate"] <= carb_max, item.ref_external
            assert "added_sugar" not in facts[item.meal_id].tags, item.ref_external
            assert peanut_id not in facts[item.meal_id].allergens, item.ref_external


def test_target_snapshot_has_f1c_keys_and_kcal_matches_user_targets(
    scenario: ScenarioResult, session: Session
) -> None:
    for _persona, day in _planned(scenario):
        assert day.target is not None
        assert day.target_snapshot is not None
        assert set(day.target_snapshot) == SNAPSHOT_KEYS
        stored = session.get(UserTarget, day.target.target_id)
        assert stored is not None
        assert D(day.target_snapshot["target"]["kcal"]) == to_decimal(stored.target_kcal)


def test_p1_day2_uses_weight_update_and_each_user_has_one_current_target(
    scenario: ScenarioResult, session: Session
) -> None:
    p1 = scenario.personas["P1"]
    p2 = scenario.personas["P2"]
    day2 = p1.days[2]
    assert day2.target is not None
    assert day2.target.reason == "WEIGHT_UPDATE"
    initial = next(t for t in p1.targets if t.reason == "INITIAL")
    assert initial.valid_to is not None
    assert day2.target.target_id != initial.target_id
    assert day2.target.target_id == p1.days[2].target.target_id
    plan = session.get(MealPlan, day2.plan_id)
    assert plan is not None
    assert plan.target_id == day2.target.target_id

    for persona in (p1, p2):
        current = session.execute(
            select(UserTarget).where(
                UserTarget.user_id == persona.user_id, UserTarget.valid_to.is_(None)
            )
        ).scalars()
        rows = list(current)
        assert len(rows) == 1
    assert p2.days[2].target is not None
    assert p2.days[2].target.reason == "INITIAL"
    assert p2.days[2].target.target_id == p2.days[0].target.target_id
    assert p2.weight_events[-1].target_status == "NOT_TRIGGERED"


def test_active_logs_have_mandatory_nutrients_correction_and_swap(
    scenario: ScenarioResult, session: Session
) -> None:
    mandatory = _mandatory(session)
    for _persona, day in _planned(scenario):
        for log in day.logs:
            if log.status != "ACTIVE":
                continue
            nutrients = log.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY]
            assert set(nutrients) == set(mandatory)

    for key in ("P1", "P2"):
        day1 = scenario.personas[key].days[1]
        breakfast = next(item for item in day1.items if item.slot == MealSlot.BREAKFAST)
        breakfast_logs = [log for log in day1.logs if log.plan_item_id == breakfast.item_id]
        assert {log.status for log in breakfast_logs} == {"TOMBSTONE", "ACTIVE"}
        assert sum(1 for log in breakfast_logs if log.status == "TOMBSTONE") == 1
        assert sum(1 for log in breakfast_logs if log.status == "ACTIVE") == 1
        lunch = next(item for item in day1.items if item.slot == MealSlot.LUNCH)
        assert lunch.was_swapped is True
        assert day1.lunch_swap is not None
        assert lunch.ref_external == day1.lunch_swap[1]
        assert lunch.ref_external != day1.lunch_swap[0]


def test_adherence_completion_status_and_streak(scenario: ScenarioResult) -> None:
    places = COMPLETION_PLACES
    for key in ("P1", "P2"):
        persona = scenario.personas[key]
        day0, day1, day2 = persona.days
        assert day0.adherence.completion == D("1.000")
        assert day2.adherence.completion == D("1.000")
        expected = round_half_up(
            D(day1.adherence.plan_items_consumed) / D(day1.adherence.plan_items_total),
            places,
        )
        assert day1.adherence.completion == expected
        assert day1.adherence.target_kcal is not None
        recomputed = day_status(
            day1.adherence.energy_kcal,
            day1.adherence.target_kcal,
            not day1.adherence.exceeded_max_per_day,
        )
        assert day1.adherence.status is recomputed
        implied = 0
        for day in reversed(persona.days):
            if day.adherence.status is not DayStatus.ACHIEVED:
                break
            implied += 1
        assert persona.streak == implied


def test_p3_is_ineligible_and_may_still_log(scenario: ScenarioResult, session: Session) -> None:
    p3 = scenario.personas["P3"]
    assert p3.screening.eligible is False
    assert p3.screening.reasons == ["UNSUPPORTED_CONDITION:CKD"]
    assert p3.target_error is not None
    assert p3.plan_error is not None
    assert "UNSUPPORTED_CONDITION:CKD" in p3.target_error
    assert "UNSUPPORTED_CONDITION:CKD" in p3.plan_error
    assert p3.targets == ()
    assert (
        session.execute(
            select(func.count()).select_from(UserTarget).where(UserTarget.user_id == p3.user_id)
        ).scalar_one()
        == 0
    )
    assert (
        session.execute(
            select(func.count()).select_from(MealPlan).where(MealPlan.user_id == p3.user_id)
        ).scalar_one()
        == 0
    )
    assert (
        session.execute(
            select(func.count())
            .select_from(MealPlanItem)
            .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
            .where(MealPlan.user_id == p3.user_id)
        ).scalar_one()
        == 0
    )
    day0 = p3.days[0]
    assert day0.plan_id is None
    active = [log for log in day0.logs if log.status == "ACTIVE"]
    assert len(active) == 1
    assert active[0].kind == "MEAL"
    assert active[0].item == "F1-B01"
    assert active[0].amount == 1
    assert p3.weight_events
    assert day0.adherence.status is None
    assert day0.adherence.reason == NO_TARGET
    assert (
        session.execute(
            select(func.count())
            .select_from(ConsumptionLog)
            .where(ConsumptionLog.user_id == p3.user_id)
        ).scalar_one()
        == 1
    )


def test_p1_day0_build_day_plan_is_deterministic(
    scenario: ScenarioResult, session: Session
) -> None:
    p1 = scenario.personas["P1"]
    day0 = p1.days[0]
    assert day0.target is not None
    assert day0.limits is not None
    stored = session.get(UserTarget, day0.target.target_id)
    assert stored is not None
    again = build_day_plan(
        session,
        p1.user_id,
        day0.limits,
        PlanTarget.from_user_target(stored),
        day0.plan_date,
    )
    expected = [(item.slot, item.meal_id, item.multiplier) for item in day0.planned_items]
    got = [(item.slot, item.meal_id, item.multiplier) for item in again.items]
    assert got == expected
