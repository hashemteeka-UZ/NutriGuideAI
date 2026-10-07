"""greedy_v1: deterministic one-day meal plan (Step F.1; §28.1, §28.2, §28.4, §28.6, §11.7).

build_day_plan writes nothing; create_day_plan screens the user, resolves the condition limits
and stores the plan with its frozen target_snapshot. Greedy is the accepted baseline (§28.4).

Hard rules (never relaxed): every Layer 1 rule at the item's multiplier, every resolved
max_per_day (with a lookahead over the main slots still to fill), LIMIT-tag servings, no meal
and no variant_group (#76) twice in one day. Soft rules (reported, not enforced): day energy
within ±10% of target_kcal and the resolved min_per_day values.

A LIMIT tag's weekly number is checked against this day's servings only; accounting across
the plans of one week is out of Step F.1 scope.
"""

from __future__ import annotations

from collections import Counter
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Final
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import MealPlan, MealPlanItem, Nutrient, UserProfile, UserTarget
from app.db.models.user import MealSlot
from app.services.common import to_decimal
from app.services.condition_limits import (
    ENERGY_NUTRIENT,
    ResolvedLimits,
    resolve_condition_limits,
)
from app.services.meal_filter import (
    MealEvaluation,
    MealFacts,
    UserPreferences,
    evaluate_meal,
    load_meal_facts,
    load_user_preferences,
    per_meal_violations,
)
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.screening import ProfileNotFoundError, screen_user
from app.services.tag_rules import TAG_RULES_VERSION
from app.services.targets import KCAL_PER_G_PROTEIN, UserNotEligibleError, fiber_target_g

PLANNER_VERSION: Final = "greedy_v1"
GENERATED_BY: Final = "greedy"
PROTEIN_NUTRIENT: Final = "protein"

# --- Step F.1 planner decision, to be recorded in the next doc version -------------------------
MAIN_SLOTS: Final = (MealSlot.BREAKFAST, MealSlot.LUNCH, MealSlot.DINNER)
SLOT_ENERGY_SHARE: Final[Mapping[str, Decimal]] = {
    MealSlot.BREAKFAST: Decimal("0.25"),
    MealSlot.LUNCH: Decimal("0.35"),
    MealSlot.DINNER: Decimal("0.25"),
}
SNACK_ENERGY_SHARE: Final = Decimal("0.15")
MULTIPLIERS: Final = (Decimal("0.5"), Decimal("1.0"), Decimal("1.5"), Decimal("2.0"))  # §11.8
LOOKAHEAD_MULTIPLIER: Final = Decimal("0.5")
MAX_SNACKS: Final = 2
SNACKS_WHILE_BELOW: Final = Decimal("0.90")  # of target_kcal
DAY_KCAL_CEILING: Final = Decimal("1.10")  # of target_kcal, for snacks
KCAL_TOLERANCE: Final = Decimal("0.10")  # kcal_within_10pct (§28.4, §30.5)
# §28.6 reason-code thresholds.
FITS_KCAL_TOLERANCE: Final = Decimal("0.15")  # of the item's slot target
HIGH_PROTEIN_ENERGY_SHARE: Final = Decimal("0.20")
LOW_SODIUM_MG_PER_100G: Final = Decimal(120)  # UK FSA "low"
LOW_SUGAR_G_PER_100G: Final = Decimal(5)  # UK FSA "low"
LOW_SATURATED_FAT_G_PER_100G: Final = Decimal("1.5")  # UK FSA "low"
HIGH_FIBER_G_PER_100G: Final = Decimal(6)  # EU "high fibre" claim
# ---------------------------------------------------------------------------------------------

FITS_KCAL_TARGET: Final = "FITS_KCAL_TARGET"
HIGH_PROTEIN: Final = "HIGH_PROTEIN"
LOW_SODIUM: Final = "LOW_SODIUM"
LOW_SUGAR: Final = "LOW_SUGAR"
LOW_SATURATED_FAT: Final = "LOW_SATURATED_FAT"
HIGH_FIBER: Final = "HIGH_FIBER"
SUITS_CONDITION_PREFIX: Final = "SUITS_CONDITION_"
MATCHES_LIKED_INGREDIENT: Final = "MATCHES_LIKED_INGREDIENT"
PER_100G_REASONS: Final = (
    (LOW_SODIUM, "sodium", LOW_SODIUM_MG_PER_100G, False),
    (LOW_SUGAR, "sugars", LOW_SUGAR_G_PER_100G, False),
    (LOW_SATURATED_FAT, "saturated_fat", LOW_SATURATED_FAT_G_PER_100G, False),
    (HIGH_FIBER, "fiber", HIGH_FIBER_G_PER_100G, True),
)

