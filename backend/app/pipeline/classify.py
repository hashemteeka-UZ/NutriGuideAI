"""Nutrient source order (#93) and accepted / quarantine / excluded classification."""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from enum import StrEnum

from app.pipeline.files import (
    FNDDS_INGREDIENT_SOURCE,
    SR_RELEASE,
    CatalogFiles,
    CatalogIngredient,
    CatalogMeal,
    CatalogMealFile,
    FnddsIngredientRow,
    IngredientFoodSource,
)
from app.seed.f1_files import NutrientSeed, SubsetRow
from app.seed.quality_gates import GateFailure, _keyword_pattern


class Outcome(StrEnum):
    ACCEPTED = "accepted"
    QUARANTINE = "quarantine"
    EXCLUDED = "excluded"


@dataclass(frozen=True)
class NutrientFill:
    ndb: str
    nutrient_code: str
    value: float
    source: str


@dataclass(frozen=True)
class FilledFood:
    key: str
    source: IngredientFoodSource
    ndb_number: str | None
    fdc_id: int | None
    description: str
    category_code: str
    category_name_en: str
    state: str
    amounts: dict[str, float]
    fills: tuple[NutrientFill, ...]
    source_reference: str
    ingredient_code: str | None = None


@dataclass(frozen=True)
class ClassifiedRecord:
    record_type: str
    key: str
    outcome: Outcome
    reason: str
    detail: str


@dataclass
class Classification:
    foods: dict[str, ClassifiedRecord] = field(default_factory=dict)
    ingredients: dict[str, ClassifiedRecord] = field(default_factory=dict)
    meals: dict[str, ClassifiedRecord] = field(default_factory=dict)
    filled: dict[str, FilledFood] = field(default_factory=dict)

    def all_records(self) -> list[ClassifiedRecord]:
        records = [
            *self.foods.values(),
            *self.ingredients.values(),
            *self.meals.values(),
        ]
        return sorted(records, key=lambda r: (r.record_type, r.key, r.outcome, r.reason, r.detail))


def _amounts_from_sr(
    nutrients: Sequence[NutrientSeed], subset: Sequence[SubsetRow]
) -> dict[str, dict[str, float]]:
    code_by_nbr = {n.source_code: n.code for n in nutrients if n.source_code}
    amounts: dict[str, dict[str, float]] = defaultdict(dict)
    for row in subset:
        code = code_by_nbr.get(row.nutrient_nbr)
        if code is not None:
            amounts[row.ndb_number][code] = row.amount_per_100g
    return amounts


def _amounts_from_fndds(
    nutrients: Sequence[NutrientSeed], subset: Sequence[FnddsIngredientRow]
) -> dict[str, dict[str, float]]:
    code_by_nbr = {n.source_code: n.code for n in nutrients if n.source_code}
    amounts: dict[str, dict[str, float]] = defaultdict(dict)
    for row in subset:
        code = code_by_nbr.get(row.nutrient_nbr)
        if code is not None:
            amounts[row.ndb_number][code] = row.amount_per_100g
    return amounts


def fill_foods(files: CatalogFiles) -> dict[str, FilledFood]:
    """SR values, then FNDDS ingredient fill for missing mandatory nutrients (#93)."""
    sr_amounts = _amounts_from_sr(files.seed.nutrients, files.sr_subset)
    fndds_amounts = _amounts_from_fndds(files.seed.nutrients, files.fndds_subset)
    mandatory = [n.code for n in files.seed.nutrients if n.is_mandatory]
    sr_meta: dict[str, SubsetRow] = {}
    for row in files.sr_subset:
        sr_meta.setdefault(row.ndb_number, row)
    manuals = {food.code: food for food in files.manuals}
    filled: dict[str, FilledFood] = {}

    for ingredient in files.ingredients.ingredients:
        if ingredient.food.source is IngredientFoodSource.MANUAL:
            food = manuals[ingredient.food.code]
            filled[ingredient.food.code] = FilledFood(
                key=food.code,
                source=IngredientFoodSource.MANUAL,
                ndb_number=None,
                fdc_id=None,
                description=food.description,
                category_code=food.category,
                category_name_en="",
                state=food.state.value,
                amounts=dict(food.nutrients),
                fills=(),
                source_reference=food.source_reference,
                ingredient_code=ingredient.code,
            )
            continue
        ndb = ingredient.food.code
        meta = sr_meta[ndb]
        amounts = dict(sr_amounts.get(ndb, {}))
        fills: list[NutrientFill] = []
        for code in mandatory:
            if code in amounts:
                continue
            if code in fndds_amounts.get(ndb, {}):
                value = fndds_amounts[ndb][code]
                amounts[code] = value
                fills.append(
                    NutrientFill(
                        ndb=ndb,
                        nutrient_code=code,
                        value=value,
                        source=FNDDS_INGREDIENT_SOURCE,
                    )
                )
        fill_names = sorted({f.nutrient_code for f in fills})
        reference = f"{SR_RELEASE}, NDB {ndb}"
        if fill_names:
            reference += f"; {', '.join(fill_names)} from {FNDDS_INGREDIENT_SOURCE}"
        filled[ndb] = FilledFood(
            key=ndb,
            source=IngredientFoodSource.SR_LEGACY,
            ndb_number=ndb,
            fdc_id=meta.fdc_id,
            description=meta.description,
            category_code=meta.food_category_code,
            category_name_en=meta.food_category_description,
            state=ingredient.state.value,
            amounts=amounts,
            fills=tuple(fills),
            source_reference=reference,
            ingredient_code=ingredient.code,
        )
    return filled


