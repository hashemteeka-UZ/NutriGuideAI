"""Consumption logging (§11.9, §33.4) on the loaded F.1 slice."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import delete, func, select, update
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import ConsumptionLog, Food, FoodNutrient, Meal, MealNutrient, Nutrient
from app.db.models.user import MealPlanItem
from app.services.common import InvalidTimezoneError, to_decimal
from app.services.consumption import (
    SNAPSHOT_NUTRIENTS_KEY,
    SNAPSHOT_VERSION_KEY,
    ClientUuidConflictError,
    IncompleteNutritionError,
    LogNotFoundError,
    LogStatus,
    PlanItemAlreadyLoggedError,
    PlanItemNotFoundError,
    active_logs,
    correct_log,
    delete_log,
    log_food,
    log_meal,
    log_plan_item,
)
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.planner import create_day_plan
from app.services.recompute_meals import recompute_meal
from tests.builders import make_user_profile
from tests.services.conftest import NOW, PLAN_DATE, case_1_user, htn_dm2_plan, meal_id, plan_target

D = Decimal
EATEN = datetime(2026, 10, 7, 12, 0, tzinfo=ZoneInfo("Africa/Tripoli"))
GARLIC_NDB = "11215"


def _mandatory(session: Session) -> list[str]:
    return list(
        session.execute(
            select(Nutrient.code).where(Nutrient.is_mandatory).order_by(Nutrient.code)
        ).scalars()
    )


def _meal_amounts(session: Session, meal: int) -> dict[str, Decimal]:
    return {
        code: to_decimal(amount)
        for code, amount in session.execute(
            select(Nutrient.code, MealNutrient.amount_per_serving)
            .join(MealNutrient, MealNutrient.nutrient_id == Nutrient.nutrient_id)
            .where(MealNutrient.meal_id == meal, Nutrient.is_mandatory)
        ).tuples()
    }


def _food_id(session: Session, ndb: str) -> int:
    return session.execute(
        select(Food.food_id).where(Food.external_source == "FDC", Food.external_code == ndb)
    ).scalar_one()


def _food_amounts(session: Session, food: int) -> dict[str, Decimal]:
    return {
        code: to_decimal(amount)
        for code, amount in session.execute(
            select(Nutrient.code, FoodNutrient.amount_per_100g)
            .join(FoodNutrient, FoodNutrient.nutrient_id == Nutrient.nutrient_id)
            .where(FoodNutrient.food_id == food, Nutrient.is_mandatory)
        ).tuples()
    }


def _count(session: Session) -> int:
    return session.execute(select(func.count()).select_from(ConsumptionLog)).scalar_one()


def _items(session: Session, plan_id: int) -> list[MealPlanItem]:
    return list(
        session.execute(
            select(MealPlanItem).where(MealPlanItem.plan_id == plan_id).order_by(MealPlanItem.id)
        ).scalars()
    )


def test_meal_snapshot_is_half_of_each_mandatory_amount(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-B01")
    result = log_meal(slice_session, user, meal, D("0.5"), EATEN, "BREAKFAST", uuid4(), NOW)
    assert result.status is LogStatus.CREATED
    snapshot = result.log.nutrients_snapshot
    assert snapshot[SNAPSHOT_VERSION_KEY] == COMPUTATION_VERSION == "calc_v1"
    nutrients = snapshot[SNAPSHOT_NUTRIENTS_KEY]
    expected = _meal_amounts(slice_session, meal)
    assert set(nutrients) == set(_mandatory(slice_session)) == set(expected)
    assert "potassium" not in nutrients
    for code, amount in expected.items():
        assert isinstance(nutrients[code], str)
        assert D(nutrients[code]) == amount * D("0.5")
        assert nutrients[code] == str(amount * D("0.5"))


def test_food_snapshot_is_amount_times_grams_over_100(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    food = _food_id(slice_session, GARLIC_NDB)
    result = log_food(slice_session, user, food, 150, EATEN, None, uuid4(), NOW)
    nutrients = result.log.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY]
    expected = _food_amounts(slice_session, food)
    assert set(nutrients) == set(expected)
    for code, amount in expected.items():
        assert D(nutrients[code]) == amount * D("1.5")


def test_snapshot_survives_recompute_and_incomplete_meal_cannot_be_logged(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-B01")
    result = log_meal(slice_session, user, meal, D("0.5"), EATEN, None, uuid4(), NOW)
    stored = result.log.nutrients_snapshot
    recompute_meal(slice_session, meal, NOW)
    slice_session.refresh(result.log)
    assert result.log.nutrients_snapshot == stored

    sodium = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "sodium", Nutrient.is_mandatory)
    ).scalar_one()
    slice_session.execute(
        delete(MealNutrient).where(MealNutrient.meal_id == meal, MealNutrient.nutrient_id == sodium)
    )
    slice_session.refresh(result.log)
    assert result.log.nutrients_snapshot == stored
    with pytest.raises(IncompleteNutritionError, match="mandatory"):
        log_meal(slice_session, user, meal, 1, EATEN, None, uuid4(), NOW)


def test_food_missing_a_mandatory_nutrient_cannot_be_logged(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    food = _food_id(slice_session, GARLIC_NDB)
    sodium = slice_session.execute(
        select(Nutrient.nutrient_id).where(Nutrient.code == "sodium")
    ).scalar_one()
    slice_session.execute(
        delete(FoodNutrient).where(FoodNutrient.food_id == food, FoodNutrient.nutrient_id == sodium)
    )
    with pytest.raises(IncompleteNutritionError, match="sodium"):
        log_food(slice_session, user, food, 10, EATEN, None, uuid4(), NOW)


def test_log_date_uses_the_profile_timezone(
    slice_session: Session, integrity_conn: Connection
) -> None:
    moment = datetime(2026, 10, 7, 23, 30, tzinfo=UTC)
    tripoli = make_user_profile(integrity_conn, timezone="Africa/Tripoli")
    utc = make_user_profile(integrity_conn, timezone="UTC")
    meal = meal_id(slice_session, "F1-B02")
    east = log_meal(slice_session, tripoli, meal, 1, moment, None, uuid4(), NOW).log
    west = log_meal(slice_session, utc, meal, 1, moment, None, uuid4(), NOW).log
    assert east.log_date.isoformat() == "2026-10-08"
    assert west.log_date.isoformat() == "2026-10-07"


def test_unknown_timezone_raises(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn, timezone="Not/A_Zone")
    with pytest.raises(InvalidTimezoneError, match="Not/A_Zone"):
        log_meal(
            slice_session, user, meal_id(slice_session, "F1-B02"), 1, EATEN, None, uuid4(), NOW
        )


def test_plan_item_copies_meal_and_slot_and_blocks_a_second_active_log(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user, plan = htn_dm2_plan(slice_session, integrity_conn)
    breakfast = next(i for i in _items(slice_session, plan.plan_id) if i.slot == "BREAKFAST")
    result = log_plan_item(slice_session, user, breakfast.id, D("0.75"), EATEN, uuid4(), NOW)
    assert result.status is LogStatus.CREATED
    assert (result.log.meal_id, result.log.slot, result.log.plan_item_id) == (
        breakfast.meal_id,
        "BREAKFAST",
        breakfast.id,
    )
    assert to_decimal(result.log.servings_consumed) == D("0.75")
    with pytest.raises(PlanItemAlreadyLoggedError):
        log_plan_item(slice_session, user, breakfast.id, 1, EATEN, uuid4(), NOW)

    delete_log(slice_session, user, result.log.id, NOW)
    again = log_plan_item(slice_session, user, breakfast.id, 1, EATEN, uuid4(), NOW)
    assert again.status is LogStatus.CREATED
    assert again.log.id != result.log.id
    assert [row.id for row in active_logs(slice_session, user, PLAN_DATE)] == [again.log.id]


def test_plan_item_of_another_user_raises(
    slice_session: Session, integrity_conn: Connection
) -> None:
    owner, plan = htn_dm2_plan(slice_session, integrity_conn)
    other = case_1_user(integrity_conn)
    plan_target(slice_session, other)
    item = _items(slice_session, plan.plan_id)[0]
    with pytest.raises(PlanItemNotFoundError, match=str(other)):
        log_plan_item(slice_session, other, item.id, 1, EATEN, uuid4(), NOW)
    assert owner != other
    assert _count(slice_session) == 0


def test_same_client_uuid_is_idempotent(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-B02")
    client = uuid4()
    first = log_meal(slice_session, user, meal, 1, EATEN, "BREAKFAST", client, NOW)
    second = log_meal(slice_session, user, meal, 1, EATEN, "BREAKFAST", client, NOW)
    assert first.status is LogStatus.CREATED
    assert second.status is LogStatus.DUPLICATE
    assert second.log.id == first.log.id
    assert _count(slice_session) == 1
    with pytest.raises(ClientUuidConflictError, match=str(client)):
        log_meal(slice_session, user, meal, D("0.5"), EATEN, "BREAKFAST", client, NOW)
    assert _count(slice_session) == 1


def test_correct_log_tombstones_and_inserts(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-B01")
    original = log_meal(slice_session, user, meal, 1, EATEN, "BREAKFAST", uuid4(), NOW).log
    before = {
        "user_id": original.user_id,
        "consumed_at": original.consumed_at,
        "log_date": original.log_date,
        "slot": original.slot,
        "plan_item_id": original.plan_item_id,
        "meal_id": original.meal_id,
        "food_id": original.food_id,
        "servings_consumed": original.servings_consumed,
        "grams_consumed": original.grams_consumed,
        "created_at": original.created_at,
        "client_uuid": original.client_uuid,
        "nutrients_snapshot": original.nutrients_snapshot,
    }
    later = NOW.replace(hour=12)
    half = original.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY]
    result = correct_log(
        slice_session,
        user,
        original.id,
        servings_consumed=D("0.5"),
        new_client_uuid=uuid4(),
        now=later,
    )
    slice_session.refresh(original)
    assert original.deleted_at == later
    for key, value in before.items():
        assert getattr(original, key) == value
    assert result.status is LogStatus.CREATED
    new = result.log
    assert new.id != original.id
    assert (new.meal_id, new.slot, new.plan_item_id) == (meal, "BREAKFAST", None)
    assert to_decimal(new.servings_consumed) == D("0.5")
    assert new.created_at == later and new.deleted_at is None
    nutrients = new.nutrients_snapshot[SNAPSHOT_NUTRIENTS_KEY]
    for code, value in half.items():
        assert D(nutrients[code]) == D(value) * D("0.5")
    assert [row.id for row in active_logs(slice_session, user, PLAN_DATE)] == [new.id]


def test_delete_log_twice_raises(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    log = log_meal(
        slice_session, user, meal_id(slice_session, "F1-B02"), 1, EATEN, None, uuid4(), NOW
    ).log
    delete_log(slice_session, user, log.id, NOW)
    with pytest.raises(LogNotFoundError):
        delete_log(slice_session, user, log.id, NOW)
    other = make_user_profile(integrity_conn)
    with pytest.raises(LogNotFoundError):
        delete_log(slice_session, other, log.id, NOW)


def test_meal_log_cannot_be_corrected_in_grams(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = make_user_profile(integrity_conn)
    log = log_meal(
        slice_session, user, meal_id(slice_session, "F1-B02"), 1, EATEN, None, uuid4(), NOW
    ).log
    with pytest.raises(ValueError, match="servings"):
        correct_log(
            slice_session, user, log.id, grams_consumed=10, new_client_uuid=uuid4(), now=NOW
        )


def test_inactive_meal_can_be_logged(slice_session: Session, integrity_conn: Connection) -> None:
    user = make_user_profile(integrity_conn)
    meal = meal_id(slice_session, "F1-B02")
    slice_session.execute(update(Meal).where(Meal.meal_id == meal).values(is_active=False))
    result = log_meal(slice_session, user, meal, 1, EATEN, "BREAKFAST", uuid4(), NOW)
    assert result.log.meal_id == meal


def test_plan_item_idempotent_retry_after_create(
    slice_session: Session, integrity_conn: Connection
) -> None:
    user = case_1_user(integrity_conn)
    plan_target(slice_session, user)
    plan = create_day_plan(slice_session, user, PLAN_DATE, NOW)
    item = _items(slice_session, plan.plan_id)[0]
    client = uuid4()
    first = log_plan_item(
        slice_session, user, item.id, item.servings_multiplier, EATEN, client, NOW
    )
    second = log_plan_item(
        slice_session, user, item.id, item.servings_multiplier, EATEN, client, NOW
    )
    assert second.status is LogStatus.DUPLICATE
    assert second.log.id == first.log.id
