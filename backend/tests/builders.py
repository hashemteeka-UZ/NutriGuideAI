"""Valid-row builders for integrity tests. Each make_* inserts one valid row and returns its key."""

from __future__ import annotations

from collections.abc import Callable
from datetime import UTC, date, datetime, timedelta
from itertools import count
from typing import Any
from uuid import uuid4

from sqlalchemy import Table, insert
from sqlalchemy.engine import Connection, Row

import app.db.models  # noqa: F401  (registers every model on Base.metadata)
from app.db.base import Base

_n = count(1)


def nxt() -> int:
    return next(_n)


def table(name: str) -> Table:
    return Base.metadata.tables[name]


def insert_values(conn: Connection, table_name: str, values: dict[str, Any]) -> Row[Any]:
    tbl = table(table_name)
    pk_cols = list(tbl.primary_key.columns)
    return conn.execute(insert(tbl).values(**values).returning(*pk_cols)).one()


def values_for(conn: Connection, table_name: str, **overrides: Any) -> dict[str, Any]:
    return VALUE_BUILDERS[table_name](conn, **overrides)


def make_row(conn: Connection, table_name: str, **overrides: Any) -> Any:
    row = insert_values(conn, table_name, values_for(conn, table_name, **overrides))
    if len(row) == 1:
        return row[0]
    return tuple(row)


# --- REFERENCE ----------------------------------------------------------------


