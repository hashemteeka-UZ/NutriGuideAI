"""Helpers shared by the services: exact decimals for NUMERIC values and row-change counts."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal


class MealNotFoundError(LookupError):
    pass


def to_decimal(value: float | int | Decimal) -> Decimal:
    """NUMERIC columns are mapped to float (app/db/types.py); str() gives back the stored digits."""
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


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
