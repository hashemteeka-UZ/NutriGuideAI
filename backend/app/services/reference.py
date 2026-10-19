"""Public vocabularies read from the database (#180)."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.text import pick_name
from app.db.models import Allergen, Cuisine, HealthCondition
from app.db.models.user import ActivityLevel, GoalType, MealSlot, Sex
from app.services.catalog_version import active_dataset_version

UNKNOWN_DATASET_VERSION = "unknown"


@dataclass(frozen=True)
class ConditionItem:
    code: str
    name: str
    is_supported: bool
    fluid_goal_requires_clinician: bool


@dataclass(frozen=True)
class CodeNameItem:
    code: str
    name: str


@dataclass(frozen=True)
class ReferenceLists:
    health_conditions: tuple[ConditionItem, ...]
    allergens: tuple[CodeNameItem, ...]
    cuisines: tuple[CodeNameItem, ...]
    activity_levels: tuple[ActivityLevel, ...]
    goal_types: tuple[GoalType, ...]
    sexes: tuple[Sex, ...]
    slots: tuple[MealSlot, ...]
    dataset_version: str


def reference_lists(session: Session, lang: str) -> ReferenceLists:
    """Supported conditions first, then code. Allergens and cuisines by code."""
    conditions = session.execute(
        select(HealthCondition).order_by(HealthCondition.is_supported.desc(), HealthCondition.code)
    ).scalars()
    allergens = session.scalars(select(Allergen).order_by(Allergen.code))
    cuisines = session.scalars(select(Cuisine).order_by(Cuisine.code))
    version = active_dataset_version(session)
    return ReferenceLists(
        health_conditions=tuple(
            ConditionItem(
                code=row.code,
                name=pick_name(lang, row.name_ar, row.name_en),
                is_supported=row.is_supported,
                fluid_goal_requires_clinician=row.fluid_goal_requires_clinician,
            )
            for row in conditions
        ),
        allergens=tuple(
            CodeNameItem(code=row.code, name=pick_name(lang, row.name_ar, row.name_en))
            for row in allergens
        ),
        cuisines=tuple(
            CodeNameItem(code=row.code, name=pick_name(lang, row.name_ar, row.name_en))
            for row in cuisines
        ),
        activity_levels=tuple(ActivityLevel),
        goal_types=tuple(GoalType),
        sexes=tuple(Sex),
        slots=tuple(MealSlot),
        dataset_version=version if version is not None else UNKNOWN_DATASET_VERSION,
    )
