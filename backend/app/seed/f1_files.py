"""Step F.1 input files: pydantic models for the three YAML files and the FDC subset CSV.

Enum fields reuse the model enums, so a value outside a schema CHECK set fails here, before
any database write. Unknown keys are rejected (`extra="forbid"`) to catch typos.
"""

from __future__ import annotations

import csv
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Annotated, Any, Literal, Self

import yaml
from pydantic import BaseModel, ConfigDict, Field, StringConstraints, model_validator

from app.db.models.catalog import QualityTier, WeightMethod
from app.db.models.reference import (
    FoodState,
    LimitBasis,
    NutrientUnit,
    RestrictionType,
    TagGroup,
)

REFERENCE_SEED_FILE = "reference_seed.yaml"
SLICE_FOODS_FILE = "slice_foods.yaml"
SLICE_MEALS_FILE = "slice_meals.yaml"
SUBSET_CSV_FILE = "fdc_sr_legacy_subset.csv"
SOURCE_MANIFEST_FILE = "fdc_source_manifest.yaml"

SUBSET_COLUMNS = (
    "ndb_number",
    "fdc_id",
    "description",
    "food_category_code",
    "food_category_description",
    "nutrient_nbr",
    "amount_per_100g",
)

Text = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
# SR Legacy NDB numbers are five digits; kept as text so leading zeros survive.
NdbNumber = Annotated[str, StringConstraints(pattern=r"^\d{5}$")]
FdcCategoryCode = Annotated[str, StringConstraints(pattern=r"^\d{4}$")]
NonNegative = Annotated[float, Field(ge=0)]


