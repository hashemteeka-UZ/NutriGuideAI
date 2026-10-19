"""GET /reference is public and follows Accept-Language (#180)."""

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from tests.api.conftest import NOW

_HIDDEN = ("CKD", "PREGNANCY", "LACTATION", "GOUT", "kidney", "pregnancy", "gout")


def test_reference_is_public_localized_and_matches_health(
    client: TestClient, api_session: Session
) -> None:
    load_f1_slice(api_session, DEFAULT_DATA_DIR, now=NOW)
    response = client.get("/api/v1/reference")
    assert response.status_code == 200, response.text
    assert response.headers["cache-control"] == "public, max-age=3600"
    body = response.json()
    insulin = next(item for item in body["health_conditions"] if item["code"] == "DIABETES_INSULIN")
    heart = next(item for item in body["health_conditions"] if item["code"] == "HEART_DISEASE")
    assert insulin["is_supported"] is False
    assert heart["fluid_goal_requires_clinician"] is True
    assert "\u0627\u0631\u062a\u0641\u0627\u0639" in next(
        item["name"] for item in body["health_conditions"] if item["code"] == "HYPERTENSION"
    )
    rendered = response.text.lower()
    for word in _HIDDEN:
        assert word.lower() not in rendered
    english = client.get("/api/v1/reference", headers={"Accept-Language": "en"})
    assert english.status_code == 200
    assert (
        next(
            item["name"]
            for item in english.json()["health_conditions"]
            if item["code"] == "HYPERTENSION"
        )
        == "Hypertension"
    )
    health = client.get("/api/v1/health")
    assert health.json()["dataset_version"] is None
    assert body["dataset_version"] == "unknown"
