"""Active-meal list, detail, and offline snapshot (#184, #185, #186, #188).

Nutrition is read from meal_nutrients (calc_v1). This module does not recompute it.
Browsing is not filtered by the caller's health conditions or allergies.
"""

from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from dataclasses import dataclass
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import and_, case, func, or_, select, union_all
from sqlalchemy.orm import Session, aliased
from sqlalchemy.sql import Select

from app.core.text import pick_name
from app.db.models import (
    Allergen,
    Cuisine,
    DietaryTag,
    Ingredient,
    Meal,
    MealAllergen,
    MealIngredient,
    MealNutrient,
    MealStep,
    MealTag,
    MealTranslation,
    Nutrient,
    UserMealPref,
)
from app.services.catalog_version import active_dataset_version
from app.services.common import MEASURE_PLACES, MealNotFoundError, round_half_up, to_decimal
from app.services.condition_limits import ENERGY_NUTRIENT
from app.services.meal_filter import SLOT_OCCASION
from app.services.text_search import SIMILARITY_MIN, like_pattern, match_rank, normalize_query

# /reference uses the same sentinel when the catalog version cannot be confirmed.
UNKNOWN_DATASET_VERSION = "unknown"
_PROTEIN = "protein"
_CARB = "carbohydrate"
_FAT = "total_fat"


@dataclass(frozen=True)
class NutrientLine:
    code: str
    unit: str
    per_serving: float
    per_100g: float


@dataclass(frozen=True)
class IngredientLine:
    ingredient_id: int
    name: str
    grams_per_serving: float
    is_optional: bool


@dataclass(frozen=True)
class MealSummaryData:
    meal_id: int
    name: str
    cuisine: str | None
    dish_form: str | None
    serving_grams: float
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    allergens: tuple[str, ...]
    tags: tuple[str, ...]
    my_stance: str | None


@dataclass(frozen=True)
class MealDetailData:
    summary: MealSummaryData
    servings: int
    total_grams: float
    nutrients: tuple[NutrientLine, ...]
    ingredients: tuple[IngredientLine, ...]
    steps: tuple[str, ...]
    source: str
    dataset_version: str


@dataclass(frozen=True)
class _Loaded:
    meal: Meal
    cuisine: str | None
    name: str


def _round(value: Decimal) -> float:
    return float(round_half_up(value, MEASURE_PLACES))


def _scope(lang: str) -> tuple[Select[Any], Any]:
    """Active meals with cuisine code and the name shown for `lang` (#184)."""
    translation = aliased(MealTranslation)
    display_name = case(
        (Meal.default_lang == lang, Meal.name),
        else_=func.coalesce(translation.name, Meal.name),
    )
    sort_name = case(
        (Meal.default_lang == lang, Meal.name_normalized),
        else_=func.coalesce(translation.name_normalized, Meal.name_normalized),
    )
    stmt = (
        select(
            Meal,
            Cuisine.code.label("cuisine_code"),
            display_name.label("display_name"),
            sort_name.label("sort_name"),
        )
        .outerjoin(Cuisine, Cuisine.cuisine_id == Meal.cuisine_id)
        .outerjoin(
            translation,
            and_(translation.meal_id == Meal.meal_id, translation.lang == lang),
        )
        .where(Meal.is_active.is_(True))
    )
    return stmt, sort_name


def _scores(normalized: str) -> Any:
    """Best rank and similarity of the meal name or any translation (#185)."""
    contains = like_pattern(normalized, prefix=False)
    meal_names = select(
        Meal.meal_id.label("meal_id"),
        match_rank(Meal.name_normalized, normalized).label("match_rank"),
        func.similarity(Meal.name_normalized, normalized).label("similarity"),
    ).where(
        Meal.is_active.is_(True),
        or_(
            Meal.name_normalized.like(contains, escape="\\"),
            func.similarity(Meal.name_normalized, normalized) >= SIMILARITY_MIN,
        ),
    )
    translations = (
        select(
            MealTranslation.meal_id.label("meal_id"),
            match_rank(MealTranslation.name_normalized, normalized).label("match_rank"),
            func.similarity(MealTranslation.name_normalized, normalized).label("similarity"),
        )
        .join(Meal, Meal.meal_id == MealTranslation.meal_id)
        .where(
            Meal.is_active.is_(True),
            or_(
                MealTranslation.name_normalized.like(contains, escape="\\"),
                func.similarity(MealTranslation.name_normalized, normalized) >= SIMILARITY_MIN,
            ),
        )
    )
    combined = union_all(meal_names, translations).subquery()
    return (
        select(
            combined.c.meal_id,
            func.max(combined.c.match_rank).label("match_rank"),
            func.max(combined.c.similarity).label("similarity"),
        )
        .group_by(combined.c.meal_id)
        .subquery()
    )