class _Model(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


# --- reference_seed.yaml ----------------------------------------------------------


class CuisineSeed(_Model):
    key: Text
    name_en: Text
    name_ar: Text


class AllergenSeed(_Model):
    name_en: Text
    name_ar: Text


class TagSeed(_Model):
    code: Text
    tag_group: TagGroup
    name_en: Text
    name_ar: Text


class NutrientSeed(_Model):
    code: Text
    source_code: Text | None
    name: Text
    unit: NutrientUnit
    is_mandatory: bool


class ConditionSeed(_Model):
    code: Text
    name_en: Text
    name_ar: Text
    is_supported: bool
    fluid_goal_requires_clinician: bool


class ConditionLimitSeed(_Model):
    condition: Text
    nutrient: Text
    limit_basis: LimitBasis
    max_per_meal: NonNegative | None = None
    max_per_day: NonNegative | None = None
    min_per_day: NonNegative | None = None
    source_reference: Text
    severity_note: Text | None = None

    @model_validator(mode="after")
    def _limits_consistent(self) -> Self:
        values = (self.max_per_meal, self.max_per_day, self.min_per_day)
        if all(value is None for value in values):
            raise ValueError("at least one of max_per_meal, max_per_day, min_per_day is required")
        if (
            self.min_per_day is not None
            and self.max_per_day is not None
            and self.min_per_day > self.max_per_day
        ):
            raise ValueError("min_per_day must be <= max_per_day")
        if self.limit_basis is LimitBasis.PERCENT_ENERGY and any(
            value is not None and value > 100 for value in values
        ):
            raise ValueError("PERCENT_ENERGY values must be <= 100")
        return self


class ConditionTagRestrictionSeed(_Model):
    condition: Text
    tag: Text
    restriction_type: RestrictionType
    max_servings_per_week: Annotated[int, Field(gt=0)] | None = None

    @model_validator(mode="after")
    def _servings_only_for_limit(self) -> Self:
        if (
            self.restriction_type is not RestrictionType.LIMIT
            and self.max_servings_per_week is not None
        ):
            raise ValueError("max_servings_per_week is only allowed for LIMIT")
        return self


class ReferenceSeed(_Model):
    seed_version: Text
    categories_ar: dict[FdcCategoryCode, Text]
    cuisines: list[CuisineSeed]
    allergens: list[AllergenSeed]
    dietary_tags: list[TagSeed]
    nutrients: list[NutrientSeed]
    health_conditions: list[ConditionSeed]
    condition_nutrient_limits: list[ConditionLimitSeed]
    condition_tag_restrictions: list[ConditionTagRestrictionSeed]
    excluded_keywords: list[Text]

    @model_validator(mode="after")
    def _unique_keys(self) -> Self:
        _require_unique("cuisines.key", [c.key for c in self.cuisines])
        _require_unique("cuisines.name_en", [c.name_en for c in self.cuisines])
        _require_unique("allergens.name_en", [a.name_en for a in self.allergens])
        _require_unique("dietary_tags.code", [t.code for t in self.dietary_tags])
        _require_unique("nutrients.code", [n.code for n in self.nutrients])
        _require_unique(
            "nutrients.source_code", [n.source_code for n in self.nutrients if n.source_code]
        )
        _require_unique("health_conditions.code", [c.code for c in self.health_conditions])
        _require_unique(
            "condition_nutrient_limits",
            [(r.condition, r.nutrient, r.limit_basis) for r in self.condition_nutrient_limits],
        )
        _require_unique(
            "condition_tag_restrictions",
            [(r.condition, r.tag) for r in self.condition_tag_restrictions],
        )
        return self


# --- slice_foods.yaml -------------------------------------------------------------


class SliceFood(_Model):
    ndb_number: NdbNumber
    sr_description: Text
    ingredient_en: Text
    ingredient_ar: Text
    state: FoodState
    allergens: list[Text]
    ingredient_tags: list[Text]


class SliceFoods(_Model):
    source: Text
    foods: list[SliceFood]

    @model_validator(mode="after")
    def _unique_foods(self) -> Self:
        _require_unique("foods.ndb_number", [f.ndb_number for f in self.foods])
        return self


# --- slice_meals.yaml -------------------------------------------------------------


class MealIngredientEntry(_Model):
    ndb_number: NdbNumber
    grams: Annotated[float, Field(gt=0)]
    label_ar: str | None = None  # informational only; the loader ignores it


class SliceMeal(_Model):
    ref_external: Text
    name_ar: Text
    name_en: Text
    cuisine: Text
    servings: Annotated[int, Field(gt=0)]
    weight_method: WeightMethod
    yield_factor: float | None
    yield_factor_source: Text | None
    occasion_tags: list[Text]
    dietary_tags: list[Text]
    reviewed_by: Text | None
    ingredients: Annotated[list[MealIngredientEntry], Field(min_length=1)]


class SliceMeals(_Model):
    dataset_version: Text
    source: Text
    source_license: Text
    quality_tier: QualityTier
    default_lang: Literal["ar"]
    meals: list[SliceMeal]

    @model_validator(mode="after")
    def _unique_meals(self) -> Self:
        _require_unique("meals.ref_external", [m.ref_external for m in self.meals])
        return self


# --- fdc_sr_legacy_subset.csv -----------------------------------------------------


class SubsetRow(_Model):
    ndb_number: NdbNumber
    fdc_id: Annotated[int, Field(gt=0)]
    description: Text
    food_category_code: FdcCategoryCode
    food_category_description: Text
    nutrient_nbr: Annotated[str, StringConstraints(pattern=r"^\d+$")]
    amount_per_100g: NonNegative


# --- reading ----------------------------------------------------------------------


@dataclass(frozen=True)
class F1Files:
    seed: ReferenceSeed
    foods: SliceFoods
    meals: SliceMeals
    subset: list[SubsetRow]


def _require_unique(label: str, values: list[Any]) -> None:
    duplicates = sorted(str(value) for value, n in Counter(values).items() if n > 1)
    if duplicates:
        raise ValueError(f"duplicate {label}: {duplicates}")


def _read_yaml(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def read_reference_seed(path: Path) -> ReferenceSeed:
    return ReferenceSeed.model_validate(_read_yaml(path))


def read_slice_foods(path: Path) -> SliceFoods:
    return SliceFoods.model_validate(_read_yaml(path))


def read_slice_meals(path: Path) -> SliceMeals:
    return SliceMeals.model_validate(_read_yaml(path))


def read_subset(path: Path) -> list[SubsetRow]:
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if tuple(reader.fieldnames or ()) != SUBSET_COLUMNS:
            raise ValueError(f"{path.name}: header {reader.fieldnames} != {list(SUBSET_COLUMNS)}")
        rows = [SubsetRow.model_validate(row) for row in reader]
    _require_unique(
        f"{path.name} (ndb_number, nutrient_nbr)", [(r.ndb_number, r.nutrient_nbr) for r in rows]
    )
    return rows


def read_f1_files(data_dir: Path) -> F1Files:
    return F1Files(
        seed=read_reference_seed(data_dir / REFERENCE_SEED_FILE),
        foods=read_slice_foods(data_dir / SLICE_FOODS_FILE),
        meals=read_slice_meals(data_dir / SLICE_MEALS_FILE),
        subset=read_subset(data_dir / SUBSET_CSV_FILE),
    )
