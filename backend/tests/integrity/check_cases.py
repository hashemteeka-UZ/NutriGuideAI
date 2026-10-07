"""CHECK constraint cases: one accepted boundary and one rejection per constraint."""

from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from typing import Any
from uuid import uuid4

from sqlalchemy.engine import Connection

from tests.builders import (
    make_dietary_tag,
    make_food,
    make_health_condition,
    make_meal,
    make_meal_plan,
    make_meal_plan_item,
    make_nutrient,
    make_user,
)
from tests.test_models_metadata import ENUM_COLUMNS

Overrides = Mapping[str, Any] | Callable[[Connection], dict[str, Any]]


@dataclass(frozen=True)
class CheckCase:
    table: str
    positive: Overrides = field(default_factory=dict)
    negative: Overrides = field(default_factory=dict)


def resolve(overrides: Overrides, conn: Connection) -> dict[str, Any]:
    if callable(overrides):
        return overrides(conn)
    return dict(overrides)


ENUM_INVALID = "NOT_A_VALID_ENUM_VALUE"
# Extra columns so an out-of-set enum doesn't fail a different CHECK first.
ENUM_ROW_EXTRAS: dict[tuple[str, str], dict[str, Any]] = {
    ("user_profiles", "goal_type"): {"target_weight_kg": 70, "weekly_rate_kg": 0.5},
}


def _enum_cases() -> dict[str, CheckCase]:
    cases: dict[str, CheckCase] = {}
    for (table_name, column), enum_cls in ENUM_COLUMNS.items():
        name = f"ck_{table_name}_{column}_valid"
        extras = ENUM_ROW_EXTRAS.get((table_name, column), {})
        cases[name] = CheckCase(
            table=table_name,
            positive={column: next(iter(enum_cls)).value, **extras},
            negative={column: ENUM_INVALID, **extras},
        )
    return cases


def _food_log(conn: Connection, **extra: Any) -> dict[str, Any]:
    return {
        "meal_id": None,
        "food_id": make_food(conn),
        "servings_consumed": None,
        "grams_consumed": 50,
        **extra,
    }


def _plan_item_on_food(conn: Connection) -> dict[str, Any]:
    return _food_log(conn, plan_item_id=make_meal_plan_item(conn), meal_id=None)


def _issued_and_expired_equal(_conn: Connection) -> dict[str, Any]:
    ts = datetime(2026, 1, 1, tzinfo=UTC)
    return {"issued_at": ts, "expires_at": ts}


