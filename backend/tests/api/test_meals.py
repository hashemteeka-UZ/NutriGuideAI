"""GET /meals, GET /meals/{id}, and GET /catalog/snapshot (#184 to #188)."""

from __future__ import annotations

import gzip

from fastapi.testclient import TestClient
from sqlalchemy import select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.core.text import normalize_search_text
from app.db.models import Meal, User
from tests.builders import (
    make_allergen,
    make_cuisine,
    make_dietary_tag,
    make_ingredient,
    make_meal,
    make_meal_allergen,
    make_meal_ingredient,
    make_meal_nutrient,
    make_meal_step,
    make_meal_tag,
    make_meal_translation,
    make_nutrient,
    make_user_meal_pref,
)

RICE = "\u0623\u0631\u0632"
RICE_PLAIN = "\u0627\u0631\u0632"
RICE_MARKED = "\u0623\u064e\u0631\u0652\u0632"
SHAK = "\u0634\u0643\u0634\u0648\u0643\u0629"
STEP_AR = "\u0633\u062e\u0651\u0646 \u0627\u0644\u0632\u064a\u062a"


def _auth(client: TestClient, email: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _user_id(conn: Connection, email: str) -> int:
    return conn.execute(select(User.user_id).where(User.email == email)).scalar_one()


def _macros(conn: Connection) -> dict[str, int]:
    return {
        "energy_kcal": make_nutrient(conn, code="energy_kcal", name="Energy", unit="kcal"),
        "protein": make_nutrient(conn, code="protein", name="Protein", unit="g"),
        "carbohydrate": make_nutrient(conn, code="carbohydrate", name="Carbohydrate", unit="g"),
        "total_fat": make_nutrient(conn, code="total_fat", name="Fat", unit="g"),
    }


def _amounts(
    conn: Connection,
    meal_id: int,
    macros: dict[str, int],
    *,
    kcal: float,
    protein: float,
    carb: float,
    fat: float,
) -> None:
    for code, amount in (
        ("energy_kcal", kcal),
        ("protein", protein),
        ("carbohydrate", carb),
        ("total_fat", fat),
    ):
        make_meal_nutrient(
            conn,
            meal_id=meal_id,
            nutrient_id=macros[code],
            amount_per_serving=amount,
            amount_per_100g=amount,
        )


def test_list_requires_a_token_and_rejects_a_blank_query(client: TestClient) -> None:
    missing = client.get("/api/v1/meals", params={"q": "rice"})
    assert missing.status_code == 401
    assert missing.json()["code"] == "UNAUTHORIZED"
    headers = _auth(client, "meals-blank@example.com")
    blank = client.get("/api/v1/meals", params={"q": "   "}, headers=headers)
    assert blank.status_code == 422
    assert blank.json()["code"] == "VALIDATION_ERROR"


def test_search_rank_slot_and_cuisine(client: TestClient, integrity_conn: Connection) -> None:
    headers = _auth(client, "meals-search@example.com")
    macros = _macros(integrity_conn)
    breakfast = make_dietary_tag(integrity_conn, code="breakfast_suitable", tag_group="OCCASION")
    lunch = make_dietary_tag(integrity_conn, code="lunch_suitable", tag_group="OCCASION")
    libyan = make_cuisine(integrity_conn, code="LIBYAN", name_en="Libyan", name_ar="Libyan")
    other = make_cuisine(integrity_conn, code="OTHER", name_en="Other", name_ar="Other")

    rice = make_meal(
        integrity_conn,
        name=RICE,
        name_normalized=normalize_search_text(RICE),
        default_lang="ar",
        cuisine_id=libyan,
        dataset_version="team_recipes_v1",
    )
    _amounts(integrity_conn, rice, macros, kcal=100, protein=1, carb=1, fat=1)
    make_meal_tag(integrity_conn, meal_id=rice, tag_id=breakfast)

    shak = make_meal(
        integrity_conn,
        name=SHAK,
        name_normalized=normalize_search_text(SHAK),
        default_lang="ar",
        cuisine_id=libyan,
    )
    _amounts(integrity_conn, shak, macros, kcal=200, protein=2, carb=2, fat=2)
    make_meal_translation(
        integrity_conn,
        meal_id=shak,
        lang="en",
        name="shakshuka",
        name_normalized=normalize_search_text("shakshuka"),
    )

    pie = make_meal(
        integrity_conn,
        name="apple pie",
        name_normalized="apple pie",
        default_lang="en",
        cuisine_id=other,
    )
    contains = make_meal(
        integrity_conn,
        name="pineapple",
        name_normalized="pineapple",
        default_lang="en",
        cuisine_id=other,
    )
    for meal_id in (pie, contains):
        _amounts(integrity_conn, meal_id, macros, kcal=50, protein=1, carb=1, fat=1)
        make_meal_tag(integrity_conn, meal_id=meal_id, tag_id=breakfast)

    midday = make_meal(
        integrity_conn,
        name="lunch stew",
        name_normalized="lunch stew",
        default_lang="en",
        cuisine_id=other,
    )
    _amounts(integrity_conn, midday, macros, kcal=80, protein=1, carb=1, fat=1)
    make_meal_tag(integrity_conn, meal_id=midday, tag_id=lunch)

    plain = client.get("/api/v1/meals", params={"q": RICE_PLAIN}, headers=headers)
    marked = client.get("/api/v1/meals", params={"q": RICE_MARKED}, headers=headers)
    assert plain.status_code == 200, plain.text
    assert marked.status_code == 200, marked.text
    assert plain.json()["items"][0]["meal_id"] == rice
    assert marked.json()["items"][0]["meal_id"] == rice

    english = client.get(
        "/api/v1/meals",
        params={"q": "shakshuka"},
        headers={**headers, "Accept-Language": "en"},
    )
    assert english.status_code == 200, english.text
    assert english.json()["items"][0]["meal_id"] == shak
    assert english.json()["items"][0]["name"] == "shakshuka"

    ranked = client.get("/api/v1/meals", params={"q": "apple"}, headers=headers)
    assert [item["meal_id"] for item in ranked.json()["items"]] == [pie, contains]

    breakfasts = client.get("/api/v1/meals", params={"slot": "BREAKFAST"}, headers=headers)
    assert breakfasts.status_code == 200, breakfasts.text
    breakfast_ids = {item["meal_id"] for item in breakfasts.json()["items"]}
    assert breakfast_ids == {rice, pie, contains}
    assert all("breakfast_suitable" in item["tags"] for item in breakfasts.json()["items"])

    libyan_page = client.get("/api/v1/meals", params={"cuisine": "LIBYAN"}, headers=headers)
    assert {item["meal_id"] for item in libyan_page.json()["items"]} == {rice, shak}
    assert libyan_page.json()["items"][0]["cuisine"] == "LIBYAN"

    unknown = client.get("/api/v1/meals", params={"cuisine": "NO_SUCH_CUISINE"}, headers=headers)
    assert unknown.status_code == 200
    assert unknown.json() == {"items": [], "total": 0}


def test_paging_stance_and_inactive_meals(client: TestClient, integrity_conn: Connection) -> None:
    caller = _auth(client, "meals-caller@example.com")
    other = _auth(client, "meals-other@example.com")
    caller_id = _user_id(integrity_conn, "meals-caller@example.com")
    other_id = _user_id(integrity_conn, "meals-other@example.com")
    ids = []
    for name in ("a-meal", "b-meal", "c-meal"):
        meal = make_meal(integrity_conn, name=name, name_normalized=name, default_lang="en")
        ids.append(meal)
    liked = ids[0]
    make_user_meal_pref(integrity_conn, user_id=caller_id, meal_id=liked, stance="LIKE")
    make_user_meal_pref(integrity_conn, user_id=other_id, meal_id=liked, stance="DISLIKE")
    hidden = make_meal(
        integrity_conn,
        name="hidden",
        name_normalized="hidden",
        default_lang="en",
        is_active=False,
    )

    page = client.get("/api/v1/meals", params={"limit": 1, "offset": 1}, headers=caller)
    assert page.status_code == 200, page.text
    assert page.json()["total"] == 3
    assert [item["meal_id"] for item in page.json()["items"]] == [sorted(ids)[1]]

    full = client.get("/api/v1/meals", headers=caller)
    by_id = {item["meal_id"]: item for item in full.json()["items"]}
    assert hidden not in by_id
    assert by_id[liked]["my_stance"] == "LIKE"
    other_page = client.get("/api/v1/meals", headers=other)
    other_by_id = {item["meal_id"]: item for item in other_page.json()["items"]}
    assert other_by_id[liked]["my_stance"] == "DISLIKE"


def test_detail_language_steps_and_stored_energy(
    client: TestClient, integrity_conn: Connection
) -> None:
    headers = _auth(client, "meals-detail@example.com")
    macros = _macros(integrity_conn)
    allergen = make_allergen(integrity_conn, code="MILK")
    egg = make_allergen(integrity_conn, code="EGG")
    tag = make_dietary_tag(integrity_conn, code="vegetarian", tag_group="DIETARY")
    tomato = make_ingredient(
        integrity_conn,
        code="TOMATO",
        canonical_name="Tomato",
        canonical_name_ar="\u0637\u0645\u0627\u0637\u0645",
    )
    meal = make_meal(
        integrity_conn,
        name=SHAK,
        name_normalized=normalize_search_text(SHAK),
        default_lang="ar",
        servings=2,
        total_grams=500,
        dish_form="ONE_DISH",
        dataset_version="team_recipes_v2",
        source="NutriGuide catalog",
    )
    _amounts(integrity_conn, meal, macros, kcal=200.5, protein=1, carb=1, fat=1)
    make_meal_allergen(integrity_conn, meal_id=meal, allergen_id=allergen)
    make_meal_allergen(integrity_conn, meal_id=meal, allergen_id=egg)
    make_meal_tag(integrity_conn, meal_id=meal, tag_id=tag)
    make_meal_ingredient(
        integrity_conn, meal_id=meal, ingredient_id=tomato, position=1, grams=100, is_optional=False
    )
    make_meal_step(integrity_conn, meal_id=meal, lang="ar", position=1, text=STEP_AR)
    make_meal_translation(
        integrity_conn,
        meal_id=meal,
        lang="en",
        name="shakshuka",
        name_normalized="shakshuka",
    )
    bare = make_meal(
        integrity_conn,
        name="\u0645\u0644\u0648\u062e\u064a\u0629",
        name_normalized="\u0645\u0644\u0648\u062e\u064a\u0647",
        default_lang="ar",
    )
    inactive = make_meal(integrity_conn, is_active=False)

    arabic = client.get(f"/api/v1/meals/{meal}", headers=headers)
    assert arabic.status_code == 200, arabic.text
    body = arabic.json()
    assert body["name"] == SHAK
    assert body["steps"] == [STEP_AR]
    assert body["kcal"] == 200.5
    assert body["protein_g"] == 1
    assert body["serving_grams"] == 250
    assert body["dataset_version"] == "team_recipes_v2"
    assert body["allergens"] == ["EGG", "MILK"]
    assert body["tags"] == ["vegetarian"]
    assert body["ingredients"][0]["grams_per_serving"] == 50
    assert body["ingredients"][0]["name"] == "\u0637\u0645\u0627\u0637\u0645"
    assert [item["code"] for item in body["nutrients"]] == [
        "carbohydrate",
        "energy_kcal",
        "protein",
        "total_fat",
    ]

    english = client.get(f"/api/v1/meals/{meal}", headers={**headers, "Accept-Language": "en"})
    assert english.json()["name"] == "shakshuka"
    assert english.json()["steps"] == [STEP_AR]
    assert english.json()["ingredients"][0]["name"] == "Tomato"

    fallback = client.get(f"/api/v1/meals/{bare}", headers={**headers, "Accept-Language": "en"})
    assert fallback.status_code == 200, fallback.text
    assert fallback.json()["name"] == "\u0645\u0644\u0648\u062e\u064a\u0629"
    assert fallback.json()["steps"] == []

    missing = client.get("/api/v1/meals/999999", headers=headers)
    assert missing.status_code == 404
    assert missing.json()["code"] == "MEAL_NOT_FOUND"
    gone = client.get(f"/api/v1/meals/{inactive}", headers=headers)
    assert gone.status_code == 404
    assert gone.json()["code"] == "MEAL_NOT_FOUND"


def test_snapshot_etag_language_deactivation_and_gzip(
    client: TestClient, integrity_conn: Connection, api_session: Session
) -> None:
    headers = _auth(client, "meals-snapshot@example.com")
    meal = make_meal(
        integrity_conn,
        name="snapshot meal",
        name_normalized="snapshot meal",
        default_lang="ar",
        dataset_version="team_recipes_v1",
    )
    make_meal_step(integrity_conn, meal_id=meal, lang="ar", position=1, text="x" * 1500)
    other = make_meal(
        integrity_conn,
        name="second",
        name_normalized="second",
        default_lang="ar",
    )

    first = client.get("/api/v1/catalog/snapshot", headers=headers)
    assert first.status_code == 200, first.text
    etag = first.headers["etag"]
    assert etag.startswith('"') and etag.endswith('"')
    assert first.headers["cache-control"] == "private, no-cache"
    # GZipMiddleware appends Accept-Encoding when the body is large enough to compress.
    assert first.headers["vary"] == "Accept-Language, Authorization, Accept-Encoding"
    body = first.json()
    assert body["dataset_version"] == "unknown"
    by_id = {item["meal_id"]: item for item in body["meals"]}
    assert list(by_id) == sorted((meal, other))
    assert "my_stance" not in by_id[meal]
    assert by_id[meal]["dataset_version"] == "team_recipes_v1"

    same = client.get(
        "/api/v1/catalog/snapshot",
        headers={**headers, "If-None-Match": etag},
    )
    assert same.status_code == 304
    assert same.content == b""
    assert same.headers["etag"] == etag
    listed = client.get(
        "/api/v1/catalog/snapshot",
        headers={**headers, "If-None-Match": f'{etag}, "other"'},
    )
    assert listed.status_code == 304
    wildcard = client.get(
        "/api/v1/catalog/snapshot",
        headers={**headers, "If-None-Match": "*"},
    )
    assert wildcard.status_code == 304

    english = client.get(
        "/api/v1/catalog/snapshot",
        headers={**headers, "Accept-Language": "en"},
    )
    assert english.status_code == 200
    assert english.headers["etag"] != etag

    api_session.execute(update(Meal).where(Meal.meal_id == other).values(is_active=False))
    api_session.expire_all()
    changed = client.get("/api/v1/catalog/snapshot", headers=headers)
    assert changed.status_code == 200
    assert changed.headers["etag"] != etag
    assert [item["meal_id"] for item in changed.json()["meals"]] == [meal]

    with client.stream(
        "GET",
        "/api/v1/catalog/snapshot",
        headers={**headers, "Accept-Encoding": "gzip"},
    ) as compressed:
        raw = b"".join(compressed.iter_raw())
        assert compressed.headers["content-encoding"] == "gzip"
    assert len(gzip.decompress(raw)) > len(raw)
    assert len(gzip.decompress(raw)) >= 1024