# Planner rules, as counted in NoFeasiblePlanError.reasons (Layer 1 codes are counted as is).
MEAL_ALREADY_USED: Final = "MEAL_ALREADY_USED"
VARIANT_GROUP_USED: Final = "VARIANT_GROUP_USED"
MAX_PER_DAY: Final = "MAX_PER_DAY"
LOOKAHEAD_MAX_PER_DAY: Final = "LOOKAHEAD_MAX_PER_DAY"
LIMIT_TAG: Final = "LIMIT_TAG"
DAY_KCAL_ABOVE_CEILING: Final = "DAY_KCAL_ABOVE_CEILING"


class PlanError(Exception):
    pass


class MissingTargetError(PlanError, LookupError):
    pass


class NoFeasiblePlanError(PlanError):
    """A main slot has no valid (meal, multiplier) pair; no limit is relaxed, no slot dropped.

    reasons counts, per rule, the candidate pairs it removed; a pair failing several rules is
    counted under each of them.
    """

    def __init__(self, slot: str, reasons: Mapping[str, int], candidates: int) -> None:
        self.slot = str(slot)
        self.reasons = dict(sorted(reasons.items()))
        self.candidates = candidates
        summary = ", ".join(f"{rule} {count}" for rule, count in self.reasons.items())
        super().__init__(
            f"no valid (meal, multiplier) pair for {self.slot}: {candidates} candidate pairs, "
            f"removed by {summary}"
        )


@dataclass(frozen=True)
class PlanTarget:
    formula_version: str
    kcal: Decimal
    protein_g: Decimal
    carb_g: Decimal
    fat_g: Decimal
    fiber_g: Decimal

    @classmethod
    def from_user_target(cls, target: UserTarget) -> PlanTarget:
        kcal = to_decimal(target.target_kcal)
        return cls(
            formula_version=target.formula_version,
            kcal=kcal,
            protein_g=to_decimal(target.target_protein_g),
            carb_g=to_decimal(target.target_carb_g),
            fat_g=to_decimal(target.target_fat_g),
            fiber_g=Decimal(fiber_target_g(kcal)),
        )

    def to_snapshot(self) -> dict[str, str]:
        return {
            "kcal": str(self.kcal),
            "protein_g": str(self.protein_g),
            "carb_g": str(self.carb_g),
            "fat_g": str(self.fat_g),
            "fiber_g": str(self.fiber_g),
        }


@dataclass(frozen=True)
class PlanItem:
    slot: str
    meal_id: int
    ref_external: str | None
    name: str
    multiplier: Decimal
    nutrients: Mapping[str, Decimal]
    reason_codes: tuple[str, ...]


@dataclass(frozen=True)
class UnmetMinimum:
    nutrient: str
    minimum: Decimal
    total: Decimal | None
    gap: Decimal | None


@dataclass(frozen=True)
class DayPlan:
    plan_date: date
    target: PlanTarget
    items: tuple[PlanItem, ...]
    totals: Mapping[str, Decimal | None]
    kcal_within_10pct: bool
    unmet_minimums: tuple[UnmetMinimum, ...]
    planner_version: str = PLANNER_VERSION


@dataclass(frozen=True)
class _Pair:
    meal: MealFacts
    multiplier: Decimal

    @property
    def kcal(self) -> Decimal:
        return self.meal.per_serving[ENERGY_NUTRIENT] * self.multiplier

    @property
    def protein(self) -> Decimal:
        return self.meal.per_serving[PROTEIN_NUTRIENT] * self.multiplier


