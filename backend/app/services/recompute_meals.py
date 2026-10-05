"""Recompute meal_nutrients (calc_v1) and derived meal data for active meals.

    uv run python -m app.services.recompute_meals (--all | --meal-id N)

Runs compute_meal_nutrients, then recompute_meal_derived, for every selected meal in one
transaction against DATABASE_URL. Idempotent: a second run changes nothing.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db.models import Meal
from app.services.common import MealNotFoundError, RowChanges
from app.services.meal_derived import MealDerivedResult, TagRuleError, recompute_meal_derived
from app.services.meal_nutrition import (
    COMPUTATION_VERSION,
    MealNutritionResult,
    compute_meal_nutrients,
)
from app.services.tag_rules import TAG_RULES_VERSION


@dataclass(frozen=True)
class MealRecompute:
    meal_id: int
    ref_external: str | None
    nutrition: MealNutritionResult
    derived: MealDerivedResult

    @property
    def changed(self) -> bool:
        return self.nutrition.changes.changed or self.derived.changed


def recompute_meal(
    session: Session, meal_id: int, now: datetime
) -> tuple[MealNutritionResult, MealDerivedResult]:
    nutrition = compute_meal_nutrients(session, meal_id, now)
    return nutrition, recompute_meal_derived(session, meal_id)


def recompute_active_meals(
    session: Session, now: datetime, meal_id: int | None = None
) -> list[MealRecompute]:
    query = select(Meal.meal_id, Meal.ref_external).where(Meal.is_active).order_by(Meal.meal_id)
    if meal_id is not None:
        query = query.where(Meal.meal_id == meal_id)
    meals = session.execute(query).all()
    if meal_id is not None and not meals:
        raise MealNotFoundError(f"no active meal with meal_id {meal_id}")
    results = []
    for meal in meals:
        nutrition, derived = recompute_meal(session, meal.meal_id, now)
        results.append(MealRecompute(meal.meal_id, meal.ref_external, nutrition, derived))
    return results


def _total(changes: list[RowChanges]) -> RowChanges:
    return RowChanges(
        inserted=sum(c.inserted for c in changes),
        updated=sum(c.updated for c in changes),
        deleted=sum(c.deleted for c in changes),
        unchanged=sum(c.unchanged for c in changes),
    )


def format_results(results: list[MealRecompute]) -> str:
    header = f"{'meal_id':>7}  {'ref':<8} {'complete':<20} {'derived tags':<26} allergens"
    lines = [f"Recompute ({COMPUTATION_VERSION}, {TAG_RULES_VERSION})", header]
    for r in results:
        missing = r.nutrition.missing_mandatory
        complete = "yes" if not missing else "no: " + ",".join(missing)
        tags = ", ".join(r.derived.derived_tags) or "-"
        if r.derived.unknown_threshold_tags:
            tags += " (unknown: " + ",".join(r.derived.unknown_threshold_tags) + ")"
        allergens = ", ".join(r.derived.allergens) or "-"
        lines.append(
            f"{r.meal_id:>7}  {r.ref_external or '-':<8} {complete:<20} {tags:<26} {allergens}"
        )
    complete_count = sum(r.nutrition.is_complete for r in results)
    lines.append(f"{len(results)} meals, {complete_count} complete.")
    totals = {
        "meal_nutrients": _total([r.nutrition.changes for r in results]),
        "meal_allergens": _total([r.derived.allergen_changes for r in results]),
        "meal_tags (DERIVED)": _total([r.derived.tag_changes for r in results]),
    }
    lines.append("Row changes (+inserted ~updated -deleted =unchanged):")
    lines += [f"  {name:<20} {changes}" for name, changes in totals.items()]
    replaced = [(r.ref_external, t) for r in results for t in r.derived.replaced_manual_tags]
    if replaced:
        lines.append(
            "MANUAL rows replaced by DERIVED: " + ", ".join(f"{m}:{t}" for m, t in replaced)
        )
    changed = any(r.changed for r in results)
    lines.append("Changes written." if changed else "No changes.")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Recompute meal nutrients and derived data.")
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--all", action="store_true", help="every active meal")
    selection.add_argument("--meal-id", type=int, help="one active meal")
    args = parser.parse_args(argv)

    from app.db.session import SessionLocal

    with SessionLocal() as session:
        try:
            results = recompute_active_meals(session, datetime.now(UTC), args.meal_id)
            session.commit()
        except (MealNotFoundError, TagRuleError, SQLAlchemyError) as exc:
            session.rollback()
            print(f"Recompute failed, nothing written: {exc}", file=sys.stderr)
            return 1
    print(format_results(results))
    return 0


if __name__ == "__main__":
    sys.exit(main())
