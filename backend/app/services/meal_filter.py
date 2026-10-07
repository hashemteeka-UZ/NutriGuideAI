"""Layer 1 hard filtering (§28.1, §9.4b): deterministic rules, never a statistical guess.

load_meal_facts and load_user_preferences read the database once; evaluate_meal is pure, so
the planner can evaluate every (slot, multiplier) pair without new queries. evaluate_meals
returns every meal, active or not, with all the rules it fails. The exclusion codes are for
tests and the report; they are not stored.
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from decimal import Decimal
from typing import Final

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    DietaryTag,
    Meal,
    MealAllergen,
    MealIngredient,
    MealNutrient,
    MealTag,
    Nutrient,
    UserAllergenPref,
    UserIngredientPref,
)
from app.db.models.user import IngredientStance, MealSlot
from app.services.common import to_decimal
from app.services.condition_limits import ENERGY_NUTRIENT, ResolvedLimits, energy_share_percent

# --- §28.1 / §9.4b constants ------------------------------------------------------------------
# Rule 6. beverage and nuts_seeds_snack alone do not make a meal a snack candidate; every slice
# snack also carries snack_suitable (Step F.1 decision).
SLOT_OCCASION: Final[Mapping[str, str]] = {
    MealSlot.BREAKFAST: "breakfast_suitable",
    MealSlot.LUNCH: "lunch_suitable",
    MealSlot.DINNER: "dinner_suitable",
    MealSlot.SNACK: "snack_suitable",
}
DEFAULT_MULTIPLIER: Final = Decimal("1.0")
# ---------------------------------------------------------------------------------------------

INACTIVE: Final = "INACTIVE"
INCOMPLETE_NUTRIENTS: Final = "INCOMPLETE_NUTRIENTS"
ALLERGEN: Final = "ALLERGEN"
EXCLUDED_INGREDIENT: Final = "EXCLUDED_INGREDIENT"
AVOID_TAG: Final = "AVOID_TAG"
MAX_PER_MEAL: Final = "MAX_PER_MEAL"
NO_OCCASION: Final = "NO_OCCASION"


@dataclass(frozen=True)
class MealFacts:
    """What Layer 1 and the planner need to know about one meal."""

    meal_id: int
    ref_external: str | None
    name: str
    variant_group: str | None
    is_active: bool
    is_nutritionally_complete: bool
    per_serving: Mapping[str, Decimal]
    per_100g: Mapping[str, Decimal]
    allergens: Mapping[int, str]
    ingredient_ids: frozenset[int]
    tags: frozenset[str]

    @property
    def sort_key(self) -> tuple[bool, str, int]:
        return (self.ref_external is None, self.ref_external or "", self.meal_id)

    def amount(self, nutrient: str, multiplier: Decimal) -> Decimal | None:
        """Amount for `multiplier` servings; None when unknown (missing ≠ zero, §9.8)."""
        per_serving = self.per_serving.get(nutrient)
        return None if per_serving is None else per_serving * multiplier


@dataclass(frozen=True)
class UserPreferences:
    allergen_ids: frozenset[int]
    excluded_ingredient_ids: frozenset[int]
    liked_ingredient_ids: frozenset[int]


@dataclass(frozen=True)
class MealEvaluation:
    meal_id: int
    ref_external: str | None
    slot: str
    servings_multiplier: Decimal
    eligible: bool
    exclusion_codes: list[str]


def load_meal_facts(session: Session) -> list[MealFacts]:
    """Every meal (active or not), sorted by ref_external then meal_id."""
    mandatory = frozenset(
        session.execute(select(Nutrient.code).where(Nutrient.is_mandatory)).scalars()
    )
    per_serving: dict[int, dict[str, Decimal]] = defaultdict(dict)
    per_100g: dict[int, dict[str, Decimal]] = defaultdict(dict)
    for row in session.execute(
        select(
            MealNutrient.meal_id,
            Nutrient.code,
            MealNutrient.amount_per_serving,
            MealNutrient.amount_per_100g,
        ).join(Nutrient, Nutrient.nutrient_id == MealNutrient.nutrient_id)
    ):
        per_serving[row.meal_id][row.code] = to_decimal(row.amount_per_serving)
        per_100g[row.meal_id][row.code] = to_decimal(row.amount_per_100g)
    allergens: dict[int, dict[int, str]] = defaultdict(dict)
    for meal_id, allergen_id, name_en in session.execute(
        select(MealAllergen.meal_id, Allergen.allergen_id, Allergen.name_en).join(
            Allergen, Allergen.allergen_id == MealAllergen.allergen_id
        )
    ).tuples():
        allergens[meal_id][allergen_id] = name_en
    ingredients: dict[int, set[int]] = defaultdict(set)
    for meal_id, ingredient_id in session.execute(
        select(MealIngredient.meal_id, MealIngredient.ingredient_id)
    ).tuples():
        ingredients[meal_id].add(ingredient_id)
    tags: dict[int, set[str]] = defaultdict(set)
    for meal_id, code in session.execute(
        select(MealTag.meal_id, DietaryTag.code).join(
            DietaryTag, DietaryTag.tag_id == MealTag.tag_id
        )
    ).tuples():
        tags[meal_id].add(code)

    facts = [
        MealFacts(
            meal_id=row.meal_id,
            ref_external=row.ref_external,
            name=row.name,
            variant_group=row.variant_group,
            is_active=row.is_active,
            # Same rule as is_meal_nutritionally_complete (§10.3), for all meals at once.
            is_nutritionally_complete=mandatory <= per_serving[row.meal_id].keys(),
            per_serving=per_serving[row.meal_id],
            per_100g=per_100g[row.meal_id],
            allergens=allergens[row.meal_id],
            ingredient_ids=frozenset(ingredients[row.meal_id]),
            tags=frozenset(tags[row.meal_id]),
        )
        for row in session.execute(
            select(Meal.meal_id, Meal.ref_external, Meal.name, Meal.variant_group, Meal.is_active)
        )
    ]
    return sorted(facts, key=lambda meal: meal.sort_key)


def load_user_preferences(session: Session, user_id: int) -> UserPreferences:
    """§11.4: any allergen severity excludes; §11.5: only EXCLUDE excludes, LIKE is kept."""
    allergen_ids = frozenset(
        session.execute(
            select(UserAllergenPref.allergen_id).where(UserAllergenPref.user_id == user_id)
        ).scalars()
    )
    stances: dict[str, set[int]] = defaultdict(set)
    for row in session.execute(
        select(UserIngredientPref.ingredient_id, UserIngredientPref.stance).where(
            UserIngredientPref.user_id == user_id
        )
    ):
        stances[row.stance].add(row.ingredient_id)
    return UserPreferences(
        allergen_ids=allergen_ids,
        excluded_ingredient_ids=frozenset(stances[IngredientStance.EXCLUDE]),
        liked_ingredient_ids=frozenset(stances[IngredientStance.LIKE]),
    )


def per_meal_violations(
    meal: MealFacts,
    multiplier: Decimal,
    absolute: Mapping[str, Decimal],
    percent_energy: Mapping[str, Decimal],
) -> list[str]:
    """Nutrients whose amount for `multiplier` servings breaks a per-meal maximum (rule 5).

    Absolute maxima compare the amount; percentage maxima compare the nutrient's share of the
    meal's own energy, which does not depend on the multiplier (§9.5b). An unknown amount
    cannot be shown to respect a limit, so it counts as a violation.
    """
    violations: set[str] = set()
    for nutrient, maximum in absolute.items():
        amount = meal.amount(nutrient, multiplier)
        if amount is None or amount > maximum:
            violations.add(nutrient)
    energy = meal.per_serving.get(ENERGY_NUTRIENT)
    for nutrient, maximum in percent_energy.items():
        amount = meal.per_serving.get(nutrient)
        if (
            amount is None
            or energy is None
            or energy_share_percent(nutrient, amount, energy) > maximum
        ):
            violations.add(nutrient)
    return sorted(violations)


def evaluate_meal(
    meal: MealFacts,
    preferences: UserPreferences,
    slot: str,
    limits: ResolvedLimits,
    servings_multiplier: Decimal = DEFAULT_MULTIPLIER,
) -> MealEvaluation:
    """All failing Layer 1 rules of one meal for one slot, in rule order (§28.1)."""
    slot = MealSlot(slot)
    codes: list[str] = []
    if not meal.is_active:
        codes.append(INACTIVE)
    if not meal.is_nutritionally_complete:
        codes.append(INCOMPLETE_NUTRIENTS)
    codes += sorted(
        f"{ALLERGEN}:{name}"
        for allergen_id, name in meal.allergens.items()
        if allergen_id in preferences.allergen_ids
    )
    codes += [
        f"{EXCLUDED_INGREDIENT}:{ingredient_id}"
        for ingredient_id in sorted(meal.ingredient_ids & preferences.excluded_ingredient_ids)
    ]
    codes += [f"{AVOID_TAG}:{tag}" for tag in sorted(meal.tags & limits.avoid_tags)]
    codes += [
        f"{MAX_PER_MEAL}:{nutrient}"
        for nutrient in per_meal_violations(
            meal,
            servings_multiplier,
            {n: limit.value for n, limit in limits.max_per_meal.items()},
            {n: limit.value for n, limit in limits.max_per_meal_percent_energy.items()},
        )
    ]
    if SLOT_OCCASION[slot] not in meal.tags:
        codes.append(f"{NO_OCCASION}:{slot}")
    return MealEvaluation(
        meal_id=meal.meal_id,
        ref_external=meal.ref_external,
        slot=slot,
        servings_multiplier=servings_multiplier,
        eligible=not codes,
        exclusion_codes=codes,
    )


def evaluate_all(
    meals: Iterable[MealFacts],
    preferences: UserPreferences,
    slot: str,
    limits: ResolvedLimits,
    servings_multiplier: Decimal = DEFAULT_MULTIPLIER,
) -> list[MealEvaluation]:
    return [evaluate_meal(m, preferences, slot, limits, servings_multiplier) for m in meals]


def evaluate_meals(
    session: Session,
    user_id: int,
    slot: str,
    limits: ResolvedLimits,
    servings_multiplier: Decimal = DEFAULT_MULTIPLIER,
) -> list[MealEvaluation]:
    """Every meal (active or not) with eligible and all its exclusion codes."""
    return evaluate_all(
        load_meal_facts(session),
        load_user_preferences(session, user_id),
        slot,
        limits,
        servings_multiplier,
    )


def eligible_meal_ids(
    session: Session,
    user_id: int,
    slot: str,
    limits: ResolvedLimits,
    servings_multiplier: Decimal = DEFAULT_MULTIPLIER,
) -> list[int]:
    return [
        e.meal_id
        for e in evaluate_meals(session, user_id, slot, limits, servings_multiplier)
        if e.eligible
    ]
