"""greedy_v1 one-day planner (Step F.1) on the loaded F.1 slice, plus two synthetic cases."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

import pytest
from sqlalchemy import func, insert, select
from sqlalchemy.engine import Connection
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.models import Allergen, MealPlan, MealPlanItem, UserTarget
from app.db.models.user import SERVINGS_MULTIPLIER_STEPS
from app.services.condition_limits import ResolvedLimit, ResolvedLimits, resolve_condition_limits
from app.services.meal_filter import (
    SLOT_OCCASION,
    MealFacts,
    UserPreferences,
    evaluate_meals,
    load_meal_facts,
)
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.planner import (
    DAY_KCAL_CEILING,
    FITS_KCAL_TOLERANCE,
    MAX_SNACKS,
    MULTIPLIERS,
    PLANNER_VERSION,
    SLOT_ENERGY_SHARE,
    SNACK_ENERGY_SHARE,
    DayPlan,
    MissingTargetError,
    NoFeasiblePlanError,
    PlanTarget,
    build_day_plan,
    create_day_plan,
    current_plan_id,
    plan_day,
    reason_codes,
)
from app.services.tag_rules import TAG_RULES_VERSION
from app.services.targets import UserNotEligibleError
from tests.builders import make_user_allergen_pref, make_user_ingredient_pref
from tests.services.conftest import (
    NOW,
    PLAN_DATE,
    add_conditions,
    case_1_user,
    case_2_user,
    meal_id,
    plan_target,
)

D = Decimal
MAIN = ["BREAKFAST", "LUNCH", "DINNER"]
SNAPSHOT_KEYS = {
    "formula_version",
    "target",
    "limits",
    "tag_rules_version",
    "planner_version",
    "computation_version",
}
STATIC_REASON_CODES = {
    "FITS_KCAL_TARGET",
    "HIGH_PROTEIN",
    "LOW_SODIUM",
    "LOW_SUGAR",
    "LOW_SATURATED_FAT",
    "HIGH_FIBER",
    "MATCHES_LIKED_INGREDIENT",
}


def _facts(session: Session) -> dict[int, MealFacts]:
    return {meal.meal_id: meal for meal in load_meal_facts(session)}


def _plan(session: Session, user: int) -> tuple[DayPlan, ResolvedLimits, PlanTarget]:
    target = plan_target(session, user)
    limits = resolve_condition_limits(session, user, target.kcal)
    return build_day_plan(session, user, limits, target, PLAN_DATE), limits, target


def _assert_structure(session: Session, user: int, day: DayPlan, limits: ResolvedLimits) -> None:
    slots = [item.slot for item in day.items]
    assert slots[:3] == MAIN
    assert set(slots[3:]) <= {"SNACK"}
    assert len(slots[3:]) <= MAX_SNACKS
    facts = _facts(session)
    meal_ids = [item.meal_id for item in day.items]
    assert len(set(meal_ids)) == len(meal_ids)
    groups = [facts[m].variant_group for m in meal_ids if facts[m].variant_group is not None]
    assert len(set(groups)) == len(groups)
    for item in day.items:
        assert item.multiplier in MULTIPLIERS
        [evaluation] = [
            e
            for e in evaluate_meals(session, user, item.slot, limits, item.multiplier)
            if e.meal_id == item.meal_id
        ]
        assert evaluation.eligible, (item.ref_external, evaluation.exclusion_codes)
        meal = facts[item.meal_id]
        assert item.nutrients == {
            code: amount * item.multiplier for code, amount in meal.per_serving.items()
        }
    for code, total in day.totals.items():
        assert total == sum((item.nutrients[code] for item in day.items), D(0))
    energy = day.totals["energy_kcal"]
    assert energy is not None
    assert day.kcal_within_10pct == (abs(energy - day.target.kcal) <= D("0.10") * day.target.kcal)
    if len(slots) > 3:
        assert energy <= DAY_KCAL_CEILING * day.target.kcal


def _tag_servings(session: Session, day: DayPlan, tag: str) -> Decimal:
    facts = _facts(session)
    return sum((item.multiplier for item in day.items if tag in facts[item.meal_id].tags), D(0))


def test_multipliers_match_the_schema_steps() -> None:
    assert tuple(D(str(step)) for step in SERVINGS_MULTIPLIER_STEPS) == MULTIPLIERS


def test_healthy_adult(slice_session: Session, integrity_conn: Connection) -> None:
    user = case_1_user(integrity_conn)
    day, limits, target = _plan(slice_session, user)
    assert limits.is_empty
    assert target.kcal == 2364
    _assert_structure(slice_session, user, day, limits)
    assert day.unmet_minimums == ()
    assert build_day_plan(slice_session, user, limits, target, PLAN_DATE) == day


def test_hypertension_and_diabetes(slice_session: Session, integrity_conn: Connection) -> None:
    user = case_2_user(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HYPERTENSION", "DIABETES_T2")
    day, limits, target = _plan(slice_session, user)
    assert target.kcal == 1200
    _assert_structure(slice_session, user, day, limits)

    sodium, sugars, fiber = (day.totals[n] for n in ("sodium", "sugars", "fiber"))
    assert sodium is not None and sugars is not None and fiber is not None
    assert limits.max_per_day["sodium"].value == 2000
    assert sodium <= 2000
    sugars_max = D(10) / 100 * target.kcal / 4
    assert limits.max_per_day["sugars"].value == sugars_max
    assert sugars <= sugars_max
    facts = _facts(slice_session)
    for item in day.items:
        assert item.nutrients["carbohydrate"] <= 60, item.ref_external
        assert "added_sugar" not in facts[item.meal_id].tags
        assert {"SUITS_CONDITION_HYPERTENSION", "SUITS_CONDITION_DIABETES_T2"} <= set(
            item.reason_codes
        ), item.ref_external
    assert _tag_servings(slice_session, day, "high_sodium") <= 3
    assert _tag_servings(slice_session, day, "high_sugar") <= 3

    fiber_min = limits.min_per_day["fiber"].value
    assert fiber_min == 25
    if fiber < fiber_min:
        [unmet] = day.unmet_minimums
        assert (unmet.nutrient, unmet.minimum, unmet.total) == ("fiber", fiber_min, fiber)
        assert unmet.gap == fiber_min - fiber
    else:
        assert day.unmet_minimums == ()


def test_reason_codes_follow_the_thresholds(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HYPERTENSION", "DIABETES_T2")
    day, _limits, target = _plan(slice_session, user)
    facts = _facts(slice_session)
    snacks = sum(1 for item in day.items if item.slot == "SNACK")
    for item in day.items:
        meal = facts[item.meal_id]
        slot_kcal = (
            SNACK_ENERGY_SHARE * target.kcal / snacks
            if item.slot == "SNACK"
            else SLOT_ENERGY_SHARE[item.slot] * target.kcal
        )
        kcal = item.nutrients["energy_kcal"]
        per_100g = meal.per_100g
        expected = {
            "FITS_KCAL_TARGET": abs(kcal - slot_kcal) <= FITS_KCAL_TOLERANCE * slot_kcal,
            "HIGH_PROTEIN": item.nutrients["protein"] * 4 >= D("0.20") * kcal,
            "LOW_SODIUM": per_100g["sodium"] <= 120,
            "LOW_SUGAR": per_100g["sugars"] <= 5,
            "LOW_SATURATED_FAT": per_100g["saturated_fat"] <= D("1.5"),
            "HIGH_FIBER": per_100g["fiber"] >= 6,
            "MATCHES_LIKED_INGREDIENT": False,
        }
        assert {code for code, on in expected.items() if on} == (
            set(item.reason_codes) & STATIC_REASON_CODES
        ), item.ref_external
        assert list(item.reason_codes) == sorted(item.reason_codes)


def test_condition_limit_tag_removes_suits_condition(
    slice_session: Session, integrity_conn: Connection
) -> None:
    """S06 is derived high_sodium: allowed (3 servings/week) but it does not suit HYPERTENSION."""
    user = case_1_user(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HYPERTENSION")
    target = plan_target(slice_session, user)
    limits = resolve_condition_limits(slice_session, user, target.kcal)
    facts = _facts(slice_session)
    s06 = facts[meal_id(slice_session, "F1-S06")]
    assert "high_sodium" in s06.tags
    preferences = UserPreferences(frozenset(), frozenset(), frozenset())
    assert "SUITS_CONDITION_HYPERTENSION" not in reason_codes(
        s06, D("1.0"), D(300), limits, preferences
    )
    s03 = facts[meal_id(slice_session, "F1-S03")]
    assert "SUITS_CONDITION_HYPERTENSION" in reason_codes(
        s03, D("1.0"), D(300), limits, preferences
    )


def test_liked_ingredient_is_explained_and_does_not_change_the_plan(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    day, limits, target = _plan(slice_session, user)
    breakfast = day.items[0]
    liked = min(_facts(slice_session)[breakfast.meal_id].ingredient_ids)
    make_user_ingredient_pref(integrity_conn, user_id=user, ingredient_id=liked, stance="LIKE")
    again = build_day_plan(slice_session, user, limits, target, PLAN_DATE)
    assert [(i.meal_id, i.multiplier) for i in again.items] == [
        (i.meal_id, i.multiplier) for i in day.items
    ]
    assert "MATCHES_LIKED_INGREDIENT" in again.items[0].reason_codes


# --- create_day_plan ---------------------------------------------------------------------------


def _rows(session: Session, model: Any, *where: Any) -> list[Any]:
    return sorted(session.execute(select(model.__table__).where(*where)).all())


def _plan_counts(session: Session, user: int) -> tuple[int, int]:
    plans = select(MealPlan.plan_id).where(MealPlan.user_id == user)
    return (
        session.execute(
            select(func.count()).select_from(MealPlan).where(MealPlan.user_id == user)
        ).scalar_one(),
        session.execute(
            select(func.count()).select_from(MealPlanItem).where(MealPlanItem.plan_id.in_(plans))
        ).scalar_one(),
    )


def test_create_day_plan_writes_plan_and_items(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_2_user(integrity_conn)
    add_conditions(slice_session, integrity_conn, user, "HYPERTENSION", "DIABETES_T2")
    day, limits, target = _plan(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)

    current_target = slice_session.execute(
        select(UserTarget).where(UserTarget.user_id == user, UserTarget.valid_to.is_(None))
    ).scalar_one()
    slice_session.refresh(plan)
    assert (plan.date_from, plan.date_to) == (PLAN_DATE, PLAN_DATE)
    assert (plan.generated_by, plan.algorithm_version) == ("greedy", PLANNER_VERSION)
    assert plan.target_id == current_target.target_id
    assert plan.created_at == NOW
    snapshot = plan.target_snapshot
    assert set(snapshot) == SNAPSHOT_KEYS
    assert snapshot["formula_version"] == "targets_v1"
    assert snapshot["target"] == {
        "kcal": str(target.kcal),
        "protein_g": str(target.protein_g),
        "carb_g": str(target.carb_g),
        "fat_g": str(target.fat_g),
        "fiber_g": str(target.fiber_g),
    }
    assert D(snapshot["target"]["kcal"]) == D(str(current_target.target_kcal))
    assert snapshot["target"]["fiber_g"] == "17"
    assert snapshot["limits"] == limits.to_snapshot()
    assert snapshot["tag_rules_version"] == TAG_RULES_VERSION
    assert snapshot["planner_version"] == PLANNER_VERSION
    assert snapshot["computation_version"] == COMPUTATION_VERSION

    items = slice_session.execute(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id).order_by(MealPlanItem.id)
    ).scalars()
    stored = [
        (i.day_index, i.slot, i.meal_id, D(str(i.servings_multiplier)), i.was_swapped)
        for i in items
    ]
    assert stored == [(0, i.slot, i.meal_id, i.multiplier, False) for i in day.items]
    known = STATIC_REASON_CODES | {f"SUITS_CONDITION_{c}" for c in limits.conditions}
    for item in slice_session.execute(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id)
    ).scalars():
        assert isinstance(item.reason_codes, list)
        assert item.reason_codes == sorted(item.reason_codes)
        assert set(item.reason_codes) <= known
    assert current_plan_id(slice_session, user, PLAN_DATE) == plan.plan_id


def test_second_plan_leaves_the_first_untouched(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    first = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    first_id = first.plan_id
    before = (
        _rows(slice_session, MealPlan, MealPlan.plan_id == first_id),
        _rows(slice_session, MealPlanItem, MealPlanItem.plan_id == first_id),
    )
    second = create_day_plan(slice_session, user, PLAN_DATE, NOW + timedelta(hours=1))

    assert second.plan_id != first_id
    after = (
        _rows(slice_session, MealPlan, MealPlan.plan_id == first_id),
        _rows(slice_session, MealPlanItem, MealPlanItem.plan_id == first_id),
    )
    assert after == before
    assert _plan_counts(slice_session, user)[0] == 2
    assert current_plan_id(slice_session, user, PLAN_DATE) == second.plan_id
    assert current_plan_id(slice_session, user, PLAN_DATE + timedelta(days=1)) is None


def test_ineligible_user_writes_nothing(slice_session: Session, integrity_conn: Connection) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    add_conditions(slice_session, integrity_conn, user, "CKD")
    with pytest.raises(UserNotEligibleError) as caught:
        create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert caught.value.reasons == ["UNSUPPORTED_CONDITION:CKD"]
    assert _plan_counts(slice_session, user) == (0, 0)


def test_user_without_current_target_writes_nothing(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    with pytest.raises(MissingTargetError):
        create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert _plan_counts(slice_session, user) == (0, 0)


def test_naive_now_is_rejected(slice_session: Session, integrity_conn: Connection) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    with pytest.raises(ValueError, match="timezone-aware"):
        create_day_plan(slice_session, user, PLAN_DATE, NOW.replace(tzinfo=None))


def test_one_main_slot_per_day_is_enforced(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    slots = slice_session.execute(
        select(MealPlanItem.slot, func.count())
        .where(MealPlanItem.plan_id == plan.plan_id)
        .group_by(MealPlanItem.slot)
    ).all()
    assert {slot: n for slot, n in slots if slot != "SNACK"} == dict.fromkeys(MAIN, 1)

    any_meal = meal_id(slice_session, "F1-S03")
    with pytest.raises(IntegrityError), slice_session.begin_nested():
        slice_session.execute(
            insert(MealPlanItem).values(
                plan_id=plan.plan_id,
                day_index=0,
                slot="BREAKFAST",
                meal_id=any_meal,
                servings_multiplier=1.0,
            )
        )
    for _ in range(2):
        slice_session.execute(
            insert(MealPlanItem).values(
                plan_id=plan.plan_id,
                day_index=0,
                slot="SNACK",
                meal_id=any_meal,
                servings_multiplier=1.0,
            )
        )


# --- infeasible days -----------------------------------------------------------------------------


def test_no_breakfast_left_raises_and_writes_nothing(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    for allergen in slice_session.execute(select(Allergen.allergen_id)).scalars():
        make_user_allergen_pref(integrity_conn, user_id=user, allergen_id=allergen)
    facts = load_meal_facts(slice_session)
    remaining = [
        meal for meal in facts if SLOT_OCCASION["BREAKFAST"] in meal.tags and not meal.allergens
    ]
    assert remaining
    for ingredient in sorted({i for meal in remaining for i in meal.ingredient_ids}):
        make_user_ingredient_pref(
            integrity_conn, user_id=user, ingredient_id=ingredient, stance="EXCLUDE"
        )
    plan_target(slice_session, user)

    with pytest.raises(NoFeasiblePlanError) as caught:
        create_day_plan(slice_session, user, PLAN_DATE, NOW)
    error = caught.value
    assert error.slot == "BREAKFAST"
    assert error.candidates == len(facts) * len(MULTIPLIERS)
    not_breakfast = sum(1 for meal in facts if SLOT_OCCASION["BREAKFAST"] not in meal.tags)
    assert error.reasons["NO_OCCASION:BREAKFAST"] == not_breakfast * len(MULTIPLIERS)
    gluten = sum(1 for meal in facts if "Gluten" in meal.allergens.values())
    assert error.reasons["ALLERGEN:Gluten"] == gluten * len(MULTIPLIERS)
    assert _plan_counts(slice_session, user) == (0, 0)


def _exclude_lunch_and_dinner_except(
    session: Session, conn: Connection, user: int, keep: set[str]
) -> None:
    """EXCLUDE one ingredient of every lunch/dinner meal outside `keep`, sparing breakfasts."""
    facts = load_meal_facts(session)
    lunch_dinner = {SLOT_OCCASION["LUNCH"], SLOT_OCCASION["DINNER"]}
    kept_ingredients = {i for m in facts if m.ref_external in keep for i in m.ingredient_ids}
    targets = [m for m in facts if m.tags & lunch_dinner and m.ref_external not in keep]
    spared = [m for m in facts if SLOT_OCCASION["BREAKFAST"] in m.tags and m not in targets]
    excluded: set[int] = set()
    for meal in targets:
        if meal.ingredient_ids & excluded:
            continue
        choices = sorted(meal.ingredient_ids - kept_ingredients)
        assert choices, f"{meal.ref_external} has only ingredients of {sorted(keep)}"
        excluded.add(min(choices, key=lambda i: (sum(i in m.ingredient_ids for m in spared), i)))
    for ingredient in sorted(excluded):
        make_user_ingredient_pref(conn, user_id=user, ingredient_id=ingredient, stance="EXCLUDE")


def _lunch_dinner_survivors(session: Session, user: int, limits: ResolvedLimits) -> set[str]:
    return {
        str(e.ref_external)
        for slot in ("LUNCH", "DINNER")
        for e in evaluate_meals(session, user, slot, limits)
        if e.eligible
    }


@pytest.mark.parametrize(
    ("keep", "dinner_codes"),
    [
        # Couscous carries lunch_suitable only: dinner fails on the occasion rule as well.
        ({"F1-L01", "F1-L01-CH"}, {"NO_OCCASION:DINNER", "VARIANT_GROUP_USED"}),
        # Bamia is lunch and dinner suitable: only the variant rule keeps the sibling out.
        ({"F1-L06", "F1-L06-CH"}, {"VARIANT_GROUP_USED"}),
    ],
    ids=["couscous", "bamia"],
)
def test_two_variants_of_one_dish_never_share_a_day(
    slice_session: Session,
    integrity_conn: Connection,
    keep: set[str],
    dinner_codes: set[str],
) -> None:
    user = case_1_user(integrity_conn)
    _exclude_lunch_and_dinner_except(slice_session, integrity_conn, user, keep)
    target = plan_target(slice_session, user)
    limits = resolve_condition_limits(slice_session, user, target.kcal)
    assert _lunch_dinner_survivors(slice_session, user, limits) == keep

    with pytest.raises(NoFeasiblePlanError) as caught:
        build_day_plan(slice_session, user, limits, target, PLAN_DATE)
    error = caught.value
    assert error.slot == "DINNER"
    assert dinner_codes <= set(error.reasons)
    with pytest.raises(NoFeasiblePlanError):
        create_day_plan(slice_session, user, PLAN_DATE, NOW)
    assert _plan_counts(slice_session, user) == (0, 0)


# --- synthetic cases (pure plan_day) -------------------------------------------------------------

NUTRIENTS = ("energy_kcal", "protein", "sodium")
NO_PREFERENCES = UserPreferences(frozenset(), frozenset(), frozenset())


def _meal(meal_id: int, ref: str, slots: Iterable[str], kcal: int, sodium: int = 0) -> MealFacts:
    per_serving = {"energy_kcal": D(kcal), "protein": D(0), "sodium": D(sodium)}
    return MealFacts(
        meal_id=meal_id,
        ref_external=ref,
        name=ref,
        variant_group=None,
        is_active=True,
        is_nutritionally_complete=True,
        per_serving=per_serving,
        per_100g=per_serving,
        allergens={},
        ingredient_ids=frozenset(),
        tags=frozenset(SLOT_OCCASION[slot] for slot in slots),
    )


def _limits(max_sodium: int | None = None) -> ResolvedLimits:
    max_per_day = {} if max_sodium is None else {"sodium": ResolvedLimit(D(max_sodium), ())}
    return ResolvedLimits(
        target_kcal=D(2000),
        conditions=(),
        max_per_day=max_per_day,
        min_per_day={},
        max_per_meal={},
        max_per_meal_percent_energy={},
        avoid_tags=frozenset(),
        limit_tags={},
        tag_restrictions=(),
    )


def _target(kcal: int) -> PlanTarget:
    return PlanTarget("targets_v1", D(kcal), D(0), D(1), D(1), D(1))


def test_lookahead_keeps_the_later_slots_feasible() -> None:
    """Without the lookahead B-A x1.0 (exact 500 kcal) would leave 200 mg for lunch + dinner."""
    meals = [
        _meal(1, "B-A", ["BREAKFAST"], kcal=500, sodium=800),
        _meal(2, "B-B", ["BREAKFAST"], kcal=420, sodium=100),
        _meal(3, "L", ["LUNCH"], kcal=700, sodium=600),
        _meal(4, "D", ["DINNER"], kcal=500, sodium=200),
    ]
    day = plan_day(meals, NO_PREFERENCES, _limits(1000), _target(2000), date(2026, 1, 1), NUTRIENTS)
    assert [(i.ref_external, i.multiplier) for i in day.items] == [
        ("B-B", D("1.0")),
        ("L", D("1.0")),
        ("D", D("1.0")),
    ]
    assert day.totals["sodium"] == 900

    no_limit = plan_day(
        meals, NO_PREFERENCES, _limits(), _target(2000), date(2026, 1, 1), NUTRIENTS
    )
    assert no_limit.items[0].ref_external == "B-A"


def test_ties_break_on_ref_external_then_smaller_multiplier() -> None:
    """Breakfast target 600 kcal: 800 kcal at x0.5 and x1.0 are both 200 kcal away."""
    meals = [
        _meal(1, "B-2", ["BREAKFAST"], kcal=800),
        _meal(2, "B-1", ["BREAKFAST"], kcal=800),
        _meal(3, "L", ["LUNCH"], kcal=840),
        _meal(4, "D", ["DINNER"], kcal=600),
    ]
    day = plan_day(meals, NO_PREFERENCES, _limits(), _target(2400), date(2026, 1, 1), NUTRIENTS)
    assert (day.items[0].ref_external, day.items[0].multiplier) == ("B-1", D("0.5"))
    assert (
        plan_day(
            list(reversed(meals)),
            NO_PREFERENCES,
            _limits(),
            _target(2400),
            date(2026, 1, 1),
            NUTRIENTS,
        )
        == day
    )


def test_snacks_fill_the_gap_up_to_two_and_never_past_the_ceiling() -> None:
    """Target 1000 kcal: the main slots give 820 kcal, below the 900 kcal snack threshold."""
    main = [
        _meal(1, "B", ["BREAKFAST"], kcal=240),
        _meal(2, "L", ["LUNCH"], kcal=340),
        _meal(3, "D", ["DINNER"], kcal=240),
    ]

    def plan(*snacks: MealFacts) -> DayPlan:
        return plan_day(
            [*main, *snacks], NO_PREFERENCES, _limits(), _target(1000), date(2026, 1, 1), NUTRIENTS
        )

    small = plan(
        _meal(4, "S-1", ["SNACK"], kcal=20),
        _meal(5, "S-2", ["SNACK"], kcal=25),
        _meal(6, "S-3", ["SNACK"], kcal=30),
    )
    assert [(i.ref_external, i.multiplier) for i in small.items[3:]] == [
        ("S-3", D("2.0")),
        ("S-2", D("2.0")),
    ]
    assert small.totals["energy_kcal"] == 930

    half = plan(_meal(4, "S-BIG", ["SNACK"], kcal=500))
    assert [(i.ref_external, i.multiplier) for i in half.items[3:]] == [("S-BIG", D("0.5"))]
    assert half.totals["energy_kcal"] == 1070
    assert half.totals["energy_kcal"] <= DAY_KCAL_CEILING * 1000

    none = plan(_meal(4, "S-HUGE", ["SNACK"], kcal=700))
    assert [i.slot for i in none.items] == MAIN
    assert not none.kcal_within_10pct
