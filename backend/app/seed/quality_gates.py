"""Step F.1 quality gates (§9.7, §31.3, §31.6). Pure functions: no database, no I/O.

Each gate returns a list of failures; an empty list means the gate passed. The loader runs every
gate and refuses to write anything if any gate fails, so all failures are reported at once.
"""

from __future__ import annotations

import re
from collections import defaultdict
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass

from app.db.models.catalog import WeightMethod
from app.db.models.reference import LimitBasis, TagGroup
from app.seed.f1_files import (
    ConditionLimitSeed,
    F1Files,
    NutrientSeed,
    SliceFood,
    SliceMeal,
    SubsetRow,
)

# §9.5b: PERCENT_ENERGY is only meaningful for energy-yielding nutrients.
PERCENT_ENERGY_NUTRIENTS = frozenset(
    {"total_fat", "saturated_fat", "carbohydrate", "sugars", "protein"}
)
ENERGY_TOLERANCE_RELATIVE = 0.20
ENERGY_TOLERANCE_ABSOLUTE_KCAL = 15.0
LOW_ENERGY_KCAL = 50.0
MAX_YIELD_FACTOR = 3.0
# §10.2 seed QC: basic cooking ingredients a recipe cannot leave out.
NEVER_OPTIONAL_NDB = {"14555": "water", "02047": "salt", "04053": "olive oil"}


@dataclass(frozen=True)
class GateFailure:
    gate: str
    subject: str
    message: str

    def __str__(self) -> str:
        return f"{self.gate} {self.subject}: {self.message}"


def _amounts_by_food(
    nutrients: Sequence[NutrientSeed], subset: Iterable[SubsetRow]
) -> dict[str, dict[str, float]]:
    """{ndb_number: {nutrient code: amount per 100 g}} for nutrients present in the source."""
    code_by_nbr = {n.source_code: n.code for n in nutrients if n.source_code}
    amounts: dict[str, dict[str, float]] = defaultdict(dict)
    for row in subset:
        code = code_by_nbr.get(row.nutrient_nbr)
        if code is not None:
            amounts[row.ndb_number][code] = row.amount_per_100g
    return amounts


def gate_mandatory_nutrients(
    foods: Sequence[SliceFood], nutrients: Sequence[NutrientSeed], subset: Sequence[SubsetRow]
) -> list[GateFailure]:
    """G1: every food has a source value for every is_mandatory nutrient (§9.7, §31.3)."""
    mandatory = sorted(n.code for n in nutrients if n.is_mandatory)
    amounts = _amounts_by_food(nutrients, subset)
    failures = []
    for food in foods:
        missing = [code for code in mandatory if code not in amounts.get(food.ndb_number, {})]
        if missing:
            failures.append(
                GateFailure("G1", food.ndb_number, f"missing mandatory nutrients {missing}")
            )
    return failures


def atwater_kcal(protein: float, carbohydrate: float, fiber: float, total_fat: float) -> float:
    """4/4/9 with fiber at 2 kcal/g; SR Legacy carbohydrate is by difference and includes fiber."""
    return 4 * protein + 4 * (carbohydrate - fiber) + 2 * fiber + 9 * total_fat


def gate_energy_consistency(
    nutrients: Sequence[NutrientSeed], subset: Sequence[SubsetRow]
) -> list[GateFailure]:
    """G2: reported energy agrees with the macronutrients (§31.3)."""
    needed = ("energy_kcal", "protein", "carbohydrate", "fiber", "total_fat")
    failures = []
    for ndb, values in sorted(_amounts_by_food(nutrients, subset).items()):
        if not all(code in values for code in needed):
            continue  # reported by G1
        energy = values["energy_kcal"]
        calc = atwater_kcal(
            values["protein"], values["carbohydrate"], values["fiber"], values["total_fat"]
        )
        diff = abs(calc - energy)
        if energy >= LOW_ENERGY_KCAL:
            bad = diff / energy > ENERGY_TOLERANCE_RELATIVE
        else:
            bad = diff > ENERGY_TOLERANCE_ABSOLUTE_KCAL
        if bad:
            failures.append(
                GateFailure(
                    "G2", ndb, f"energy_kcal {energy:g} vs macronutrient estimate {calc:.1f}"
                )
            )
    return failures


def _keyword_pattern(keyword: str) -> re.Pattern[str]:
    return re.compile(rf"(?<!\w){re.escape(keyword)}(?!\w)", re.IGNORECASE)


def gate_excluded_ingredients(
    keywords: Sequence[str], foods: Sequence[SliceFood], subset: Sequence[SubsetRow]
) -> list[GateFailure]:
    """G3: no excluded keyword, as a whole word, in a food or ingredient name (§31.6)."""
    patterns = [(kw, _keyword_pattern(kw)) for kw in keywords]
    fdc_descriptions: dict[str, set[str]] = defaultdict(set)
    for row in subset:
        fdc_descriptions[row.ndb_number].add(row.description)
    failures = []
    for food in foods:
        texts = {
            food.sr_description,
            food.ingredient_en,
            food.ingredient_ar,
            *fdc_descriptions.get(food.ndb_number, set()),
        }
        for keyword, pattern in patterns:
            for text in sorted(texts):
                if pattern.search(text):
                    failures.append(
                        GateFailure(
                            "G3", food.ndb_number, f"excluded keyword {keyword!r} in {text!r}"
                        )
                    )
    return failures


