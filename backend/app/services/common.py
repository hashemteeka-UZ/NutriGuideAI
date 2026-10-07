"""Helpers shared by the services: exact decimals for NUMERIC values and row-change counts."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

MEASURE_PLACES = 3  # NUMERIC(12,3), §15.2


class MealNotFoundError(LookupError):
    pass


class InvalidTimezoneError(ValueError):
    pass


def to_decimal(value: float | int | Decimal) -> Decimal:
    """NUMERIC columns are mapped to float (app/db/types.py); str() gives back the stored digits."""
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


def measure(value: float | int | Decimal, name: str) -> Decimal:
    """An input stored in a NUMERIC(12,3) column: rejected rather than silently rounded."""
    amount = to_decimal(value)
    if not amount.is_finite():
        raise ValueError(f"{name} must be a finite number, got {amount}")
    exponent = amount.as_tuple().exponent
    if isinstance(exponent, int) and exponent < -MEASURE_PLACES:
        raise ValueError(f"{name} has more than {MEASURE_PLACES} decimal places: {amount}")
    return amount


def require_aware(value: datetime, name: str) -> None:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError(f"{name} must be timezone-aware")


def zone(name: str) -> ZoneInfo:
    """The IANA zone of user_profiles.timezone (§11.2)."""
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError) as exc:
        raise InvalidTimezoneError(f"unknown timezone {name!r}") from exc


def round_half_up(value: Decimal, places: int) -> Decimal:
    """Rounds like PostgreSQL NUMERIC: halves away from zero."""
    return value.quantize(Decimal(1).scaleb(-places), rounding=ROUND_HALF_UP)


@dataclass
class RowChanges:
    inserted: int = 0
    updated: int = 0
    deleted: int = 0
    unchanged: int = 0

    @property
    def changed(self) -> bool:
        return bool(self.inserted or self.updated or self.deleted)

    def __str__(self) -> str:
        return f"+{self.inserted} ~{self.updated} -{self.deleted} ={self.unchanged}"
