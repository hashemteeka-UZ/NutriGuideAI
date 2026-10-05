"""Extract the Step F.1 food subset from the official USDA FDC SR Legacy CSV release.

Run from backend/:  uv run python -m scripts.f1_extract_fdc [--zip PATH]

Writes data/f1_slice/fdc_sr_legacy_subset.csv (one row per food per nutrient present in the
source; absent values are skipped, never written as 0 — §9.8) and
data/f1_slice/fdc_source_manifest.yaml (provenance, §14). The raw zip stays in data/raw/ and is
never committed.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import sys
import zipfile
from collections import defaultdict
from collections.abc import Iterator
from datetime import UTC, datetime
from pathlib import Path

import yaml

from app.seed.f1_files import (
    REFERENCE_SEED_FILE,
    SLICE_FOODS_FILE,
    SOURCE_MANIFEST_FILE,
    SUBSET_COLUMNS,
    SUBSET_CSV_FILE,
    read_reference_seed,
    read_slice_foods,
)

BACKEND_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BACKEND_DIR / "data" / "f1_slice"
RAW_DIR = BACKEND_DIR / "data" / "raw"
ZIP_GLOB = "FoodData_Central_sr_legacy_food_csv_*.zip"
DOWNLOAD_PAGE = "https://fdc.nal.usda.gov/download-datasets"
REQUIRED_CSVS = (
    "food.csv",
    "food_nutrient.csv",
    "nutrient.csv",
    "food_category.csv",
    "sr_legacy_food.csv",
)


class ExtractionError(Exception):
    pass


def _find_zip(explicit: Path | None) -> Path:
    if explicit is not None:
        if not explicit.is_file():
            raise ExtractionError(f"zip not found: {explicit}")
        return explicit
    matches = sorted(RAW_DIR.glob(ZIP_GLOB))
    if len(matches) != 1:
        raise ExtractionError(
            f"expected exactly one {ZIP_GLOB} in {RAW_DIR}, found {[m.name for m in matches]}"
        )
    return matches[0]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _member_names(archive: zipfile.ZipFile) -> dict[str, str]:
    """Map each required CSV file name to its path inside the zip, whatever the folder is."""
    found: dict[str, list[str]] = defaultdict(list)
    for member in archive.namelist():
        name = member.rsplit("/", 1)[-1]
        if name in REQUIRED_CSVS:
            found[name].append(member)
    problems = [
        f"{name}: {found.get(name, [])}" for name in REQUIRED_CSVS if len(found.get(name, [])) != 1
    ]
    if problems:
        raise ExtractionError(f"each CSV must appear exactly once in the zip: {problems}")
    return {name: paths[0] for name, paths in found.items()}


def _rows(archive: zipfile.ZipFile, member: str) -> Iterator[dict[str, str]]:
    with archive.open(member) as raw:
        yield from csv.DictReader(io.TextIOWrapper(raw, encoding="utf-8", newline=""))


def _ndb_key(value: str) -> int:
    # sr_legacy_food.csv stores NDB numbers without leading zeros ("1019" for "01019").
    return int(value)


def extract(zip_path: Path, data_dir: Path) -> tuple[list[dict[str, str]], dict[str, object]]:
    seed = read_reference_seed(data_dir / REFERENCE_SEED_FILE)
    foods = read_slice_foods(data_dir / SLICE_FOODS_FILE)
    wanted_nbrs = {n.source_code for n in seed.nutrients if n.source_code}

    with zipfile.ZipFile(zip_path) as archive:
        members = _member_names(archive)

        fdc_by_ndb: dict[int, int] = {}
        for row in _rows(archive, members["sr_legacy_food.csv"]):
            fdc_by_ndb[_ndb_key(row["NDB_number"])] = int(row["fdc_id"])
        missing_ndb = [
            f.ndb_number for f in foods.foods if _ndb_key(f.ndb_number) not in fdc_by_ndb
        ]
        if missing_ndb:
            raise ExtractionError(f"NDB numbers not found in sr_legacy_food.csv: {missing_ndb}")
        ndb_by_fdc = {fdc_by_ndb[_ndb_key(f.ndb_number)]: f.ndb_number for f in foods.foods}

        nbr_by_nutrient_id: dict[str, str] = {}
        ids_by_nbr: dict[str, list[str]] = defaultdict(list)
        for row in _rows(archive, members["nutrient.csv"]):
            if row["nutrient_nbr"] in wanted_nbrs:
                nbr_by_nutrient_id[row["id"]] = row["nutrient_nbr"]
                ids_by_nbr[row["nutrient_nbr"]].append(row["id"])
        missing_nbr = sorted(wanted_nbrs - set(ids_by_nbr))
        ambiguous = {nbr: ids for nbr, ids in ids_by_nbr.items() if len(ids) > 1}
        if missing_nbr or ambiguous:
            raise ExtractionError(
                f"nutrient_nbr not found: {missing_nbr}; nutrient_nbr with several ids: {ambiguous}"
            )

        categories = {row["id"]: row for row in _rows(archive, members["food_category.csv"])}
        food_info: dict[int, dict[str, str]] = {}
        for row in _rows(archive, members["food.csv"]):
            fdc_id = int(row["fdc_id"])
            if fdc_id in ndb_by_fdc:
                category = categories[row["food_category_id"]]
                food_info[fdc_id] = {
                    "description": row["description"],
                    "food_category_code": category["code"],
                    "food_category_description": category["description"],
                }
        missing_food = sorted(ndb_by_fdc[fdc] for fdc in set(ndb_by_fdc) - set(food_info))
        if missing_food:
            raise ExtractionError(
                f"fdc_id of these NDB numbers missing from food.csv: {missing_food}"
            )

        amounts: dict[tuple[int, str], str] = {}
        for row in _rows(archive, members["food_nutrient.csv"]):
            fdc_id = int(row["fdc_id"])
            nbr = nbr_by_nutrient_id.get(row["nutrient_id"])
            if fdc_id not in ndb_by_fdc or nbr is None or row["amount"].strip() == "":
                continue
            key = (fdc_id, nbr)
            if key in amounts:
                raise ExtractionError(f"duplicate food_nutrient row for fdc_id/nutrient_nbr {key}")
            amounts[key] = row["amount"].strip()

    out_rows = [
        {
            "ndb_number": ndb_by_fdc[fdc_id],
            "fdc_id": str(fdc_id),
            **food_info[fdc_id],
            "nutrient_nbr": nbr,
            "amount_per_100g": amount,
        }
        for (fdc_id, nbr), amount in amounts.items()
    ]
    out_rows.sort(key=lambda r: (r["ndb_number"], int(r["nutrient_nbr"])))
    manifest: dict[str, object] = {
        "source": "USDA FoodData Central, SR Legacy",
        "download_page": DOWNLOAD_PAGE,
        "zip_file": zip_path.name,
        "zip_sha256": _sha256(zip_path),
        "extracted_on": datetime.now(UTC).date().isoformat(),
        "script": "backend/scripts/f1_extract_fdc.py",
        "output_file": SUBSET_CSV_FILE,
        "foods": len(ndb_by_fdc),
        "row_count": len(out_rows),
    }
    return out_rows, manifest


def write_outputs(rows: list[dict[str, str]], manifest: dict[str, object], data_dir: Path) -> None:
    with (data_dir / SUBSET_CSV_FILE).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=SUBSET_COLUMNS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    with (data_dir / SOURCE_MANIFEST_FILE).open("w", encoding="utf-8", newline="\n") as handle:
        yaml.safe_dump(manifest, handle, sort_keys=False, allow_unicode=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--zip", type=Path, default=None, help=f"default: the one {ZIP_GLOB}")
    parser.add_argument("--data-dir", type=Path, default=DATA_DIR)
    args = parser.parse_args(argv)
    try:
        zip_path = _find_zip(args.zip)
        rows, manifest = extract(zip_path, args.data_dir)
    except ExtractionError as exc:
        print(f"f1_extract_fdc: {exc}", file=sys.stderr)
        return 1
    write_outputs(rows, manifest, args.data_dir)
    print(f"wrote {manifest['row_count']} rows for {manifest['foods']} foods from {zip_path.name}")
    print(f"zip sha256 {manifest['zip_sha256']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
