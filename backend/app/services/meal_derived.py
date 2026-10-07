"""recompute_meal_derived: meal_allergens and DERIVED meal_tags (§10.4, §10.5, rule R1).

Run after compute_meal_nutrients: threshold tags read the meal's meal_nutrients rows.
- meal_allergens = union of the ingredients' ingredient_allergens (fully rebuilt).
- DERIVED meal_tags = union of the ingredients' CONDITION ingredient_tags (presence properties)
  plus the threshold tags of app/services/tag_rules.py. DIETARY ingredient tags are not unioned.
- Only DERIVED rows are deleted; a MANUAL row for a derived tag becomes DERIVED (§10.5).
- Every DERIVED row records rule_version = TAG_RULES_VERSION; MANUAL rows keep it NULL.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from sqlalchemy import delete, insert, select, update
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    DietaryTag,
    IngredientAllergen,
    IngredientTag,
    Meal,
    MealAllergen,
    MealIngredient,
    MealNutrient,
    MealTag,
    Nutrient,
)
from app.db.models.catalog import MealTagSource
from app.db.models.reference import TagGroup
from app.services.common import MealNotFoundError, RowChanges, to_decimal
from app.services.tag_rules import TAG_RULES_VERSION, THRESHOLD_TAGS


class TagRuleError(ValueError):
    """The reference data contradicts rule R1 (a data error, never skipped silently)."""


@dataclass(frozen=True)
class MealDerivedResult:
    meal_id: int
    allergens: tuple[str, ...]
    derived_tags: tuple[str, ...]
    unknown_threshold_tags: tuple[str, ...]
    replaced_manual_tags: tuple[str, ...]
    allergen_changes: RowChanges
    tag_changes: RowChanges
    tag_rules_version: str = TAG_RULES_VERSION

    @property
    def changed(self) -> bool:
        return self.allergen_changes.changed or self.tag_changes.changed


def _threshold_tag_ids(session: Session) -> dict[str, int]:
    rows = session.execute(
        select(DietaryTag.code, DietaryTag.tag_id, DietaryTag.tag_group).where(
            DietaryTag.code.in_(list(THRESHOLD_TAGS))
        )
    ).all()
    found = {row.code: row for row in rows}
    problems = [
        f"{code}: not in dietary_tags" for code in sorted(THRESHOLD_TAGS) if code not in found
    ]
    problems += [
        f"{row.code}: tag_group is {row.tag_group}, expected {TagGroup.CONDITION}"
        for row in rows
        if row.tag_group != TagGroup.CONDITION
    ]
    nutrient_codes = {nutrient for nutrient, _ in THRESHOLD_TAGS.values()}
    known_nutrients = set(
        session.execute(select(Nutrient.code).where(Nutrient.code.in_(nutrient_codes))).scalars()
    )
    problems += [
        f"{tag}: nutrient {nutrient!r} not in nutrients"
        for tag, (nutrient, _) in sorted(THRESHOLD_TAGS.items())
        if nutrient not in known_nutrients
    ]
    if problems:
        raise TagRuleError(f"threshold tags ({TAG_RULES_VERSION}): " + "; ".join(problems))
    return {code: row.tag_id for code, row in found.items()}


def _forbid_threshold_ingredient_tags(
    session: Session, threshold_tag_ids: Mapping[str, int]
) -> None:
    rows = session.execute(
        select(IngredientTag.ingredient_id, DietaryTag.code)
        .join(DietaryTag, DietaryTag.tag_id == IngredientTag.tag_id)
        .where(IngredientTag.tag_id.in_(list(threshold_tag_ids.values())))
        .order_by(IngredientTag.ingredient_id, DietaryTag.code)
    ).all()
    if rows:
        listed = ", ".join(f"ingredient {row.ingredient_id} has {row.code}" for row in rows)
        raise TagRuleError(
            f"threshold tags are derived from meal nutrients ({TAG_RULES_VERSION}, rule R1) "
            f"and must not be in ingredient_tags: {listed}"
        )


def recompute_meal_derived(session: Session, meal_id: int) -> MealDerivedResult:
    if session.execute(select(Meal.meal_id).where(Meal.meal_id == meal_id)).first() is None:
        raise MealNotFoundError(f"meal {meal_id} does not exist")
    threshold_tag_ids = _threshold_tag_ids(session)
    _forbid_threshold_ingredient_tags(session, threshold_tag_ids)
    meal_ingredient_ids = select(MealIngredient.ingredient_id).where(
        MealIngredient.meal_id == meal_id
    )

    allergens = dict(
        session.execute(
            select(Allergen.allergen_id, Allergen.name_en)
            .join(IngredientAllergen, IngredientAllergen.allergen_id == Allergen.allergen_id)
            .where(IngredientAllergen.ingredient_id.in_(meal_ingredient_ids))
            .distinct()
        )
        .tuples()
        .all()
    )
    allergen_changes = _sync_meal_allergens(session, meal_id, set(allergens))

    derived: dict[int, str] = dict(
        session.execute(
            select(DietaryTag.tag_id, DietaryTag.code)
            .join(IngredientTag, IngredientTag.tag_id == DietaryTag.tag_id)
            .where(
                IngredientTag.ingredient_id.in_(meal_ingredient_ids),
                DietaryTag.tag_group == TagGroup.CONDITION,
            )
            .distinct()
        )
        .tuples()
        .all()
    )
    per_100g = dict(
        session.execute(
            select(Nutrient.code, MealNutrient.amount_per_100g)
            .join(MealNutrient, MealNutrient.nutrient_id == Nutrient.nutrient_id)
            .where(MealNutrient.meal_id == meal_id)
        )
        .tuples()
        .all()
    )
    unknown: list[str] = []
    for tag_code, (nutrient_code, threshold) in sorted(THRESHOLD_TAGS.items()):
        amount = per_100g.get(nutrient_code)
        if amount is None:
            unknown.append(tag_code)
        elif to_decimal(amount) > to_decimal(threshold):
            derived[threshold_tag_ids[tag_code]] = tag_code
    tag_changes, replaced = _sync_derived_meal_tags(session, meal_id, derived)

    return MealDerivedResult(
        meal_id=meal_id,
        allergens=tuple(sorted(allergens.values())),
        derived_tags=tuple(sorted(derived.values())),
        unknown_threshold_tags=tuple(unknown),
        replaced_manual_tags=tuple(sorted(replaced)),
        allergen_changes=allergen_changes,
        tag_changes=tag_changes,
    )


def _sync_meal_allergens(session: Session, meal_id: int, allergen_ids: set[int]) -> RowChanges:
    existing = set(
        session.execute(
            select(MealAllergen.allergen_id).where(MealAllergen.meal_id == meal_id)
        ).scalars()
    )
    stale = existing - allergen_ids
    new = allergen_ids - existing
    if stale:
        session.execute(
            delete(MealAllergen).where(
                MealAllergen.meal_id == meal_id, MealAllergen.allergen_id.in_(list(stale))
            )
        )
    if new:
        session.execute(
            insert(MealAllergen),
            [{"meal_id": meal_id, "allergen_id": allergen_id} for allergen_id in sorted(new)],
        )
    return RowChanges(inserted=len(new), deleted=len(stale), unchanged=len(existing & allergen_ids))


def _sync_derived_meal_tags(
    session: Session, meal_id: int, derived: Mapping[int, str]
) -> tuple[RowChanges, list[str]]:
    existing = {
        row.tag_id: row
        for row in session.execute(
            select(MealTag.tag_id, MealTag.source, MealTag.rule_version).where(
                MealTag.meal_id == meal_id
            )
        )
    }
    derived_values = {"source": MealTagSource.DERIVED, "rule_version": TAG_RULES_VERSION}
    changes = RowChanges()
    replaced: list[str] = []
    inserts: list[dict[str, Any]] = []
    for tag_id, code in derived.items():
        row = existing.get(tag_id)
        if row is None:
            inserts.append({"meal_id": meal_id, "tag_id": tag_id, **derived_values})
            changes.inserted += 1
        elif row.source == MealTagSource.DERIVED and row.rule_version == TAG_RULES_VERSION:
            changes.unchanged += 1
        else:
            session.execute(
                update(MealTag)
                .where(MealTag.meal_id == meal_id, MealTag.tag_id == tag_id)
                .values(**derived_values)
            )
            if row.source != MealTagSource.DERIVED:
                replaced.append(code)
            changes.updated += 1
    stale = [
        tag_id
        for tag_id, row in existing.items()
        if row.source == MealTagSource.DERIVED and tag_id not in derived
    ]
    if stale:
        session.execute(
            delete(MealTag).where(MealTag.meal_id == meal_id, MealTag.tag_id.in_(stale))
        )
        changes.deleted = len(stale)
    if inserts:
        session.execute(insert(MealTag), inserts)
    return changes, replaced
