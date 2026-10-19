"""GET /ingredients requires a token and searches normalized aliases (#181)."""

from fastapi.testclient import TestClient
from sqlalchemy.engine import Connection

from app.core.text import normalize_search_text
from tests.builders import make_ingredient, make_ingredient_alias

RICE = "\u0623\u0631\u0632"
RICE_PLAIN = "\u0627\u0631\u0632"
RICE_MARKED = "\u0623\u064e\u0631\u0652\u0632"


def _auth(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "search@example.com", "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _alias(conn: Connection, ingredient_id: int, text: str, lang: str) -> None:
    make_ingredient_alias(
        conn,
        ingredient_id=ingredient_id,
        alias_text=text,
        lang=lang,
        alias_normalized=normalize_search_text(text),
    )


def test_search_requires_a_token_and_rejects_an_empty_query(
    client: TestClient, integrity_conn: Connection
) -> None:
    missing = client.get("/api/v1/ingredients", params={"q": "rice"})
    assert missing.status_code == 401
    assert missing.json()["code"] == "UNAUTHORIZED"
    headers = _auth(client)
    for query in ("   ", "\u064e"):
        response = client.get("/api/v1/ingredients", params={"q": query}, headers=headers)
        assert response.status_code == 422, query
        assert response.json()["code"] == "VALIDATION_ERROR"


def test_arabic_english_rank_page_and_rejected(
    client: TestClient, integrity_conn: Connection
) -> None:
    headers = _auth(client)
    rice = make_ingredient(
        integrity_conn, code="RICE", canonical_name="Rice", canonical_name_ar=RICE
    )
    _alias(integrity_conn, rice, RICE, "ar")
    _alias(integrity_conn, rice, "Rice", "en")
    prefix = make_ingredient(integrity_conn, code="APPLE_PIE", canonical_name="apple pie")
    contains = make_ingredient(integrity_conn, code="PINEAPPLE", canonical_name="pineapple")
    _alias(integrity_conn, prefix, "apple pie", "en")
    _alias(integrity_conn, contains, "pineapple", "en")
    rejected = make_ingredient(
        integrity_conn, code="SECRET", canonical_name="apple secret", review_status="REJECTED"
    )
    _alias(integrity_conn, rejected, "apple secret", "en")

    plain = client.get("/api/v1/ingredients", params={"q": RICE_PLAIN}, headers=headers)
    marked = client.get("/api/v1/ingredients", params={"q": RICE_MARKED}, headers=headers)
    assert plain.status_code == 200, plain.text
    assert marked.json()["items"][0]["ingredient_id"] == plain.json()["items"][0]["ingredient_id"]
    english = client.get(
        "/api/v1/ingredients",
        params={"q": "Rice"},
        headers={**headers, "Accept-Language": "en"},
    )
    assert english.json()["items"][0]["name"] == "Rice"

    ranked = client.get("/api/v1/ingredients", params={"q": "apple"}, headers=headers)
    assert [item["code"] for item in ranked.json()["items"]] == ["APPLE_PIE", "PINEAPPLE"]
    assert ranked.json()["total"] == 2
    page = client.get(
        "/api/v1/ingredients", params={"q": "apple", "limit": 1, "offset": 1}, headers=headers
    )
    assert page.json()["total"] == 2
    assert [item["code"] for item in page.json()["items"]] == ["PINEAPPLE"]
