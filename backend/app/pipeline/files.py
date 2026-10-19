"""Pydantic models and readers for `backend/data/catalog/` (Decision #94).

Authoring errors (schema, unknown codes, duplicates, stale subset hashes) are collected
and raised together — they are bugs in the files, not data-quality outcomes.
"""

from __future__ import annotations

import csv
import hashlib
import re
from collections import Counter
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from enum import StrEnum
from pathlib import Path
from typing import Annotated, Any, Literal, Self

import yaml
from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    ValidationError,
    model_validator,
)

from app.db.models.catalog import DishForm, WeightMethod
from app.db.models.reference import FoodState, ReviewStatus
from app.seed.f1_files import (
    SUBSET_COLUMNS,
    FdcCategoryCode,
    IngredientCode,
    LowerSnake,
    NdbNumber,
    NonNegative,
    ReferenceSeed,
    SubsetRow,
    Text,
    _require_unique,
    read_subset,
)

REFERENCE_SEED_FILE = "reference_seed.yaml"
INGREDIENTS_FILE = "ingredients.yaml"
MANUAL_FOODS_FILE = "manual_foods.yaml"
MEALS_DIR = "meals"
STEPS_DIR = "steps"
SOURCES_DIR = "sources"
REPORTS_DIR = "reports"
SOURCE_MANIFEST_FILE = "source_manifest.yaml"
SR_SUBSET_FILE = "sr_legacy_subset.csv"
FNDDS_SUBSET_FILE = "fndds_ingredient_subset.csv"

FNDDS_SUBSET_COLUMNS = ("ndb_number", "nutrient_nbr", "amount_per_100g")

SR_RELEASE = "USDA FDC SR Legacy (April 2018)"
FNDDS_INGREDIENT_SOURCE = "FNDDS 2021-2023 Ingredient Nutrient Values"
FDC_DOWNLOAD_PAGE = "https://fdc.nal.usda.gov/download-datasets"
FNDDS_DOWNLOAD_PAGE = (
    "https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/"
    "beltsville-human-nutrition-research-center/food-surveys-research-group/"
    "docs/fndds-download-databases/"
)

# Official FDC food-group codes used by SR Legacy (name_en for categories upsert).
FDC_CATEGORY_EN: dict[str, str] = {
    "0100": "Dairy and Egg Products",
    "0200": "Spices and Herbs",
    "0400": "Fats and Oils",
    "0500": "Poultry Products",
    "0800": "Breakfast Cereals",
    "0900": "Fruits and Fruit Juices",
    "1100": "Vegetables and Vegetable Products",
    "1200": "Nut and Seed Products",
    "1300": "Beef Products",
    "1400": "Beverages",
    "1500": "Finfish and Shellfish Products",
    "1600": "Legumes and Legume Products",
    "1700": "Lamb, Veal, and Game Products",
    "1800": "Baked Products",
    "1900": "Sweets",
    "2000": "Cereal Grains and Pasta",
}

THRESHOLD_TAG_CODES = frozenset({"high_sodium", "high_sugar"})
# §10.7: steps files are Arabic until the team writes another language.
SUPPORTED_STEP_LANGS = frozenset({"ar"})
MAX_STEP_CHARS = 500


class IngredientFoodSource(StrEnum):
    SR_LEGACY = "SR_LEGACY"
    MANUAL = "MANUAL"


class YieldFactorKind(StrEnum):
    PUBLISHED = "PUBLISHED"
    TEAM_ESTIMATE = "TEAM_ESTIMATE"


class CrossCheckStatus(StrEnum):
    PASS = "PASS"
    FAIL_REVIEWED = "FAIL_REVIEWED"