def _filtered(
    lang: str,
    *,
    q: str | None,
    slot: str | None,
    cuisine: str | None,
) -> Select[Any]:
    stmt, sort_name = _scope(lang)
    if q is not None:
        scores = _scores(normalize_query(q))
        stmt = stmt.join(scores, scores.c.meal_id == Meal.meal_id).order_by(
            scores.c.match_rank.desc(),
            scores.c.similarity.desc(),
            Meal.meal_id,
        )
    else:
        stmt = stmt.order_by(sort_name, Meal.meal_id)
    if slot is not None:
        stmt = stmt.where(
            Meal.meal_id.in_(
                select(MealTag.meal_id)
                .join(DietaryTag, DietaryTag.tag_id == MealTag.tag_id)
                .where(DietaryTag.code == SLOT_OCCASION[slot])
            )
        )
    if cuisine is not None:
        # An unknown code matches no row, so the page is empty (#185).
        stmt = stmt.where(Cuisine.code == cuisine)
    return stmt


def _count(session: Session, stmt: Select[Any]) -> int:
    counted = stmt.order_by(None).subquery()
    total = session.scalar(select(func.count()).select_from(counted))
    return int(total or 0)


def _loaded(session: Session, stmt: Select[Any]) -> list[_Loaded]:
    return [
        _Loaded(meal=meal, cuisine=cuisine, name=name)
        for meal, cuisine, name, _sort_name in session.execute(stmt).all()
    ]


def _nutrient_lines(session: Session, meal_ids: list[int]) -> dict[int, list[NutrientLine]]:
    # Nutrients have no display-order column, so the stable order is the code.
    rows = session.execute(
        select(
            MealNutrient.meal_id,
            Nutrient.code,
            Nutrient.unit,
            MealNutrient.amount_per_serving,
            MealNutrient.amount_per_100g,
        )
        .join(Nutrient, Nutrient.nutrient_id == MealNutrient.nutrient_id)
        .where(MealNutrient.meal_id.in_(meal_ids))
        .order_by(MealNutrient.meal_id, Nutrient.code)
    ).all()
    grouped: dict[int, list[NutrientLine]] = defaultdict(list)
    for meal_id, code, unit, per_serving, per_100g in rows:
        grouped[meal_id].append(
            NutrientLine(
                code=code,
                unit=unit,
                per_serving=_round(to_decimal(per_serving)),
                per_100g=_round(to_decimal(per_100g)),
            )
        )
    return grouped


def _codes(session: Session, meal_ids: list[int], *, allergens: bool) -> dict[int, tuple[str, ...]]:
    if allergens:
        rows = session.execute(
            select(MealAllergen.meal_id, Allergen.code)
            .join(Allergen, Allergen.allergen_id == MealAllergen.allergen_id)
            .where(MealAllergen.meal_id.in_(meal_ids))
        ).all()
    else:
        rows = session.execute(
            select(MealTag.meal_id, DietaryTag.code)
            .join(DietaryTag, DietaryTag.tag_id == MealTag.tag_id)
            .where(MealTag.meal_id.in_(meal_ids))
        ).all()
    grouped: dict[int, list[str]] = defaultdict(list)
    for meal_id, code in rows:
        grouped[meal_id].append(code)
    return {meal_id: tuple(sorted(codes)) for meal_id, codes in grouped.items()}


def _stances(session: Session, user_id: int, meal_ids: list[int]) -> dict[int, str]:
    rows = session.execute(
        select(UserMealPref.meal_id, UserMealPref.stance).where(
            UserMealPref.user_id == user_id,
            UserMealPref.meal_id.in_(meal_ids),
        )
    ).all()
    return {meal_id: stance for meal_id, stance in rows}


