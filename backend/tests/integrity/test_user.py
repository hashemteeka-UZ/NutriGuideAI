"""USER-domain integrity tests (§19 verification 5-6 and related bullets)."""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

from sqlalchemy import delete, text
from sqlalchemy.engine import Connection

from tests.builders import (
    make_consumption_log,
    make_food,
    make_meal,
    make_meal_plan,
    make_meal_plan_item,
    make_refresh_token,
    make_user,
    make_user_allergen_pref,
    make_user_health_condition,
    make_user_ingredient_pref,
    make_user_interaction,
    make_user_profile,
    make_user_target,
    make_water_log,
    make_weight_log,
    table,
)
from tests.integrity.helpers import assert_rejected, assert_rejects, fetch_by_pk


def test_verification_5_user_profile_prefs_interactions_weight_targets(
    integrity_conn: Connection,
) -> None:
    user_id = make_user(integrity_conn)
    make_user_profile(integrity_conn, user_id=user_id)
    make_user_allergen_pref(integrity_conn, user_id=user_id)
    make_user_ingredient_pref(integrity_conn, user_id=user_id)
    make_user_interaction(integrity_conn, user_id=user_id)
    make_weight_log(integrity_conn, user_id=user_id)
    make_user_target(integrity_conn, user_id=user_id)
    assert fetch_by_pk(integrity_conn, "users", user_id) is not None


def test_verification_6_user_meal_plan_and_consumption_log_relationships(
    integrity_conn: Connection,
) -> None:
    user_id = make_user(integrity_conn)
    meal_id = make_meal(integrity_conn)
    plan_id = make_meal_plan(integrity_conn, user_id=user_id)
    item_id = make_meal_plan_item(integrity_conn, plan_id=plan_id, meal_id=meal_id)
    make_consumption_log(integrity_conn, user_id=user_id, plan_item_id=item_id, meal_id=meal_id)
    food_id = make_food(integrity_conn)
    make_consumption_log(
        integrity_conn,
        user_id=user_id,
        meal_id=None,
        food_id=food_id,
        servings_consumed=None,
        grams_consumed=40,
    )
    assert fetch_by_pk(integrity_conn, "meal_plan_items", item_id) is not None


def test_consumption_logs_both_meal_and_food_rejected(integrity_conn: Connection) -> None:
    meal_id = make_meal(integrity_conn)
    food_id = make_food(integrity_conn)
    assert_rejected(
        integrity_conn,
        lambda: make_consumption_log(
            integrity_conn, meal_id=meal_id, food_id=food_id, servings_consumed=1
        ),
    )


def test_consumption_logs_neither_meal_nor_food_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_consumption_logs_one_target",
        lambda: make_consumption_log(
            integrity_conn,
            meal_id=None,
            food_id=None,
            servings_consumed=None,
            grams_consumed=None,
        ),
    )


def test_consumption_logs_food_with_servings_and_no_grams_rejected(
    integrity_conn: Connection,
) -> None:
    food_id = make_food(integrity_conn)
    assert_rejects(
        integrity_conn,
        "ck_consumption_logs_food_requires_grams",
        lambda: make_consumption_log(
            integrity_conn,
            meal_id=None,
            food_id=food_id,
            servings_consumed=1,
            grams_consumed=None,
        ),
    )


def test_consumption_logs_plan_item_without_meal_rejected(integrity_conn: Connection) -> None:
    item_id = make_meal_plan_item(integrity_conn)
    food_id = make_food(integrity_conn)
    assert_rejects(
        integrity_conn,
        "ck_consumption_logs_plan_item_needs_meal",
        lambda: make_consumption_log(
            integrity_conn,
            plan_item_id=item_id,
            meal_id=None,
            food_id=food_id,
            servings_consumed=None,
            grams_consumed=10,
        ),
    )


def test_deleting_meal_plan_cascades_items_and_nulls_consumption_plan_item(
    integrity_conn: Connection,
) -> None:
    user_id = make_user(integrity_conn)
    meal_id = make_meal(integrity_conn)
    plan_id = make_meal_plan(integrity_conn, user_id=user_id)
    item_id = make_meal_plan_item(integrity_conn, plan_id=plan_id, meal_id=meal_id)
    log_id = make_consumption_log(
        integrity_conn, user_id=user_id, plan_item_id=item_id, meal_id=meal_id
    )
    plans = table("meal_plans")
    integrity_conn.execute(delete(plans).where(plans.c.plan_id == plan_id))
    assert fetch_by_pk(integrity_conn, "meal_plan_items", item_id) is None
    log = fetch_by_pk(integrity_conn, "consumption_logs", log_id)
    assert log is not None
    assert log.plan_item_id is None
    assert log.meal_id == meal_id


