"""Extract SR Legacy / FNDDS subsets and write the raw-table profile (#93).

uv run python -m app.pipeline.extract [--profile-only] [--data-dir PATH] [--raw-dir PATH]
"""

from __future__ import annotations

import argparse
import sys
import zipfile
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import pandas as pd
import yaml

from app.pipeline.files import (
    FDC_DOWNLOAD_PAGE,
    FNDDS_DOWNLOAD_PAGE,
    FNDDS_SUBSET_COLUMNS,
    FNDDS_SUBSET_FILE,
    INGREDIENTS_FILE,
    REFERENCE_SEED_FILE,
    REPORTS_DIR,
    SOURCE_MANIFEST_FILE,
    SOURCES_DIR,
    SR_SUBSET_FILE,
    SUBSET_COLUMNS,
    CatalogIngredients,
    CatalogReferenceSeed,
    pad_ndb,
    read_catalog_reference_seed,
    sha256_file,
    write_csv,
    write_yaml,
)
from app.pipeline.lookup import LOOKUP_REPORT_FILE, format_ingredient_lookup, index_sr_foods
from app.pipeline.profile import (
    FNDDS_FOODS,
    FNDDS_INGREDIENT_NUTRIENTS,
    FNDDS_PORTIONS,
    SR_FOOD,
    SR_FOOD_NUTRIENT,
    SR_NUTRIENT,
    TableProfile,
    fndds_nutrient_values_schema,
    normalize_columns,
    profile_table,
)
from app.seed.f1_files import NutrientSeed
from scripts.f1_extract_fdc import REQUIRED_CSVS, ZIP_GLOB, ExtractionError, _member_names

FNDDS_DIRNAME = "fndds"
FNDDS_FILENAMES = (
    "FNDDS Ingredients.xlsx",
    "FNDDS Nutrient Values.xlsx",
    "Foods and Beverages.xlsx",
    "Ingredient Nutrient Values.xlsx",
    "Portions and Weights.xlsx",
)
FNDDS_SHEETS = {
    "FNDDS Ingredients.xlsx": "FNDDS Ingredients",
    "FNDDS Nutrient Values.xlsx": "FNDDS Nutrient Values",
    "Foods and Beverages.xlsx": "Food and Beverages",
    "Ingredient Nutrient Values.xlsx": "Ingredient Nutrient Values",
    "Portions and Weights.xlsx": "Portions and Weights",
}
F_03_CASES = (("17013", "lamb"), ("20028", "dry couscous"))
AGREEMENT_TOLERANCE = 0.05
RAW_PROFILE_FILE = "raw_profile.md"
DEFAULT_DATA_DIR = Path(__file__).resolve().parents[2] / "data" / "catalog"
DEFAULT_RAW_DIR = Path(__file__).resolve().parents[2] / "data" / "raw"


class ExtractError(Exception):
    pass


@dataclass
class GapRow:
    nutrient_code: str
    source_code: str
    sr_missing: int
    fndds_fills: int


@dataclass
class CaseRow:
    ndb: str
    label: str
    sr_missing: list[str]
    fndds_values: dict[str, float]


@dataclass
class Feasibility:
    sr_foods: int
    foods_missing_any: int
    gaps: int
    gaps_filled: int
    per_nutrient: list[GapRow]
    cases: list[CaseRow]
    agreement_pairs: int
    agreement_disagree: int


@dataclass
class ExtractResult:
    profiles: list[TableProfile]
    feasibility: Feasibility
    manifest: dict[str, Any]
    subset_rows: dict[str, int] = field(default_factory=dict)


def read_sr_tables(zip_path: Path) -> dict[str, pd.DataFrame]:
    with zipfile.ZipFile(zip_path) as archive:
        members = _member_names(archive)
        tables = {
            name: pd.read_csv(archive.open(members[name]), dtype=str) for name in REQUIRED_CSVS
        }
    return tables


def read_fndds_sheet(path: Path, sheet: str) -> pd.DataFrame:
    frame = pd.read_excel(path, sheet_name=sheet, header=1, engine="openpyxl")
    return normalize_columns(frame)