CHECK_CASES: dict[str, CheckCase] = {
    **_enum_cases(),
    "ck_condition_nutrient_limits_at_least_one_limit": CheckCase(
        table="condition_nutrient_limits",
        positive={"max_per_day": 1, "max_per_meal": None, "min_per_day": None},
        negative={"max_per_day": None, "max_per_meal": None, "min_per_day": None},
    ),
    "ck_condition_nutrient_limits_min_le_max": CheckCase(
        table="condition_nutrient_limits",
        positive={"min_per_day": 10, "max_per_day": 10},
        negative={"min_per_day": 11, "max_per_day": 10},
    ),
    "ck_condition_nutrient_limits_values_non_negative": CheckCase(
        table="condition_nutrient_limits",
        positive={"max_per_meal": 0},
        negative={"max_per_meal": -0.001},
    ),
    "ck_condition_nutrient_limits_percent_max_100": CheckCase(
        table="condition_nutrient_limits",
        positive={"limit_basis": "PERCENT_ENERGY", "max_per_day": 100},
        negative={"limit_basis": "PERCENT_ENERGY", "max_per_day": 150},
    ),
    "ck_condition_tag_restrictions_max_servings_only_for_limit": CheckCase(
        table="condition_tag_restrictions",
        positive={"restriction_type": "AVOID", "max_servings_per_week": None},
        negative={"restriction_type": "AVOID", "max_servings_per_week": 1},
    ),
    "ck_condition_tag_restrictions_max_servings_positive": CheckCase(
        table="condition_tag_restrictions",
        positive={"restriction_type": "LIMIT", "max_servings_per_week": 1},
        negative={"restriction_type": "LIMIT", "max_servings_per_week": 0},
    ),
    "ck_foods_basis_grams_100": CheckCase(
        table="foods",
        positive={"basis_grams": 100},
        negative={"basis_grams": 99},
    ),
    "ck_food_nutrients_amount_non_negative": CheckCase(
        table="food_nutrients",
        positive={"amount_per_100g": 0},
        negative={"amount_per_100g": -0.001},
    ),
    "ck_portions_food_gram_weight_positive": CheckCase(
        table="portions_food",
        positive={"gram_weight": 0.001},
        negative={"gram_weight": 0},
    ),
    "ck_ingredient_aliases_lang_iso639_1": CheckCase(
        table="ingredient_aliases",
        positive={"lang": "ar"},
        negative={"lang": "AR"},
    ),
    "ck_ingredient_aliases_confidence_range": CheckCase(
        table="ingredient_aliases",
        positive={"confidence": 0},
        negative={"confidence": 1.001},
    ),
    "ck_meals_servings_positive": CheckCase(
        table="meals",
        positive={"servings": 1},
        negative={"servings": 0},
    ),
    "ck_meals_total_grams_positive": CheckCase(
        table="meals",
        positive={"total_grams": 0.001},
        negative={"total_grams": 0},
    ),
    "ck_meals_default_lang_iso639_1": CheckCase(
        table="meals",
        positive={"default_lang": "en"},
        negative={"default_lang": "EN"},
    ),
    "ck_meals_yield_factor_range": CheckCase(
        table="meals",
        positive={"weight_method": "YIELD_FACTOR", "yield_factor": 3},
        negative={"weight_method": "YIELD_FACTOR", "yield_factor": 3.001},
    ),
    "ck_meals_yield_factor_only_for_yield_method": CheckCase(
        table="meals",
        positive={"weight_method": "WEIGHED", "yield_factor": None},
        negative={"weight_method": "WEIGHED", "yield_factor": 1},
    ),
    "ck_meal_ingredients_grams_positive": CheckCase(
        table="meal_ingredients",
        positive={"grams": 0.001},
        negative={"grams": 0},
    ),
    "ck_meal_ingredients_position_min_1": CheckCase(
        table="meal_ingredients",
        positive={"position": 1},
        negative={"position": 0},
    ),
    "ck_meal_ingredients_mapping_confidence_range": CheckCase(
        table="meal_ingredients",
        positive={"mapping_confidence": 1},
        negative={"mapping_confidence": -0.001},
    ),
    "ck_meal_nutrients_amount_per_serving_non_negative": CheckCase(
        table="meal_nutrients",
        positive={"amount_per_serving": 0},
        negative={"amount_per_serving": -1},
    ),
    "ck_meal_nutrients_amount_per_100g_non_negative": CheckCase(
        table="meal_nutrients",
        positive={"amount_per_100g": 0},
        negative={"amount_per_100g": -0.001},
    ),
    "ck_meal_tags_rule_version_only_derived": CheckCase(
        table="meal_tags",
        positive={"source": "DERIVED", "rule_version": "tags_v1"},
        negative={"source": "MANUAL", "rule_version": "tags_v1"},
    ),
    "ck_meal_translations_lang_iso639_1": CheckCase(
        table="meal_translations",
        positive={"lang": "ar"},
        negative={"lang": "AR"},
    ),
    "ck_users_email_lowercase": CheckCase(
        table="users",
        positive={"email": "ok@example.com"},
        negative={"email": "A@x.com"},
    ),
    "ck_user_profiles_height_range": CheckCase(
        table="user_profiles",
        positive={"height_cm": 100},
        negative={"height_cm": 99.999},
    ),
    "ck_user_profiles_target_weight_range": CheckCase(
        table="user_profiles",
        positive={"target_weight_kg": 30},
        negative={"target_weight_kg": 29.999},
    ),
    "ck_user_profiles_weekly_rate_range": CheckCase(
        table="user_profiles",
        positive={"weekly_rate_kg": 1.0},
        negative={"weekly_rate_kg": 1.5},
    ),
    "ck_user_profiles_water_goal_range": CheckCase(
        table="user_profiles",
        positive={"water_goal_ml": 500},
        negative={"water_goal_ml": 100},
    ),
    "ck_user_profiles_status_requires_female": CheckCase(
        table="user_profiles",
        positive={"sex": "MALE", "physiological_status": "NONE"},
        negative={"sex": "MALE", "physiological_status": "PREGNANT"},
    ),
    "ck_user_profiles_goal_requires_target": CheckCase(
        table="user_profiles",
        positive={"goal_type": "LOSE", "target_weight_kg": 70, "weekly_rate_kg": 0.5},
        negative={"goal_type": "LOSE", "target_weight_kg": None, "weekly_rate_kg": None},
    ),
    "ck_user_interactions_value_range": CheckCase(
        table="user_interactions",
        positive={"event_type": "RATE", "value": 1},
        negative={"event_type": "VIEW", "value": 6},
    ),
    "ck_user_interactions_rate_requires_value": CheckCase(
        table="user_interactions",
        positive={"event_type": "RATE", "value": 5},
        negative={"event_type": "RATE", "value": None},
    ),
    "ck_meal_plans_date_range": CheckCase(
        table="meal_plans",
        positive={"date_from": date(2026, 1, 1), "date_to": date(2026, 1, 1)},
        negative={"date_from": date(2026, 1, 2), "date_to": date(2026, 1, 1)},
    ),
    "ck_meal_plan_items_day_index_non_negative": CheckCase(
        table="meal_plan_items",
        positive={"day_index": 0},
        negative={"day_index": -1},
    ),
    "ck_meal_plan_items_servings_multiplier_step": CheckCase(
        table="meal_plan_items",
        positive={"servings_multiplier": 0.5},
        negative={"servings_multiplier": 0.7},
    ),
    "ck_consumption_logs_one_target": CheckCase(
        table="consumption_logs",
        positive={},
        negative={
            "meal_id": None,
            "food_id": None,
            "servings_consumed": None,
            "grams_consumed": None,
        },
    ),
    "ck_consumption_logs_meal_requires_servings": CheckCase(
        table="consumption_logs",
        positive={"servings_consumed": 0.001, "grams_consumed": None},
        negative={"servings_consumed": 0, "grams_consumed": None},
    ),
    "ck_consumption_logs_food_requires_grams": CheckCase(
        table="consumption_logs",
        positive=lambda conn: _food_log(conn, grams_consumed=0.001),
        negative=lambda conn: _food_log(conn, grams_consumed=0),
    ),
    "ck_consumption_logs_plan_item_needs_meal": CheckCase(
        table="consumption_logs",
        positive=lambda conn: {
            "plan_item_id": make_meal_plan_item(conn),
            "meal_id": make_meal(conn),
            "food_id": None,
            "servings_consumed": 1,
            "grams_consumed": None,
        },
        negative=_plan_item_on_food,
    ),
    "ck_weight_logs_weight_range": CheckCase(
        table="weight_logs",
        positive={"weight_kg": 20},
        negative={"weight_kg": 19.999},
    ),
    "ck_user_targets_valid_to_after_from": CheckCase(
        table="user_targets",
        positive={
            "valid_from": datetime(2026, 1, 1, tzinfo=UTC),
            "valid_to": datetime(2026, 1, 1, 0, 0, 1, tzinfo=UTC),
        },
        negative={
            "valid_from": datetime(2026, 1, 1, tzinfo=UTC),
            "valid_to": datetime(2026, 1, 1, tzinfo=UTC),
        },
    ),
    "ck_user_targets_values_positive": CheckCase(
        table="user_targets",
        positive={"bmr_kcal": 0.001},
        negative={"bmr_kcal": 0},
    ),
    "ck_refresh_tokens_expires_after_issued": CheckCase(
        table="refresh_tokens",
        positive={
            "issued_at": datetime(2026, 1, 1, tzinfo=UTC),
            "expires_at": datetime(2026, 1, 1, 0, 0, 1, tzinfo=UTC),
        },
        negative=_issued_and_expired_equal,
    ),
    "ck_water_logs_amount_range": CheckCase(
        table="water_logs",
        positive={"amount_ml": 1},
        negative={"amount_ml": 0},
    ),
}