def test_two_open_user_targets_for_same_user_rejected(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    make_user_target(integrity_conn, user_id=user_id, valid_to=None)
    assert_rejects(
        integrity_conn,
        "ix_user_targets_user_id",
        lambda: make_user_target(integrity_conn, user_id=user_id, valid_to=None),
    )


def test_two_breakfasts_same_plan_day_rejected(integrity_conn: Connection) -> None:
    plan_id = make_meal_plan(integrity_conn)
    make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="BREAKFAST")
    assert_rejects(
        integrity_conn,
        "ix_meal_plan_items_plan_id_day_index_slot",
        lambda: make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="BREAKFAST"),
    )


def test_two_snacks_same_plan_day_accepted(integrity_conn: Connection) -> None:
    plan_id = make_meal_plan(integrity_conn)
    make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="SNACK")
    make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="SNACK")


def test_same_slot_on_different_plan_day_accepted(integrity_conn: Connection) -> None:
    plan_id = make_meal_plan(integrity_conn)
    make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="BREAKFAST")
    make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=1, slot="BREAKFAST")


def test_same_slot_and_day_in_different_plan_accepted(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    for _ in range(2):
        plan_id = make_meal_plan(integrity_conn, user_id=user_id)
        make_meal_plan_item(integrity_conn, plan_id=plan_id, day_index=0, slot="BREAKFAST")


def test_two_weight_logs_same_user_and_day_rejected(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    day = date(2026, 4, 1)
    make_weight_log(integrity_conn, user_id=user_id, measured_on=day)
    assert_rejects(
        integrity_conn,
        "uq_weight_logs_user_id_measured_on",
        lambda: make_weight_log(integrity_conn, user_id=user_id, measured_on=day),
    )


def test_user_profiles_lose_with_null_target_weight_rejected(
    integrity_conn: Connection,
) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_profiles_goal_requires_target",
        lambda: make_user_profile(
            integrity_conn, goal_type="LOSE", target_weight_kg=None, weekly_rate_kg=None
        ),
    )


def test_user_profiles_male_pregnant_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_profiles_status_requires_female",
        lambda: make_user_profile(integrity_conn, sex="MALE", physiological_status="PREGNANT"),
    )


def test_weekly_rate_kg_1_5_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_profiles_weekly_rate_range",
        lambda: make_user_profile(integrity_conn, weekly_rate_kg=1.5),
    )


def test_duplicate_client_uuid_on_consumption_logs_rejected(
    integrity_conn: Connection,
) -> None:
    shared = uuid4()
    make_consumption_log(integrity_conn, client_uuid=shared)
    assert_rejects(
        integrity_conn,
        "uq_consumption_logs_client_uuid",
        lambda: make_consumption_log(integrity_conn, client_uuid=shared),
    )


def test_null_client_uuid_on_consumption_logs_accepted_twice(
    integrity_conn: Connection,
) -> None:
    make_consumption_log(integrity_conn, client_uuid=None)
    make_consumption_log(integrity_conn, client_uuid=None)


def test_duplicate_client_uuid_on_user_interactions_rejected(
    integrity_conn: Connection,
) -> None:
    shared = uuid4()
    make_user_interaction(integrity_conn, client_uuid=shared)
    assert_rejects(
        integrity_conn,
        "uq_user_interactions_client_uuid",
        lambda: make_user_interaction(integrity_conn, client_uuid=shared),
    )


def test_null_client_uuid_on_user_interactions_accepted_twice(
    integrity_conn: Connection,
) -> None:
    make_user_interaction(integrity_conn, client_uuid=None)
    make_user_interaction(integrity_conn, client_uuid=None)


def test_query_pattern_tombstoned_consumption_logs_excluded_from_adherence(
    integrity_conn: Connection,
) -> None:
    """Adherence sums `consumption_logs` with `deleted_at IS NULL` (§30.5, §19 v4.5)."""
    user_id = make_user(integrity_conn)
    log_date = date(2026, 5, 1)
    stamp = datetime(2026, 5, 1, 12, tzinfo=UTC)
    make_consumption_log(
        integrity_conn,
        user_id=user_id,
        log_date=log_date,
        consumed_at=stamp,
        nutrients_snapshot={"kcal": 100},
    )
    tomb_id = make_consumption_log(
        integrity_conn,
        user_id=user_id,
        log_date=log_date,
        consumed_at=stamp,
        nutrients_snapshot={"kcal": 999},
        deleted_at=stamp,
    )
    total = integrity_conn.execute(
        text(
            "SELECT coalesce(sum((nutrients_snapshot->>'kcal')::numeric), 0) "
            "FROM consumption_logs "
            "WHERE user_id = :user_id AND log_date = :log_date AND deleted_at IS NULL"
        ),
        {"user_id": user_id, "log_date": log_date},
    ).scalar_one()
    assert total == 100
    assert fetch_by_pk(integrity_conn, "consumption_logs", tomb_id) is not None


def test_two_refresh_tokens_same_token_hash_rejected(integrity_conn: Connection) -> None:
    make_refresh_token(integrity_conn, token_hash="same-hash")
    assert_rejects(
        integrity_conn,
        "uq_refresh_tokens_token_hash",
        lambda: make_refresh_token(integrity_conn, token_hash="same-hash"),
    )


