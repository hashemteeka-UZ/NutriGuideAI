"""Catalog record-level gates (F.1 G2/G6-G9 plus G10-G12)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence

from app.db.models.catalog import WeightMethod
from app.pipeline.files import (
    MAX_STEP_CHARS,
    SUPPORTED_STEP_LANGS,
    THRESHOLD_TAG_CODES,
    CatalogFiles,
    CatalogIngredient,
    CatalogMeal,
    IngredientFoodSource,
    ManualFood,
    YieldFactorKind,
)
from app.seed.quality_gates import (
    ENERGY_TOLERANCE_ABSOLUTE_KCAL,
    ENERGY_TOLERANCE_RELATIVE,
    LOW_ENERGY_KCAL,
    MAX_YIELD_FACTOR,
    NEVER_OPTIONAL_NDB,
    GateFailure,
    atwater_kcal,
    gate_percent_energy_limits,
    gate_variant_groups,
)

NEVER_OPTIONAL_CODES = frozenset({"WATER", "SALT", "OLIVE_OIL"})


def gate_energy_from_amounts(amounts: Mapping[str, Mapping[str, float]]) -> list[GateFailure]:
    """G2: reported energy agrees with the macronutrients (§31.3), on filled values."""
    needed = ("energy_kcal", "protein", "carbohydrate", "fiber", "total_fat")
    failures = []
    for key, values in sorted(amounts.items()):
        if not all(code in values for code in needed):
            continue
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
                    "G2", key, f"energy_kcal {energy:g} vs macronutrient estimate {calc:.1f}"
                )
            )
    return failures


def gate_weight_method_catalog(meals: Sequence[CatalogMeal]) -> list[GateFailure]:
    """G6: weight_method agrees with the yield factor (§10.1). WEIGHED is allowed."""
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
        elif meal.yield_factor is not None:
            failures.append(
                GateFailure(
                    "G6",
                    subject,
                    f"{meal.weight_method.value} needs yield_factor null",
                )
            )
    return failures


def gate_optional_ingredients_catalog(
    meals: Sequence[CatalogMeal], ingredients: Mapping[str, CatalogIngredient]
) -> list[GateFailure]:
    """G8: water, salt and oil are never optional; one ingredient must stay (#75, §10.2)."""
    failures = []
    for meal in meals:
        for item in meal.ingredients:
            ingredient = ingredients.get(item.code)
            ndb = (
                ingredient.food.code
                if ingredient is not None
                and ingredient.food.source is IngredientFoodSource.SR_LEGACY
                else None
            )
            never = item.code in NEVER_OPTIONAL_CODES or ndb in NEVER_OPTIONAL_NDB
            if item.optional and never:
                name = NEVER_OPTIONAL_NDB.get(ndb or "", item.code)
                failures.append(
                    GateFailure("G8", meal.ref_external, f"{name} ({item.code}) is never optional")
                )
        if all(item.optional for item in meal.ingredients):
            failures.append(GateFailure("G8", meal.ref_external, "every ingredient is optional"))
    return failures


def gate_manual_threshold_tags(
    ingredients: Sequence[CatalogIngredient], meals: Sequence[CatalogMeal]
) -> list[GateFailure]:
    """G10: high_sodium / high_sugar are derived per meal, never authored (#74, §10.5)."""
    failures = []
    for ingredient in ingredients:
        bad = sorted(set(ingredient.ingredient_tags) & THRESHOLD_TAG_CODES)
        if bad:
            failures.append(
                GateFailure("G10", ingredient.code, f"manual threshold tags not allowed: {bad}")
            )
    for meal in meals:
        tags = [*meal.occasion_tags, *meal.dietary_tags]
        bad = sorted(set(tags) & THRESHOLD_TAG_CODES)
        if bad:
            failures.append(
                GateFailure("G10", meal.ref_external, f"manual threshold tags not allowed: {bad}")
            )
    return failures


def gate_yield_factor_kind(meals: Sequence[CatalogMeal]) -> list[GateFailure]:
    """G11: PUBLISHED requires a non-empty yield_factor_source."""
    failures = []
    for meal in meals:
        if meal.yield_factor_kind is YieldFactorKind.PUBLISHED and not meal.yield_factor_source:
            failures.append(
                GateFailure("G11", meal.ref_external, "PUBLISHED requires yield_factor_source")
            )
    return failures


def gate_manual_foods(manuals: Sequence[ManualFood], mandatory: Sequence[str]) -> list[GateFailure]:
    """G12: manual foods carry every mandatory nutrient and a non-empty source_reference."""
    failures = []
    for food in manuals:
        missing = [code for code in mandatory if code not in food.nutrients]
        if missing:
            failures.append(GateFailure("G12", food.code, f"missing mandatory nutrients {missing}"))
        if not food.source_reference.strip():
            failures.append(GateFailure("G12", food.code, "source_reference is empty"))
    return failures


def gate_recipe_steps(files: CatalogFiles) -> list[GateFailure]:
    """G13: steps files name catalog meals, once, with non-blank steps of at most 500 characters."""
    meal_refs = {meal.ref_external for _, meal in files.meals}
    failures: list[GateFailure] = []
    seen: dict[str, str] = {}
    for step_file in files.step_files:
        if step_file.default_lang not in SUPPORTED_STEP_LANGS:
            failures.append(
                GateFailure(
                    "G13",
                    step_file.dataset_version,
                    f"default_lang {step_file.default_lang!r} is not a supported language",
                )
            )
        for meal in step_file.meals:
            subject = meal.ref_external
            if subject not in meal_refs:
                failures.append(GateFailure("G13", subject, f"unknown ref_external {subject!r}"))
            previous = seen.get(subject)
            if previous is not None:
                failures.append(
                    GateFailure(
                        "G13",
                        subject,
                        f"duplicate ref_external {subject!r} (also in {previous})",
                    )
                )
            else:
                seen[subject] = step_file.dataset_version
            for number, step in enumerate(meal.steps_ar, start=1):
                if not step.strip():
                    failures.append(GateFailure("G13", subject, f"step {number} is blank"))
                elif len(step) > MAX_STEP_CHARS:
                    failures.append(
                        GateFailure(
                            "G13",
                            subject,
                            f"step {number} is longer than {MAX_STEP_CHARS} characters",
                        )
                    )
    return failures


def run_catalog_gates(
    files: CatalogFiles, amounts: Mapping[str, Mapping[str, float]]
) -> dict[str, list[GateFailure]]:
    meals = [meal for _, meal in files.meals]
    by_code = {i.code: i for i in files.ingredients.ingredients}
    mandatory = sorted(n.code for n in files.seed.nutrients if n.is_mandatory)
    return {
        "G2": gate_energy_from_amounts(amounts),
        "G6": gate_weight_method_catalog(meals),
        "G7": gate_percent_energy_limits(files.seed.condition_nutrient_limits),
        "G8": gate_optional_ingredients_catalog(meals, by_code),
        "G9": gate_variant_groups(meals),  # type: ignore[arg-type]
        "G10": gate_manual_threshold_tags(files.ingredients.ingredients, meals),
        "G11": gate_yield_factor_kind(meals),
        "G12": gate_manual_foods(files.manuals, mandatory),
        "G13": gate_recipe_steps(files),
    }
