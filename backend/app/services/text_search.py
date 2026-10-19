"""Shared name search: normalization, LIKE escaping, rank, and trigram cutoff (#185)."""

from __future__ import annotations

from typing import Any, Final

from sqlalchemy import case

from app.core.text import normalize_search_text

# pg_trgm similarity that still catches a small typo without matching unrelated words.
SIMILARITY_MIN: Final = 0.3


class EmptySearchError(ValueError):
    def __init__(self) -> None:
        super().__init__("q is empty after normalization")


def normalize_query(q: str) -> str:
    """Search text after normalize_search_text. Empty text is a validation error."""
    normalized = normalize_search_text(q)
    if not normalized:
        raise EmptySearchError
    return normalized


def like_pattern(fragment: str, *, prefix: bool) -> str:
    """LIKE pattern where \\, %, and _ in the query stay literal characters."""
    escaped = fragment.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    if prefix:
        return f"{escaped}%"
    return f"%{escaped}%"


def match_rank(column: Any, normalized: str) -> Any:
    """3 exact, 2 prefix, 1 contains, 0 otherwise."""
    contains = like_pattern(normalized, prefix=False)
    prefix = like_pattern(normalized, prefix=True)
    return case(
        (column == normalized, 3),
        (column.like(prefix, escape="\\"), 2),
        (column.like(contains, escape="\\"), 1),
        else_=0,
    )