@dataclass
class _Day:
    chosen: list[tuple[str, _Pair]] = field(default_factory=list)

    def total(self, nutrient: str) -> Decimal | None:
        total = Decimal(0)
        for _slot, pair in self.chosen:
            amount = pair.meal.amount(nutrient, pair.multiplier)
            if amount is None:
                return None
            total += amount
        return total

    @property
    def kcal(self) -> Decimal:
        return sum((pair.kcal for _slot, pair in self.chosen), Decimal(0))

    def uses(self, meal: MealFacts) -> tuple[bool, bool]:
        """(meal already used, its variant_group already used)."""
        used_meals = {pair.meal.meal_id for _slot, pair in self.chosen}
        groups = {pair.meal.variant_group for _slot, pair in self.chosen} - {None}
        return meal.meal_id in used_meals, meal.variant_group in groups

    def tag_servings(self, tag: str) -> Decimal:
        return sum(
            (pair.multiplier for _slot, pair in self.chosen if tag in pair.meal.tags), Decimal(0)
        )

    @property
    def snack_count(self) -> int:
        return sum(1 for slot, _pair in self.chosen if slot == MealSlot.SNACK)


Evaluations = Mapping[tuple[str, Decimal], Mapping[int, MealEvaluation]]


def _minimum_additions(
    meals: Iterable[MealFacts],
    evaluations: Mapping[int, MealEvaluation],
    limits: ResolvedLimits,
) -> dict[str, Decimal]:
    """Smallest amount, per max_per_day nutrient, that any eligible meal adds at 0.5 servings."""
    smallest: dict[str, Decimal] = {}
    for meal in meals:
        if not evaluations[meal.meal_id].eligible:
            continue
        for nutrient in limits.max_per_day:
            amount = meal.amount(nutrient, LOOKAHEAD_MULTIPLIER)
            if amount is not None and (nutrient not in smallest or amount < smallest[nutrient]):
                smallest[nutrient] = amount
    return smallest


def _rejections(
    pair: _Pair,
    evaluation: MealEvaluation,
    day: _Day,
    limits: ResolvedLimits,
    reserve: Mapping[str, Decimal],
    kcal_ceiling: Decimal | None,
) -> list[str]:
    rules = list(evaluation.exclusion_codes)
    meal_used, group_used = day.uses(pair.meal)
    if meal_used:
        rules.append(MEAL_ALREADY_USED)
    if group_used:
        rules.append(VARIANT_GROUP_USED)
    for nutrient, limit in limits.max_per_day.items():
        amount = pair.meal.amount(nutrient, pair.multiplier)
        running = day.total(nutrient)
        if amount is None or running is None or running + amount > limit.value:
            rules.append(f"{MAX_PER_DAY}:{nutrient}")
        elif running + amount + reserve.get(nutrient, Decimal(0)) > limit.value:
            rules.append(f"{LOOKAHEAD_MAX_PER_DAY}:{nutrient}")
    for tag, weekly in limits.limit_tags.items():
        if (
            weekly is not None
            and tag in pair.meal.tags
            and day.tag_servings(tag) + pair.multiplier > weekly
        ):
            rules.append(f"{LIMIT_TAG}:{tag}")
    if kcal_ceiling is not None and (
        ENERGY_NUTRIENT not in pair.meal.per_serving or day.kcal + pair.kcal > kcal_ceiling
    ):
        rules.append(DAY_KCAL_ABOVE_CEILING)
    return rules


def _valid_pairs(
    meals: Sequence[MealFacts],
    evaluations: Evaluations,
    slot: str,
    day: _Day,
    limits: ResolvedLimits,
    reserve: Mapping[str, Decimal],
    kcal_ceiling: Decimal | None = None,
) -> tuple[list[_Pair], Counter[str], int]:
    valid: list[_Pair] = []
    removed: Counter[str] = Counter()
    candidates = 0
    for meal in meals:
        for multiplier in MULTIPLIERS:
            candidates += 1
            pair = _Pair(meal, multiplier)
            rules = _rejections(
                pair,
                evaluations[(slot, multiplier)][meal.meal_id],
                day,
                limits,
                reserve,
                kcal_ceiling,
            )
            if rules:
                removed.update(set(rules))
            else:
                valid.append(pair)
    return valid, removed, candidates


