"""REFERENCE-domain integrity tests (§19 verification 1-3, 7 and related bullets)."""

from __future__ import annotations

from sqlalchemy import delete
from sqlalchemy.engine import Connection

from tests.builders import (
    make_allergen,
    make_category,
    make_condition_nutrient_limit,
    make_condition_tag_restriction,
    make_cuisine,
    make_dietary_tag,
    make_food,
    make_food_nutrient,
    make_health_condition,
    make_ingredient,
    make_ingredient_alias,
    make_ingredient_allergen,
    make_ingredient_tag,
    make_meal_ingredient,
    make_nutrient,
    make_portion_food,
    table,
)
from tests.integrity.helpers import assert_rejects, fetch_by_pk


def test_verification_1_reference_records_insert(integrity_conn: Connection) -> None:
    assert make_category(integrity_conn) > 0
    assert make_dietary_tag(integrity_conn) > 0
    assert make_health_condition(integrity_conn) > 0
    assert make_nutrient(integrity_conn) > 0
    assert make_allergen(integrity_conn) > 0


def test_verification_2_food_category_nutrient_portion_relationships(
    integrity_conn: Connection,
) -> None:
    category_id = make_category(integrity_conn)
    food_id = make_food(integrity_conn, category_id=category_id)
    nutrient_id = make_nutrient(integrity_conn)
    make_food_nutrient(integrity_conn, food_id=food_id, nutrient_id=nutrient_id)
    portion_id = make_portion_food(integrity_conn, food_id=food_id)
    row = fetch_by_pk(integrity_conn, "foods", food_id)
    assert row is not None
    assert row.category_id == category_id
    assert fetch_by_pk(integrity_conn, "portions_food", portion_id) is not None


def test_verification_3_ingredient_food_alias_allergen_tag_relationships(
    integrity_conn: Connection,
) -> None:
    food_id = make_food(integrity_conn)
    ingredient_id = make_ingredient(integrity_conn, default_food_id=food_id)
    make_ingredient_alias(integrity_conn, ingredient_id=ingredient_id)
    make_ingredient_allergen(integrity_conn, ingredient_id=ingredient_id)
    make_ingredient_tag(integrity_conn, ingredient_id=ingredient_id)
    row = fetch_by_pk(integrity_conn, "ingredients", ingredient_id)
    assert row is not None
    assert row.default_food_id == food_id


def test_verification_7_health_condition_limit_and_tag_restriction_relationships(
    integrity_conn: Connection,
) -> None:
    condition_id = make_health_condition(integrity_conn)
    make_condition_nutrient_limit(integrity_conn, condition_id=condition_id)
    make_condition_tag_restriction(integrity_conn, condition_id=condition_id)
    assert fetch_by_pk(integrity_conn, "health_conditions", condition_id) is not None


def test_deleting_ingredient_referenced_by_meal_ingredients_restricted(
    integrity_conn: Connection,
) -> None:
    ingredient_id = make_ingredient(integrity_conn)
    make_meal_ingredient(integrity_conn, ingredient_id=ingredient_id)
    ingredients = table("ingredients")
    assert_rejects(
        integrity_conn,
        "fk_meal_ingredients_ingredient_id_ingredients",
        lambda: integrity_conn.execute(
            delete(ingredients).where(ingredients.c.ingredient_id == ingredient_id)
        ),
    )


def test_deleting_food_sets_ingredient_default_food_id_null(
    integrity_conn: Connection,
) -> None:
    food_id = make_food(integrity_conn)
    ingredient_id = make_ingredient(integrity_conn, default_food_id=food_id)
    foods = table("foods")
    integrity_conn.execute(delete(foods).where(foods.c.food_id == food_id))
    row = fetch_by_pk(integrity_conn, "ingredients", ingredient_id)
    assert row is not None
    assert row.default_food_id is None


def test_deleting_ingredient_cascades_to_ingredient_allergens(
    integrity_conn: Connection,
) -> None:
    ingredient_id = make_ingredient(integrity_conn)
    allergen_id = make_allergen(integrity_conn)
    make_ingredient_allergen(integrity_conn, ingredient_id=ingredient_id, allergen_id=allergen_id)
    ingredients = table("ingredients")
    integrity_conn.execute(delete(ingredients).where(ingredients.c.ingredient_id == ingredient_id))
    assert fetch_by_pk(integrity_conn, "ingredient_allergens", (ingredient_id, allergen_id)) is None
    assert fetch_by_pk(integrity_conn, "allergens", allergen_id) is not None


