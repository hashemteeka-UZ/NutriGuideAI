"""Builders for catalog pipeline tests (tiny raw files and fixture copies)."""

from __future__ import annotations

import csv
import io
import shutil
import zipfile
from pathlib import Path

from openpyxl import Workbook

MINI_CATALOG = Path(__file__).resolve().parents[1] / "fixtures" / "catalog_mini"

NUTRIENTS = (
    (1003, "Protein", "203"),
    (1004, "Total lipid (fat)", "204"),
    (1005, "Carbohydrate", "205"),
    (1008, "Energy", "208"),
    (1012, "Fiber", "291"),
    (1013, "Sugars", "269"),
    (1093, "Sodium", "307"),
    (1258, "Saturated fat", "606"),
    (1253, "Cholesterol", "601"),
)

FNDDS_FILES = {
    "FNDDS Ingredients.xlsx": ("FNDDS Ingredients", ["Food code", "Ingredient code"]),
    "FNDDS Nutrient Values.xlsx": (
        "FNDDS Nutrient Values",
        ["Food code", "Main food description", "Energy (kcal)", "Protein (g)"],
    ),
    "Foods and Beverages.xlsx": (
        "Food and Beverages",
        ["Food code", "Main food description"],
    ),
    "Ingredient Nutrient Values.xlsx": (
        "Ingredient Nutrient Values",
        ["Ingredient code", "Nutrient code", "Nutrient value"],
    ),
    "Portions and Weights.xlsx": (
        "Portions and Weights",
        ["Food code", "Seq num", "Portion weight (g)"],
    ),
}


def copy_mini(tmp_path: Path) -> Path:
    target = tmp_path / "catalog"
    shutil.copytree(MINI_CATALOG, target)
    return target


def write_xlsx(path: Path, sheet: str, headers: list[str], rows: list[list[object]]) -> None:
    workbook = Workbook()
    worksheet = workbook.active
    assert worksheet is not None
    worksheet.title = sheet
    worksheet.append([f"{sheet} title row"])
    worksheet.append(headers)
    for row in rows:
        worksheet.append(row)
    path.parent.mkdir(parents=True, exist_ok=True)
    workbook.save(path)


def write_fndds_dir(
    raw_dir: Path,
    *,
    ingredient_nutrients: list[list[object]] | None = None,
    nutrient_values: list[list[object]] | None = None,
    foods: list[list[object]] | None = None,
    portions: list[list[object]] | None = None,
) -> Path:
    folder = raw_dir / "fndds"
    folder.mkdir(parents=True, exist_ok=True)
    extra = {
        "Ingredient Nutrient Values.xlsx": ingredient_nutrients or [],
        "FNDDS Nutrient Values.xlsx": nutrient_values or [[11100000, "Milk, NFS", 52, 3.33]],
        "Foods and Beverages.xlsx": foods or [[11100000, "Milk, NFS"]],
        "Portions and Weights.xlsx": portions or [[11100000, 1, 246]],
        "FNDDS Ingredients.xlsx": [],
    }
    for name, (sheet, headers) in FNDDS_FILES.items():
        write_xlsx(folder / name, sheet, headers, extra[name])
    return folder


def write_sr_zip(
    raw_dir: Path,
    *,
    foods: list[tuple[int, int, str, int]],
    food_nutrients: list[tuple[int, int, float]],
    categories: list[tuple[int, str, str]] | None = None,
) -> Path:
    """foods: (fdc_id, ndb, description, category_id). nutrients: (fdc_id, id, amount)."""
    categories = categories or [(17, "1700", "Lamb, Veal, and Game Products")]
    buf = io.BytesIO()
    prefix = "FoodData_Central_sr_legacy_food_csv_2018-04/"
    with zipfile.ZipFile(buf, "w") as archive:
        _add_csv(
            archive,
            prefix + "food.csv",
            ["fdc_id", "data_type", "description", "food_category_id", "publication_date"],
            [[fdc, "sr_legacy_food", desc, cat, "2019-04-01"] for fdc, _ndb, desc, cat in foods],
        )
        _add_csv(
            archive,
            prefix + "sr_legacy_food.csv",
            ["fdc_id", "NDB_number"],
            [[fdc, ndb] for fdc, ndb, _desc, _cat in foods],
        )
        _add_csv(
            archive,
            prefix + "food_category.csv",
            ["id", "code", "description"],
            [list(row) for row in categories],
        )
        _add_csv(
            archive,
            prefix + "nutrient.csv",
            ["id", "name", "unit_name", "nutrient_nbr", "rank"],
            [[nid, name, "G", nbr, "1"] for nid, name, nbr in NUTRIENTS],
        )
        _add_csv(
            archive,
            prefix + "food_nutrient.csv",
            [
                "id",
                "fdc_id",
                "nutrient_id",
                "amount",
                "data_points",
                "derivation_id",
                "min",
                "max",
                "median",
                "footnote",
                "min_year_acquired",
            ],
            [
                [index, fdc, nid, amount, 1, 46, "", "", "", "", ""]
                for index, (fdc, nid, amount) in enumerate(food_nutrients, start=1)
            ],
        )
    raw_dir.mkdir(parents=True, exist_ok=True)
    path = raw_dir / "FoodData_Central_sr_legacy_food_csv_2018-04.zip"
    path.write_bytes(buf.getvalue())
    return path


def _add_csv(
    archive: zipfile.ZipFile, name: str, header: list[str], rows: list[list[object]]
) -> None:
    text = io.StringIO()
    writer = csv.writer(text, lineterminator="\n")
    writer.writerow(header)
    writer.writerows(rows)
    archive.writestr(name, text.getvalue())


def complete_nutrients(
    fdc_id: int, *, skip: set[str] | None = None
) -> list[tuple[int, int, float]]:
    skip = skip or set()
    amounts = {
        "203": 10.0,
        "204": 1.0,
        "205": 5.0,
        "208": 70.0,
        "291": 0.0,
        "269": 2.0,
        "307": 20.0,
        "606": 0.3,
        "601": 4.0,
    }
    id_by_nbr = {nbr: nid for nid, _name, nbr in NUTRIENTS}
    return [(fdc_id, id_by_nbr[nbr], value) for nbr, value in amounts.items() if nbr not in skip]