class _Model(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


class CatalogReferenceSeed(ReferenceSeed):
    """F.1 `ReferenceSeed` plus `uncertain_keywords` (§31.6)."""

    uncertain_keywords: list[Text]


class IngredientFoodRef(_Model):
    source: IngredientFoodSource
    code: Text

    @model_validator(mode="after")
    def _sr_code_is_ndb(self) -> Self:
        if self.source is IngredientFoodSource.SR_LEGACY and not re.fullmatch(
            r"^\d{5}$", self.code
        ):
            raise ValueError("SR_LEGACY food.code must be a 5-digit NDB number")
        return self


class CatalogIngredient(_Model):
    code: IngredientCode
    name_en: Text
    name_ar: Text
    aliases_en: list[Text]
    aliases_ar: list[Text]
    food: IngredientFoodRef
    state: FoodState
    allergens: list[Text]
    ingredient_tags: list[Text]
    review_status: ReviewStatus


class CatalogIngredients(_Model):
    dataset_version: Text
    ingredients: list[CatalogIngredient]

    @model_validator(mode="after")
    def _unique_codes(self) -> Self:
        _require_unique("ingredients.code", [i.code for i in self.ingredients])
        return self


class ManualFood(_Model):
    code: IngredientCode
    description: Text
    category: FdcCategoryCode
    state: FoodState
    source_reference: Text
    nutrients: dict[Text, NonNegative]


class ManualFoodsFile(_Model):
    foods: list[ManualFood]

    @model_validator(mode="after")
    def _unique_codes(self) -> Self:
        _require_unique("manual_foods.code", [f.code for f in self.foods])
        return self


class CrossCheck(_Model):
    status: CrossCheckStatus
    note: Text


class CatalogMealIngredient(_Model):
    code: IngredientCode
    grams: Annotated[float, Field(gt=0)]
    label_ar: Text | None = None
    optional: bool = False


class CatalogMeal(_Model):
    ref_external: Text
    name_ar: Text
    name_en: Text
    cuisine: Text
    servings: Annotated[int, Field(gt=0)]
    weight_method: WeightMethod
    yield_factor: float | None
    yield_factor_source: Text | None
    yield_factor_kind: YieldFactorKind | None = None
    variant_group: LowerSnake | None = None
    occasion_tags: list[Text]
    dietary_tags: list[Text]
    reviewed_by: Text | None
    ingredients: Annotated[list[CatalogMealIngredient], Field(min_length=1)]
    cross_check: CrossCheck | None = None

    @model_validator(mode="after")
    def _yield_kind_matches_method(self) -> Self:
        if self.weight_method is WeightMethod.YIELD_FACTOR:
            if self.yield_factor_kind is None:
                raise ValueError("yield_factor_kind is required when weight_method is YIELD_FACTOR")
        elif self.yield_factor_kind is not None:
            raise ValueError("yield_factor_kind is forbidden unless weight_method is YIELD_FACTOR")
        return self


class CatalogMealFile(_Model):
    dataset_version: Text
    source: Text
    source_license: Text
    default_lang: Literal["ar"]
    meals: list[CatalogMeal]


class CatalogMealSteps(_Model):
    ref_external: Text
    dish_form: DishForm
    steps_ar: Annotated[list[str], Field(min_length=1)]


class CatalogStepsFile(_Model):
    dataset_version: Text
    default_lang: Literal["ar"]
    note: str | None = None
    meals: list[CatalogMealSteps]


class ManifestSubset(_Model):
    sha256: Text
    row_count: Annotated[int, Field(ge=0)]


class ManifestRawFile(_Model):
    name: Text
    size_bytes: Annotated[int, Field(ge=0)]
    sha256: Text
    download_page: Text
    extracted_on: Text


class SourceManifest(_Model):
    raw_files: list[ManifestRawFile]
    subsets: dict[Text, ManifestSubset] = Field(default_factory=dict)


class FnddsIngredientRow(_Model):
    ndb_number: NdbNumber
    nutrient_nbr: Annotated[str, StringConstraints(pattern=r"^\d+$")]
    amount_per_100g: NonNegative


@dataclass
class CatalogFiles:
    seed: CatalogReferenceSeed
    ingredients: CatalogIngredients
    manuals: list[ManualFood]
    meal_files: list[CatalogMealFile]
    step_files: list[CatalogStepsFile]
    sr_subset: list[SubsetRow]
    fndds_subset: list[FnddsIngredientRow]
    manifest: SourceManifest
    input_hashes: dict[str, str] = field(default_factory=dict)

    @property
    def meals(self) -> list[tuple[CatalogMealFile, CatalogMeal]]:
        return [(batch, meal) for batch in self.meal_files for meal in batch.meals]


class CatalogAuthoringError(Exception):
    def __init__(self, errors: Sequence[str]) -> None:
        self.errors = list(errors)
        super().__init__(f"catalog authoring failed: {len(self.errors)} error(s)")

    def format(self) -> str:
        lines = [f"Catalog authoring failed ({len(self.errors)} error(s)):"]
        lines.extend(f"  - {error}" for error in self.errors)
        return "\n".join(lines)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pad_ndb(value: int | str) -> str:
    return f"{int(value):05d}"


def _read_yaml(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def _format_validation(path: Path, exc: ValidationError) -> list[str]:
    errors = []
    for err in exc.errors():
        loc = ".".join(str(part) for part in err["loc"])
        errors.append(f"{path.name}: {loc}: {err['msg']}")
    return errors


def read_catalog_reference_seed(path: Path) -> CatalogReferenceSeed:
    return CatalogReferenceSeed.model_validate(_read_yaml(path))


def read_fndds_subset(path: Path) -> list[FnddsIngredientRow]:
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if tuple(reader.fieldnames or ()) != FNDDS_SUBSET_COLUMNS:
            raise ValueError(
                f"{path.name}: header {reader.fieldnames} != {list(FNDDS_SUBSET_COLUMNS)}"
            )
        rows = [FnddsIngredientRow.model_validate(row) for row in reader]
    _require_unique(
        f"{path.name} (ndb_number, nutrient_nbr)", [(r.ndb_number, r.nutrient_nbr) for r in rows]
    )
    return rows


def _hashed_inputs(paths: Iterable[Path], root: Path) -> dict[str, str]:
    hashes: dict[str, str] = {}
    for path in paths:
        if path.is_file():
            hashes[path.relative_to(root).as_posix()] = sha256_file(path)
    return dict(sorted(hashes.items()))


def read_catalog(data_dir: Path) -> CatalogFiles:
    """Read and cross-check every catalog file. Raises CatalogAuthoringError with every error."""
    errors: list[str] = []
    seed: CatalogReferenceSeed | None = None
    ingredients: CatalogIngredients | None = None
    manuals: list[ManualFood] = []
    meal_files: list[CatalogMealFile] = []
    step_files: list[CatalogStepsFile] = []
    sr_subset: list[SubsetRow] = []
    fndds_subset: list[FnddsIngredientRow] = []
    manifest: SourceManifest | None = None

    seed_path = data_dir / REFERENCE_SEED_FILE
    ingredients_path = data_dir / INGREDIENTS_FILE
    manuals_path = data_dir / MANUAL_FOODS_FILE
    meals_dir = data_dir / MEALS_DIR
    steps_dir = data_dir / STEPS_DIR
    sources_dir = data_dir / SOURCES_DIR
    manifest_path = sources_dir / SOURCE_MANIFEST_FILE
    sr_path = sources_dir / SR_SUBSET_FILE
    fndds_path = sources_dir / FNDDS_SUBSET_FILE

    def _load(path: Path, loader: Any, label: str) -> Any:
        if not path.is_file():
            errors.append(f"missing required file: {label}")
            return None
        try:
            return loader(path)
        except ValidationError as exc:
            errors.extend(_format_validation(path, exc))
        except (OSError, ValueError, yaml.YAMLError) as exc:
            errors.append(f"{path.name}: {exc}")
        return None

    seed = _load(seed_path, read_catalog_reference_seed, REFERENCE_SEED_FILE)
    ingredients = _load(ingredients_path, _read_ingredients, INGREDIENTS_FILE)
    if manuals_path.is_file():
        parsed = _load(manuals_path, _read_manual_foods, MANUAL_FOODS_FILE)
        if parsed is not None:
            manuals = parsed
    manifest = _load(manifest_path, _read_manifest, f"{SOURCES_DIR}/{SOURCE_MANIFEST_FILE}")
    if sr_path.is_file():
        try:
            sr_subset = read_subset(sr_path)
        except (OSError, ValueError, ValidationError) as exc:
            errors.append(f"{sr_path.name}: {exc}")
    else:
        errors.append(f"missing required file: {SOURCES_DIR}/{SR_SUBSET_FILE}")
    if fndds_path.is_file():
        try:
            fndds_subset = read_fndds_subset(fndds_path)
        except (OSError, ValueError, ValidationError) as exc:
            errors.append(f"{fndds_path.name}: {exc}")
    else:
        errors.append(f"missing required file: {SOURCES_DIR}/{FNDDS_SUBSET_FILE}")

    meal_paths = sorted(meals_dir.glob("*.yaml")) if meals_dir.is_dir() else []
    raw_refs: list[str] = []
    raw_meal_ingredient_codes: list[tuple[str, str]] = []
    for path in meal_paths:
        raw: Any
        try:
            raw = _read_yaml(path)
        except (OSError, yaml.YAMLError) as exc:
            errors.append(f"{path.name}: {exc}")
            continue
        if not isinstance(raw, dict):
            errors.append(f"{path.name}: file must be a mapping")
            continue
        header_keys = ("dataset_version", "source", "source_license", "default_lang")
        header = {k: raw.get(k) for k in header_keys}
        meals_raw = raw.get("meals")
        if not isinstance(meals_raw, list):
            errors.append(f"{path.name}: meals must be a list")
            meals_raw = []
        parsed_meals: list[CatalogMeal] = []
        for index, meal_raw in enumerate(meals_raw):
            subject = f"{path.name} meals[{index}]"
            if not isinstance(meal_raw, dict):
                errors.append(f"{subject}: meal must be a mapping")
                continue
            ref = meal_raw.get("ref_external")
            if isinstance(ref, str):
                raw_refs.append(ref)
                if not ref.startswith("NG-"):
                    errors.append(f"{subject}: ref_external {ref!r} must start with 'NG-'")
            try:
                parsed_meals.append(CatalogMeal.model_validate(meal_raw))
            except ValidationError as exc:
                errors.extend(
                    f"{subject}: {loc}: {err['msg']}"
                    for err in exc.errors()
                    for loc in [".".join(str(p) for p in err["loc"])]
                )
            for item in meal_raw.get("ingredients") or []:
                if isinstance(item, dict) and isinstance(item.get("code"), str):
                    raw_meal_ingredient_codes.append((str(ref), item["code"]))
        try:
            batch = CatalogMealFile.model_validate({**header, "meals": []})
        except ValidationError as exc:
            errors.extend(_format_validation(path, exc))
            continue
        meal_files.append(
            CatalogMealFile(
                dataset_version=batch.dataset_version,
                source=batch.source,
                source_license=batch.source_license,
                default_lang=batch.default_lang,
                meals=parsed_meals,
            )
        )

    duplicates = sorted(ref for ref, n in Counter(raw_refs).items() if n > 1)
    if duplicates:
        errors.append(f"duplicate ref_external: {duplicates}")

    step_paths = sorted(steps_dir.glob("*.yaml")) if steps_dir.is_dir() else []
    step_files, step_errors = _read_step_files(step_paths, set(raw_refs))
    errors.extend(step_errors)

    if manifest is not None:
        errors.extend(_check_subset_hashes(manifest, sr_path, fndds_path))

    if seed is not None and ingredients is not None:
        errors.extend(
            _cross_check(
                seed,
                ingredients,
                manuals,
                meal_files,
                sr_subset,
                raw_meal_ingredient_codes,
            )
        )

    input_paths = [
        seed_path,
        ingredients_path,
        manuals_path,
        manifest_path,
        sr_path,
        fndds_path,
        *meal_paths,
        *step_paths,
    ]
    input_hashes = _hashed_inputs(input_paths, data_dir)
    if errors:
        raise CatalogAuthoringError(sorted(set(errors)))
    assert seed is not None and ingredients is not None and manifest is not None
    return CatalogFiles(
        seed=seed,
        ingredients=ingredients,
        manuals=manuals,
        meal_files=meal_files,
        step_files=step_files,
        sr_subset=sr_subset,
        fndds_subset=fndds_subset,
        manifest=manifest,
        input_hashes=input_hashes,
    )


def _read_step_files(
    paths: Sequence[Path], meal_refs: set[str]
) -> tuple[list[CatalogStepsFile], list[str]]:
    """Parse every steps file. Schema and authoring failures are returned together."""
    files: list[CatalogStepsFile] = []
    errors: list[str] = []
    seen: dict[str, str] = {}
    for path in paths:
        try:
            raw = _read_yaml(path)
        except (OSError, yaml.YAMLError) as exc:
            errors.append(f"{path.name}: {exc}")
            continue
        if not isinstance(raw, dict):
            errors.append(f"{path.name}: file must be a mapping")
            continue
        file_errors = _step_file_errors(path.name, raw, meal_refs, seen)
        errors.extend(file_errors)
        if file_errors:
            continue
        try:
            files.append(CatalogStepsFile.model_validate(raw))
        except ValidationError as exc:
            errors.extend(_format_validation(path, exc))
    return files, errors


def _step_file_errors(
    filename: str,
    raw: Mapping[str, Any],
    meal_refs: set[str],
    seen: dict[str, str],
) -> list[str]:
    """G13 checks that must be visible even when a meal fails the pydantic model."""
    errors: list[str] = []
    lang = raw.get("default_lang")
    if lang not in SUPPORTED_STEP_LANGS:
        errors.append(f"G13 {filename}: default_lang {lang!r} is not a supported language")
    meals = raw.get("meals")
    if not isinstance(meals, list):
        return errors
    for index, meal in enumerate(meals):
        if not isinstance(meal, dict):
            errors.append(f"G13 {filename} meals[{index}]: meal must be a mapping")
            continue
        ref = meal.get("ref_external")
        subject = f"{filename} {ref}" if isinstance(ref, str) else f"{filename} meals[{index}]"
        form = meal.get("dish_form")
        if form not in {member.value for member in DishForm}:
            errors.append(f"G13 {subject}: dish_form {form!r} is not ONE_DISH or PLATE")
        if isinstance(ref, str):
            if ref not in meal_refs:
                errors.append(f"G13 {subject}: unknown ref_external {ref!r}")
            previous = seen.get(ref)
            if previous is not None:
                errors.append(f"G13 {subject}: duplicate ref_external {ref!r} (also in {previous})")
            else:
                seen[ref] = filename
        steps = meal.get("steps_ar")
        if isinstance(steps, list):
            for number, step in enumerate(steps, start=1):
                if not isinstance(step, str) or not step.strip():
                    errors.append(f"G13 {subject}: step {number} is blank")
                elif len(step) > MAX_STEP_CHARS:
                    errors.append(
                        f"G13 {subject}: step {number} is longer than {MAX_STEP_CHARS} characters"
                    )
    return errors


def _read_ingredients(path: Path) -> CatalogIngredients:
    return CatalogIngredients.model_validate(_read_yaml(path))


def _read_manual_foods(path: Path) -> list[ManualFood]:
    raw = _read_yaml(path)
    if isinstance(raw, dict) and "foods" in raw:
        return ManualFoodsFile.model_validate(raw).foods
    if isinstance(raw, list):
        return ManualFoodsFile.model_validate({"foods": raw}).foods
    raise ValueError(f"{path.name}: expected a list or a mapping with 'foods'")


def _read_manifest(path: Path) -> SourceManifest:
    return SourceManifest.model_validate(_read_yaml(path))


def _check_subset_hashes(manifest: SourceManifest, sr_path: Path, fndds_path: Path) -> list[str]:
    errors: list[str] = []
    for filename, path in ((SR_SUBSET_FILE, sr_path), (FNDDS_SUBSET_FILE, fndds_path)):
        listed = manifest.subsets.get(filename)
        if listed is None:
            errors.append(f"source_manifest.yaml: missing subset entry {filename}")
            continue
        if not path.is_file():
            continue
        actual = sha256_file(path)
        if actual != listed.sha256:
            errors.append(
                f"{filename}: SHA-256 {actual} differs from source_manifest.yaml ({listed.sha256})"
            )
    return errors


def _cross_check(
    seed: CatalogReferenceSeed,
    ingredients: CatalogIngredients,
    manuals: Sequence[ManualFood],
    meal_files: Sequence[CatalogMealFile],
    sr_subset: Sequence[SubsetRow],
    raw_meal_ingredient_codes: Sequence[tuple[str, str]],
) -> list[str]:
    errors: list[str] = []
    ingredient_codes = {i.code for i in ingredients.ingredients}
    manual_codes = {f.code for f in manuals}
    allergen_codes = {a.code for a in seed.allergens}
    tag_codes = {t.code for t in seed.dietary_tags}
    cuisine_codes = {c.code for c in seed.cuisines}
    nutrient_codes = {n.code for n in seed.nutrients}
    subset_ndbs = {r.ndb_number for r in sr_subset}
    overlap = sorted(kw for kw in seed.uncertain_keywords if kw in set(seed.excluded_keywords))
    if overlap:
        errors.append(f"uncertain_keywords also listed as excluded_keywords: {overlap}")

    for ingredient in ingredients.ingredients:
        if ingredient.food.source is IngredientFoodSource.SR_LEGACY:
            if ingredient.food.code not in subset_ndbs:
                errors.append(
                    f"ingredient {ingredient.code}: SR NDB {ingredient.food.code} "
                    f"is not in {SR_SUBSET_FILE}"
                )
        elif ingredient.food.code not in manual_codes:
            errors.append(
                f"ingredient {ingredient.code}: MANUAL food {ingredient.food.code} "
                f"is not in {MANUAL_FOODS_FILE}"
            )
        for allergen in ingredient.allergens:
            if allergen not in allergen_codes:
                errors.append(f"ingredient {ingredient.code}: unknown allergen code {allergen!r}")
        for tag in ingredient.ingredient_tags:
            if tag not in tag_codes:
                errors.append(f"ingredient {ingredient.code}: unknown ingredient tag {tag!r}")
        group = {t.code: t.tag_group for t in seed.dietary_tags}
        for tag in ingredient.ingredient_tags:
            tagged = group.get(tag)
            if tagged is not None and tagged.value == "OCCASION":
                errors.append(
                    f"ingredient {ingredient.code}: tag {tag!r} is OCCASION "
                    f"(not allowed on ingredients)"
                )

    for food in manuals:
        if food.category not in seed.categories_ar:
            errors.append(f"manual food {food.code}: category {food.category} not in categories_ar")
        elif food.category not in FDC_CATEGORY_EN:
            errors.append(f"manual food {food.code}: no English name for category {food.category}")
        for code in food.nutrients:
            if code not in nutrient_codes:
                errors.append(f"manual food {food.code}: unknown nutrient {code!r}")

    known_ingredients = ingredient_codes
    for batch, meal in ((b, m) for b in meal_files for m in b.meals):
        _ = batch
        if meal.cuisine not in cuisine_codes:
            errors.append(f"meal {meal.ref_external}: unknown cuisine {meal.cuisine!r}")
        for tag in (*meal.occasion_tags, *meal.dietary_tags):
            if tag not in tag_codes:
                errors.append(f"meal {meal.ref_external}: unknown tag {tag!r}")
        for item in meal.ingredients:
            if item.code not in known_ingredients:
                errors.append(f"meal {meal.ref_external}: unknown ingredient code {item.code!r}")

    for ref, code in raw_meal_ingredient_codes:
        if code not in known_ingredients:
            errors.append(f"meal {ref}: unknown ingredient code {code!r}")

    return errors


def write_csv(path: Path, columns: Sequence[str], rows: Sequence[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(columns), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def write_yaml(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        yaml.safe_dump(data, handle, sort_keys=False, allow_unicode=True)


# Re-export for extract / tests that build a seed without the catalog wrapper.
__all__ = [
    "FDC_CATEGORY_EN",
    "FDC_DOWNLOAD_PAGE",
    "FNDDS_DOWNLOAD_PAGE",
    "FNDDS_INGREDIENT_SOURCE",
    "FNDDS_SUBSET_COLUMNS",
    "FNDDS_SUBSET_FILE",
    "INGREDIENTS_FILE",
    "MANUAL_FOODS_FILE",
    "MAX_STEP_CHARS",
    "MEALS_DIR",
    "REFERENCE_SEED_FILE",
    "REPORTS_DIR",
    "SOURCES_DIR",
    "SOURCE_MANIFEST_FILE",
    "SR_RELEASE",
    "SR_SUBSET_FILE",
    "STEPS_DIR",
    "SUBSET_COLUMNS",
    "SUPPORTED_STEP_LANGS",
    "THRESHOLD_TAG_CODES",
    "CatalogAuthoringError",
    "CatalogFiles",
    "CatalogIngredient",
    "CatalogIngredients",
    "CatalogMeal",
    "CatalogMealFile",
    "CatalogMealSteps",
    "CatalogReferenceSeed",
    "CatalogStepsFile",
    "CrossCheck",
    "CrossCheckStatus",
    "FnddsIngredientRow",
    "IngredientFoodRef",
    "IngredientFoodSource",
    "ManualFood",
    "SourceManifest",
    "YieldFactorKind",
    "pad_ndb",
    "read_catalog",
    "read_catalog_reference_seed",
    "read_fndds_subset",
    "sha256_file",
    "write_csv",
    "write_yaml",
]
