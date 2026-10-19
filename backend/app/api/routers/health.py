"""Liveness: the database answers and the catalog has one dataset version (#72)."""

from fastapi import APIRouter, Request
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError

from app.api.deps import DbSession
from app.api.errors import PROBLEM_RESPONSES, ApiError
from app.api.schemas.health import HealthResponse
from app.services.catalog_version import active_dataset_version
from app.services.planner import DEFAULT_PLANNER

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse, responses=PROBLEM_RESPONSES)
def health(request: Request, session: DbSession) -> HealthResponse:
    try:
        session.execute(text("SELECT 1"))
        version = active_dataset_version(session)
    except DBAPIError as exc:
        raise ApiError(503, "DATABASE_UNAVAILABLE", "Database unavailable") from exc
    return HealthResponse(
        status="ok",
        api_version=str(request.app.version),
        database="ok",
        dataset_version=version,
        default_planner=DEFAULT_PLANNER,
    )