def _ingredients(
    session: Session, meals: dict[int, Meal], lang: str
) -> dict[int, tuple[IngredientLine, ...]]:
    rows = session.execute(
        select(
            MealIngredient.meal_id,
            MealIngredient.position,
            MealIngredient.ingredient_id,
            MealIngredient.grams,
            MealIngredient.is_optional,
            Ingredient.canonical_name_ar,
            Ingredient.canonical_name,
        )
        .join(Ingredient, Ingredient.ingredient_id == MealIngredient.ingredient_id)
        .where(MealIngredient.meal_id.in_(list(meals)))
        .order_by(MealIngredient.meal_id, MealIngredient.position)
    ).all()
    grouped: dict[int, list[IngredientLine]] = defaultdict(list)
    for meal_id, _position, ingredient_id, grams, optional, name_ar, name_en in rows:
        servings = Decimal(meals[meal_id].servings)
        grouped[meal_id].append(
            IngredientLine(
                ingredient_id=ingredient_id,
                name=pick_name(lang, name_ar, name_en),
                grams_per_serving=_round(to_decimal(grams) / servings),
                is_optional=optional,
            )
        )
    return {meal_id: tuple(lines) for meal_id, lines in grouped.items()}


def _steps(session: Session, meal_ids: list[int], lang: str) -> dict[int, tuple[str, ...]]:
    languages = (lang,) if lang == "ar" else (lang, "ar")
    rows = session.execute(
        select(MealStep.meal_id, MealStep.lang, MealStep.position, MealStep.text)
        .where(MealStep.meal_id.in_(meal_ids), MealStep.lang.in_(languages))
        .order_by(MealStep.meal_id, MealStep.position)
    ).all()
    by_lang: dict[tuple[int, str], list[str]] = defaultdict(list)
    for meal_id, step_lang, _position, text in rows:
        by_lang[(meal_id, step_lang)].append(text)
    chosen: dict[int, tuple[str, ...]] = {}
    for meal_id in meal_ids:
        texts = by_lang.get((meal_id, lang)) or by_lang.get((meal_id, "ar")) or []
        chosen[meal_id] = tuple(texts)
    return chosen


def _macro(lines: list[NutrientLine], code: str) -> float:
    for line in lines:
        if line.code == code:
            return line.per_serving
    return 0.0


def _summary(
    loaded: _Loaded,
    lines: list[NutrientLine],
    allergens: tuple[str, ...],
    tags: tuple[str, ...],
    stance: str | None,
) -> MealSummaryData:
    meal = loaded.meal
    return MealSummaryData(
        meal_id=meal.meal_id,
        name=loaded.name,
        cuisine=loaded.cuisine,
        dish_form=meal.dish_form,
        serving_grams=_round(to_decimal(meal.total_grams) / Decimal(meal.servings)),
        kcal=_macro(lines, ENERGY_NUTRIENT),
        protein_g=_macro(lines, _PROTEIN),
        carb_g=_macro(lines, _CARB),
        fat_g=_macro(lines, _FAT),
        allergens=allergens,
        tags=tags,
        my_stance=stance,
    )


def _summaries(
    session: Session, loaded: list[_Loaded], user_id: int | None
) -> list[MealSummaryData]:
    if not loaded:
        return []
    meals = [row.meal for row in loaded]
    meal_ids = [meal.meal_id for meal in meals]
    nutrients = _nutrient_lines(session, meal_ids)
    allergens = _codes(session, meal_ids, allergens=True)
    tags = _codes(session, meal_ids, allergens=False)
    stances = _stances(session, user_id, meal_ids) if user_id is not None else {}
    return [
        _summary(
            row,
            nutrients.get(row.meal.meal_id, []),
            allergens.get(row.meal.meal_id, ()),
            tags.get(row.meal.meal_id, ()),
            stances.get(row.meal.meal_id),
        )
        for row in loaded
    ]


