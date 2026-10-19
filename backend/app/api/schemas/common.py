"""Shared contract types: pages, clock times, date ranges, and nutrient totals."""

from __future__ import annotations

import re
from datetime import date, time
from typing import Annotated, Any

from pydantic import (
    BaseModel,
    BeforeValidator,
    ConfigDict,
    Field,
    PlainSerializer,
    WithJsonSchema,
    model_validator,
)


class ValidationIssue(BaseModel):
    loc: list[str | int]
    msg: str
    type: str


class ProblemDetail(BaseModel):
    type: str = "about:blank"
    title: str
    status: int
    detail: str | None = None
    code: str
    request_id: str | None = None
    errors: list[ValidationIssue] | None = None
    reasons: list[str] | None = None


def with_example(example: Any, *, forbid_extra: bool = False) -> ConfigDict:
    extra: Any = {"example": example}
    if forbid_extra:
        return ConfigDict(extra="forbid", json_schema_extra=extra)
    return ConfigDict(json_schema_extra=extra)


_CLOCK = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def _parse_clock(value: object) -> time:
    if isinstance(value, time):
        if value.second != 0 or value.microsecond != 0:
            raise ValueError("time must be HH:MM")
        return value
    if isinstance(value, str) and _CLOCK.fullmatch(value):
        hour, minute = value.split(":")
        return time(int(hour), int(minute))
    raise ValueError("time must be HH:MM")


def _format_clock(value: time) -> str:
    return f"{value.hour:02d}:{value.minute:02d}"


ClockTime = Annotated[
    time,
    BeforeValidator(_parse_clock),
    PlainSerializer(_format_clock, return_type=str, when_used="json"),
    WithJsonSchema(
        {
            "type": "string",
            "pattern": r"^([01]\d|2[0-3]):[0-5]\d$",
            "examples": ["07:00"],
        }
    ),
]


class Page[T](BaseModel):
    """`limit`/`offset` list. `total` is the full match count, not the page length."""

    items: list[T]
    total: int = Field(ge=0)


class NutrientTotals(BaseModel):
    kcal: float | None = None
    protein_g: float | None = None
    carb_g: float | None = None
    fat_g: float | None = None
    fiber_g: float | None = None
    sodium_mg: float | None = None
    sugars_g: float | None = None
    saturated_fat_g: float | None = None

    model_config = with_example(
        {
            "kcal": 1800,
            "protein_g": 120,
            "carb_g": 195,
            "fat_g": 60,
            "fiber_g": 22,
            "sodium_mg": 1550,
            "sugars_g": 36,
            "saturated_fat_g": 14,
        }
    )


class UnmetMinimumOut(BaseModel):
    nutrient: str
    minimum: float
    total: float | None = None

    model_config = with_example({"nutrient": "fiber", "minimum": 30, "total": 22})


class ExceededLimitOut(BaseModel):
    nutrient: str
    total: float | None = None
    limit: float

    model_config = with_example({"nutrient": "sodium", "total": 2400, "limit": 2000})


def _check_span(date_from: date, date_to: date, max_inclusive_days: int) -> None:
    if date_to < date_from:
        raise ValueError("to must be on or after from")
    inclusive = (date_to - date_from).days + 1
    if inclusive > max_inclusive_days:
        raise ValueError(f"range is longer than {max_inclusive_days} days")


class _DateRange(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    date_from: date = Field(alias="from")
    date_to: date = Field(alias="to")


class PlanDateRange(_DateRange):
    """Inclusive span of at most 31 days (plans and the shopping list)."""

    @model_validator(mode="after")
    def span(self) -> PlanDateRange:
        _check_span(self.date_from, self.date_to, 31)
        return self


class HistoryDateRange(_DateRange):
    """Inclusive span of at most 92 days (adherence and weights)."""

    @model_validator(mode="after")
    def span(self) -> HistoryDateRange:
        _check_span(self.date_from, self.date_to, 92)
        return self
