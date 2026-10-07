"""CATALOG-domain integrity tests (§19 verification 4 and related bullets)."""

from __future__ import annotations

from sqlalchemy import delete, text, update
from sqlalchemy.engine import Connection

from tests.builders import (
    make_consumption_log,
    make_meal,
    make_meal_allergen,
    make_meal_ingredient,
    make_meal_nutrient,
    make_meal_plan_item,
    make_meal_tag,
    make_meal_translation,
    make_user_interaction,
    table,
)
from tests.integrity.helpers import assert_rejected, assert_rejects, fetch_by_pk


def test_verification_4_meal_child_relationships(integrity_conn: Connection) -> None:
    meal_id = make_meal(integrity_conn)
    make_meal_ingredient(integrity_conn, meal_id=meal_id)
    make_meal_nutrient(integrity_conn, meal_id=meal_id)
    make_meal_allergen(integrity_conn, meal_id=meal_id)
    make_meal_tag(integrity_conn, meal_id=meal_id)
    make_meal_translation(integrity_conn, meal_id=meal_id)
    assert fetch_by_pk(integrity_conn, "meals", meal_id) is not None


def test_meal_ingredients_grams_zero_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_meal_ingredients_grams_positive",
        lambda: make_meal_ingredient(integrity_conn, grams=0),
    )


def test_meal_ingredients_grams_negative_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_meal_ingredients_grams_positive",
        lambda: make_meal_ingredient(integrity_conn, grams=-5),
    )


def test_meal_plan_items_servings_multiplier_0_7_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_meal_plan_items_servings_multiplier_step",
        lambda: make_meal_plan_item(integrity_conn, servings_multiplier=0.7),
    )


def test_meal_translations_lang_ara_rejected_ar_accepted(integrity_conn: Connection) -> None:
    make_meal_translation(integrity_conn, lang="ar")
    # 'ARA' is three characters: VARCHAR(2) rejects it before the ISO 639-1 CHECK.
    assert_rejected(
        integrity_conn,
        lambda: make_meal_translation(integrity_conn, lang="ARA"),
    )


def test_meal_ingredients_position_zero_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_meal_ingredients_position_min_1",
        lambda: make_meal_ingredient(integrity_conn, position=0),
    )


def test_meal_nutrients_amount_per_serving_negative_rejected(
    integrity_conn: Connection,
) -> None:
    assert_rejects(
        integrity_conn,
        "ck_meal_nutrients_amount_per_serving_non_negative",
        lambda: make_meal_nutrient(integrity_conn, amount_per_serving=-1),
    )


def test_soft_deleting_meal_keeps_user_interactions(integrity_conn: Connection) -> None:
    meal_id = make_meal(integrity_conn)
    interaction_id = make_user_interaction(integrity_conn, meal_id=meal_id)
    meals = table("meals")
    integrity_conn.execute(update(meals).where(meals.c.meal_id == meal_id).values(is_active=False))
    assert fetch_by_pk(integrity_conn, "user_interactions", interaction_id) is not None
    meal = fetch_by_pk(integrity_conn, "meals", meal_id)
    assert meal is not None
    assert meal.is_active is False


def test_query_pattern_inactive_meals_excluded_from_active_catalog(
    integrity_conn: Connection,
) -> None:
    """Application filter: search/recommendation uses `is_active` (§15.8, §19 v4.1)."""
    active_id = make_meal(integrity_conn)
    inactive_id = make_meal(integrity_conn, is_active=False)
    rows = integrity_conn.execute(text("SELECT meal_id FROM meals WHERE is_active")).scalars().all()
    assert active_id in rows
    assert inactive_id not in rows


def test_hard_deleting_meal_referenced_by_consumption_logs_restricted(
    integrity_conn: Connection,
) -> None:
    meal_id = make_meal(integrity_conn)
    log_id = make_consumption_log(integrity_conn, meal_id=meal_id)
    meals = table("meals")
    assert_rejects(
        integrity_conn,
        "fk_consumption_logs_meal_id_meals",
        lambda: integrity_conn.execute(delete(meals).where(meals.c.meal_id == meal_id)),
    )
    assert fetch_by_pk(integrity_conn, "consumption_logs", log_id) is not None


def test_meals_is_active_defaults_true(integrity_conn: Connection) -> None:
    meal_id = make_meal(integrity_conn)
    row = fetch_by_pk(integrity_conn, "meals", meal_id)
    assert row is not None
    assert row.is_active is True


def test_meals_is_verified_defaults_false(integrity_conn: Connection) -> None:
    meal_id = make_meal(integrity_conn)
    row = fetch_by_pk(integrity_conn, "meals", meal_id)
    assert row is not None
    assert row.is_verified is False


def test_meals_yield_factor_range(integrity_conn: Connection) -> None:
    for factor in (0.001, 3):
        make_meal(integrity_conn, weight_method="YIELD_FACTOR", yield_factor=factor)
    for factor in (0, 3.001):
        assert_rejects(
            integrity_conn,
            "ck_meals_yield_factor_range",
            lambda factor=factor: make_meal(
                integrity_conn, weight_method="YIELD_FACTOR", yield_factor=factor
            ),
        )


def test_meals_yield_factor_only_for_yield_factor_method(integrity_conn: Connection) -> None:
    make_meal(integrity_conn, weight_method="YIELD_FACTOR", yield_factor=None)
    make_meal(integrity_conn, weight_method="SUM_OF_INGREDIENTS", yield_factor=None)
    assert_rejects(
        integrity_conn,
        "ck_meals_yield_factor_only_for_yield_method",
        lambda: make_meal(integrity_conn, weight_method="SUM_OF_INGREDIENTS", yield_factor=1),
    )


def test_meals_variant_group_is_optional_and_shared(integrity_conn: Connection) -> None:
    make_meal(integrity_conn, variant_group="couscous")
    make_meal(integrity_conn, variant_group="couscous")
    meal_id = make_meal(integrity_conn, variant_group=None)
    row = fetch_by_pk(integrity_conn, "meals", meal_id)
    assert row is not None
    assert row.variant_group is None


def test_meal_tags_rule_version_only_for_derived(integrity_conn: Connection) -> None:
    make_meal_tag(integrity_conn, source="DERIVED", rule_version="tags_v1")
    make_meal_tag(integrity_conn, source="DERIVED", rule_version=None)
    make_meal_tag(integrity_conn, source="MANUAL", rule_version=None)
    assert_rejects(
        integrity_conn,
        "ck_meal_tags_rule_version_only_derived",
        lambda: make_meal_tag(integrity_conn, source="MANUAL", rule_version="tags_v1"),
    )


def test_meal_ingredients_is_optional_defaults_false(integrity_conn: Connection) -> None:
    pk = make_meal_ingredient(integrity_conn)
    row = fetch_by_pk(integrity_conn, "meal_ingredients", pk)
    assert row is not None
    assert row.is_optional is False
    optional = fetch_by_pk(
        integrity_conn, "meal_ingredients", make_meal_ingredient(integrity_conn, is_optional=True)
    )
    assert optional is not None
    assert optional.is_optional is True
