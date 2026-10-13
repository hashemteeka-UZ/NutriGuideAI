"""Liveness: the database answers and the catalog has one dataset version (#72)."""

import logging

from fastapi import APIRouter, Request
from sqlalchemy import select, text
from sqlalchemy.exc import DBAPIError

from app.api.deps import DbSession
from app.api.errors import PROBLEM_RESPONSES, ApiError
from app.api.observability import API_LOGGER_NAME
from app.api.schemas.health import HealthResponse
from app.db.models import Meal
from app.services.planner import DEFAULT_PLANNER

logger = logging.getLogger(API_LOGGER_NAME)

router = APIRouter(tags=["health"])


def _dataset_version(versions: list[str]) -> str | None:
    if len(versions) == 1:
        return versions[0]
    if len(versions) > 1:
        listed = ", ".join(sorted(versions))
        logger.warning("active meals have more than one dataset_version: %s", listed)
    return None


@router.get("/health", response_model=HealthResponse, responses=PROBLEM_RESPONSES)
def health(request: Request, session: DbSession) -> HealthResponse:
    try:
        session.execute(text("SELECT 1"))
        versions = list(
            session.scalars(
                select(Meal.dataset_version).where(Meal.is_active.is_(True)).distinct()
            ).all()
        )
    except DBAPIError as exc:
        raise ApiError(503, "DATABASE_UNAVAILABLE", "Database unavailable") from exc
    return HealthResponse(
        status="ok",
        api_version=str(request.app.version),
        database="ok",
        dataset_version=_dataset_version(versions),
        default_planner=DEFAULT_PLANNER,
    )