def gate_references(files: F1Files) -> list[GateFailure]:
    """G4: every cross-file reference resolves; every food category has an Arabic name."""
    seed, foods, meals = files.seed, files.foods.foods, files.meals.meals
    food_ndbs = {f.ndb_number for f in foods}
    subset_ndbs = {r.ndb_number for r in files.subset}
    # slice_foods.yaml names allergens by name_en; the loader maps them to the seed's code.
    allergens = set(allergen_codes_by_name(files))
    tags = {t.code for t in seed.dietary_tags}
    cuisines = {c.code for c in seed.cuisines}
    conditions = {c.code for c in seed.health_conditions}
    nutrient_codes = {n.code for n in seed.nutrients}
    nutrient_nbrs = {n.source_code for n in seed.nutrients if n.source_code}
    failures: list[GateFailure] = []

    def fail(subject: str, message: str) -> None:
        failures.append(GateFailure("G4", subject, message))

    for food in foods:
        if food.ndb_number not in subset_ndbs:
            fail(food.ndb_number, "food has no rows in the FDC subset")
        for allergen in food.allergens:
            if allergen not in allergens:
                fail(food.ndb_number, f"unknown allergen {allergen!r}")
        for tag in food.ingredient_tags:
            if tag not in tags:
                fail(food.ndb_number, f"unknown ingredient tag {tag!r}")
    for ndb in sorted(subset_ndbs - food_ndbs):
        fail(ndb, "FDC subset row for a food not in slice_foods.yaml")
    for row in files.subset:
        if row.nutrient_nbr not in nutrient_nbrs:
            fail(row.ndb_number, f"subset nutrient_nbr {row.nutrient_nbr} not in the seed")
    for code in sorted({r.food_category_code for r in files.subset} - set(seed.categories_ar)):
        fail(code, "FDC food category has no Arabic name in categories_ar")
    for ndb, fdc_ids in _values_by_ndb(files.subset, lambda r: str(r.fdc_id)).items():
        if len(fdc_ids) > 1:
            fail(ndb, f"several fdc_id values in the subset: {sorted(fdc_ids)}")
    for lang, names in (
        ("en", [f.ingredient_en for f in foods]),
        ("ar", [f.ingredient_ar for f in foods]),
    ):
        for name in sorted({n for n in names if names.count(n) > 1}):
            fail(name, f"ingredient name used by more than one food (alias {lang} must be unique)")

    for meal in meals:
        if meal.cuisine not in cuisines:
            fail(meal.ref_external, f"unknown cuisine {meal.cuisine!r}")
        for tag in (*meal.occasion_tags, *meal.dietary_tags):
            if tag not in tags:
                fail(meal.ref_external, f"unknown tag {tag!r}")
        for item in meal.ingredients:
            if item.ndb_number not in food_ndbs:
                fail(meal.ref_external, f"ingredient NDB {item.ndb_number} not in slice_foods.yaml")
    for limit in seed.condition_nutrient_limits:
        subject = f"{limit.condition}/{limit.nutrient}"
        if limit.condition not in conditions:
            fail(subject, f"unknown condition {limit.condition!r}")
        if limit.nutrient not in nutrient_codes:
            fail(subject, f"unknown nutrient {limit.nutrient!r}")
    for restriction in seed.condition_tag_restrictions:
        subject = f"{restriction.condition}/{restriction.tag}"
        if restriction.condition not in conditions:
            fail(subject, f"unknown condition {restriction.condition!r}")
        if restriction.tag not in tags:
            fail(subject, f"unknown tag {restriction.tag!r}")
    return failures


def allergen_codes_by_name(files: F1Files) -> dict[str, str]:
    return {a.name_en: a.code for a in files.seed.allergens}


def _values_by_ndb(
    rows: Iterable[SubsetRow], value: Callable[[SubsetRow], str]
) -> dict[str, set[str]]:
    result: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        result[row.ndb_number].add(value(row))
    return result


def gate_tag_groups(files: F1Files) -> list[GateFailure]:
    """G5: tags are used only in their group (§9.4, §9.4b, §9.5c, §9.13)."""
    group = {t.code: t.tag_group for t in files.seed.dietary_tags}
    failures: list[GateFailure] = []

    def check(subject: str, tag: str, ok: Callable[[TagGroup], bool], expected: str) -> None:
        actual = group.get(tag)
        if actual is not None and not ok(actual):
            failures.append(
                GateFailure("G5", subject, f"tag {tag!r} is {actual.value}, expected {expected}")
            )

    for meal in files.meals.meals:
        for tag in meal.occasion_tags:
            check(meal.ref_external, tag, lambda g: g is TagGroup.OCCASION, "OCCASION")
        for tag in meal.dietary_tags:
            check(meal.ref_external, tag, lambda g: g is TagGroup.DIETARY, "DIETARY")
        if not meal.occasion_tags:
            failures.append(GateFailure("G5", meal.ref_external, "meal has no occasion tag"))
    for food in files.foods.foods:
        for tag in food.ingredient_tags:
            check(food.ndb_number, tag, lambda g: g is not TagGroup.OCCASION, "not OCCASION")
    for restriction in files.seed.condition_tag_restrictions:
        subject = f"{restriction.condition}/{restriction.tag}"
        check(subject, restriction.tag, lambda g: g is TagGroup.CONDITION, "CONDITION")
    return failures