def test_condition_nutrient_limits_all_three_limit_columns_null_rejected(
    integrity_conn: Connection,
) -> None:
    assert_rejects(
        integrity_conn,
        "ck_condition_nutrient_limits_at_least_one_limit",
        lambda: make_condition_nutrient_limit(
            integrity_conn, max_per_meal=None, max_per_day=None, min_per_day=None
        ),
    )


def test_condition_nutrient_limits_min_per_day_greater_than_max_rejected(
    integrity_conn: Connection,
) -> None:
    assert_rejects(
        integrity_conn,
        "ck_condition_nutrient_limits_min_le_max",
        lambda: make_condition_nutrient_limit(integrity_conn, min_per_day=20, max_per_day=10),
    )


def test_condition_nutrient_limits_percent_energy_value_150_rejected(
    integrity_conn: Connection,
) -> None:
    assert_rejects(
        integrity_conn,
        "ck_condition_nutrient_limits_percent_max_100",
        lambda: make_condition_nutrient_limit(
            integrity_conn, limit_basis="PERCENT_ENERGY", max_per_day=150
        ),
    )


def test_deleting_dietary_tags_referenced_by_ingredient_tags_restricted(
    integrity_conn: Connection,
) -> None:
    tag_id = make_dietary_tag(integrity_conn)
    make_ingredient_tag(integrity_conn, tag_id=tag_id)
    tags = table("dietary_tags")
    assert_rejects(
        integrity_conn,
        "fk_ingredient_tags_tag_id_dietary_tags",
        lambda: integrity_conn.execute(delete(tags).where(tags.c.tag_id == tag_id)),
    )


def test_duplicate_nutrients_code_rejected(integrity_conn: Connection) -> None:
    make_nutrient(integrity_conn, code="ENERGY")
    assert_rejects(
        integrity_conn,
        "uq_nutrients_code",
        lambda: make_nutrient(integrity_conn, code="ENERGY"),
    )


def test_duplicate_dietary_tags_code_rejected(integrity_conn: Connection) -> None:
    make_dietary_tag(integrity_conn, code="VEGAN")
    assert_rejects(
        integrity_conn,
        "uq_dietary_tags_code",
        lambda: make_dietary_tag(integrity_conn, code="VEGAN"),
    )


def test_categories_name_en_unique(integrity_conn: Connection) -> None:
    make_category(integrity_conn, name_en="Vegetables and Vegetable Products")
    make_category(integrity_conn, name_en="Spices and Herbs")
    assert_rejects(
        integrity_conn,
        "uq_categories_name_en",
        lambda: make_category(integrity_conn, name_en="Spices and Herbs"),
    )


def test_cuisines_code_unique(integrity_conn: Connection) -> None:
    make_cuisine(integrity_conn, code="LIBYAN")
    make_cuisine(integrity_conn, code="LEVANTINE")
    assert_rejects(
        integrity_conn,
        "uq_cuisines_code",
        lambda: make_cuisine(integrity_conn, code="LIBYAN"),
    )


def test_allergens_code_unique(integrity_conn: Connection) -> None:
    make_allergen(integrity_conn, code="GLUTEN")
    make_allergen(integrity_conn, code="TREE_NUTS")
    assert_rejects(
        integrity_conn,
        "uq_allergens_code",
        lambda: make_allergen(integrity_conn, code="GLUTEN"),
    )


def test_two_foods_same_external_source_and_code_rejected(integrity_conn: Connection) -> None:
    make_food(integrity_conn, external_source="FDC", external_code="111")
    assert_rejects(
        integrity_conn,
        "uq_foods_external_source_external_code",
        lambda: make_food(integrity_conn, external_source="FDC", external_code="111"),
    )


def test_foods_external_source_out_of_set_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_foods_external_source_valid",
        lambda: make_food(integrity_conn, external_source="USDA"),
    )


def test_foods_null_fdc_id_with_valid_external_identity_accepted(
    integrity_conn: Connection,
) -> None:
    food_id = make_food(
        integrity_conn, fdc_id=None, external_source="FNDDS_FOOD", external_code="no-fdc"
    )
    row = fetch_by_pk(integrity_conn, "foods", food_id)
    assert row is not None
    assert row.fdc_id is None


def test_health_conditions_fluid_goal_requires_clinician_defaults_false(
    integrity_conn: Connection,
) -> None:
    condition_id = make_health_condition(integrity_conn)
    row = fetch_by_pk(integrity_conn, "health_conditions", condition_id)
    assert row is not None
    assert row.fluid_goal_requires_clinician is False


def test_ingredients_review_status_defaults_to_pending(integrity_conn: Connection) -> None:
    ingredient_id = make_ingredient(integrity_conn)
    row = fetch_by_pk(integrity_conn, "ingredients", ingredient_id)
    assert row is not None
    assert row.review_status == "PENDING"
