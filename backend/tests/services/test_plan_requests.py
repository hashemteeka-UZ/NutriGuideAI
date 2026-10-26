"""Plan view, generation window, alternatives, and the shopping list (#190 to #195)."""

from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import delete, event, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.core.text import normalize_search_text
from app.db.models import (
    Ingredient,
    Meal,
    MealIngredient,
    MealNutrient,
    MealPlan,
    MealPlanItem,
    Nutrient,
    UserInteraction,
)
from app.services.common import round_half_up, to_decimal
from app.services.plan_requests import (
    PlanDateOutOfRangeError,
    generate_day,
    list_alternatives,
    shopping_list,
    swap_item,
)
from app.services.plan_swap import SwapRejectedError, swap_plan_item
from app.services.plan_view import plan_view
from app.services.planner import MissingTargetError, create_day_plan
from app.services.targets import UserNotEligibleError
from app.services.water import water_day
from tests.builders import make_user_profile
from tests.services.conftest import NOW, PLAN_DATE, case_1_user, plan_target


def _selects(session: Session, call) -> int:
    statements: list[str] = []

    def _before(_conn, _cursor, statement: str, _parameters, _context, _executemany: bool) -> None:
        if statement.lstrip().upper().startswith(("SELECT", "WITH")):
            statements.append(statement)

    bind = session.connection()
    event.listen(bind, "before_cursor_execute", _before)
    try:
        call()
    finally:
        event.remove(bind, "before_cursor_execute", _before)
    return len(statements)


