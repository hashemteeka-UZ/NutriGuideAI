"""pandera schemas for the raw SR Legacy and FNDDS tables used by the catalog pipeline."""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field

import pandas as pd
import pandera.pandas as pa

KEY_COLUMNS: dict[str, tuple[str, ...]] = {
    "food.csv": ("fdc_id", "description", "food_category_id"),
    "food_nutrient.csv": ("fdc_id", "nutrient_id", "amount"),
    "nutrient.csv": ("id", "nutrient_nbr"),
    "Ingredient Nutrient Values": ("Ingredient code", "Nutrient code", "Nutrient value"),
    "FNDDS Nutrient Values": ("Food code", "Main food description"),
    "Portions and Weights": ("Food code", "Portion weight (g)"),
    "Foods and Beverages": ("Food code", "Main food description"),
}


def _int() -> pa.Column:
    return pa.Column(int, nullable=False, coerce=True)


def _str() -> pa.Column:
    return pa.Column(str, nullable=False, coerce=True)


def _nonneg(nullable: bool = False) -> pa.Column:
    return pa.Column(float, nullable=nullable, coerce=True, checks=pa.Check.ge(0))


SR_FOOD = pa.DataFrameSchema(
    {
        "fdc_id": pa.Column(int, nullable=False, coerce=True, unique=True),
        "description": _str(),
        "food_category_id": _int(),
    },
    coerce=True,
    strict=False,
)

SR_FOOD_NUTRIENT = pa.DataFrameSchema(
    {
        "fdc_id": _int(),
        "nutrient_id": _int(),
        "amount": _nonneg(nullable=True),
    },
    coerce=True,
    strict=False,
    unique=["fdc_id", "nutrient_id"],
)

SR_NUTRIENT = pa.DataFrameSchema(
    {
        "id": pa.Column(int, nullable=False, coerce=True, unique=True),
        "name": _str(),
        "nutrient_nbr": pa.Column(str, nullable=True, coerce=True),
    },
    coerce=True,
    strict=False,
)

FNDDS_INGREDIENT_NUTRIENTS = pa.DataFrameSchema(
    {
        "Ingredient code": _int(),
        "Nutrient code": _int(),
        "Nutrient value": _nonneg(),
    },
    coerce=True,
    strict=False,
    unique=["Ingredient code", "Nutrient code"],
)

FNDDS_FOODS = pa.DataFrameSchema(
    {
        "Food code": pa.Column(int, nullable=False, coerce=True, unique=True),
        "Main food description": _str(),
    },
    coerce=True,
    strict=False,
)

FNDDS_PORTIONS = pa.DataFrameSchema(
    {
        "Food code": _int(),
        "Seq num": _int(),
        "Portion weight (g)": _nonneg(),
    },
    coerce=True,
    strict=False,
    unique=["Food code", "Seq num"],
)


def fndds_nutrient_values_schema(columns: Iterable[str]) -> pa.DataFrameSchema:
    """Wide FNDDS nutrient table: Food code unique; every numeric nutrient column >= 0."""
    skip = {
        "Food code",
        "Main food description",
        "WWEIA Category number",
        "WWEIA Category description",
    }
    fields: dict[str, pa.Column] = {
        "Food code": pa.Column(int, nullable=False, coerce=True, unique=True),
        "Main food description": _str(),
    }
    for name in columns:
        if name in skip or name in fields:
            continue
        fields[name] = _nonneg(nullable=True)
    return pa.DataFrameSchema(fields, coerce=True, strict=False)


@dataclass
class SchemaIssue:
    table: str
    row: int | None
    column: str | None
    message: str

    def format(self) -> str:
        parts = [self.table]
        if self.row is not None:
            parts.append(f"row {self.row}")
        if self.column:
            parts.append(f"column {self.column}")
        return f"{' '.join(parts)}: {self.message}"


@dataclass
class TableProfile:
    name: str
    rows: int
    columns: list[str]
    null_counts: dict[str, int]
    duplicate_keys: int
    issues: list[SchemaIssue] = field(default_factory=list)


def normalize_columns(frame: pd.DataFrame) -> pd.DataFrame:
    out = frame.copy()
    out.columns = [str(col).replace("\n", " ").strip() for col in out.columns]
    return out


def profile_table(
    name: str,
    frame: pd.DataFrame,
    schema: pa.DataFrameSchema,
    key_columns: Sequence[str] | None = None,
) -> TableProfile:
    keys = key_columns if key_columns is not None else KEY_COLUMNS.get(name, ())
    null_counts = {
        col: int(frame[col].isna().sum()) if col in frame.columns else len(frame) for col in keys
    }
    duplicate_keys = 0
    unique_cols = schema.unique
    if unique_cols:
        cols = list(unique_cols) if not isinstance(unique_cols, str) else [unique_cols]
        if all(col in frame.columns for col in cols):
            duplicate_keys = int(frame.duplicated(subset=cols).sum())
    for col_name, column in schema.columns.items():
        if column.unique and col_name in frame.columns:
            duplicate_keys = max(duplicate_keys, int(frame.duplicated(subset=[col_name]).sum()))

    issues = _validate_lazy(name, frame, schema)
    return TableProfile(
        name=name,
        rows=len(frame),
        columns=[str(c) for c in frame.columns],
        null_counts=null_counts,
        duplicate_keys=duplicate_keys,
        issues=issues,
    )


def _validate_lazy(name: str, frame: pd.DataFrame, schema: pa.DataFrameSchema) -> list[SchemaIssue]:
    try:
        schema.validate(frame, lazy=True)
    except pa.errors.SchemaErrors as exc:
        issues: list[SchemaIssue] = []
        failures = exc.failure_cases
        for rec in failures.to_dict(orient="records"):
            index = rec.get("index")
            row = int(index) if index is not None and not pd.isna(index) else None
            column = rec.get("column")
            column_name = None if column is None or pd.isna(column) else str(column)
            check = rec.get("check")
            failure = rec.get("failure_case")
            issues.append(
                SchemaIssue(
                    table=name,
                    row=row,
                    column=column_name,
                    message=f"{check} failed ({failure!r})",
                )
            )
        return issues
    return []