def reason_codes(
    meal: MealFacts,
    multiplier: Decimal,
    slot_target_kcal: Decimal,
    limits: ResolvedLimits,
    preferences: UserPreferences,
) -> tuple[str, ...]:
    """§28.6 explanation codes, deterministic, sorted. NEW_FOR_VARIETY needs history (not F.1)."""
    codes: set[str] = set()
    kcal = meal.per_serving[ENERGY_NUTRIENT] * multiplier
    if abs(kcal - slot_target_kcal) <= FITS_KCAL_TOLERANCE * slot_target_kcal:
        codes.add(FITS_KCAL_TARGET)
    protein = meal.per_serving.get(PROTEIN_NUTRIENT)
    serving_kcal = meal.per_serving[ENERGY_NUTRIENT]
    if (
        protein is not None
        and serving_kcal > 0
        and protein * KCAL_PER_G_PROTEIN >= HIGH_PROTEIN_ENERGY_SHARE * serving_kcal
    ):
        codes.add(HIGH_PROTEIN)
    for code, nutrient, threshold, at_least in PER_100G_REASONS:
        amount = meal.per_100g.get(nutrient)
        if amount is not None and (amount >= threshold if at_least else amount <= threshold):
            codes.add(code)
    for condition in limits.conditions:
        absolute, percent = limits.condition_max_per_meal(condition)
        if not per_meal_violations(meal, multiplier, absolute, percent) and not (
            meal.tags & limits.condition_tags(condition)
        ):
            codes.add(f"{SUITS_CONDITION_PREFIX}{condition}")
    if meal.ingredient_ids & preferences.liked_ingredient_ids:
        codes.add(MATCHES_LIKED_INGREDIENT)
    return tuple(sorted(codes))


def plan_day(
    meals: Sequence[MealFacts],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target: PlanTarget,
    plan_date: date,
    nutrient_codes: Sequence[str],
) -> DayPlan:
    """The greedy_v1 algorithm on already-loaded data (pure)."""
    meals = sorted(meals, key=lambda meal: meal.sort_key)
    evaluations: dict[tuple[str, Decimal], dict[int, MealEvaluation]] = {
        (slot, multiplier): {
            meal.meal_id: evaluate_meal(meal, preferences, slot, limits, multiplier)
            for meal in meals
        }
        for slot in MealSlot
        for multiplier in MULTIPLIERS
    }
    smallest = {
        slot: _minimum_additions(meals, evaluations[(slot, LOOKAHEAD_MULTIPLIER)], limits)
        for slot in MAIN_SLOTS
    }
    day = _Day()

    for index, slot in enumerate(MAIN_SLOTS):
        later = MAIN_SLOTS[index + 1 :]
        reserve = {
            nutrient: sum((smallest[s].get(nutrient, Decimal(0)) for s in later), Decimal(0))
            for nutrient in limits.max_per_day
        }
        valid, removed, candidates = _valid_pairs(meals, evaluations, slot, day, limits, reserve)
        if not valid:
            raise NoFeasiblePlanError(slot, removed, candidates)
        slot_kcal = SLOT_ENERGY_SHARE[slot] * target.kcal
        slot_protein = SLOT_ENERGY_SHARE[slot] * target.protein_g
        best = min(
            valid,
            key=lambda p: (
                abs(p.kcal - slot_kcal),
                abs(p.protein - slot_protein),
                p.meal.sort_key,
                p.multiplier,
            ),
        )
        day.chosen.append((slot, best))

    ceiling = DAY_KCAL_CEILING * target.kcal
    while day.snack_count < MAX_SNACKS and day.kcal < SNACKS_WHILE_BELOW * target.kcal:
        valid, _removed, _candidates = _valid_pairs(
            meals, evaluations, MealSlot.SNACK, day, limits, {}, ceiling
        )
        if not valid:
            break
        gap = target.kcal - day.kcal
        best = min(valid, key=lambda p: (abs(gap - p.kcal), p.meal.sort_key, p.multiplier))
        day.chosen.append((MealSlot.SNACK, best))

    snack_target = (
        SNACK_ENERGY_SHARE * target.kcal / day.snack_count if day.snack_count else Decimal(0)
    )
    items = tuple(
        PlanItem(
            slot=str(slot),
            meal_id=pair.meal.meal_id,
            ref_external=pair.meal.ref_external,
            name=pair.meal.name,
            multiplier=pair.multiplier,
            nutrients={
                code: amount
                for code in nutrient_codes
                if (amount := pair.meal.amount(code, pair.multiplier)) is not None
            },
            reason_codes=reason_codes(
                pair.meal,
                pair.multiplier,
                snack_target if slot == MealSlot.SNACK else SLOT_ENERGY_SHARE[slot] * target.kcal,
                limits,
                preferences,
            ),
        )
        for slot, pair in day.chosen
    )
    totals = {code: day.total(code) for code in nutrient_codes}
    unmet = []
    for nutrient, minimum in limits.min_per_day.items():
        total = totals.get(nutrient)
        if total is None or total < minimum.value:
            unmet.append(
                UnmetMinimum(
                    nutrient=nutrient,
                    minimum=minimum.value,
                    total=total,
                    gap=None if total is None else minimum.value - total,
                )
            )
    return DayPlan(
        plan_date=plan_date,
        target=target,
        items=items,
        totals=totals,
        kcal_within_10pct=abs(day.kcal - target.kcal) <= KCAL_TOLERANCE * target.kcal,
        unmet_minimums=tuple(unmet),
    )