@dataclass(frozen=True)
class UniqueCase:
    table: str
    duplicate: Overrides
    nullable: tuple[str, ...] = ()
    nullable_equal: Overrides = field(default_factory=dict)


def _limit_pair(conn: Connection) -> dict[str, Any]:
    return {
        "condition_id": make_health_condition(conn),
        "nutrient_id": make_nutrient(conn),
        "limit_basis": "ABSOLUTE",
    }


def _restriction_pair(conn: Connection) -> dict[str, Any]:
    return {"condition_id": make_health_condition(conn), "tag_id": make_dietary_tag(conn)}


def _user_condition_pair(conn: Connection) -> dict[str, Any]:
    return {"user_id": make_user(conn), "condition_id": make_health_condition(conn)}


def _weight_day(conn: Connection) -> dict[str, Any]:
    return {"user_id": make_user(conn), "measured_on": date(2026, 6, 1)}


UNIQUE_CASES: dict[str, UniqueCase] = {
    "uq_categories_name_en": UniqueCase("categories", {"name_en": "dup-category"}),
    "uq_cuisines_code": UniqueCase("cuisines", {"code": "DUP_CUISINE"}),
    "uq_allergens_code": UniqueCase("allergens", {"code": "DUP_ALLERGEN"}),
    "uq_dietary_tags_code": UniqueCase("dietary_tags", {"code": "DUP_TAG"}),
    "uq_health_conditions_code": UniqueCase("health_conditions", {"code": "DUP_COND"}),
    "uq_condition_nutrient_limits_condition_nutrient_basis": UniqueCase(
        "condition_nutrient_limits", _limit_pair
    ),
    "uq_condition_tag_restrictions_condition_id_tag_id": UniqueCase(
        "condition_tag_restrictions", _restriction_pair
    ),
    "uq_foods_external_source_external_code": UniqueCase(
        "foods", {"external_source": "MANUAL", "external_code": "DUP_EXT"}
    ),
    "uq_foods_fdc_id": UniqueCase("foods", {"fdc_id": 424242}, nullable=("fdc_id",)),
    "uq_nutrients_code": UniqueCase("nutrients", {"code": "DUP_NUT"}),
    "uq_ingredient_aliases_alias_text_lang": UniqueCase(
        "ingredient_aliases", {"alias_text": "dup-alias", "lang": "en"}
    ),
    "uq_meals_source_ref_external": UniqueCase(
        "meals",
        {"source": "team", "ref_external": "r1"},
        nullable=("ref_external",),
        nullable_equal={"source": "team-nulls"},
    ),
    "uq_users_email": UniqueCase("users", {"email": "dup@example.com"}),
    "uq_user_health_conditions_user_id_condition_id": UniqueCase(
        "user_health_conditions", _user_condition_pair
    ),
    "uq_user_interactions_client_uuid": UniqueCase(
        "user_interactions", lambda _conn: {"client_uuid": uuid4()}, nullable=("client_uuid",)
    ),
    "uq_weight_logs_user_id_measured_on": UniqueCase("weight_logs", _weight_day),
    "uq_refresh_tokens_token_hash": UniqueCase("refresh_tokens", {"token_hash": "dup-hash"}),
    "uq_consumption_logs_client_uuid": UniqueCase(
        "consumption_logs", lambda _conn: {"client_uuid": uuid4()}, nullable=("client_uuid",)
    ),
    "uq_water_logs_client_uuid": UniqueCase(
        "water_logs", lambda _conn: {"client_uuid": uuid4()}, nullable=("client_uuid",)
    ),
}


