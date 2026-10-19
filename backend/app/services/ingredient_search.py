"""Ingredient search over normalized aliases (#181, §15.9)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Final

from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text, pick_name
from app.db.models import Ingredient, IngredientAlias
from app.db.models.reference import ReviewStatus

# pg_trgm similarity that still catches a small typo without matching unrelated words.
SIMILARITY_MIN: Final = 0.3


class EmptySearchError(ValueError):
    def __init__(self) -> None:
        super().__init__("q is empty after normalization")


@dataclass(frozen=True)
class IngredientHit:
    ingredient_id: int
    code: str
    name: str
    food_id: int | None


def _like_pattern(fragment: str, *, prefix: bool) -> str:
    escaped = fragment.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    if prefix:
        return f"{escaped}%"
    return f"%{escaped}%"


def search_ingredients(
    session: Session, q: str, limit: int, offset: int, lang: str
) -> tuple[tuple[IngredientHit, ...], int]:
    """One row per ingredient, best alias first. Rejected ingredients are left out."""
    normalized = normalize_search_text(q)
    if not normalized:
        raise EmptySearchError

    alias = IngredientAlias.alias_normalized
    contains = _like_pattern(normalized, prefix=False)
    prefix = _like_pattern(normalized, prefix=True)
    rank = case(
        (alias == normalized, 3),
        (alias.like(prefix, escape="\\"), 2),
        (alias.like(contains, escape="\\"), 1),
        else_=0,
    )
    matched = (
        select(
            IngredientAlias.ingredient_id.label("ingredient_id"),
            func.max(rank).label("match_rank"),
            func.max(func.similarity(alias, normalized)).label("similarity"),
        )
        .where(
            or_(
                alias.like(contains, escape="\\"),
                func.similarity(alias, normalized) >= SIMILARITY_MIN,
            )
        )
        .group_by(IngredientAlias.ingredient_id)
        .subquery()
    )
    visible = Ingredient.review_status != ReviewStatus.REJECTED.value
    total = session.scalar(
        select(func.count())
        .select_from(Ingredient)
        .join(matched, matched.c.ingredient_id == Ingredient.ingredient_id)
        .where(visible)
    )
    rows = session.execute(
        select(Ingredient)
        .join(matched, matched.c.ingredient_id == Ingredient.ingredient_id)
        .where(visible)
        .order_by(
            matched.c.match_rank.desc(),
            matched.c.similarity.desc(),
            Ingredient.ingredient_id,
        )
        .limit(limit)
        .offset(offset)
    ).scalars()
    hits = tuple(
        IngredientHit(
            ingredient_id=row.ingredient_id,
            code=row.code,
            name=pick_name(lang, row.canonical_name_ar, row.canonical_name),
            food_id=row.default_food_id,
        )
        for row in rows
    )
    return hits, int(total or 0)