def _details(
    session: Session, loaded: list[_Loaded], lang: str, user_id: int | None
) -> list[MealDetailData]:
    if not loaded:
        return []
    by_id = {row.meal.meal_id: row.meal for row in loaded}
    meal_ids = list(by_id)
    nutrients = _nutrient_lines(session, meal_ids)
    allergens = _codes(session, meal_ids, allergens=True)
    tags = _codes(session, meal_ids, allergens=False)
    stances = _stances(session, user_id, meal_ids) if user_id is not None else {}
    ingredients = _ingredients(session, by_id, lang)
    steps = _steps(session, meal_ids, lang)
    details: list[MealDetailData] = []
    for row in loaded:
        meal_id = row.meal.meal_id
        lines = nutrients.get(meal_id, [])
        details.append(
            MealDetailData(
                summary=_summary(
                    row,
                    lines,
                    allergens.get(meal_id, ()),
                    tags.get(meal_id, ()),
                    stances.get(meal_id),
                ),
                servings=row.meal.servings,
                total_grams=_round(to_decimal(row.meal.total_grams)),
                nutrients=tuple(lines),
                ingredients=ingredients.get(meal_id, ()),
                steps=steps.get(meal_id, ()),
                source=row.meal.source,
                dataset_version=row.meal.dataset_version,
            )
        )
    return details


def list_meals(
    session: Session,
    user_id: int,
    *,
    q: str | None,
    slot: str | None,
    cuisine: str | None,
    lang: str,
    limit: int,
    offset: int,
) -> tuple[tuple[MealSummaryData, ...], int]:
    """One page of active meals and the total before paging."""
    stmt = _filtered(lang, q=q, slot=slot, cuisine=cuisine)
    total = _count(session, stmt)
    page = _loaded(session, stmt.limit(limit).offset(offset))
    return tuple(_summaries(session, page, user_id)), total


def get_meal(session: Session, user_id: int, meal_id: int, lang: str) -> MealDetailData:
    """One active meal. Inactive and unknown ids are the same 404."""
    stmt = _filtered(lang, q=None, slot=None, cuisine=None).where(Meal.meal_id == meal_id)
    loaded = _loaded(session, stmt)
    if not loaded:
        raise MealNotFoundError(f"meal {meal_id} is not an active meal")
    return _details(session, loaded, lang, user_id)[0]


def _meal_body(detail: MealDetailData) -> dict[str, object]:
    summary = detail.summary
    return {
        "meal_id": summary.meal_id,
        "name": summary.name,
        "cuisine": summary.cuisine,
        "dish_form": summary.dish_form,
        "serving_grams": summary.serving_grams,
        "kcal": summary.kcal,
        "protein_g": summary.protein_g,
        "carb_g": summary.carb_g,
        "fat_g": summary.fat_g,
        "allergens": list(summary.allergens),
        "tags": list(summary.tags),
        "servings": detail.servings,
        "total_grams": detail.total_grams,
        "nutrients": [
            {
                "code": line.code,
                "unit": line.unit,
                "per_serving": line.per_serving,
                "per_100g": line.per_100g,
            }
            for line in detail.nutrients
        ],
        "ingredients": [
            {
                "ingredient_id": line.ingredient_id,
                "name": line.name,
                "grams_per_serving": line.grams_per_serving,
                "is_optional": line.is_optional,
            }
            for line in detail.ingredients
        ],
        "steps": list(detail.steps),
        "source": detail.source,
        "dataset_version": detail.dataset_version,
    }


def catalog_snapshot(session: Session, lang: str) -> tuple[dict[str, object], str]:
    """Every active meal, and a strong ETag of that content plus the language (#186).

    generated_at is not part of the tag, so the tag changes only when the meals or the
    language change.
    """
    stmt = _filtered(lang, q=None, slot=None, cuisine=None).order_by(None).order_by(Meal.meal_id)
    details = _details(session, _loaded(session, stmt), lang, None)
    version = active_dataset_version(session) or UNKNOWN_DATASET_VERSION
    meals = [_meal_body(detail) for detail in details]
    canonical = json.dumps(
        {"dataset_version": version, "meals": meals},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    digest = hashlib.sha256(f"{canonical}\n{lang}".encode()).hexdigest()
    return {
        "dataset_version": version,
        "generated_at": datetime.now(UTC),
        "meals": meals,
    }, f'"{digest}"'