def build_day_plan(
    session: Session,
    user_id: int,
    limits: ResolvedLimits,
    target: PlanTarget,
    plan_date: date,
) -> DayPlan:
    """One deterministic day for the user (no writes); raises NoFeasiblePlanError."""
    nutrient_codes = tuple(
        session.execute(select(Nutrient.code).order_by(Nutrient.nutrient_id)).scalars()
    )
    return plan_day(
        load_meal_facts(session),
        load_user_preferences(session, user_id),
        limits,
        target,
        plan_date,
        nutrient_codes,
    )


def target_snapshot(target: PlanTarget, limits: ResolvedLimits) -> dict[str, Any]:
    """meal_plans.target_snapshot: immutable copy of what the plan was built against (§11.7)."""
    return {
        "formula_version": target.formula_version,
        "target": target.to_snapshot(),
        "limits": limits.to_snapshot(),
        "tag_rules_version": TAG_RULES_VERSION,
        "planner_version": PLANNER_VERSION,
        "computation_version": COMPUTATION_VERSION,
    }


def create_day_plan(session: Session, user_id: int, plan_date: date, now: datetime) -> MealPlan:
    """Generate and store a one-day plan; older plans of the same day are never touched (#72).

    Screening uses the user's local date of `now`. created_at = now, so the newest plan
    covering a day is the current one.
    """
    if now.tzinfo is None:
        raise ValueError("now must be timezone-aware")
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    screening = screen_user(session, user_id, now.astimezone(ZoneInfo(profile.timezone)).date())
    if not screening.eligible:
        raise UserNotEligibleError(user_id, screening.reasons)
    current = session.execute(
        select(UserTarget).where(UserTarget.user_id == user_id, UserTarget.valid_to.is_(None))
    ).scalar_one_or_none()
    if current is None:
        raise MissingTargetError(f"user {user_id} has no current user_targets row")
    target = PlanTarget.from_user_target(current)
    limits = resolve_condition_limits(session, user_id, target.kcal)
    day = build_day_plan(session, user_id, limits, target, plan_date)

    plan = MealPlan(
        user_id=user_id,
        date_from=plan_date,
        date_to=plan_date,
        generated_by=GENERATED_BY,
        algorithm_version=PLANNER_VERSION,
        target_id=current.target_id,
        target_snapshot=target_snapshot(target, limits),
        created_at=now,
        updated_at=now,
    )
    session.add(plan)
    session.flush()
    session.add_all(
        MealPlanItem(
            plan_id=plan.plan_id,
            day_index=0,
            slot=item.slot,
            meal_id=item.meal_id,
            servings_multiplier=float(item.multiplier),
            was_swapped=False,
            reason_codes=list(item.reason_codes),
            created_at=now,
            updated_at=now,
        )
        for item in day.items
    )
    session.flush()
    return plan


def current_plan_id(session: Session, user_id: int, day: date) -> int | None:
    """§11.7 current-plan rule (#72): the newest plan (created_at) whose dates cover `day`."""
    return session.execute(
        select(MealPlan.plan_id)
        .where(MealPlan.user_id == user_id, MealPlan.date_from <= day, MealPlan.date_to >= day)
        .order_by(MealPlan.created_at.desc(), MealPlan.plan_id.desc())
        .limit(1)
    ).scalar_one_or_none()
