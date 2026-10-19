"""Alias search: normalize, rank, page, and hide rejected ingredients (#181)."""

from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text
from app.services.ingredient_search import EmptySearchError, search_ingredients
from tests.builders import make_ingredient, make_ingredient_alias

RICE = "\u0623\u0631\u0632"
RICE_PLAIN = "\u0627\u0631\u0632"
RICE_MARKED = "\u0623\u064e\u0631\u0652\u0632"


def _alias(conn: Connection, ingredient_id: int, text: str, lang: str) -> None:
    make_ingredient_alias(
        conn,
        ingredient_id=ingredient_id,
        alias_text=text,
        lang=lang,
        alias_normalized=normalize_search_text(text),
    )


def test_hamza_and_tashkeel_find_the_same_ingredient_as_the_plain_spelling(
    session: Session, integrity_conn: Connection
) -> None:
    ingredient = make_ingredient(
        integrity_conn,
        code="RICE",
        canonical_name="Rice",
        canonical_name_ar=RICE,
    )
    _alias(integrity_conn, ingredient, RICE, "ar")
    _alias(integrity_conn, ingredient, "Rice", "en")
    plain, _total = search_ingredients(session, RICE_PLAIN, 20, 0, "ar")
    marked, _total = search_ingredients(session, RICE_MARKED, 20, 0, "ar")
    english, _total = search_ingredients(session, "Rice", 20, 0, "en")
    assert plain[0].ingredient_id == marked[0].ingredient_id == ingredient
    assert english[0].name == "Rice"
    assert plain[0].name == RICE


def test_prefix_ranks_above_contains(session: Session, integrity_conn: Connection) -> None:
    prefix = make_ingredient(integrity_conn, code="APPLE_PIE", canonical_name="apple pie")
    contains = make_ingredient(integrity_conn, code="PINEAPPLE", canonical_name="pineapple")
    _alias(integrity_conn, prefix, "apple pie", "en")
    _alias(integrity_conn, contains, "pineapple", "en")
    hits, total = search_ingredients(session, "apple", 20, 0, "en")
    assert total == 2
    assert [hit.ingredient_id for hit in hits] == [prefix, contains]


def test_paging_total_and_rejected_rows(session: Session, integrity_conn: Connection) -> None:
    ids = []
    for name in ("quinoa-a", "quinoa-b", "quinoa-c"):
        ingredient = make_ingredient(integrity_conn, canonical_name=name)
        make_ingredient_alias(
            integrity_conn,
            ingredient_id=ingredient,
            alias_text=name,
            lang="en",
            alias_normalized="quinoa",
        )
        ids.append(ingredient)
    rejected = make_ingredient(integrity_conn, canonical_name="quinoa-no", review_status="REJECTED")
    make_ingredient_alias(
        integrity_conn,
        ingredient_id=rejected,
        alias_text="quinoa-no",
        lang="en",
        alias_normalized="quinoa",
    )
    page, total = search_ingredients(session, "quinoa", 1, 1, "en")
    assert total == 3
    assert [hit.ingredient_id for hit in page] == [sorted(ids)[1]]


def test_blank_and_tashkeel_queries_are_empty(session: Session) -> None:
    for query in ("   ", "\u064e\u064b"):
        try:
            search_ingredients(session, query, 20, 0, "ar")
        except EmptySearchError:
            continue
        raise AssertionError(query)


def test_like_wildcards_in_the_query_are_literals(
    session: Session, integrity_conn: Connection
) -> None:
    percent = make_ingredient(integrity_conn, code="PCT", canonical_name="100%")
    other = make_ingredient(integrity_conn, code="PLAIN", canonical_name="plain")
    _alias(integrity_conn, percent, "100%", "en")
    _alias(integrity_conn, other, "plain", "en")
    hits, total = search_ingredients(session, "%", 20, 0, "en")
    assert total == 1
    assert hits[0].ingredient_id == percent


def test_a_small_typo_still_matches(session: Session, integrity_conn: Connection) -> None:
    ingredient = make_ingredient(integrity_conn, code="TOMATO", canonical_name="tomato")
    _alias(integrity_conn, ingredient, "tomato", "en")
    hits, total = search_ingredients(session, "tomate", 20, 0, "en")
    assert total == 1
    assert hits[0].code == "TOMATO"
