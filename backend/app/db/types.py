from datetime import datetime
from enum import StrEnum
from typing import Any

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Numeric,
    String,
    func,
)
from sqlalchemy.orm import MappedColumn, mapped_column

# §15.2: measured/computed amounts.
MEASURE = Numeric(12, 3, asdecimal=False)
# §15.2: *_confidence columns, range 0-1.
CONFIDENCE = Numeric(4, 3, asdecimal=False)
# §15.2: meal_plan_items.servings_multiplier, discrete steps.
SERVINGS_MULTIPLIER = Numeric(3, 2, asdecimal=False)
# §15.5: ISO 639-1 language code.
LANG_CODE = String(2)


def pk_column() -> MappedColumn[int]:
    """Surrogate PK, BIGINT GENERATED ALWAYS AS IDENTITY (§15.1)."""
    return mapped_column(BigInteger, Identity(always=True), primary_key=True)


def fk_column(
    target: str,
    *,
    ondelete: str,
    nullable: bool = False,
    index: bool = False,
    primary_key: bool = False,
) -> MappedColumn[Any]:
    return mapped_column(
        BigInteger,
        ForeignKey(target, ondelete=ondelete),
        nullable=nullable,
        index=index,
        primary_key=primary_key,
    )


def created_at_column() -> MappedColumn[datetime]:
    return mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())


def updated_at_column() -> MappedColumn[datetime]:
    return mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )


def enum_check(column: str, values: type[StrEnum], *, name: str) -> CheckConstraint:
    allowed = ", ".join(f"'{member.value}'" for member in values)
    return CheckConstraint(f"{column} IN ({allowed})", name=name)


def lang_check(column: str, *, name: str) -> CheckConstraint:
    return CheckConstraint(f"{column} ~ '^[a-z]{{2}}$'", name=name)


def trigram_index(column: str) -> Index:
    """GIN pg_trgm index on a *_normalized search column (§15.9)."""
    return Index(
        None,
        column,
        postgresql_using="gin",
        postgresql_ops={column: "gin_trgm_ops"},
    )
