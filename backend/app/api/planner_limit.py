"""Process-wide cap on concurrent plan generations (#131, #192).

The semaphore stays in the API layer. The planner itself does not know about it.
"""

from __future__ import annotations

import threading
from collections.abc import Iterator

from app.api.errors import ApiError
from app.core.config import get_settings

PLANNER_RETRY_AFTER = "5"

planner_semaphore = threading.BoundedSemaphore(get_settings().PLANNER_MAX_CONCURRENT)


class PlannerBusyError(ApiError):
    def __init__(self) -> None:
        super().__init__(
            503,
            "PLANNER_BUSY",
            "Planner busy",
            "The planner is already running the maximum number of plans",
            headers={"Retry-After": PLANNER_RETRY_AFTER},
        )


def planner_slot() -> Iterator[None]:
    """One generation slot. Released on success and on failure. Full → 503."""
    if not planner_semaphore.acquire(blocking=False):
        raise PlannerBusyError()
    try:
        yield
    finally:
        planner_semaphore.release()
