"""Multi-condition limit resolution (§28.2, §9.5b, §9.5c).

resolve_condition_limits collects the condition_nutrient_limits and condition_tag_restrictions
rows of all the user's conditions and resolves them; the strictest limit always wins and no
limit is ever relaxed. A user without a condition gets no limit at all (§30.1, #69).
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Mapping
from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Final

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    ConditionNutrientLimit,
    ConditionTagRestriction,
    DietaryTag,
    HealthCondition,
    Nutrient,
    UserHealthCondition,
)
from app.db.models.reference import LimitBasis, RestrictionType
from app.services.common import to_decimal
from app.services.targets import KCAL_PER_G_CARB, KCAL_PER_G_FAT, KCAL_PER_G_PROTEIN

# --- §28.2 / §9.5b constants ------------------------------------------------------------------
# kcal per gram of the energy-yielding nutrients; only these may use PERCENT_ENERGY (§9.5b).
KCAL_PER_GRAM: Final[Mapping[str, Decimal]] = {
    "total_fat": KCAL_PER_G_FAT,
    "saturated_fat": KCAL_PER_G_FAT,
    "carbohydrate": KCAL_PER_G_CARB,
    "sugars": KCAL_PER_G_CARB,
    "protein": KCAL_PER_G_PROTEIN,
}
ENERGY_NUTRIENT: Final = "energy_kcal"
PERCENT: Final = Decimal(100)
# ---------------------------------------------------------------------------------------------


class ConditionLimitError(ValueError):
    """The reference data cannot be resolved (a data error, never skipped silently)."""


class ConditionConflictError(Exception):
    """§28.2: effective min_per_day > effective max_per_day; no plan may be generated."""

    def __init__(
        self,
        nutrient: str,
        min_per_day: ResolvedLimit,
        max_per_day: ResolvedLimit,
    ) -> None:
        self.nutrient = nutrient
        self.min_per_day = min_per_day.value
        self.max_per_day = max_per_day.value
        self.conditions = tuple(
            sorted({s.condition_code for s in (*min_per_day.sources, *max_per_day.sources)})
        )
        super().__init__(
            f"condition limits conflict for {nutrient}: min_per_day {self.min_per_day} "
            f"({_codes(min_per_day)}) > max_per_day {self.max_per_day} ({_codes(max_per_day)}); "
            "this combination needs professional guidance (§28.2)"
        )


def _codes(limit: ResolvedLimit) -> str:
    return ", ".join(s.condition_code for s in limit.sources)


@dataclass(frozen=True)
class LimitSource:
    """One condition_nutrient_limits value; `value` is in the unit of the resolved limit."""

    condition_code: str
    source_reference: str
    limit_basis: str
    stated_value: Decimal
    value: Decimal

    def to_snapshot(self) -> dict[str, str]:
        return {
            "condition": self.condition_code,
            "source_reference": self.source_reference,
            "limit_basis": self.limit_basis,
            "stated_value": str(self.stated_value),
            "value": str(self.value),
        }


@dataclass(frozen=True)
class ResolvedLimit:
    """The winning value and every row that contributed to it (sorted by condition code)."""

    value: Decimal
    sources: tuple[LimitSource, ...]

    def to_snapshot(self) -> dict[str, Any]:
        return {
            "value": str(self.value),
            "sources": [source.to_snapshot() for source in self.sources],
        }


@dataclass(frozen=True)
class TagRestriction:
    condition_code: str
    tag_code: str
    restriction_type: str
    max_servings_per_week: int | None


@dataclass(frozen=True)
class ResolvedLimits:
    """Resolved limits of one user at one target_kcal.

    max_per_day / min_per_day / max_per_meal are amounts in the nutrient's own unit (per-day
    PERCENT_ENERGY values converted with target_kcal). max_per_meal_percent_energy stays a
    percentage of each meal's own energy (§9.5b) and is never converted with the daily target.
    """

    target_kcal: Decimal
    conditions: tuple[str, ...]
    max_per_day: Mapping[str, ResolvedLimit]
    min_per_day: Mapping[str, ResolvedLimit]
    max_per_meal: Mapping[str, ResolvedLimit]
    max_per_meal_percent_energy: Mapping[str, ResolvedLimit]
    avoid_tags: frozenset[str]
    limit_tags: Mapping[str, int | None]
    tag_restrictions: tuple[TagRestriction, ...]

    @property
    def is_empty(self) -> bool:
        return not (
            self.max_per_day
            or self.min_per_day
            or self.max_per_meal
            or self.max_per_meal_percent_energy
            or self.tag_restrictions
        )

    def condition_max_per_meal(
        self, condition_code: str
    ) -> tuple[dict[str, Decimal], dict[str, Decimal]]:
        """(absolute amounts, percentages of meal energy) stated by one condition."""
        absolute = {
            nutrient: source.value
            for nutrient, limit in self.max_per_meal.items()
            for source in limit.sources
            if source.condition_code == condition_code
        }
        percent = {
            nutrient: source.value
            for nutrient, limit in self.max_per_meal_percent_energy.items()
            for source in limit.sources
            if source.condition_code == condition_code
        }
        return absolute, percent

    def condition_tags(self, condition_code: str) -> frozenset[str]:
        """Tags that one condition marks AVOID or LIMIT."""
        return frozenset(
            r.tag_code for r in self.tag_restrictions if r.condition_code == condition_code
        )

    def to_snapshot(self) -> dict[str, Any]:
        def limits(resolved: Mapping[str, ResolvedLimit]) -> dict[str, Any]:
            return {code: resolved[code].to_snapshot() for code in sorted(resolved)}

        def conditions_of(tag: str, kind: str) -> list[str]:
            return sorted(
                {
                    r.condition_code
                    for r in self.tag_restrictions
                    if r.tag_code == tag and r.restriction_type == kind
                }
            )

        return {
            "target_kcal": str(self.target_kcal),
            "conditions": list(self.conditions),
            "max_per_day": limits(self.max_per_day),
            "min_per_day": limits(self.min_per_day),
            "max_per_meal": limits(self.max_per_meal),
            "max_per_meal_percent_energy": limits(self.max_per_meal_percent_energy),
            "avoid_tags": {
                tag: conditions_of(tag, RestrictionType.AVOID) for tag in sorted(self.avoid_tags)
            },
            "limit_tags": {
                tag: {
                    "max_servings_per_week": self.limit_tags[tag],
                    "conditions": conditions_of(tag, RestrictionType.LIMIT),
                }
                for tag in sorted(self.limit_tags)
            },
        }


def _grams(nutrient: str, percent: Decimal, target_kcal: Decimal) -> Decimal:
    return percent / PERCENT * target_kcal / KCAL_PER_GRAM[nutrient]


def energy_share_percent(nutrient: str, amount: Decimal, energy_kcal: Decimal) -> Decimal:
    """Share of `energy_kcal` that `amount` of an energy-yielding nutrient provides, in %."""
    if energy_kcal <= 0:
        return Decimal(0) if amount == 0 else Decimal("Infinity")
    return amount * KCAL_PER_GRAM[nutrient] / energy_kcal * PERCENT


def _source(row: Any, stated: float, value: Decimal) -> LimitSource:
    return LimitSource(
        condition_code=row.condition_code,
        source_reference=row.source_reference,
        limit_basis=row.limit_basis,
        stated_value=to_decimal(stated),
        value=value,
    )


def _resolve(
    contributions: Mapping[str, list[LimitSource]], *, maximum_wins: bool
) -> dict[str, ResolvedLimit]:
    resolved = {}
    for nutrient, sources in sorted(contributions.items()):
        values = [s.value for s in sources]
        resolved[nutrient] = ResolvedLimit(
            value=max(values) if maximum_wins else min(values),
            sources=tuple(sorted(sources, key=lambda s: (s.condition_code, s.limit_basis))),
        )
    return resolved


def resolve_condition_limits(
    session: Session, user_id: int, target_kcal: float | int | Decimal
) -> ResolvedLimits:
    kcal = to_decimal(target_kcal)
    if kcal <= 0:
        raise ValueError(f"target_kcal must be positive, got {kcal}")
    conditions = tuple(
        session.execute(
            select(HealthCondition.code)
            .join(
                UserHealthCondition,
                UserHealthCondition.condition_id == HealthCondition.condition_id,
            )
            .where(UserHealthCondition.user_id == user_id)
            .order_by(HealthCondition.code)
        ).scalars()
    )
    user_condition_ids = select(UserHealthCondition.condition_id).where(
        UserHealthCondition.user_id == user_id
    )

    max_per_day: dict[str, list[LimitSource]] = defaultdict(list)
    min_per_day: dict[str, list[LimitSource]] = defaultdict(list)
    max_per_meal: dict[str, list[LimitSource]] = defaultdict(list)
    max_per_meal_percent: dict[str, list[LimitSource]] = defaultdict(list)
    rows = session.execute(
        select(
            HealthCondition.code.label("condition_code"),
            Nutrient.code.label("nutrient_code"),
            ConditionNutrientLimit.limit_basis,
            ConditionNutrientLimit.max_per_meal,
            ConditionNutrientLimit.max_per_day,
            ConditionNutrientLimit.min_per_day,
            ConditionNutrientLimit.source_reference,
        )
        .join(HealthCondition, HealthCondition.condition_id == ConditionNutrientLimit.condition_id)
        .join(Nutrient, Nutrient.nutrient_id == ConditionNutrientLimit.nutrient_id)
        .where(ConditionNutrientLimit.condition_id.in_(user_condition_ids))
        .order_by(HealthCondition.code, Nutrient.code, ConditionNutrientLimit.limit_basis)
    ).all()
    for row in rows:
        nutrient = row.nutrient_code
        percent = row.limit_basis == LimitBasis.PERCENT_ENERGY
        if percent and nutrient not in KCAL_PER_GRAM:
            raise ConditionLimitError(
                f"{row.condition_code}/{nutrient}: PERCENT_ENERGY is only valid for "
                f"{sorted(KCAL_PER_GRAM)} (§9.5b)"
            )
        for stated, contributions in (
            (row.max_per_day, max_per_day),
            (row.min_per_day, min_per_day),
        ):
            if stated is not None:
                value = to_decimal(stated)
                if percent:
                    value = _grams(nutrient, value, kcal)
                contributions[nutrient].append(_source(row, stated, value))
        if row.max_per_meal is not None:
            per_meal = max_per_meal_percent if percent else max_per_meal
            per_meal[nutrient].append(_source(row, row.max_per_meal, to_decimal(row.max_per_meal)))

    resolved_max = _resolve(max_per_day, maximum_wins=False)
    resolved_min = _resolve(min_per_day, maximum_wins=True)
    for nutrient, minimum in resolved_min.items():
        maximum = resolved_max.get(nutrient)
        if maximum is not None and minimum.value > maximum.value:
            raise ConditionConflictError(nutrient, minimum, maximum)

    restrictions = tuple(
        TagRestriction(
            condition_code=row.condition_code,
            tag_code=row.tag_code,
            restriction_type=row.restriction_type,
            max_servings_per_week=row.max_servings_per_week,
        )
        for row in session.execute(
            select(
                HealthCondition.code.label("condition_code"),
                DietaryTag.code.label("tag_code"),
                ConditionTagRestriction.restriction_type,
                ConditionTagRestriction.max_servings_per_week,
            )
            .join(
                HealthCondition,
                HealthCondition.condition_id == ConditionTagRestriction.condition_id,
            )
            .join(DietaryTag, DietaryTag.tag_id == ConditionTagRestriction.tag_id)
            .where(ConditionTagRestriction.condition_id.in_(user_condition_ids))
            .order_by(DietaryTag.code, HealthCondition.code)
        )
    )
    avoid_tags = frozenset(
        r.tag_code for r in restrictions if r.restriction_type == RestrictionType.AVOID
    )
    weekly: dict[str, list[int]] = {}
    for r in restrictions:
        if r.restriction_type == RestrictionType.LIMIT:
            numbers = weekly.setdefault(r.tag_code, [])
            if r.max_servings_per_week is not None:
                numbers.append(r.max_servings_per_week)
    limit_tags = {tag: min(numbers) if numbers else None for tag, numbers in weekly.items()}

    return ResolvedLimits(
        target_kcal=kcal,
        conditions=conditions,
        max_per_day=resolved_max,
        min_per_day=resolved_min,
        max_per_meal=_resolve(max_per_meal, maximum_wins=False),
        max_per_meal_percent_energy=_resolve(max_per_meal_percent, maximum_wins=False),
        avoid_tags=avoid_tags,
        limit_tags=limit_tags,
        tag_restrictions=restrictions,
    )
