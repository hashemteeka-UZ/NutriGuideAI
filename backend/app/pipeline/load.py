"""Idempotent single-transaction load of accepted catalog records."""

from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text
from app.db.base import Base
from app.db.models import (
    Allergen,
    Category,
    ConditionNutrientLimit,
    ConditionTagRestriction,
    Cuisine,
    DietaryTag,
    Food,
    FoodNutrient,
    HealthCondition,
    Ingredient,
    IngredientAlias,
    IngredientAllergen,
    IngredientTag,
    Meal,
    MealIngredient,
    MealTag,
    MealTranslation,
    Nutrient,
)
from app.db.models.catalog import MealTagSource, QualityTier, WeightMethod
from app.db.models.reference import FoodExternalSource
from app.pipeline.classify import Classification, FilledFood, Outcome
from app.pipeline.files import (
    FDC_CATEGORY_EN,
    CatalogFiles,
    CatalogMeal,
    CrossCheckStatus,
    IngredientFoodSource,
    YieldFactorKind,
)
from app.seed.f1_loader import NUMERIC_SCALE, _rounded, total_grams
from app.services.recompute_meals import MealRecompute, recompute_meal

TABLES = (
    "categories",
    "cuisines",
    "allergens",
    "dietary_tags",
    "health_conditions",
    "nutrients",
    "condition_nutrient_limits",
    "condition_tag_restrictions",
    "foods",
    "food_nutrients",
    "ingredients",
    "ingredient_aliases",
    "ingredient_allergens",
    "ingredient_tags",
    "meals",
    "meal_translations",
    "meal_ingredients",
    "meal_tags",
)
RECOMPUTE_TABLES = ("meal_nutrients", "meal_allergens", "meal_tags (DERIVED)")


@dataclass
class TableCounts:
    inserted: int = 0
    updated: int = 0
    unchanged: int = 0
    deactivated: int = 0


@dataclass
class CatalogLoadReport:
    tables: dict[str, TableCounts] = field(
        default_factory=lambda: {name: TableCounts() for name in TABLES}
    )
    deactivated_meals: list[str] = field(default_factory=list)
    reactivated_meals: list[str] = field(default_factory=list)
    recomputed: list[MealRecompute] = field(default_factory=list)

    @property
    def all_unchanged(self) -> bool:
        return not any(
            c.inserted or c.updated or c.deactivated for c in self.tables.values()
        ) and not any(r.changed for r in self.recomputed)


def quality_tier(meal: CatalogMeal) -> QualityTier:
    """#96: GOLD when reviewed and (WEIGHED | SUM | published yield) and cross-check not failed."""
    reviewed = meal.reviewed_by is not None
    method_ok = meal.weight_method in {
        WeightMethod.WEIGHED,
        WeightMethod.SUM_OF_INGREDIENTS,
    } or (
        meal.weight_method is WeightMethod.YIELD_FACTOR
        and meal.yield_factor_kind is YieldFactorKind.PUBLISHED
    )
    failed = (
        meal.cross_check is not None and meal.cross_check.status is CrossCheckStatus.FAIL_REVIEWED
    )
    cross_ok = not failed
    if reviewed and method_ok and cross_ok:
        return QualityTier.GOLD
    return QualityTier.SILVER


def _same(current: Any, desired: Any) -> bool:
    if isinstance(current, float) or isinstance(desired, float):
        if current is None or desired is None:
            return current is desired
        return round(float(current), NUMERIC_SCALE) == round(float(desired), NUMERIC_SCALE)
    return bool(current == desired)


class _LoadConflictError(Exception):
    pass