def locate_sr_zip(raw_dir: Path) -> Path:
    matches = sorted(raw_dir.glob(ZIP_GLOB))
    if len(matches) != 1:
        raise ExtractError(
            f"expected exactly one {ZIP_GLOB} in {raw_dir}, found {[m.name for m in matches]}"
        )
    return matches[0]


def locate_fndds(raw_dir: Path) -> dict[str, Path]:
    folder = raw_dir / FNDDS_DIRNAME
    found: dict[str, Path] = {}
    missing: list[str] = []
    for name in FNDDS_FILENAMES:
        path = folder / name
        if path.is_file():
            found[name] = path
        else:
            missing.append(name)
    if missing:
        raise ExtractError(f"FNDDS files missing or named differently in {folder}: {missing}")
    return found


def _raw_manifest_entry(path: Path, download_page: str, extracted_on: str) -> dict[str, str | int]:
    return {
        "name": path.name,
        "size_bytes": path.stat().st_size,
        "sha256": sha256_file(path),
        "download_page": download_page,
        "extracted_on": extracted_on,
    }


def _to_numeric(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


def _as_int(value: object) -> int:
    return int(float(str(value)))


def _as_float(value: object) -> float:
    return float(str(value))


def feasibility_report(
    food: pd.DataFrame,
    food_nutrient: pd.DataFrame,
    nutrient: pd.DataFrame,
    sr_legacy: pd.DataFrame,
    fndds_ingredient: pd.DataFrame,
    nutrients: Sequence[NutrientSeed],
) -> Feasibility:
    mandatory = [n for n in nutrients if n.is_mandatory and n.source_code]
    nbrs = {n.source_code for n in mandatory}
    code_by_nbr = {n.source_code: n.code for n in mandatory}

    nutrient = nutrient.copy()
    nutrient["id"] = _to_numeric(nutrient["id"])
    nutrient["nutrient_nbr"] = nutrient["nutrient_nbr"].astype(str).str.strip()
    id_to_nbr: dict[int, str] = {}
    for nid, nbr in zip(nutrient["id"], nutrient["nutrient_nbr"], strict=True):
        text = str(nbr).strip()
        if not text or not text.replace(".", "", 1).isdigit():
            continue
        id_to_nbr[_as_int(nid)] = str(_as_int(text))
    # nutrient_nbr in SR is stored as "208" or "208.0"; keep integer form as text
    id_to_nbr = {k: v.split(".")[0] if "." in v else v for k, v in id_to_nbr.items()}
    wanted_ids = {nid: nbr for nid, nbr in id_to_nbr.items() if nbr in nbrs}

    sr_legacy = sr_legacy.copy()
    sr_legacy["fdc_id"] = _to_numeric(sr_legacy["fdc_id"]).astype("Int64")
    sr_legacy["NDB_number"] = _to_numeric(sr_legacy["NDB_number"]).astype("Int64")
    ndb_by_fdc = {
        _as_int(fdc): _as_int(ndb)
        for fdc, ndb in zip(sr_legacy["fdc_id"], sr_legacy["NDB_number"], strict=True)
        if pd.notna(fdc) and pd.notna(ndb)
    }

    food = food.copy()
    food["fdc_id"] = _to_numeric(food["fdc_id"]).astype("Int64")
    sr_fdc = [fdc for fdc in food["fdc_id"].dropna().astype(int).tolist() if fdc in ndb_by_fdc]
    sr_foods = len(sr_fdc)

    fn = food_nutrient.copy()
    fn["fdc_id"] = _to_numeric(fn["fdc_id"]).astype("Int64")
    fn["nutrient_id"] = _to_numeric(fn["nutrient_id"]).astype("Int64")
    fn["amount"] = _to_numeric(fn["amount"])
    present: dict[int, dict[str, float]] = defaultdict(dict)
    for fdc_id, nutrient_id, amount in zip(
        fn["fdc_id"], fn["nutrient_id"], fn["amount"], strict=True
    ):
        if pd.isna(fdc_id) or pd.isna(nutrient_id) or pd.isna(amount):
            continue
        nbr = wanted_ids.get(_as_int(nutrient_id))
        if nbr is None:
            continue
        present[_as_int(fdc_id)][nbr] = _as_float(amount)

    fndds = fndds_ingredient.copy()
    fndds["Ingredient code"] = _to_numeric(fndds["Ingredient code"]).astype("Int64")
    fndds["Nutrient code"] = _to_numeric(fndds["Nutrient code"]).astype("Int64")
    fndds["Nutrient value"] = _to_numeric(fndds["Nutrient value"])
    fndds_values: dict[int, dict[str, float]] = defaultdict(dict)
    for ing_code, nut_code, value in zip(
        fndds["Ingredient code"],
        fndds["Nutrient code"],
        fndds["Nutrient value"],
        strict=True,
    ):
        if pd.isna(ing_code) or pd.isna(nut_code) or pd.isna(value):
            continue
        fndds_values[int(ing_code)][str(int(nut_code))] = float(value)

    missing_any = 0
    gaps = 0
    gaps_filled = 0
    per_missing: dict[str, int] = {n.source_code or "": 0 for n in mandatory}
    per_filled: dict[str, int] = {n.source_code or "": 0 for n in mandatory}
    agreement_pairs = 0
    agreement_disagree = 0

    for fdc_id in sr_fdc:
        ndb = ndb_by_fdc[fdc_id]
        have = present.get(fdc_id, {})
        food_missing = False
        for n in mandatory:
            nbr = n.source_code or ""
            if nbr in have:
                fndds_amount = fndds_values.get(ndb, {}).get(nbr)
                if fndds_amount is not None:
                    agreement_pairs += 1
                    sr_amount = have[nbr]
                    if sr_amount == 0:
                        differ = fndds_amount != 0
                    else:
                        differ = (
                            abs(fndds_amount - sr_amount) / abs(sr_amount) > AGREEMENT_TOLERANCE
                        )
                    if differ:
                        agreement_disagree += 1
                continue
            food_missing = True
            gaps += 1
            per_missing[nbr] += 1
            if nbr in fndds_values.get(ndb, {}):
                gaps_filled += 1
                per_filled[nbr] += 1
        if food_missing:
            missing_any += 1

    cases: list[CaseRow] = []
    fdc_by_ndb = {ndb: fdc for fdc, ndb in ndb_by_fdc.items()}
    for ndb_text, label in F_03_CASES:
        ndb = int(ndb_text)
        case_fdc = fdc_by_ndb.get(ndb)
        have = present.get(case_fdc, {}) if case_fdc is not None else {}
        missing = [
            code_by_nbr[n.source_code or ""] for n in mandatory if (n.source_code or "") not in have
        ]
        fndds_for = {
            code_by_nbr[nbr]: amount
            for nbr, amount in fndds_values.get(ndb, {}).items()
            if nbr in nbrs
        }
        cases.append(
            CaseRow(
                ndb=ndb_text,
                label=label,
                sr_missing=missing,
                fndds_values={code: fndds_for[code] for code in missing if code in fndds_for},
            )
        )

    per_nutrient = [
        GapRow(
            nutrient_code=n.code,
            source_code=n.source_code or "",
            sr_missing=per_missing[n.source_code or ""],
            fndds_fills=per_filled[n.source_code or ""],
        )
        for n in mandatory
    ]
    return Feasibility(
        sr_foods=sr_foods,
        foods_missing_any=missing_any,
        gaps=gaps,
        gaps_filled=gaps_filled,
        per_nutrient=per_nutrient,
        cases=cases,
        agreement_pairs=agreement_pairs,
        agreement_disagree=agreement_disagree,
    )


def profile_raw_tables(
    sr_tables: dict[str, pd.DataFrame], fndds_tables: dict[str, pd.DataFrame]
) -> list[TableProfile]:
    profiles = [
        profile_table("food.csv", sr_tables["food.csv"], SR_FOOD),
        profile_table("food_nutrient.csv", sr_tables["food_nutrient.csv"], SR_FOOD_NUTRIENT),
        profile_table("nutrient.csv", sr_tables["nutrient.csv"], SR_NUTRIENT),
        profile_table(
            "Ingredient Nutrient Values",
            fndds_tables["Ingredient Nutrient Values"],
            FNDDS_INGREDIENT_NUTRIENTS,
        ),
        profile_table(
            "FNDDS Nutrient Values",
            fndds_tables["FNDDS Nutrient Values"],
            fndds_nutrient_values_schema(fndds_tables["FNDDS Nutrient Values"].columns),
        ),
        profile_table("Portions and Weights", fndds_tables["Portions and Weights"], FNDDS_PORTIONS),
        profile_table("Foods and Beverages", fndds_tables["Food and Beverages"], FNDDS_FOODS),
    ]
    return profiles


def format_raw_profile(profiles: Sequence[TableProfile], feasibility: Feasibility) -> str:
    lines = ["# Raw table profile", ""]
    for prof in profiles:
        lines.append(f"## {prof.name}")
        lines.append(f"- rows: {prof.rows}")
        lines.append(f"- columns: {len(prof.columns)}")
        lines.append("- null counts of key columns:")
        if prof.null_counts:
            for col, count in prof.null_counts.items():
                lines.append(f"  - {col}: {count}")
        else:
            lines.append("  - (none)")
        lines.append(
            f"- schema errors: {len(prof.issues)}"
            + (" (expected: none)" if not prof.issues else "")
        )
        for issue in prof.issues:
            lines.append(f"  - {issue.format()}")
        lines.append(f"- duplicate keys: {prof.duplicate_keys}")
        lines.append("")
    lines.append("## #93 Feasibility: SR mandatory-nutrient gaps vs FNDDS ingredient fill")
    lines.append("")
    lines.append(f"- SR Legacy foods: {feasibility.sr_foods}")
    lines.append(
        f"- foods missing at least one mandatory nutrient: {feasibility.foods_missing_any}"
    )
    lines.append(f"- missing (food, nutrient) gaps: {feasibility.gaps}")
    lines.append(
        f"- of those gaps, FNDDS Ingredient Nutrient Values fills: {feasibility.gaps_filled}"
    )
    lines.append("")
    lines.append("### Per-nutrient")
    lines.append("")
    lines.append("| nutrient | source_code | SR foods missing | of which FNDDS fills |")
    lines.append("|---|---|---:|---:|")
    for row in feasibility.per_nutrient:
        lines.append(
            f"| {row.nutrient_code} | {row.source_code} | {row.sr_missing} | {row.fndds_fills} |"
        )
    lines.append("")
    lines.append("### F-03 cases")
    lines.append("")
    for case in feasibility.cases:
        lines.append(f"#### NDB {case.ndb} ({case.label})")
        if case.sr_missing:
            lines.append(f"- SR lacks: {', '.join(case.sr_missing)}")
        else:
            lines.append("- SR lacks: (none)")
        if case.fndds_values:
            values = ", ".join(f"{code} = {value:g}" for code, value in case.fndds_values.items())
            lines.append(f"- FNDDS values: {values}")
        else:
            lines.append("- FNDDS values: (none for the nutrients SR lacks)")
        lines.append("")
    lines.append("### Agreement")
    lines.append("")
    lines.append(
        f"FNDDS values for nutrients SR also publishes that differ by more than 5%: "
        f"{feasibility.agreement_disagree} of {feasibility.agreement_pairs}"
    )
    lines.append("")
    return "\n".join(lines)


def _write_subsets(
    data_dir: Path,
    ingredients: CatalogIngredients,
    seed: CatalogReferenceSeed,
    sr_tables: dict[str, pd.DataFrame],
    fndds_ingredient: pd.DataFrame,
) -> dict[str, dict[str, int | str]]:
    wanted_ndbs = {
        int(ing.food.code)
        for ing in ingredients.ingredients
        if ing.food.source.value == "SR_LEGACY"
    }
    wanted_nbrs = {n.source_code for n in seed.nutrients if n.source_code}
    food = sr_tables["food.csv"]
    sr_legacy = sr_tables["sr_legacy_food.csv"]
    categories = sr_tables["food_category.csv"]
    nutrient = sr_tables["nutrient.csv"]
    food_nutrient = sr_tables["food_nutrient.csv"]

    fdc_by_ndb: dict[int, int] = {}
    for _, row in sr_legacy.iterrows():
        ndb = int(float(row["NDB_number"]))
        if ndb in wanted_ndbs:
            fdc_by_ndb[ndb] = int(float(row["fdc_id"]))
    missing = sorted(wanted_ndbs - set(fdc_by_ndb))
    if missing:
        raise ExtractError(f"NDB numbers not found in sr_legacy_food.csv: {missing}")
    ndb_by_fdc = {fdc: ndb for ndb, fdc in fdc_by_ndb.items()}

    cat_by_id = {str(row["id"]): row for _, row in categories.iterrows()}
    food_info: dict[int, dict[str, str]] = {}
    for _, row in food.iterrows():
        fdc_id = int(float(row["fdc_id"]))
        if fdc_id not in ndb_by_fdc:
            continue
        category = cat_by_id[str(int(float(row["food_category_id"])))]
        food_info[fdc_id] = {
            "description": str(row["description"]),
            "food_category_code": str(category["code"]),
            "food_category_description": str(category["description"]),
        }

    nbr_by_id: dict[int, str] = {}
    for _, row in nutrient.iterrows():
        nbr = str(row["nutrient_nbr"]).strip()
        if not nbr:
            continue
        nbr = str(int(float(nbr))) if nbr.replace(".", "", 1).isdigit() else nbr
        if nbr in wanted_nbrs:
            nbr_by_id[int(float(row["id"]))] = nbr

    sr_rows: list[dict[str, str]] = []
    for _, row in food_nutrient.iterrows():
        fdc_id = int(float(row["fdc_id"]))
        if fdc_id not in ndb_by_fdc:
            continue
        amount = str(row["amount"]).strip()
        if amount == "":
            continue
        nid = int(float(row["nutrient_id"]))
        mapped_nbr = nbr_by_id.get(nid)
        if mapped_nbr is None:
            continue
        sr_rows.append(
            {
                "ndb_number": pad_ndb(ndb_by_fdc[fdc_id]),
                "fdc_id": str(fdc_id),
                **food_info[fdc_id],
                "nutrient_nbr": mapped_nbr,
                "amount_per_100g": amount,
            }
        )
    sr_rows.sort(key=lambda r: (r["ndb_number"], int(r["nutrient_nbr"])))

    fndds_rows: list[dict[str, str]] = []
    for _, row in fndds_ingredient.iterrows():
        if pd.isna(row["Ingredient code"]) or pd.isna(row["Nutrient code"]):
            continue
        ndb = int(row["Ingredient code"])
        if ndb not in wanted_ndbs:
            continue
        nbr = str(int(row["Nutrient code"]))
        if nbr not in wanted_nbrs:
            continue
        if pd.isna(row["Nutrient value"]):
            continue
        fndds_rows.append(
            {
                "ndb_number": pad_ndb(ndb),
                "nutrient_nbr": nbr,
                "amount_per_100g": str(row["Nutrient value"]),
            }
        )
    fndds_rows.sort(key=lambda r: (r["ndb_number"], int(r["nutrient_nbr"])))

    sources = data_dir / SOURCES_DIR
    write_csv(sources / SR_SUBSET_FILE, SUBSET_COLUMNS, sr_rows)
    write_csv(sources / FNDDS_SUBSET_FILE, FNDDS_SUBSET_COLUMNS, fndds_rows)
    return {
        SR_SUBSET_FILE: {
            "sha256": sha256_file(sources / SR_SUBSET_FILE),
            "row_count": len(sr_rows),
        },
        FNDDS_SUBSET_FILE: {
            "sha256": sha256_file(sources / FNDDS_SUBSET_FILE),
            "row_count": len(fndds_rows),
        },
    }


def run_extract(
    data_dir: Path,
    raw_dir: Path,
    *,
    profile_only: bool = False,
    extracted_on: str | None = None,
) -> ExtractResult:
    extracted_on = extracted_on or datetime.now(UTC).date().isoformat()
    zip_path = locate_sr_zip(raw_dir)

    fndds_paths = locate_fndds(raw_dir)
    seed_path = data_dir / REFERENCE_SEED_FILE
    if not seed_path.is_file():
        raise ExtractError(f"missing {REFERENCE_SEED_FILE} in {data_dir}")
    seed = read_catalog_reference_seed(seed_path)

    sr_tables = read_sr_tables(zip_path)
    fndds_tables = {
        FNDDS_SHEETS[name]: read_fndds_sheet(path, FNDDS_SHEETS[name])
        for name, path in fndds_paths.items()
        if name != "FNDDS Ingredients.xlsx"
    }
    # Always read Ingredient Nutrient Values (used by profile + feasibility + subsets).
    if "Ingredient Nutrient Values" not in fndds_tables:
        fndds_tables["Ingredient Nutrient Values"] = read_fndds_sheet(
            fndds_paths["Ingredient Nutrient Values.xlsx"], "Ingredient Nutrient Values"
        )

    profiles = profile_raw_tables(sr_tables, fndds_tables)
    feasibility = feasibility_report(
        sr_tables["food.csv"],
        sr_tables["food_nutrient.csv"],
        sr_tables["nutrient.csv"],
        sr_tables["sr_legacy_food.csv"],
        fndds_tables["Ingredient Nutrient Values"],
        seed.nutrients,
    )

    raw_files = [
        _raw_manifest_entry(zip_path, FDC_DOWNLOAD_PAGE, extracted_on),
        *[
            _raw_manifest_entry(fndds_paths[name], FNDDS_DOWNLOAD_PAGE, extracted_on)
            for name in FNDDS_FILENAMES
        ],
    ]
    manifest: dict[str, Any] = {"raw_files": raw_files, "subsets": {}}
    subset_rows: dict[str, int] = {}
    if not profile_only:
        ingredients_path = data_dir / INGREDIENTS_FILE
        if not ingredients_path.is_file():
            raise ExtractError(f"{INGREDIENTS_FILE} is required unless --profile-only")
        ingredients = CatalogIngredients.model_validate(
            yaml.safe_load(ingredients_path.read_text(encoding="utf-8"))
        )
        # Lookup is written even when some NDB numbers are missing. The subset
        # step below still fails and lists every unknown number together.
        reports_dir = data_dir / REPORTS_DIR
        reports_dir.mkdir(parents=True, exist_ok=True)
        foods = index_sr_foods(
            sr_tables["food.csv"],
            sr_tables["food_nutrient.csv"],
            sr_tables["nutrient.csv"],
            sr_tables["sr_legacy_food.csv"],
            sr_tables["food_category.csv"],
            fndds_tables["Ingredient Nutrient Values"],
            seed.nutrients,
        )
        (reports_dir / LOOKUP_REPORT_FILE).write_text(
            format_ingredient_lookup(ingredients, foods), encoding="utf-8"
        )
        subsets = _write_subsets(
            data_dir, ingredients, seed, sr_tables, fndds_tables["Ingredient Nutrient Values"]
        )
        manifest["subsets"] = subsets
        subset_rows = {name: int(info["row_count"]) for name, info in subsets.items()}

    reports_dir = data_dir / REPORTS_DIR
    reports_dir.mkdir(parents=True, exist_ok=True)
    (reports_dir / RAW_PROFILE_FILE).write_text(
        format_raw_profile(profiles, feasibility), encoding="utf-8"
    )
    write_yaml(data_dir / SOURCES_DIR / SOURCE_MANIFEST_FILE, manifest)
    return ExtractResult(
        profiles=profiles, feasibility=feasibility, manifest=manifest, subset_rows=subset_rows
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Profile raw USDA files and extract catalog subsets."
    )
    parser.add_argument("--profile-only", action="store_true")
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    parser.add_argument("--raw-dir", type=Path, default=DEFAULT_RAW_DIR)
    args = parser.parse_args(argv)
    try:
        result = run_extract(args.data_dir, args.raw_dir, profile_only=args.profile_only)
    except (ExtractError, ExtractionError, OSError) as exc:
        print(f"extract: {exc}", file=sys.stderr)
        return 1
    issues = sum(len(p.issues) for p in result.profiles)
    print(
        f"wrote {REPORTS_DIR}/{RAW_PROFILE_FILE}; "
        f"{result.feasibility.sr_foods} SR foods; "
        f"{result.feasibility.foods_missing_any} missing a mandatory nutrient; "
        f"{issues} schema errors"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