def test_refresh_tokens_expires_at_not_after_issued_at_rejected(
    integrity_conn: Connection,
) -> None:
    issued = datetime(2026, 1, 1, tzinfo=UTC)
    assert_rejects(
        integrity_conn,
        "ck_refresh_tokens_expires_after_issued",
        lambda: make_refresh_token(integrity_conn, issued_at=issued, expires_at=issued),
    )


def test_deleting_user_cascades_to_refresh_tokens(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    token_id = make_refresh_token(integrity_conn, user_id=user_id)
    users = table("users")
    integrity_conn.execute(delete(users).where(users.c.user_id == user_id))
    assert fetch_by_pk(integrity_conn, "refresh_tokens", token_id) is None


def test_meal_plan_items_reason_codes_defaults_to_empty_array(
    integrity_conn: Connection,
) -> None:
    item_id = make_meal_plan_item(integrity_conn)
    row = fetch_by_pk(integrity_conn, "meal_plan_items", item_id)
    assert row is not None
    assert row.reason_codes == []


def test_water_logs_amount_ml_zero_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_water_logs_amount_range",
        lambda: make_water_log(integrity_conn, amount_ml=0),
    )


def test_water_logs_amount_ml_2001_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_water_logs_amount_range",
        lambda: make_water_log(integrity_conn, amount_ml=2001),
    )


def test_water_logs_amount_ml_250_accepted(integrity_conn: Connection) -> None:
    log_id = make_water_log(integrity_conn, amount_ml=250)
    assert fetch_by_pk(integrity_conn, "water_logs", log_id) is not None


def test_duplicate_client_uuid_on_water_logs_rejected(integrity_conn: Connection) -> None:
    shared = uuid4()
    make_water_log(integrity_conn, client_uuid=shared)
    assert_rejects(
        integrity_conn,
        "uq_water_logs_client_uuid",
        lambda: make_water_log(integrity_conn, client_uuid=shared),
    )


def test_null_client_uuid_on_water_logs_accepted_twice(integrity_conn: Connection) -> None:
    make_water_log(integrity_conn, client_uuid=None)
    make_water_log(integrity_conn, client_uuid=None)


def test_query_pattern_tombstoned_water_logs_excluded_from_daily_total(
    integrity_conn: Connection,
) -> None:
    """Daily water total uses `deleted_at IS NULL` (§11.13, §19 v4.6)."""
    user_id = make_user(integrity_conn)
    log_date = date(2026, 5, 2)
    stamp = datetime(2026, 5, 2, 9, tzinfo=UTC)
    make_water_log(
        integrity_conn, user_id=user_id, log_date=log_date, consumed_at=stamp, amount_ml=250
    )
    tomb_id = make_water_log(
        integrity_conn,
        user_id=user_id,
        log_date=log_date,
        consumed_at=stamp,
        amount_ml=500,
        deleted_at=stamp,
    )
    total = integrity_conn.execute(
        text(
            "SELECT coalesce(sum(amount_ml), 0) FROM water_logs "
            "WHERE user_id = :user_id AND log_date = :log_date AND deleted_at IS NULL"
        ),
        {"user_id": user_id, "log_date": log_date},
    ).scalar_one()
    assert total == 250
    assert fetch_by_pk(integrity_conn, "water_logs", tomb_id) is not None


def test_deleting_user_cascades_to_water_logs(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    log_id = make_water_log(integrity_conn, user_id=user_id)
    users = table("users")
    integrity_conn.execute(delete(users).where(users.c.user_id == user_id))
    assert fetch_by_pk(integrity_conn, "water_logs", log_id) is None


def test_user_profiles_water_goal_ml_100_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_profiles_water_goal_range",
        lambda: make_user_profile(integrity_conn, water_goal_ml=100),
    )


def test_user_profiles_water_goal_ml_null_accepted(integrity_conn: Connection) -> None:
    profile_id = make_user_profile(integrity_conn, water_goal_ml=None)
    row = fetch_by_pk(integrity_conn, "user_profiles", profile_id)
    assert row is not None
    assert row.water_goal_ml is None


def test_users_email_uppercase_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_users_email_lowercase",
        lambda: make_user(integrity_conn, email="A@x.com"),
    )


def test_user_interactions_rate_with_null_value_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_interactions_rate_requires_value",
        lambda: make_user_interaction(integrity_conn, event_type="RATE", value=None),
    )


def test_user_interactions_value_6_rejected(integrity_conn: Connection) -> None:
    assert_rejects(
        integrity_conn,
        "ck_user_interactions_value_range",
        lambda: make_user_interaction(integrity_conn, event_type="VIEW", value=6),
    )


def test_user_health_conditions_relationship(integrity_conn: Connection) -> None:
    user_id = make_user(integrity_conn)
    make_user_health_condition(integrity_conn, user_id=user_id)
    assert fetch_by_pk(integrity_conn, "users", user_id) is not None
