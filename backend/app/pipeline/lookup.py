"""NDB lookup report: SR Legacy descriptions plus the #93 FNDDS fill.

Written before the subset files. Unknown NDB numbers are listed here and still
fail extraction afterwards.
"""

from __future__ import annotations

import re
from collections import defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass

import pandas as pd

from app.pipeline.files import CatalogIngredients, IngredientFoodSource, pad_ndb
from app.seed.f1_files import NutrientSeed

LOOKUP_REPORT_FILE = "ingredient_lookup.md"
_MAX_CANDIDATES = 5
_DROP_WORDS = frozenset({"and", "with", "fresh", "raw"})
_NON_WORD = re.compile(r"[^a-z0-9]+")
_HEADER = (
    "code | name_en | NDB | SR description | SR category | "
    "missing mandatory nutrients in SR | filled from FNDDS | status"
)


@dataclass(frozen=True)
class LookupFood:
    ndb: str
    description: str
    category: str
    missing_sr: tuple[str, ...]
    filled_fndds: tuple[str, ...]
    complete: bool
    words: frozenset[str]


def _as_int(value: object) -> int:
    return int(float(str(value)))


def _to_numeric(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


def _nbr_text(value: object) -> str | None:
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    if not text.replace(".", "", 1).isdigit():
        return None
    return str(_as_int(text))


def _name_words(text: str) -> frozenset[str]:
    """Lower-case, drop punctuation, short words, and a few stop words; strip one trailing s."""
    words: set[str] = set()
    for word in _NON_WORD.sub(" ", text.lower()).split():
        if len(word) <= 2 or word in _DROP_WORDS:
            continue
        if word.endswith("s"):
            word = word[:-1]
        if word:
            words.add(word)
    return frozenset(words)


def _cell(value: str) -> str:
    return " ".join(value.replace("|", "/").replace("\n", " ").split())


def _id_to_code(nutrient: pd.DataFrame, code_by_nbr: Mapping[str, str]) -> dict[int, str]:
    mapped: dict[int, str] = {}
    ids = _to_numeric(nutrient["id"])
    for nid, nbr in zip(ids, nutrient["nutrient_nbr"], strict=True):
        if pd.isna(nid):
            continue
        text = _nbr_text(nbr)
        if text is None:
            continue
        code = code_by_nbr.get(text)
        if code is not None:
            mapped[_as_int(nid)] = code
    return mapped


def _present_codes(
    food_nutrient: pd.DataFrame, id_to_code: Mapping[int, str]
) -> dict[int, set[str]]:
    present: dict[int, set[str]] = defaultdict(set)
    fdc_ids = _to_numeric(food_nutrient["fdc_id"])
    nutrient_ids = _to_numeric(food_nutrient["nutrient_id"])
    amounts = _to_numeric(food_nutrient["amount"])
    for fdc_id, nutrient_id, amount in zip(fdc_ids, nutrient_ids, amounts, strict=True):
        if pd.isna(fdc_id) or pd.isna(nutrient_id) or pd.isna(amount):
            continue
        code = id_to_code.get(_as_int(nutrient_id))
        if code is not None:
            present[_as_int(fdc_id)].add(code)
    return present


def _fndds_codes(
    fndds_ingredient: pd.DataFrame, code_by_nbr: Mapping[str, str]
) -> dict[int, set[str]]:
    filled: dict[int, set[str]] = defaultdict(set)
    ing_codes = _to_numeric(fndds_ingredient["Ingredient code"])
    nut_codes = _to_numeric(fndds_ingredient["Nutrient code"])
    values = _to_numeric(fndds_ingredient["Nutrient value"])
    for ing_code, nut_code, value in zip(ing_codes, nut_codes, values, strict=True):
        if pd.isna(ing_code) or pd.isna(nut_code) or pd.isna(value):
            continue
        code = code_by_nbr.get(str(_as_int(nut_code)))
        if code is not None:
            filled[_as_int(ing_code)].add(code)
    return filled


def index_sr_foods(
    food: pd.DataFrame,
    food_nutrient: pd.DataFrame,
    nutrient: pd.DataFrame,
    sr_legacy: pd.DataFrame,
    categories: pd.DataFrame,
    fndds_ingredient: pd.DataFrame,
    nutrients: Sequence[NutrientSeed],
) -> dict[str, LookupFood]:
    """Every SR Legacy food, with mandatory nutrients after the #93 FNDDS fill."""
    mandatory = [n for n in nutrients if n.is_mandatory and n.source_code]
    mandatory_codes = [n.code for n in mandatory]
    code_by_nbr = {n.source_code or "": n.code for n in mandatory}
    id_to_code = _id_to_code(nutrient, code_by_nbr)
    present = _present_codes(food_nutrient, id_to_code)
    fndds = _fndds_codes(fndds_ingredient, code_by_nbr)

    cat_by_id: dict[str, str] = {}
    for cat_id, description in zip(
        _to_numeric(categories["id"]), categories["description"], strict=True
    ):
        if pd.isna(cat_id):
            continue
        cat_by_id[str(_as_int(cat_id))] = str(description)

    ndb_by_fdc: dict[int, str] = {}
    for fdc_id, ndb in zip(
        _to_numeric(sr_legacy["fdc_id"]), _to_numeric(sr_legacy["NDB_number"]), strict=True
    ):
        if pd.isna(fdc_id) or pd.isna(ndb):
            continue
        ndb_by_fdc[_as_int(fdc_id)] = pad_ndb(_as_int(ndb))

    foods: dict[str, LookupFood] = {}
    descriptions = food["description"]
    category_ids = _to_numeric(food["food_category_id"])
    for fdc_id, description, category_id in zip(
        _to_numeric(food["fdc_id"]), descriptions, category_ids, strict=True
    ):
        if pd.isna(fdc_id):
            continue
        fdc = _as_int(fdc_id)
        ndb = ndb_by_fdc.get(fdc)
        if ndb is None:
            continue
        have = present.get(fdc, set())
        filled_codes = fndds.get(int(ndb), set())
        missing = tuple(code for code in mandatory_codes if code not in have)
        filled = tuple(code for code in missing if code in filled_codes)
        complete = len(filled) == len(missing)
        text = "" if pd.isna(description) else str(description)
        category_key = "" if pd.isna(category_id) else str(_as_int(category_id))
        foods[ndb] = LookupFood(
            ndb=ndb,
            description=text,
            category=cat_by_id.get(category_key, ""),
            missing_sr=missing,
            filled_fndds=filled,
            complete=complete,
            words=_name_words(text) if complete else frozenset(),
        )
    return foods


def _candidates(name: str, complete: Sequence[LookupFood]) -> list[LookupFood]:
    words = _name_words(name)
    ranked = sorted(complete, key=lambda food: (-len(words & food.words), int(food.ndb)))
    return list(ranked[:_MAX_CANDIDATES])


def format_ingredient_lookup(
    ingredients: CatalogIngredients, foods: Mapping[str, LookupFood]
) -> str:
    """One row per SR Legacy ingredient, sorted by code, with candidates underneath."""
    complete = [food for food in foods.values() if food.complete]
    lines = ["# Ingredient lookup", "", _HEADER]
    sr_ingredients = sorted(
        (
            ingredient
            for ingredient in ingredients.ingredients
            if ingredient.food.source is IngredientFoodSource.SR_LEGACY
        ),
        key=lambda ingredient: ingredient.code,
    )
    for ingredient in sr_ingredients:
        food = foods.get(ingredient.food.code)
        if food is None:
            cells = [
                ingredient.code,
                ingredient.name_en,
                ingredient.food.code,
                "",
                "",
                "",
                "",
                "NOT_FOUND",
            ]
            status_complete = False
        else:
            cells = [
                ingredient.code,
                ingredient.name_en,
                food.ndb,
                food.description,
                food.category,
                ", ".join(food.missing_sr),
                ", ".join(food.filled_fndds),
                "COMPLETE" if food.complete else "INCOMPLETE",
            ]
            status_complete = food.complete
        lines.append("")
        lines.append(" | ".join(_cell(cell) for cell in cells))
        if not status_complete:
            for candidate in _candidates(ingredient.name_en, complete):
                description = _cell(candidate.description)
                category = _cell(candidate.category)
                lines.append(f"  {candidate.ndb} | {description} | {category}")
    return "\n".join(lines) + "\n"
