"""GET /me and DELETE /me, including the cascade from users."""

from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import (
    ConsumptionLog,
    Cuisine,
    Meal,
    MealPlan,
    MealPlanItem,
    RefreshToken,
    User,
    UserCuisinePref,
    UserInteraction,
    UserMealPref,
    UserProfile,
    UserTarget,
    WaterLog,
    WeightLog,
)
from tests.builders import (
    make_consumption_log,
    make_cuisine,
    make_meal,
    make_meal_plan,
    make_meal_plan_item,
    make_refresh_token,
    make_user_cuisine_pref,
    make_user_interaction,
    make_user_meal_pref,
    make_user_profile,
    make_user_target,
    make_water_log,
    make_weight_log,
)

PASSWORD = "password1"


def _count(conn: Connection, model: type, **where: object) -> int:
    query = select(func.count()).select_from(model)
    for column, value in where.items():
        query = query.where(getattr(model, column) == value)
    return conn.execute(query).scalar_one()


def test_delete_me_removes_user_rows_and_leaves_the_catalog(
    client: TestClient, integrity_conn: Connection, api_session: Session
) -> None:
    registered = client.post(
        "/api/v1/auth/register",
        json={"email": "delete-me@example.com", "password": PASSWORD},
    )
    assert registered.status_code == 201, registered.text
    access = registered.json()["access_token"]
    headers = {"Authorization": f"Bearer {access}"}
    user_id = client.get("/api/v1/me", headers=headers).json()["user_id"]

    meal_id = make_meal(integrity_conn)
    cuisine_id = make_cuisine(integrity_conn)
    make_user_profile(integrity_conn, user_id=user_id)
    make_weight_log(integrity_conn, user_id=user_id)
    target_id = make_user_target(integrity_conn, user_id=user_id)
    plan_id = make_meal_plan(integrity_conn, user_id=user_id, target_id=target_id)
    item_id = make_meal_plan_item(integrity_conn, plan_id=plan_id, meal_id=meal_id)
    make_consumption_log(
        integrity_conn,
        user_id=user_id,
        meal_id=meal_id,
        plan_item_id=item_id,
        servings_consumed=1,
    )
    make_water_log(integrity_conn, user_id=user_id)
    make_user_interaction(integrity_conn, user_id=user_id, meal_id=meal_id)
    make_user_meal_pref(integrity_conn, user_id=user_id, meal_id=meal_id)
    make_user_cuisine_pref(integrity_conn, user_id=user_id, cuisine_id=cuisine_id)
    make_refresh_token(integrity_conn, user_id=user_id)
    api_session.expire_all()

    meals_before = _count(integrity_conn, Meal)
    cuisines_before = _count(integrity_conn, Cuisine)
    deleted = client.delete("/api/v1/me", headers=headers)
    assert deleted.status_code == 204
    api_session.expire_all()

    assert _count(integrity_conn, User, user_id=user_id) == 0
    assert _count(integrity_conn, UserProfile, user_id=user_id) == 0
    assert _count(integrity_conn, WeightLog, user_id=user_id) == 0
    assert _count(integrity_conn, UserTarget, user_id=user_id) == 0
    assert _count(integrity_conn, MealPlan, user_id=user_id) == 0
    assert _count(integrity_conn, MealPlanItem, id=item_id) == 0
    assert _count(integrity_conn, ConsumptionLog, user_id=user_id) == 0
    assert _count(integrity_conn, WaterLog, user_id=user_id) == 0
    assert _count(integrity_conn, UserInteraction, user_id=user_id) == 0
    assert _count(integrity_conn, UserMealPref, user_id=user_id) == 0
    assert _count(integrity_conn, UserCuisinePref, user_id=user_id) == 0
    assert _count(integrity_conn, RefreshToken, user_id=user_id) == 0
    assert _count(integrity_conn, Meal) == meals_before
    assert _count(integrity_conn, Cuisine) == cuisines_before
    assert _count(integrity_conn, Meal, meal_id=meal_id) == 1

    gone = client.get("/api/v1/me", headers=headers)
    assert gone.status_code == 401
    assert gone.json()["code"] == "UNAUTHORIZED"
