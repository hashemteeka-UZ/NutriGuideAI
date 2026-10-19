"""Ingredient search over normalized aliases (#181, §15.9)."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.text import pick_name
from app.db.models import Ingredient, IngredientAlias
from app.db.models.reference import ReviewStatus
from app.services.text_search import (
    SIMILARITY_MIN,
    EmptySearchError,
    like_pattern,
    match_rank,
    normalize_query,
)

__all__ = ["EmptySearchError", "IngredientHit", "search_ingredients"]


@dataclass(frozen=True)
class IngredientHit:
    ingredient_id: int
    code: str
    name: str
    food_id: int | None


def search_ingredients(
    session: Session, q: str, limit: int, offset: int, lang: str
) -> tuple[tuple[IngredientHit, ...], int]:
    """One row per ingredient, best alias first. Rejected ingredients are left out."""
    normalized = normalize_query(q)
    alias = IngredientAlias.alias_normalized
    contains = like_pattern(normalized, prefix=False)
    matched = (
        select(
            IngredientAlias.ingredient_id.label("ingredient_id"),
            func.max(match_rank(alias, normalized)).label("match_rank"),
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