def gate_weight_method(meals: Sequence[SliceMeal]) -> list[GateFailure]:
    """G6: weight_method agrees with the yield factor (§10.1)."""
    failures = []
    for meal in meals:
        subject = meal.ref_external
        if meal.weight_method is WeightMethod.YIELD_FACTOR:
            factor = meal.yield_factor
            if factor is None or not 0 < factor <= MAX_YIELD_FACTOR:
                failures.append(
                    GateFailure(
                        "G6", subject, f"YIELD_FACTOR needs 0 < yield_factor <= 3, got {factor}"
                    )
                )
            if meal.yield_factor_source is None:
                failures.append(
                    GateFailure("G6", subject, "YIELD_FACTOR needs yield_factor_source")
                )
        elif meal.weight_method is WeightMethod.SUM_OF_INGREDIENTS:
            if meal.yield_factor is not None:
                failures.append(
                    GateFailure("G6", subject, "SUM_OF_INGREDIENTS needs yield_factor null")
                )
        else:
            failures.append(
                GateFailure("G6", subject, f"{meal.weight_method.value} is not used in F.1")
            )
    return failures


def gate_percent_energy_limits(limits: Sequence[ConditionLimitSeed]) -> list[GateFailure]:
    """G7: PERCENT_ENERGY only for energy-yielding nutrients (§9.5b)."""
    return [
        GateFailure(
            "G7",
            f"{limit.condition}/{limit.nutrient}",
            "PERCENT_ENERGY is only valid for " + ", ".join(sorted(PERCENT_ENERGY_NUTRIENTS)),
        )
        for limit in limits
        if limit.limit_basis is LimitBasis.PERCENT_ENERGY
        and limit.nutrient not in PERCENT_ENERGY_NUTRIENTS
    ]


def gate_optional_ingredients(meals: Sequence[SliceMeal]) -> list[GateFailure]:
    """G8: water, salt and olive oil are never optional; one ingredient must stay (#75, §10.2)."""
    failures = []
    for meal in meals:
        for item in meal.ingredients:
            if item.optional and item.ndb_number in NEVER_OPTIONAL_NDB:
                name = NEVER_OPTIONAL_NDB[item.ndb_number]
                failures.append(
                    GateFailure(
                        "G8", meal.ref_external, f"{name} ({item.ndb_number}) is never optional"
                    )
                )
        if all(item.optional for item in meal.ingredients):
            failures.append(GateFailure("G8", meal.ref_external, "every ingredient is optional"))
    return failures


def gate_variant_groups(meals: Sequence[SliceMeal]) -> list[GateFailure]:
    """G9: a variant group has >= 2 meals sharing cuisine, servings and occasion tags (#76)."""
    groups: dict[str, list[SliceMeal]] = defaultdict(list)
    for meal in meals:
        if meal.variant_group is not None:
            groups[meal.variant_group].append(meal)
    failures = []
    for group, members in sorted(groups.items()):
        refs = [m.ref_external for m in members]
        if len(members) < 2:
            failures.append(GateFailure("G9", group, f"only one meal in the group: {refs}"))
            continue
        shared: dict[str, Callable[[SliceMeal], object]] = {
            "cuisine": lambda m: m.cuisine,
            "servings": lambda m: m.servings,
            "occasion_tags": lambda m: sorted(set(m.occasion_tags)),
        }
        for field, value in shared.items():
            values = {m.ref_external: value(m) for m in members}
            if len({str(v) for v in values.values()}) > 1:
                failures.append(GateFailure("G9", group, f"{field} differs: {values}"))
    return failures


GATE_NAMES = {
    "G1": "mandatory nutrients",
    "G2": "energy consistency",
    "G3": "excluded ingredients",
    "G4": "references",
    "G5": "tag groups",
    "G6": "weight method",
    "G7": "percent-energy limits",
    "G8": "optional ingredients",
    "G9": "variant groups",
}


def run_all_gates(files: F1Files) -> dict[str, list[GateFailure]]:
    seed, foods = files.seed, files.foods.foods
    return {
        "G1": gate_mandatory_nutrients(foods, seed.nutrients, files.subset),
        "G2": gate_energy_consistency(seed.nutrients, files.subset),
        "G3": gate_excluded_ingredients(seed.excluded_keywords, foods, files.subset),
        "G4": gate_references(files),
        "G5": gate_tag_groups(files),
        "G6": gate_weight_method(files.meals.meals),
        "G7": gate_percent_energy_limits(seed.condition_nutrient_limits),
        "G8": gate_optional_ingredients(files.meals.meals),
        "G9": gate_variant_groups(files.meals.meals),
    }
