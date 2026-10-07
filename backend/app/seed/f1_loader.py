"""Step F.1: load the slice data (reference seed, FDC foods, meals) and recompute the meals.

    uv run python -m app.seed.f1_loader [--data-dir PATH]

Loads into DATABASE_URL in one transaction. Every input file is validated and every quality
gate runs before anything is written; any failure writes nothing and reports all failures.
Idempotent: rows are matched on natural keys and only rewritten when a value differs.
Meals of the file's source that the file no longer lists are deactivated, never deleted (#79).
The same transaction ends with compute_meal_nutrients and recompute_meal_derived for every
meal in the file (§10.3-§10.5).
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import yaml
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
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
from app.db.models.catalog import MealTagSource, WeightMethod
from app.db.models.reference import FoodExternalSource, ReviewStatus
from app.seed.f1_files import F1Files, SubsetRow, read_f1_files
from app.seed.quality_gates import (
    GATE_NAMES,
    GateFailure,
    allergen_codes_by_name,
    run_all_gates,
)
from app.services.common import RowChanges
from app.services.meal_derived import TagRuleError
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.recompute_meals import MealRecompute, recompute_meal
from app.services.tag_rules import TAG_RULES_VERSION

DEFAULT_DATA_DIR = Path(__file__).resolve().parents[2] / "data" / "f1_slice"
FDC_DATA_TYPE = "sr_legacy_food"
FDC_RELEASE = "USDA FoodData Central, SR Legacy (2018-04)"
NUMERIC_SCALE = 3  # NUMERIC(12,3) / NUMERIC(4,3), §15.2
SEED_VERSION_SUFFIX = re.compile(r"_v\d+$")

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

STATIC_FINDINGS = (
    "§9.10: ingredients have no natural key; idempotency uses default_food_id (one ingredient "
    "per food in F.1), which the schema does not keep unique (deferred to Step G, #77).",
)


@dataclass
class TableCounts:
    inserted: int = 0
    updated: int = 0
    unchanged: int = 0
    deleted: int = 0

    @property
    def changed(self) -> bool:
        return bool(self.inserted or self.updated or self.deleted)


@dataclass
class LoadReport:
    data_dir: str
    tables: dict[str, TableCounts] = field(
        default_factory=lambda: {name: TableCounts() for name in TABLES}
    )
    gates: dict[str, list[GateFailure]] = field(default_factory=dict)
    errors: list[str] = field(default_factory=list)
    unverified_meals: int = 0
    total_meals: int = 0
    deactivated_meals: list[str] = field(default_factory=list)
    reactivated_meals: list[str] = field(default_factory=list)
    recomputed: list[MealRecompute] = field(default_factory=list)
    findings: list[str] = field(default_factory=list)

    @property
    def failures(self) -> list[str]:
        return [*self.errors, *(str(f) for fs in self.gates.values() for f in fs)]

    @property
    def ok(self) -> bool:
        return not self.failures

    @property
    def recompute_changes(self) -> dict[str, RowChanges]:
        def total(changes: list[RowChanges]) -> RowChanges:
            return RowChanges(
                inserted=sum(c.inserted for c in changes),
                updated=sum(c.updated for c in changes),
                deleted=sum(c.deleted for c in changes),
                unchanged=sum(c.unchanged for c in changes),
            )

        return dict(
            zip(
                RECOMPUTE_TABLES,
                (
                    total([r.nutrition.changes for r in self.recomputed]),
                    total([r.derived.allergen_changes for r in self.recomputed]),
                    total([r.derived.tag_changes for r in self.recomputed]),
                ),
                strict=True,
            )
        )

    @property
    def incomplete_meals(self) -> list[str]:
        return [
            r.ref_external or str(r.meal_id) for r in self.recomputed if not r.nutrition.is_complete
        ]

    @property
    def all_unchanged(self) -> bool:
        return not any(counts.changed for counts in self.tables.values()) and not any(
            r.changed for r in self.recomputed
        )

    def format(self) -> str:
        lines = [f"F.1 slice load: {'OK' if self.ok else 'FAILED'} (data: {self.data_dir})"]
        lines.append("Quality gates:")
        for gate, name in GATE_NAMES.items():
            if gate not in self.gates:
                lines.append(f"  {gate} {name}: not run")
                continue
            failures = self.gates[gate]
            lines.append(
                f"  {gate} {name}: {'PASS' if not failures else f'FAIL ({len(failures)})'}"
            )
            lines.extend(f"    - {failure}" for failure in failures)
        if self.errors:
            lines.append("Errors:")
            lines.extend(f"  - {error}" for error in self.errors)
        width = max(len(name) for name in (*TABLES, *RECOMPUTE_TABLES))
        lines.append(f"Tables ({'inserted / updated / unchanged / deleted'}):")
        for name, c in self.tables.items():
            numbers = " / ".join(f"{n:>4}" for n in (c.inserted, c.updated, c.unchanged, c.deleted))
            lines.append(f"  {name:<{width}}  {numbers}")
        verified = self.total_meals - self.unverified_meals
        lines.append(
            f"Meals in file: {self.total_meals}; verified {verified}, "
            f"unverified (reviewed_by is null) {self.unverified_meals}"
        )
        lines.append(
            f"Deactivated meals (not in the file): {len(self.deactivated_meals)}"
            + (f" {self.deactivated_meals}" if self.deactivated_meals else "")
        )
        lines.append(
            f"Reactivated meals: {len(self.reactivated_meals)}"
            + (f" {self.reactivated_meals}" if self.reactivated_meals else "")
        )
        complete = len(self.recomputed) - len(self.incomplete_meals)
        lines.append(
            f"Recompute ({COMPUTATION_VERSION}, {TAG_RULES_VERSION}): "
            f"{len(self.recomputed)} meals, {complete} nutritionally complete"
            + (f"; incomplete {self.incomplete_meals}" if self.incomplete_meals else "")
        )
        lines.append("  Row changes (+inserted ~updated -deleted =unchanged):")
        lines.extend(
            f"  {name:<{width}}  {changes}" for name, changes in self.recompute_changes.items()
        )
        replaced = [
            f"{r.ref_external}:{tag}"
            for r in self.recomputed
            for tag in r.derived.replaced_manual_tags
        ]
        if replaced:
            lines.append("  MANUAL rows replaced by DERIVED: " + ", ".join(replaced))
        lines.append("Findings:")
        lines.extend(f"  - {finding}" for finding in self.findings)
        return "\n".join(lines)


class F1LoadError(Exception):
    def __init__(self, report: LoadReport) -> None:
        super().__init__(f"F.1 slice load failed: {len(report.failures)} failure(s)")
        self.report = report


class _LoadConflictError(Exception):
    pass


def _same(current: Any, desired: Any) -> bool:
    if isinstance(current, float) or isinstance(desired, float):
        if current is None or desired is None:
            return current is desired
        return round(float(current), NUMERIC_SCALE) == round(float(desired), NUMERIC_SCALE)
    return bool(current == desired)


def _rounded(value: float | None) -> float | None:
    return None if value is None else round(value, NUMERIC_SCALE)


def total_grams(
    grams: list[float], weight_method: WeightMethod, yield_factor: float | None
) -> float:
    """Final as-served weight of the whole recipe (§10.1, Decision #25)."""
    raw = sum(grams)
    if weight_method is WeightMethod.YIELD_FACTOR:
        assert yield_factor is not None  # guaranteed by gate G6
        raw *= yield_factor
    return round(raw, NUMERIC_SCALE)


def _findings(files: F1Files) -> list[str]:
    findings = list(STATIC_FINDINGS)
    allergen_codes = {a.code for a in files.seed.allergens}
    by_name = sorted(
        {name for f in files.foods.foods for name in f.allergens if name not in allergen_codes}
    )
    if by_name:
        findings.append(
            f"§9.3: slice_foods.yaml names allergens by name_en ({', '.join(by_name)}), not by "
            "allergens.code; the loader maps each name to the seed's code."
        )
    fdc_description = {row.ndb_number: row.description for row in files.subset}
    differing = sorted(
        f.ndb_number
        for f in files.foods.foods
        if f.ndb_number in fdc_description and f.sr_description != fdc_description[f.ndb_number]
    )
    if differing:
        findings.append(
            "slice_foods.yaml sr_description differs from the official FDC description for "
            f"{differing}; foods.description uses the FDC text."
        )
    zeros = sum(1 for row in files.subset if row.amount_per_100g == 0)
    findings.append(
        f"§9.8: {zeros} of {len(files.subset)} subset values are 0 in the source; they are loaded "
        "as known zeros (absent values have no row)."
    )
    unverified = sum(1 for m in files.meals.meals if m.reviewed_by is None)
    if files.meals.source == "llm_draft_reviewed" and unverified:
        findings.append(
            f"§31.4: meals.source = 'llm_draft_reviewed' while {unverified} meals have no "
            "reviewer; is_verified = false records that the review has not happened."
        )
    return findings


class _Loader:
    def __init__(self, session: Session, files: F1Files, report: LoadReport, now: datetime) -> None:
        self.session = session
        self.files = files
        self.report = report
        self.now = now
        self.alias_source = files.seed.seed_version
        lineage = SEED_VERSION_SUFFIX.sub("", self.alias_source)
        self._seed_alias_source = re.compile(rf"^{re.escape(lineage)}_v\d+$")

    def _is_seed_alias(self, row: IngredientAlias) -> bool:
        """Aliases written by any version of this seed (f1_seed_v0, f1_seed_v1, ...)."""
        source = row.source
        return source == self.alias_source or (
            source is not None and self._seed_alias_source.match(source) is not None
        )

    # --- generic helpers ------------------------------------------------------------

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
        """Make the child rows of `parent` equal `desired` ({key tuple: values})."""
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
                counts.deleted += 1
        self.session.flush()

    # --- REFERENCE ----------------------------------------------------------------

    def run(self) -> None:
        seed = self.files.seed
        category_ids = self._load_categories()
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
                },
            )
        nutrient_by_nbr = {
            n.source_code: nutrient_ids[n.code] for n in seed.nutrients if n.source_code
        }
        food_ids, ingredient_ids = self._load_foods_and_ingredients(
            category_ids, nutrient_by_nbr, allergen_ids, tag_ids
        )
        meal_ids = self._load_meals(cuisine_ids, tag_ids, food_ids, ingredient_ids)
        self._deactivate_missing_meals()
        self._recompute(meal_ids)

    def _load_categories(self) -> dict[str, int]:
        descriptions = {
            row.food_category_code: row.food_category_description for row in self.files.subset
        }
        return {
            code: self._upsert(
                "categories",
                Category,
                "category_id",
                {"name_en": description},
                {"name_ar": self.files.seed.categories_ar[code]},
            )
            for code, description in sorted(descriptions.items())
        }

    def _load_foods_and_ingredients(
        self,
        category_ids: Mapping[str, int],
        nutrient_by_nbr: Mapping[str, int],
        allergen_ids: Mapping[str, int],
        tag_ids: Mapping[str, int],
    ) -> tuple[dict[str, int], dict[str, int]]:
        subset_by_ndb: dict[str, list[SubsetRow]] = defaultdict(list)
        for row in self.files.subset:
            subset_by_ndb[row.ndb_number].append(row)
        allergen_code = allergen_codes_by_name(self.files)
        food_ids: dict[str, int] = {}
        ingredient_ids: dict[str, int] = {}
        alias_names: dict[int, dict[str, str]] = {}
        for food in self.files.foods.foods:
            rows = subset_by_ndb[food.ndb_number]
            first = rows[0]
            food_id = self._upsert(
                "foods",
                Food,
                "food_id",
                {"external_source": FoodExternalSource.FDC.value, "external_code": food.ndb_number},
                {
                    "fdc_id": first.fdc_id,
                    "description": first.description,
                    "data_type": FDC_DATA_TYPE,
                    "category_id": category_ids[first.food_category_code],
                    "basis_grams": 100.0,
                    "state": food.state.value,
                    "source_reference": (
                        f"{FDC_RELEASE}; FDC ID {first.fdc_id}; NDB {food.ndb_number}"
                    ),
                },
            )
            food_ids[food.ndb_number] = food_id
            self._sync(
                "food_nutrients",
                FoodNutrient,
                {"food_id": food_id},
                ("nutrient_id",),
                {
                    (nutrient_by_nbr[r.nutrient_nbr],): {"amount_per_100g": r.amount_per_100g}
                    for r in rows
                },
            )
            ingredient_id = self._upsert(
                "ingredients",
                Ingredient,
                "ingredient_id",
                {"default_food_id": food_id},
                {"canonical_name": food.ingredient_en, "canonical_name_ar": food.ingredient_ar},
                insert_only={"review_status": ReviewStatus.PENDING.value},
            )
            ingredient_ids[food.ndb_number] = ingredient_id
            alias_names[ingredient_id] = {"en": food.ingredient_en, "ar": food.ingredient_ar}
            self._sync(
                "ingredient_allergens",
                IngredientAllergen,
                {"ingredient_id": ingredient_id},
                ("allergen_id",),
                {(allergen_ids[allergen_code[name]],): {} for name in food.allergens},
            )
            self._sync(
                "ingredient_tags",
                IngredientTag,
                {"ingredient_id": ingredient_id},
                ("tag_id",),
                {(tag_ids[code],): {} for code in food.ingredient_tags},
            )
        self._load_aliases(alias_names)
        return food_ids, ingredient_ids

    def _load_aliases(self, names_by_ingredient: Mapping[int, Mapping[str, str]]) -> None:
        """Seed aliases of the loaded ingredients become exactly the file's names."""
        counts = self.report.tables["ingredient_aliases"]
        wanted = {
            ingredient_id: {(text, lang) for lang, text in names.items()}
            for ingredient_id, names in names_by_ingredient.items()
        }
        # Stale seed aliases go first, so a name moved between ingredients is free again.
        for row in self.session.execute(
            select(IngredientAlias).where(IngredientAlias.ingredient_id.in_(list(wanted)))
        ).scalars():
            if (
                self._is_seed_alias(row)
                and (row.alias_text, row.lang) not in wanted[row.ingredient_id]
            ):
                self.session.delete(row)
                counts.deleted += 1
        self.session.flush()

        for ingredient_id, names in names_by_ingredient.items():
            for lang, text in names.items():
                owner = self.session.execute(
                    select(IngredientAlias.ingredient_id).where(
                        IngredientAlias.alias_text == text,
                        IngredientAlias.lang == lang,
                        IngredientAlias.ingredient_id != ingredient_id,
                    )
                ).scalar_one_or_none()
                if owner is not None:
                    raise _LoadConflictError(
                        f"ingredient_aliases: ({text!r}, {lang}) already belongs to "
                        f"ingredient {owner}"
                    )
            self._sync(
                "ingredient_aliases",
                IngredientAlias,
                {"ingredient_id": ingredient_id},
                ("alias_text", "lang"),
                {
                    (text, lang): {
                        "alias_normalized": normalize_search_text(text),
                        "confidence": 1.0,
                        "source": self.alias_source,
                    }
                    for lang, text in names.items()
                },
                may_delete=lambda _row: False,
            )

    # --- CATALOG ------------------------------------------------------------------

    def _load_meals(
        self,
        cuisine_ids: Mapping[str, int],
        tag_ids: Mapping[str, int],
        food_ids: Mapping[str, int],
        ingredient_ids: Mapping[str, int],
    ) -> dict[int, str]:
        meals = self.files.meals
        inactive = set(
            self.session.execute(
                select(Meal.ref_external).where(Meal.source == meals.source, ~Meal.is_active)
            ).scalars()
        )
        meal_ids: dict[int, str] = {}
        for meal in meals.meals:
            meal_id = self._upsert(
                "meals",
                Meal,
                "meal_id",
                {"source": meals.source, "ref_external": meal.ref_external},
                {
                    "name": meal.name_ar,
                    "default_lang": meals.default_lang,
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
                    "source_license": meals.source_license,
                    "quality_tier": meals.quality_tier.value,
                    "reviewed_by": meal.reviewed_by,
                    "is_verified": meal.reviewed_by is not None,
                    "is_active": True,
                    "dataset_version": meals.dataset_version,
                },
            )
            meal_ids[meal_id] = meal.ref_external
            if meal.ref_external in inactive:
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
            self._sync(
                "meal_ingredients",
                MealIngredient,
                {"meal_id": meal_id},
                ("position",),
                {
                    (position,): {
                        "ingredient_id": ingredient_ids[item.ndb_number],
                        "food_id": food_ids[item.ndb_number],
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
        for tag_id in sorted(wanted & derived):
            self.report.findings.append(
                f"§10.5: meal {meal_id} tag {tag_id} is DERIVED; the MANUAL row is not added"
            )
        self._sync(
            "meal_tags",
            MealTag,
            {"meal_id": meal_id, "source": MealTagSource.MANUAL.value},
            ("tag_id",),
            {(tag_id,): {} for tag_id in sorted(wanted - derived)},
        )

    def _deactivate_missing_meals(self) -> None:
        """#79, §15.8: a meal the file no longer lists is deactivated, never deleted."""
        meals = self.files.meals
        refs = [m.ref_external for m in meals.meals]
        stale = self.session.execute(
            select(Meal)
            .where(
                Meal.source == meals.source,
                Meal.is_active,
                Meal.ref_external.is_not(None),
                Meal.ref_external.not_in(refs),
            )
            .order_by(Meal.ref_external)
        ).scalars()
        for meal in stale:
            meal.is_active = False
            self.report.tables["meals"].updated += 1
            self.report.deactivated_meals.append(str(meal.ref_external))
        self.session.flush()

    def _recompute(self, meal_ids: Mapping[int, str]) -> None:
        for meal_id, ref_external in meal_ids.items():
            nutrition, derived = recompute_meal(self.session, meal_id, self.now)
            self.report.recomputed.append(MealRecompute(meal_id, ref_external, nutrition, derived))


def load_f1_slice(session: Session, data_dir: Path, now: datetime | None = None) -> LoadReport:
    """Validate, gate, load and recompute the F.1 slice inside one SAVEPOINT of `session`.

    Raises F1LoadError (with the full report) if any input or gate fails; nothing is written
    then. The caller owns the outer transaction and decides whether to commit.
    """
    report = LoadReport(data_dir=str(data_dir))
    try:
        files = read_f1_files(data_dir)
    except (OSError, ValueError, ValidationError, yaml.YAMLError) as exc:
        report.errors.append(f"input files: {exc}")
        raise F1LoadError(report) from exc

    report.gates = run_all_gates(files)
    report.total_meals = len(files.meals.meals)
    report.unverified_meals = sum(1 for m in files.meals.meals if m.reviewed_by is None)
    report.findings = _findings(files)
    if not report.ok:
        raise F1LoadError(report)

    try:
        with session.begin_nested():
            _Loader(session, files, report, now or datetime.now(UTC)).run()
    except (SQLAlchemyError, _LoadConflictError, TagRuleError) as exc:
        report.errors.append(f"database (rolled back): {exc}")
        report.tables = {name: TableCounts() for name in TABLES}
        report.deactivated_meals = []
        report.reactivated_meals = []
        report.recomputed = []
        raise F1LoadError(report) from exc
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Load the Step F.1 slice into DATABASE_URL.")
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    args = parser.parse_args(argv)

    from app.db.session import SessionLocal

    with SessionLocal() as session:
        try:
            report = load_f1_slice(session, args.data_dir)
        except F1LoadError as exc:
            session.rollback()
            print(exc.report.format())
            return 1
        session.commit()
    print(report.format())
    return 0


if __name__ == "__main__":
    sys.exit(main())