class _Loader:
    def __init__(
        self,
        session: Session,
        files: CatalogFiles,
        classified: Classification,
        report: CatalogLoadReport,
        now: datetime,
    ) -> None:
        self.session = session
        self.files = files
        self.classified = classified
        self.report = report
        self.now = now
        self.alias_source = files.ingredients.dataset_version

    def _upsert(
        self,
        table: str,
        model: type[Base],
        pk: str,
        key: Mapping[str, Any],
        values: Mapping[str, Any],
        insert_only: Mapping[str, Any] | None = None,
    ) -> int:
        rows = self.session.execute(select(model).filter_by(**key)).scalars().all()
        if len(rows) > 1:
            raise _LoadConflictError(f"{table}: {len(rows)} existing rows match {dict(key)}")
        counts = self.report.tables[table]
        if not rows:
            row = model(**key, **values, **(insert_only or {}))
            self.session.add(row)
            self.session.flush()
            counts.inserted += 1
            return int(getattr(row, pk))
        row = rows[0]
        changed = {k: v for k, v in values.items() if not _same(getattr(row, k), v)}
        if changed:
            for name, value in changed.items():
                setattr(row, name, value)
            self.session.flush()
            counts.updated += 1
        else:
            counts.unchanged += 1
        return int(getattr(row, pk))

    def _sync(
        self,
        table: str,
        model: type[Base],
        parent: Mapping[str, Any],
        key_columns: tuple[str, ...],
        desired: Mapping[tuple[Any, ...], Mapping[str, Any]],
        may_delete: Callable[[Any], bool] = lambda _row: True,
    ) -> None:
        counts = self.report.tables[table]
        existing = {
            tuple(getattr(row, col) for col in key_columns): row
            for row in self.session.execute(select(model).filter_by(**parent)).scalars()
        }
        for key, values in desired.items():
            row = existing.pop(key, None)
            if row is None:
                self.session.add(
                    model(**parent, **dict(zip(key_columns, key, strict=True)), **values)
                )
                counts.inserted += 1
                continue
            changed = {k: v for k, v in values.items() if not _same(getattr(row, k), v)}
            for name, value in changed.items():
                setattr(row, name, value)
            if changed:
                counts.updated += 1
            else:
                counts.unchanged += 1
        for row in existing.values():
            if may_delete(row):
                self.session.delete(row)
                counts.deactivated += 1
        self.session.flush()

    def run(self) -> None:
        seed = self.files.seed
        accepted_foods = {
            key: food
            for key, food in self.classified.filled.items()
            if (
                self.classified.foods.get(key)
                and self.classified.foods[key].outcome is Outcome.ACCEPTED
            )
        }
        category_ids = self._load_categories(accepted_foods)
        cuisine_ids = {
            c.code: self._upsert(
                "cuisines",
                Cuisine,
                "cuisine_id",
                {"code": c.code},
                {"name_en": c.name_en, "name_ar": c.name_ar},
            )
            for c in seed.cuisines
        }
        allergen_ids = {
            a.code: self._upsert(
                "allergens",
                Allergen,
                "allergen_id",
                {"code": a.code},
                {"name_en": a.name_en, "name_ar": a.name_ar},
            )
            for a in seed.allergens
        }
        tag_ids = {
            t.code: self._upsert(
                "dietary_tags",
                DietaryTag,
                "tag_id",
                {"code": t.code},
                {"name_en": t.name_en, "name_ar": t.name_ar, "tag_group": t.tag_group.value},
            )
            for t in seed.dietary_tags
        }
        condition_ids = {
            c.code: self._upsert(
                "health_conditions",
                HealthCondition,
                "condition_id",
                {"code": c.code},
                {
                    "name_en": c.name_en,
                    "name_ar": c.name_ar,
                    "is_supported": c.is_supported,
                    "fluid_goal_requires_clinician": c.fluid_goal_requires_clinician,
                },
            )
            for c in seed.health_conditions
        }
        nutrient_ids = {
            n.code: self._upsert(
                "nutrients",
                Nutrient,
                "nutrient_id",
                {"code": n.code},
                {
                    "source_code": n.source_code,
                    "name": n.name,
                    "unit": n.unit.value,
                    "is_mandatory": n.is_mandatory,
                },
            )
            for n in seed.nutrients
        }
        for limit in seed.condition_nutrient_limits:
            self._upsert(
                "condition_nutrient_limits",
                ConditionNutrientLimit,
                "id",
                {
                    "condition_id": condition_ids[limit.condition],
                    "nutrient_id": nutrient_ids[limit.nutrient],
                    "limit_basis": limit.limit_basis.value,
                },
                {
                    "max_per_meal": limit.max_per_meal,
                    "max_per_day": limit.max_per_day,
                    "min_per_day": limit.min_per_day,
                    "severity_note": limit.severity_note,
                    "source_reference": limit.source_reference,
                },
            )
        for restriction in seed.condition_tag_restrictions:
            self._upsert(
                "condition_tag_restrictions",
                ConditionTagRestriction,
                "id",
                {
                    "condition_id": condition_ids[restriction.condition],
                    "tag_id": tag_ids[restriction.tag],
                },
                {
                    "restriction_type": restriction.restriction_type.value,
                    "max_servings_per_week": restriction.max_servings_per_week,
                    "source_reference": restriction.source_reference,
                },
            )
        food_ids, ingredient_ids = self._load_foods_and_ingredients(
            accepted_foods, category_ids, nutrient_ids, allergen_ids, tag_ids
        )
        meal_ids = self._load_meals(cuisine_ids, tag_ids, food_ids, ingredient_ids)
        self._deactivate_missing_meals({ref for ref in meal_ids.values()})
        self._recompute(meal_ids)

    def _load_categories(self, foods: Mapping[str, FilledFood]) -> dict[str, int]:
        wanted: dict[str, tuple[str, str]] = {}
        for food in foods.values():
            name_en = food.category_name_en or FDC_CATEGORY_EN.get(food.category_code, "")
            name_ar = self.files.seed.categories_ar[food.category_code]
            wanted[food.category_code] = (name_en, name_ar)
        return {
            code: self._upsert(
                "categories",
                Category,
                "category_id",
                {"name_en": name_en},
                {"name_ar": name_ar},
            )
            for code, (name_en, name_ar) in sorted(wanted.items())
        }

    def _load_foods_and_ingredients(
        self,
        foods: Mapping[str, FilledFood],
        category_ids: Mapping[str, int],
        nutrient_ids: Mapping[str, int],
        allergen_ids: Mapping[str, int],
        tag_ids: Mapping[str, int],
    ) -> tuple[dict[str, int], dict[str, int]]:
        food_ids: dict[str, int] = {}
        ingredient_ids: dict[str, int] = {}
        alias_names: dict[int, dict[str, list[str]]] = {}
        ingredients = {
            i.code: i
            for i in self.files.ingredients.ingredients
            if self.classified.ingredients[i.code].outcome is Outcome.ACCEPTED
        }
        for ingredient in ingredients.values():
            food = foods[ingredient.food.code]
            external_source = (
                FoodExternalSource.FDC.value
                if food.source is IngredientFoodSource.SR_LEGACY
                else FoodExternalSource.MANUAL.value
            )
            food_id = self._upsert(
                "foods",
                Food,
                "food_id",
                {"external_source": external_source, "external_code": food.key},
                {
                    "fdc_id": food.fdc_id,
                    "description": food.description,
                    "data_type": (
                        "sr_legacy_food" if food.source is IngredientFoodSource.SR_LEGACY else None
                    ),
                    "category_id": category_ids[food.category_code],
                    "basis_grams": 100.0,
                    "state": food.state,
                    "source_reference": food.source_reference,
                },
            )
            food_ids[food.key] = food_id
            self._sync(
                "food_nutrients",
                FoodNutrient,
                {"food_id": food_id},
                ("nutrient_id",),
                {
                    (nutrient_ids[code],): {"amount_per_100g": amount}
                    for code, amount in food.amounts.items()
                    if code in nutrient_ids
                },
            )
            ingredient_id = self._upsert(
                "ingredients",
                Ingredient,
                "ingredient_id",
                {"code": ingredient.code},
                {
                    "canonical_name": ingredient.name_en,
                    "canonical_name_ar": ingredient.name_ar,
                    "default_food_id": food_id,
                    "review_status": ingredient.review_status.value,
                },
            )
            ingredient_ids[ingredient.code] = ingredient_id
            names: dict[str, list[str]] = {
                "en": [ingredient.name_en, *ingredient.aliases_en],
                "ar": [ingredient.name_ar, *ingredient.aliases_ar],
            }
            alias_names[ingredient_id] = names
            self._sync(
                "ingredient_allergens",
                IngredientAllergen,
                {"ingredient_id": ingredient_id},
                ("allergen_id",),
                {(allergen_ids[code],): {} for code in ingredient.allergens},
            )
            self._sync(
                "ingredient_tags",
                IngredientTag,
                {"ingredient_id": ingredient_id},
                ("tag_id",),
                {(tag_ids[code],): {} for code in ingredient.ingredient_tags},
            )
        self._load_aliases(alias_names)
        return food_ids, ingredient_ids

    def _load_aliases(self, names_by_ingredient: Mapping[int, Mapping[str, list[str]]]) -> None:
        counts = self.report.tables["ingredient_aliases"]
        wanted = {
            ingredient_id: {(text, lang) for lang, texts in names.items() for text in texts}
            for ingredient_id, names in names_by_ingredient.items()
        }
        for row in self.session.execute(
            select(IngredientAlias).where(IngredientAlias.ingredient_id.in_(list(wanted)))
        ).scalars():
            stale = (row.alias_text, row.lang) not in wanted[row.ingredient_id]
            if row.source == self.alias_source and stale:
                self.session.delete(row)
                counts.deactivated += 1
        self.session.flush()
        for ingredient_id, names in names_by_ingredient.items():
            desired: dict[tuple[str, str], dict[str, Any]] = {}
            for lang, texts in names.items():
                for text in texts:
                    desired[(text, lang)] = {
                        "alias_normalized": normalize_search_text(text),
                        "confidence": 1.0,
                        "source": self.alias_source,
                    }
            self._sync(
                "ingredient_aliases",
                IngredientAlias,
                {"ingredient_id": ingredient_id},
                ("alias_text", "lang"),
                desired,
                may_delete=lambda _row: False,
            )

    def _load_meals(
        self,
        cuisine_ids: Mapping[str, int],
        tag_ids: Mapping[str, int],
        food_ids: Mapping[str, int],
        ingredient_ids: Mapping[str, int],
    ) -> dict[int, str]:
        accepted = [
            (batch, meal)
            for batch, meal in self.files.meals
            if self.classified.meals[meal.ref_external].outcome is Outcome.ACCEPTED
        ]
        meal_ids: dict[int, str] = {}
        inactive = {
            (row.source, row.ref_external)
            for row in self.session.execute(
                select(Meal.source, Meal.ref_external).where(~Meal.is_active)
            )
        }
        for batch, meal in accepted:
            meal_id = self._upsert(
                "meals",
                Meal,
                "meal_id",
                {"source": batch.source, "ref_external": meal.ref_external},
                {
                    "name": meal.name_ar,
                    "default_lang": batch.default_lang,
                    "name_normalized": normalize_search_text(meal.name_ar),
                    "servings": meal.servings,
                    "weight_method": meal.weight_method.value,
                    "total_grams": total_grams(
                        [item.grams for item in meal.ingredients],
                        meal.weight_method,
                        meal.yield_factor,
                    ),
                    "yield_factor": _rounded(meal.yield_factor),
                    "yield_factor_source": meal.yield_factor_source,
                    "cuisine_id": cuisine_ids[meal.cuisine],
                    "variant_group": meal.variant_group,
                    "source_license": batch.source_license,
                    "quality_tier": quality_tier(meal).value,
                    "reviewed_by": meal.reviewed_by,
                    "is_verified": meal.reviewed_by is not None,
                    "is_active": True,
                    "dataset_version": batch.dataset_version,
                },
            )
            meal_ids[meal_id] = meal.ref_external
            if (batch.source, meal.ref_external) in inactive:
                self.report.reactivated_meals.append(meal.ref_external)
            self._sync(
                "meal_translations",
                MealTranslation,
                {"meal_id": meal_id},
                ("lang",),
                {
                    ("en",): {
                        "name": meal.name_en,
                        "name_normalized": normalize_search_text(meal.name_en),
                    }
                },
                may_delete=lambda _row: False,
            )
            ingredients_by_code = {i.code: i for i in self.files.ingredients.ingredients}
            self._sync(
                "meal_ingredients",
                MealIngredient,
                {"meal_id": meal_id},
                ("position",),
                {
                    (position,): {
                        "ingredient_id": ingredient_ids[item.code],
                        "food_id": food_ids[ingredients_by_code[item.code].food.code],
                        "grams": round(item.grams, NUMERIC_SCALE),
                        "text_original": item.label_ar,
                        "mapping_confidence": 1.0,
                        "is_optional": item.optional,
                    }
                    for position, item in enumerate(meal.ingredients, start=1)
                },
            )
            self._load_manual_meal_tags(meal_id, [*meal.occasion_tags, *meal.dietary_tags], tag_ids)
        return meal_ids

    def _load_manual_meal_tags(
        self, meal_id: int, codes: list[str], tag_ids: Mapping[str, int]
    ) -> None:
        derived = set(
            self.session.execute(
                select(MealTag.tag_id).where(
                    MealTag.meal_id == meal_id, MealTag.source == MealTagSource.DERIVED.value
                )
            ).scalars()
        )
        wanted = {tag_ids[code] for code in codes}
        self._sync(
            "meal_tags",
            MealTag,
            {"meal_id": meal_id, "source": MealTagSource.MANUAL.value},
            ("tag_id",),
            {(tag_id,): {} for tag_id in sorted(wanted - derived)},
        )

    def _deactivate_missing_meals(self, accepted_refs: set[str]) -> None:
        versions = {batch.dataset_version for batch in self.files.meal_files}
        if not versions:
            return
        stale = self.session.execute(
            select(Meal)
            .where(
                Meal.dataset_version.in_(versions),
                Meal.is_active,
                Meal.ref_external.is_not(None),
                Meal.ref_external.not_in(accepted_refs),
            )
            .order_by(Meal.ref_external)
        ).scalars()
        for meal in stale:
            meal.is_active = False
            self.report.tables["meals"].deactivated += 1
            self.report.deactivated_meals.append(str(meal.ref_external))
        self.session.flush()

    def _recompute(self, meal_ids: Mapping[int, str]) -> None:
        for meal_id, ref_external in meal_ids.items():
            nutrition, derived = recompute_meal(self.session, meal_id, self.now)
            self.report.recomputed.append(MealRecompute(meal_id, ref_external, nutrition, derived))


def load_catalog(
    session: Session,
    files: CatalogFiles,
    classified: Classification,
    now: datetime | None = None,
) -> CatalogLoadReport:
    report = CatalogLoadReport()
    _Loader(session, files, classified, report, now or datetime.now(UTC)).run()
    return report
