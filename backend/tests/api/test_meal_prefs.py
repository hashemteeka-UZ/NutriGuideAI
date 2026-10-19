"""Meal likes write a learning event only when the stance changes (#182)."""

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.db.models import UserInteraction
from tests.builders import make_meal


def _auth(client: TestClient, email: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _events(session: Session, user_id: int) -> list[str]:
    return list(
        session.scalars(
            select(UserInteraction.event_type)
            .where(UserInteraction.user_id == user_id)
            .order_by(UserInteraction.id)
        ).all()
    )


def test_like_dislike_and_clear(
    client: TestClient, integrity_conn: Connection, api_session: Session
) -> None:
    headers = _auth(client, "prefs@example.com")
    other_headers = _auth(client, "other-prefs@example.com")
    meal = make_meal(integrity_conn, is_active=True)
    inactive = make_meal(integrity_conn, is_active=False)
    me = client.get("/api/v1/me", headers=headers)
    user_id = me.json()["user_id"]

    liked = client.put(f"/api/v1/me/meal-prefs/{meal}", json={"stance": "LIKE"}, headers=headers)
    assert liked.status_code == 200, liked.text
    assert liked.json()["stance"] == "LIKE"
    again = client.put(f"/api/v1/me/meal-prefs/{meal}", json={"stance": "LIKE"}, headers=headers)
    assert again.status_code == 200
    disliked = client.put(
        f"/api/v1/me/meal-prefs/{meal}", json={"stance": "DISLIKE"}, headers=headers
    )
    assert disliked.status_code == 200
    assert _events(api_session, user_id) == ["PREF_LIKE", "PREF_DISLIKE"]

    cleared = client.delete(f"/api/v1/me/meal-prefs/{meal}", headers=headers)
    assert cleared.status_code == 204
    assert cleared.content == b""
    again_clear = client.delete(f"/api/v1/me/meal-prefs/{meal}", headers=headers)
    assert again_clear.status_code == 204
    assert _events(api_session, user_id) == ["PREF_LIKE", "PREF_DISLIKE", "PREF_CLEAR"]

    missing = client.put(
        "/api/v1/me/meal-prefs/999999999", json={"stance": "LIKE"}, headers=headers
    )
    assert missing.status_code == 404
    assert missing.json()["code"] == "MEAL_NOT_FOUND"
    inactive_response = client.put(
        f"/api/v1/me/meal-prefs/{inactive}", json={"stance": "LIKE"}, headers=headers
    )
    assert inactive_response.status_code == 404

    client.put(f"/api/v1/me/meal-prefs/{meal}", json={"stance": "LIKE"}, headers=other_headers)
    visible = client.get("/api/v1/me/meal-prefs", headers=headers)
    assert visible.status_code == 200
    assert visible.json() == []
    other = client.get("/api/v1/me/meal-prefs", headers=other_headers)
    assert [row["meal_id"] for row in other.json()] == [meal]
    assert api_session.scalar(select(func.count()).select_from(UserInteraction)) == 4