@dataclass(frozen=True)
class PartialUniqueCase:
    table: str
    # Rows matching the index WHERE clause: the second identical row is rejected.
    duplicate: Overrides
    # Same key, but rows excluded by the WHERE clause: two identical rows are accepted.
    outside_predicate: Overrides


def _user_open_target(conn: Connection) -> dict[str, Any]:
    return {"user_id": make_user(conn), "valid_to": None}


def _user_closed_target(conn: Connection) -> dict[str, Any]:
    return {
        "user_id": make_user(conn),
        "valid_from": datetime(2026, 1, 1, tzinfo=UTC),
        "valid_to": datetime(2026, 2, 1, tzinfo=UTC),
    }


def _plan_day_slot(slot: str) -> Callable[[Connection], dict[str, Any]]:
    def build(conn: Connection) -> dict[str, Any]:
        return {"plan_id": make_meal_plan(conn), "day_index": 0, "slot": slot}

    return build


PARTIAL_UNIQUE_CASES: dict[str, PartialUniqueCase] = {
    "ix_user_targets_user_id": PartialUniqueCase(
        "user_targets", _user_open_target, _user_closed_target
    ),
    "ix_meal_plan_items_plan_id_day_index_slot": PartialUniqueCase(
        "meal_plan_items", _plan_day_slot("BREAKFAST"), _plan_day_slot("SNACK")
    ),
}


@dataclass(frozen=True)
class IndexCase:
    table: str
    columns: tuple[str, ...]
    method: str = "btree"
    predicate: str | None = None


# Non-unique indexes other than the single-column FK indexes (those are covered by the
# FK-index check). A new secondary index without an entry here fails the suite.
SECONDARY_INDEX_CASES: dict[str, IndexCase] = {
    "ix_ingredient_aliases_alias_normalized": IndexCase(
        "ingredient_aliases", ("alias_normalized",), method="gin"
    ),
    "ix_meals_name_normalized": IndexCase("meals", ("name_normalized",), method="gin"),
    "ix_meals_variant_group": IndexCase("meals", ("variant_group",)),
    "ix_meal_translations_name_normalized": IndexCase(
        "meal_translations", ("name_normalized",), method="gin"
    ),
    "ix_user_interactions_user_id_created_at": IndexCase(
        "user_interactions", ("user_id", "created_at")
    ),
    "ix_meal_plans_user_id_date_from": IndexCase("meal_plans", ("user_id", "date_from")),
    "ix_consumption_logs_user_id_log_date": IndexCase(
        "consumption_logs", ("user_id", "log_date"), predicate="(deleted_at IS NULL)"
    ),
    "ix_water_logs_user_id_log_date": IndexCase(
        "water_logs", ("user_id", "log_date"), predicate="(deleted_at IS NULL)"
    ),
    "ix_user_targets_user_id_valid_from": IndexCase("user_targets", ("user_id", "valid_from")),
    "ix_refresh_tokens_family_id": IndexCase("refresh_tokens", ("family_id",)),
}