def _texts_for_ingredient(ingredient: CatalogIngredient, food: FilledFood | None) -> list[str]:
    texts = [ingredient.name_en, ingredient.name_ar, *ingredient.aliases_en, *ingredient.aliases_ar]
    if food is not None:
        texts.append(food.description)
    return texts


def _keyword_hit(keywords: Sequence[str], texts: Sequence[str]) -> str | None:
    for keyword in keywords:
        pattern = _keyword_pattern(keyword)
        for text in texts:
            if pattern.search(text):
                return keyword
    return None


def _record(
    record_type: str, key: str, outcome: Outcome, reason: str, detail: str
) -> ClassifiedRecord:
    return ClassifiedRecord(record_type, key, outcome, reason, detail)


def classify(
    files: CatalogFiles,
    filled: Mapping[str, FilledFood],
    gates: Mapping[str, Sequence[GateFailure]],
) -> Classification:
    mandatory = [n.code for n in files.seed.nutrients if n.is_mandatory]
    g2 = {f.subject for f in gates.get("G2", [])}
    g6 = {f.subject for f in gates.get("G6", [])}
    g8 = {f.subject for f in gates.get("G8", [])}
    g10 = {f.subject for f in gates.get("G10", [])}
    g11 = {f.subject for f in gates.get("G11", [])}
    result = Classification(filled=dict(filled))
    ingredients_by_code = {i.code: i for i in files.ingredients.ingredients}

    for ingredient in files.ingredients.ingredients:
        food_key = ingredient.food.code
        food = filled.get(food_key)
        texts = _texts_for_ingredient(ingredient, food)
        excluded_kw = _keyword_hit(files.seed.excluded_keywords, texts)
        uncertain_kw = _keyword_hit(files.seed.uncertain_keywords, texts)
        if food is not None:
            food_outcome, food_reason, food_detail = _classify_food(
                food, mandatory, g2, excluded_kw, uncertain_kw
            )
            result.foods[food.key] = _record(
                "food", food.key, food_outcome, food_reason, food_detail
            )
        else:
            food_outcome, food_reason, food_detail = (
                Outcome.QUARANTINE,
                "missing_mandatory_nutrient",
                "food not filled",
            )

        if excluded_kw:
            ing = _record(
                "ingredient",
                ingredient.code,
                Outcome.EXCLUDED,
                "non_permissible_ingredient",
                f"excluded keyword {excluded_kw!r}",
            )
        elif food_outcome is Outcome.EXCLUDED:
            ing = _record(
                "ingredient",
                ingredient.code,
                Outcome.EXCLUDED,
                "non_permissible_ingredient",
                food_detail,
            )
        elif uncertain_kw:
            ing = _record(
                "ingredient",
                ingredient.code,
                Outcome.QUARANTINE,
                "ingredient_status_uncertain",
                f"uncertain keyword {uncertain_kw!r}",
            )
        elif food_outcome is Outcome.QUARANTINE:
            ing = _record(
                "ingredient", ingredient.code, Outcome.QUARANTINE, food_reason, food_detail
            )
        elif ingredient.code in g10:
            ing = _record("ingredient", ingredient.code, Outcome.QUARANTINE, "G10", "threshold tag")
        else:
            ing = _record("ingredient", ingredient.code, Outcome.ACCEPTED, "", "")
        result.ingredients[ingredient.code] = ing

    for batch, meal in files.meals:
        result.meals[meal.ref_external] = _classify_meal(
            batch, meal, ingredients_by_code, result.ingredients, g6, g8, g10, g11
        )
    return result


def _classify_food(
    food: FilledFood,
    mandatory: Sequence[str],
    g2: set[str],
    excluded_kw: str | None,
    uncertain_kw: str | None,
) -> tuple[Outcome, str, str]:
    if excluded_kw:
        return Outcome.EXCLUDED, "non_permissible_ingredient", f"excluded keyword {excluded_kw!r}"
    if uncertain_kw:
        return (
            Outcome.QUARANTINE,
            "ingredient_status_uncertain",
            f"uncertain keyword {uncertain_kw!r}",
        )
    missing = [code for code in mandatory if code not in food.amounts]
    if missing:
        return Outcome.QUARANTINE, "missing_mandatory_nutrient", f"missing {missing}"
    if food.key in g2:
        return Outcome.QUARANTINE, "energy_inconsistent", "G2"
    return Outcome.ACCEPTED, "", ""


def _classify_meal(
    batch: CatalogMealFile,
    meal: CatalogMeal,
    ingredients: Mapping[str, CatalogIngredient],
    classified: Mapping[str, ClassifiedRecord],
    g6: set[str],
    g8: set[str],
    g10: set[str],
    g11: set[str],
) -> ClassifiedRecord:
    _ = batch
    _ = ingredients
    used = [classified[item.code] for item in meal.ingredients if item.code in classified]
    excluded = [r.key for r in used if r.outcome is Outcome.EXCLUDED]
    if excluded:
        return _record(
            "meal",
            meal.ref_external,
            Outcome.EXCLUDED,
            "uses_excluded_ingredient",
            f"ingredients {excluded}",
        )
    quarantined = [r.key for r in used if r.outcome is Outcome.QUARANTINE]
    if quarantined:
        return _record(
            "meal",
            meal.ref_external,
            Outcome.QUARANTINE,
            "uses_quarantined_ingredient",
            f"ingredients {quarantined}",
        )
    if meal.reviewed_by is None:
        return _record("meal", meal.ref_external, Outcome.QUARANTINE, "not_reviewed", "")
    for gate, subjects in (("G6", g6), ("G8", g8), ("G10", g10), ("G11", g11)):
        if meal.ref_external in subjects:
            return _record("meal", meal.ref_external, Outcome.QUARANTINE, gate, "")
    return _record("meal", meal.ref_external, Outcome.ACCEPTED, "", "")
