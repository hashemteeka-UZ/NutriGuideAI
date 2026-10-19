"""The dataset version shared by /health and /reference (#72, #180)."""

from __future__ import annotations

import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.observability import API_LOGGER_NAME
from app.db.models import Meal

logger = logging.getLogger(API_LOGGER_NAME)


def active_dataset_version(session: Session) -> str | None:
    """The dataset_version of every active meal, or None when there isn't exactly one."""
    versions = list(
        session.scalars(
            select(Meal.dataset_version).where(Meal.is_active.is_(True)).distinct()
        ).all()
    )
    if len(versions) == 1:
        return versions[0]
    if len(versions) > 1:
        listed = ", ".join(sorted(versions))
        logger.warning("active meals have more than one dataset_version: %s", listed)
    return None
