"""A meal page loads related rows in a fixed number of queries (#184, #189)."""

import logging

import pytest
from sqlalchemy import delete, event
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import MealNutrient
from app.services.common import MealNotFoundError
from app.services.meal_catalog import catalog_snapshot, get_meal, list_meals
from tests.builders import (
    make_allergen,
    make_dietary_tag,
    make_meal,
    make_meal_allergen,
    make_meal_nutrient,
    make_meal_tag,
    make_meal_translation,
    make_nutrient,
    make_user,
    make_user_meal_pref,
)


def test_a_twenty_meal_page_uses_seven_selects(
    session: Session, integrity_conn: Connection
) -> None:
    user = make_user(integrity_conn)
    energy = make_nutrient(integrity_conn, code="energy_kcal", unit="kcal")
    protein = make_nutrient(integrity_conn, code="protein", unit="g")
    carb = make_nutrient(integrity_conn, code="carbohydrate", unit="g")
    fat = make_nutrient(integrity_conn, code="total_fat", unit="g")
    tag = make_dietary_tag(integrity_conn, code="breakfast_suitable", tag_group="OCCASION")
    allergen = make_allergen(integrity_conn, code="EGG")
    for index in range(20):
        meal = make_meal(
            integrity_conn,
            name=f"meal-{index:02d}",
            name_normalized=f"meal-{index:02d}",
            default_lang="en",
            servings=2,
            total_grams=400,
        )
        make_meal_nutrient(
            integrity_conn,
            meal_id=meal,
            nutrient_id=energy,
            amount_per_serving=100,
            amount_per_100g=50,
        )
        make_meal_nutrient(
            integrity_conn,
            meal_id=meal,
            nutrient_id=protein,
            amount_per_serving=10,
            amount_per_100g=5,
        )
        make_meal_nutrient(
            integrity_conn,
            meal_id=meal,
            nutrient_id=carb,
            amount_per_serving=20,
            amount_per_100g=10,
        )
        make_meal_nutrient(
            integrity_conn,
            meal_id=meal,
            nutrient_id=fat,
            amount_per_serving=5,
            amount_per_100g=2,
        )
        make_meal_tag(integrity_conn, meal_id=meal, tag_id=tag)
        make_meal_allergen(integrity_conn, meal_id=meal, allergen_id=allergen)
        make_meal_translation(
            integrity_conn,
            meal_id=meal,
            lang="ar",
            name=f"w-{index:02d}",
            name_normalized=f"w-{index:02d}",
        )
        make_user_meal_pref(integrity_conn, user_id=user, meal_id=meal, stance="LIKE")

    statements: list[str] = []

    def _before(_conn, _cursor, statement: str, _parameters, _context, _executemany: bool) -> None:
        if statement.lstrip().upper().startswith(("SELECT", "WITH")):
            statements.append(statement)

    bind = session.connection()
    event.listen(bind, "before_cursor_execute", _before)
    try:
        items, total = list_meals(
            session,
            user,
            q=None,
            slot=None,
            cuisine=None,
            lang="en",
            limit=20,
            offset=0,
        )
    finally:
        event.remove(bind, "before_cursor_execute", _before)

    assert total == 20
    assert len(items) == 20
    assert len(statements) == 7
    assert items[0].kcal == 100
    assert items[0].protein_g == 10
    assert items[0].carb_g == 20
    assert items[0].fat_g == 5
    assert items[0].my_stance == "LIKE"


def test_a_meal_missing_energy_is_left_out_and_warned(
    session: Session, integrity_conn: Connection, caplog: pytest.LogCaptureFixture
) -> None:
    user = make_user(integrity_conn)
    energy = make_nutrient(integrity_conn, code="energy_kcal", unit="kcal")
    protein = make_nutrient(integrity_conn, code="protein", unit="g")
    carb = make_nutrient(integrity_conn, code="carbohydrate", unit="g")
    fat = make_nutrient(integrity_conn, code="total_fat", unit="g")
    meal = make_meal(integrity_conn, name="plain", name_normalized="plain", default_lang="en")
    for nutrient, amount in ((energy, 100), (protein, 10), (carb, 20), (fat, 5)):
        make_meal_nutrient(
            integrity_conn,
            meal_id=meal,
            nutrient_id=nutrient,
            amount_per_serving=amount,
            amount_per_100g=amount,
        )
    session.execute(
        delete(MealNutrient).where(MealNutrient.meal_id == meal, MealNutrient.nutrient_id == energy)
    )
    session.expire_all()

    with caplog.at_level(logging.WARNING):
        items, total = list_meals(
            session, user, q=None, slot=None, cuisine=None, lang="en", limit=20, offset=0
        )
        snapshot, _tag = catalog_snapshot(session, "en")
        with pytest.raises(MealNotFoundError):
            get_meal(session, user, meal, "en")

    assert total == 0
    assert items == ()
    meals = snapshot["meals"]
    assert isinstance(meals, list)
    assert meals == []
    warnings = [
        record.getMessage() for record in caplog.records if record.levelno >= logging.WARNING
    ]
    assert any(str(meal) in message and "energy_kcal" in message for message in warnings)