def test_plan_view_query_count_does_not_grow_with_items(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    first = _selects(slice_session, lambda: plan_view(slice_session, user, plan, "en"))
    slice_session.add(
        MealPlanItem(
            plan_id=plan.plan_id,
            day_index=0,
            slot="SNACK",
            meal_id=slice_session.scalars(
                select(MealPlanItem.meal_id).where(MealPlanItem.plan_id == plan.plan_id)
            ).first(),
            servings_multiplier=1.0,
            was_swapped=False,
            reason_codes=[],
            created_at=NOW,
            updated_at=NOW,
        )
    )
    slice_session.flush()
    second = _selects(slice_session, lambda: plan_view(slice_session, user, plan, "en"))
    assert first == second == 7


def test_plan_view_uses_the_snapshot_and_nulls_a_missing_total(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    view = plan_view(slice_session, user, plan, "ar")
    assert view.target.kcal == int(Decimal(plan.target_snapshot["target"]["kcal"]))
    assert view.stats is not None
    assert view.stats.solver_status in {"OPTIMAL", "FEASIBLE"}
    assert view.stats.candidate_meals > 0
    assert view.kcal_within_10pct is True
    assert view.totals["kcal"] is not None

    plan.algorithm_version = "greedy_v1"
    assert plan_view(slice_session, user, plan, "ar").stats is None
    plan.algorithm_version = "cpsat_v1"
    solver = dict(plan.target_snapshot["solver"])
    solver.pop("solve_seconds")
    solver.pop("candidate_meals")
    snapshot = dict(plan.target_snapshot)
    snapshot["solver"] = solver
    plan.target_snapshot = snapshot
    flag_modified(plan, "target_snapshot")
    assert plan_view(slice_session, user, plan, "ar").stats is None

    fiber = slice_session.scalar(select(Nutrient.nutrient_id).where(Nutrient.code == "fiber"))
    meal_id = view.items[0].meal.meal_id
    slice_session.execute(
        delete(MealNutrient).where(
            MealNutrient.meal_id == meal_id, MealNutrient.nutrient_id == fiber
        )
    )
    slice_session.expire_all()
    plan = slice_session.get(MealPlan, plan.plan_id)
    assert plan is not None
    incomplete = plan_view(slice_session, user, plan, "ar")
    assert incomplete.totals["fiber_g"] is None
    assert incomplete.totals["kcal"] is not None
    assert incomplete.kcal_within_10pct is True


def _expect_out_of_range(session: Session, user: int) -> None:
    try:
        generate_day(session, user, PLAN_DATE.replace(year=PLAN_DATE.year - 2), NOW, "ar")
    except PlanDateOutOfRangeError as exc:
        local_today = date(2026, 10, 6)
        assert exc.earliest == local_today - timedelta(days=1)
        assert exc.latest == local_today + timedelta(days=13)
        return
    raise AssertionError("expected PlanDateOutOfRangeError")


def test_generate_day_rejects_a_far_date_an_ineligible_user_and_a_missing_target(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    _expect_out_of_range(slice_session, user)
    young = make_user_profile(
        integrity_conn,
        sex="MALE",
        birth_date=PLAN_DATE.replace(year=PLAN_DATE.year - 10),
        height_cm=140,
        activity_level="MODERATE",
        goal_type="MAINTAIN",
        timezone="Africa/Tripoli",
    )
    try:
        generate_day(slice_session, young, PLAN_DATE, NOW, "ar")
    except UserNotEligibleError as exc:
        assert "UNDER_18" in exc.reasons
    else:
        raise AssertionError("expected UserNotEligibleError")
    try:
        generate_day(slice_session, user, PLAN_DATE, NOW, "ar")
    except MissingTargetError:
        return
    raise AssertionError("expected MissingTargetError")


def test_alternatives_are_swappable_and_swap_writes_swap_out(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    items = list(
        slice_session.scalars(
            select(MealPlanItem)
            .where(MealPlanItem.plan_id == plan.plan_id)
            .order_by(MealPlanItem.id)
        ).all()
    )
    assert items
    by_item = [(item, list_alternatives(slice_session, user, item.id, "en")) for item in items]
    item, alternatives = max(by_item, key=lambda pair: len(pair[1]))
    assert len(alternatives) >= 3
    for alternative in alternatives[:3]:
        nested = slice_session.begin_nested()
        swapped = swap_plan_item(slice_session, user, item.id, alternative.meal.meal_id, NOW)
        assert swapped.meal_id == alternative.meal.meal_id
        nested.rollback()
    try:
        swap_plan_item(slice_session, user, item.id, item.meal_id, NOW)
    except SwapRejectedError as exc:
        assert exc.exclusion_codes == ["SAME_MEAL"]
    else:
        raise AssertionError("expected SwapRejectedError")
    slice_session.refresh(item)
    old_meal_id = item.meal_id
    chosen = alternatives[0]
    swap_item(slice_session, user, item.id, chosen.meal.meal_id, NOW, "en")
    row = slice_session.scalars(
        select(UserInteraction).where(UserInteraction.user_id == user)
    ).one()
    assert row.event_type == "SWAP_OUT"
    assert row.meal_id == old_meal_id
    assert row.context == {
        "replaced_by": chosen.meal.meal_id,
        "plan_id": plan.plan_id,
        "plan_item_id": item.id,
        "algorithm_version": plan.algorithm_version,
    }


def test_shopping_list_sums_two_days_and_skips_optional_ingredients(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    create_day_plan(slice_session, user, PLAN_DATE, NOW)
    create_day_plan(slice_session, user, PLAN_DATE + timedelta(days=1), NOW + timedelta(days=1))
    ingredient_id = slice_session.scalar(
        select(MealIngredient.ingredient_id)
        .join(MealPlanItem, MealPlanItem.meal_id == MealIngredient.meal_id)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlan.user_id == user, MealIngredient.is_optional.is_(False))
        .limit(1)
    )
    assert ingredient_id is not None
    slice_session.execute(
        update(MealIngredient)
        .where(MealIngredient.ingredient_id == ingredient_id)
        .values(is_optional=True)
    )
    slice_session.flush()
    lines = shopping_list(slice_session, user, PLAN_DATE, PLAN_DATE + timedelta(days=1), "ar")
    assert ingredient_id not in {line.ingredient_id for line in lines}
    assert lines
    ordered = [normalize_search_text(line.name) for line in lines]
    assert ordered == sorted(ordered)
    sample = lines[0]
    rows = slice_session.execute(
        select(
            MealIngredient.grams,
            Meal.servings,
            MealPlanItem.servings_multiplier,
            MealPlanItem.id,
        )
        .join(Meal, Meal.meal_id == MealIngredient.meal_id)
        .join(MealPlanItem, MealPlanItem.meal_id == Meal.meal_id)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(
            MealPlan.user_id == user,
            MealIngredient.ingredient_id == sample.ingredient_id,
            MealIngredient.is_optional.is_(False),
        )
    ).all()
    expected = Decimal(0)
    seen: set[int] = set()
    for grams, servings, multiplier, item_id in rows:
        expected += to_decimal(grams) / Decimal(servings) * to_decimal(multiplier)
        seen.add(item_id)
    assert sample.grams == float(round_half_up(expected, 1))
    assert sample.meals == len(seen)


def test_water_day_sums_nothing_and_uses_the_default_goal(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    total, goal, logs = water_day(slice_session, user, PLAN_DATE)
    assert total == 0
    assert logs == []
    assert goal.goal_ml == 2000
    assert goal.source == "DEFAULT"


def test_shopping_list_leaves_out_tap_water(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    create_day_plan(slice_session, user, PLAN_DATE, NOW)
    used = slice_session.scalar(
        select(MealIngredient.ingredient_id)
        .join(MealPlanItem, MealPlanItem.meal_id == MealIngredient.meal_id)
        .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
        .where(MealPlan.user_id == user, MealIngredient.is_optional.is_(False))
        .order_by(MealIngredient.ingredient_id)
        .limit(1)
    )
    assert used is not None
    before = {
        line.ingredient_id
        for line in shopping_list(slice_session, user, PLAN_DATE, PLAN_DATE, "ar")
    }
    assert used in before
    water = slice_session.scalar(select(Ingredient.ingredient_id).where(Ingredient.code == "WATER"))
    assert water is None or water not in before
    # Make that ingredient the tap-water one (#317); move any existing WATER code aside.
    slice_session.execute(
        update(Ingredient).where(Ingredient.code == "WATER").values(code="WATER_SLICE")
    )
    slice_session.execute(
        update(Ingredient).where(Ingredient.ingredient_id == used).values(code="WATER")
    )
    slice_session.flush()
    after = {
        line.ingredient_id
        for line in shopping_list(slice_session, user, PLAN_DATE, PLAN_DATE, "ar")
    }
    assert used not in after
    # The old tap water is now an ordinary ingredient again, so it may come back.
    assert after - {water} == before - {used}