def values_categories(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {"name_en": f"category-{n}", "name_ar": f"تصنيف-{n}", **overrides}


def values_cuisines(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {"code": f"CUISINE_{n}", "name_en": f"cuisine-{n}", "name_ar": f"مطبخ-{n}", **overrides}


def values_allergens(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "code": f"ALLERGEN_{n}",
        "name_en": f"allergen-{n}",
        "name_ar": f"مسبب-{n}",
        **overrides,
    }


def values_dietary_tags(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "code": f"tag_{n}",
        "name_en": f"tag-{n}",
        "name_ar": f"وسم-{n}",
        "tag_group": "DIETARY",
        **overrides,
    }


def values_health_conditions(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "code": f"cond_{n}",
        "name_en": f"condition-{n}",
        "name_ar": f"حالة-{n}",
        **overrides,
    }


def values_nutrients(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {"code": f"nut_{n}", "name": f"nutrient-{n}", "unit": "g", **overrides}


def values_foods(conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    values: dict[str, Any] = {
        "description": f"food-{n}",
        "basis_grams": 100,
        "external_source": "MANUAL",
        "external_code": f"food-{n}",
        "state": "raw",
        "source_reference": "test",
        **overrides,
    }
    if "category_id" not in values:
        values["category_id"] = make_category(conn)
    return values


def values_food_nutrients(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"amount_per_100g": 1, **overrides}
    if "food_id" not in values:
        values["food_id"] = make_food(conn)
    if "nutrient_id" not in values:
        values["nutrient_id"] = make_nutrient(conn)
    return values


def values_portions_food(conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    values: dict[str, Any] = {
        "unit_text": f"unit-{n}",
        "amount": 1,
        "gram_weight": 10,
        **overrides,
    }
    if "food_id" not in values:
        values["food_id"] = make_food(conn)
    return values


def values_ingredients(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "canonical_name": f"ingredient-{n}",
        "canonical_name_ar": f"مكون-{n}",
        **overrides,
    }


def values_ingredient_aliases(conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    values: dict[str, Any] = {
        "alias_text": f"alias-{n}",
        "lang": "en",
        "alias_normalized": f"alias-{n}",
        **overrides,
    }
    if "ingredient_id" not in values:
        values["ingredient_id"] = make_ingredient(conn)
    return values


def values_ingredient_allergens(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = dict(overrides)
    if "ingredient_id" not in values:
        values["ingredient_id"] = make_ingredient(conn)
    if "allergen_id" not in values:
        values["allergen_id"] = make_allergen(conn)
    return values


def values_ingredient_tags(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = dict(overrides)
    if "ingredient_id" not in values:
        values["ingredient_id"] = make_ingredient(conn)
    if "tag_id" not in values:
        values["tag_id"] = make_dietary_tag(conn)
    return values


def values_condition_nutrient_limits(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "limit_basis": "ABSOLUTE",
        "max_per_day": 10,
        "source_reference": "test-guideline",
        **overrides,
    }
    if "condition_id" not in values:
        values["condition_id"] = make_health_condition(conn)
    if "nutrient_id" not in values:
        values["nutrient_id"] = make_nutrient(conn)
    return values


def values_condition_tag_restrictions(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"restriction_type": "AVOID", **overrides}
    if "condition_id" not in values:
        values["condition_id"] = make_health_condition(conn)
    if "tag_id" not in values:
        values["tag_id"] = make_dietary_tag(conn)
    return values


# --- CATALOG ------------------------------------------------------------------


def values_meals(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "name": f"meal-{n}",
        "default_lang": "en",
        "name_normalized": f"meal-{n}",
        "servings": 1,
        "total_grams": 250,
        "weight_method": "WEIGHED",
        "source": f"src-{n}",
        "source_license": "CC-BY-4.0",
        "quality_tier": "GOLD",
        "dataset_version": "test_v1",
        **overrides,
    }


def values_meal_ingredients(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"position": 1, "grams": 50, **overrides}
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    if "ingredient_id" not in values:
        values["ingredient_id"] = make_ingredient(conn)
    return values


def values_meal_nutrients(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "amount_per_serving": 1,
        "amount_per_100g": 1,
        "computed_at": datetime(2026, 1, 1, tzinfo=UTC),
        "computation_version": "calc_v1",
        **overrides,
    }
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    if "nutrient_id" not in values:
        values["nutrient_id"] = make_nutrient(conn)
    return values


def values_meal_allergens(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = dict(overrides)
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    if "allergen_id" not in values:
        values["allergen_id"] = make_allergen(conn)
    return values


def values_meal_tags(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"source": "MANUAL", **overrides}
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    if "tag_id" not in values:
        values["tag_id"] = make_dietary_tag(conn)
    return values


def values_meal_translations(conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    values: dict[str, Any] = {
        "lang": "ar",
        "name": f"وجبة-{n}",
        "name_normalized": f"وجبه-{n}",
        **overrides,
    }
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    return values


# --- USER ---------------------------------------------------------------------


def values_users(_conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    return {
        "email": f"user{n}@example.com",
        "hashed_password": "hashed",
        **overrides,
    }


def values_user_profiles(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "sex": "FEMALE",
        "birth_date": date(1990, 6, 15),
        "height_cm": 165,
        "activity_level": "MODERATE",
        "goal_type": "MAINTAIN",
        "timezone": "UTC",
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


def values_user_health_conditions(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = dict(overrides)
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    if "condition_id" not in values:
        values["condition_id"] = make_health_condition(conn)
    return values


def values_user_allergen_prefs(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"severity": "AVOID", **overrides}
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    if "allergen_id" not in values:
        values["allergen_id"] = make_allergen(conn)
    return values


def values_user_ingredient_prefs(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"stance": "LIKE", **overrides}
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    if "ingredient_id" not in values:
        values["ingredient_id"] = make_ingredient(conn)
    return values


def values_user_interactions(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {"event_type": "VIEW", **overrides}
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    return values


def values_user_targets(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "valid_from": datetime(2026, 1, 1, tzinfo=UTC),
        "based_on_weight_kg": 70,
        "bmr_kcal": 1500,
        "tdee_kcal": 2000,
        "target_kcal": 1800,
        "target_protein_g": 90,
        "target_carb_g": 200,
        "target_fat_g": 60,
        "formula_version": "targets_v1",
        "reason": "INITIAL",
        "was_floor_applied": False,
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


def values_meal_plans(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "date_from": date(2026, 2, 1),
        "date_to": date(2026, 2, 7),
        "generated_by": "test",
        "algorithm_version": "rec_v1",
        "target_snapshot": {"target_kcal": 1800},
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


def values_meal_plan_items(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "day_index": 0,
        "slot": "LUNCH",
        "servings_multiplier": 1.0,
        **overrides,
    }
    if "plan_id" not in values:
        values["plan_id"] = make_meal_plan(conn)
    if "meal_id" not in values:
        values["meal_id"] = make_meal(conn)
    return values


def values_consumption_logs(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "consumed_at": datetime(2026, 3, 1, 12, 0, tzinfo=UTC),
        "log_date": date(2026, 3, 1),
        "nutrients_snapshot": {"kcal": 400},
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    has_meal = "meal_id" in values
    has_food = "food_id" in values
    if not has_meal and not has_food:
        values["meal_id"] = make_meal(conn)
        values.setdefault("servings_consumed", 1)
        values.setdefault("grams_consumed", None)
    elif has_meal and values["meal_id"] is not None:
        values.setdefault("servings_consumed", 1)
        values.setdefault("grams_consumed", None)
    elif has_food and values["food_id"] is not None:
        values.setdefault("grams_consumed", 50)
        values.setdefault("servings_consumed", None)
    return values


def values_weight_logs(conn: Connection, **overrides: Any) -> dict[str, Any]:
    n = nxt()
    values: dict[str, Any] = {
        "measured_on": date(2026, 1, 1) + timedelta(days=n),
        "weight_kg": 70,
        "source": "MANUAL",
        "updated_at": datetime(2026, 1, 1, tzinfo=UTC),
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


def values_refresh_tokens(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "token_hash": uuid4().hex,
        "family_id": uuid4(),
        "expires_at": datetime.now(UTC) + timedelta(days=30),
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


def values_water_logs(conn: Connection, **overrides: Any) -> dict[str, Any]:
    values: dict[str, Any] = {
        "consumed_at": datetime(2026, 3, 1, 8, 0, tzinfo=UTC),
        "log_date": date(2026, 3, 1),
        "amount_ml": 250,
        **overrides,
    }
    if "user_id" not in values:
        values["user_id"] = make_user(conn)
    return values


VALUE_BUILDERS: dict[str, Callable[..., dict[str, Any]]] = {
    "categories": values_categories,
    "cuisines": values_cuisines,
    "allergens": values_allergens,
    "dietary_tags": values_dietary_tags,
    "health_conditions": values_health_conditions,
    "nutrients": values_nutrients,
    "foods": values_foods,
    "food_nutrients": values_food_nutrients,
    "portions_food": values_portions_food,
    "ingredients": values_ingredients,
    "ingredient_aliases": values_ingredient_aliases,
    "ingredient_allergens": values_ingredient_allergens,
    "ingredient_tags": values_ingredient_tags,
    "condition_nutrient_limits": values_condition_nutrient_limits,
    "condition_tag_restrictions": values_condition_tag_restrictions,
    "meals": values_meals,
    "meal_ingredients": values_meal_ingredients,
    "meal_nutrients": values_meal_nutrients,
    "meal_allergens": values_meal_allergens,
    "meal_tags": values_meal_tags,
    "meal_translations": values_meal_translations,
    "users": values_users,
    "user_profiles": values_user_profiles,
    "user_health_conditions": values_user_health_conditions,
    "user_allergen_prefs": values_user_allergen_prefs,
    "user_ingredient_prefs": values_user_ingredient_prefs,
    "user_interactions": values_user_interactions,
    "user_targets": values_user_targets,
    "meal_plans": values_meal_plans,
    "meal_plan_items": values_meal_plan_items,
    "consumption_logs": values_consumption_logs,
    "weight_logs": values_weight_logs,
    "refresh_tokens": values_refresh_tokens,
    "water_logs": values_water_logs,
}


def make_category(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "categories", **overrides)


def make_cuisine(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "cuisines", **overrides)


def make_allergen(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "allergens", **overrides)


def make_dietary_tag(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "dietary_tags", **overrides)


def make_health_condition(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "health_conditions", **overrides)


def make_nutrient(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "nutrients", **overrides)


def make_food(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "foods", **overrides)


def make_food_nutrient(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "food_nutrients", **overrides)


def make_portion_food(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "portions_food", **overrides)


def make_ingredient(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "ingredients", **overrides)


def make_ingredient_alias(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "ingredient_aliases", **overrides)


def make_ingredient_allergen(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "ingredient_allergens", **overrides)


def make_ingredient_tag(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "ingredient_tags", **overrides)


def make_condition_nutrient_limit(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "condition_nutrient_limits", **overrides)


def make_condition_tag_restriction(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "condition_tag_restrictions", **overrides)


def make_meal(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "meals", **overrides)


def make_meal_ingredient(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "meal_ingredients", **overrides)


def make_meal_nutrient(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "meal_nutrients", **overrides)


def make_meal_allergen(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "meal_allergens", **overrides)


def make_meal_tag(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "meal_tags", **overrides)


def make_meal_translation(conn: Connection, **overrides: Any) -> tuple[int, str]:
    return make_row(conn, "meal_translations", **overrides)


def make_user(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "users", **overrides)


def make_user_profile(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "user_profiles", **overrides)


def make_user_health_condition(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "user_health_conditions", **overrides)


def make_user_allergen_pref(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "user_allergen_prefs", **overrides)


def make_user_ingredient_pref(conn: Connection, **overrides: Any) -> tuple[int, int]:
    return make_row(conn, "user_ingredient_prefs", **overrides)


def make_user_interaction(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "user_interactions", **overrides)


def make_user_target(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "user_targets", **overrides)


def make_meal_plan(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "meal_plans", **overrides)


def make_meal_plan_item(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "meal_plan_items", **overrides)


def make_consumption_log(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "consumption_logs", **overrides)


def make_weight_log(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "weight_logs", **overrides)


def make_refresh_token(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "refresh_tokens", **overrides)


def make_water_log(conn: Connection, **overrides: Any) -> int:
    return make_row(conn, "water_logs", **overrides)


MAKERS: dict[str, Callable[..., Any]] = {
    name: globals()[fn_name]
    for name, fn_name in {
        "categories": "make_category",
        "cuisines": "make_cuisine",
        "allergens": "make_allergen",
        "dietary_tags": "make_dietary_tag",
        "health_conditions": "make_health_condition",
        "nutrients": "make_nutrient",
        "foods": "make_food",
        "food_nutrients": "make_food_nutrient",
        "portions_food": "make_portion_food",
        "ingredients": "make_ingredient",
        "ingredient_aliases": "make_ingredient_alias",
        "ingredient_allergens": "make_ingredient_allergen",
        "ingredient_tags": "make_ingredient_tag",
        "condition_nutrient_limits": "make_condition_nutrient_limit",
        "condition_tag_restrictions": "make_condition_tag_restriction",
        "meals": "make_meal",
        "meal_ingredients": "make_meal_ingredient",
        "meal_nutrients": "make_meal_nutrient",
        "meal_allergens": "make_meal_allergen",
        "meal_tags": "make_meal_tag",
        "meal_translations": "make_meal_translation",
        "users": "make_user",
        "user_profiles": "make_user_profile",
        "user_health_conditions": "make_user_health_condition",
        "user_allergen_prefs": "make_user_allergen_pref",
        "user_ingredient_prefs": "make_user_ingredient_pref",
        "user_interactions": "make_user_interaction",
        "user_targets": "make_user_target",
        "meal_plans": "make_meal_plan",
        "meal_plan_items": "make_meal_plan_item",
        "consumption_logs": "make_consumption_log",
        "weight_logs": "make_weight_log",
        "refresh_tokens": "make_refresh_token",
        "water_logs": "make_water_log",
    }.items()
}
