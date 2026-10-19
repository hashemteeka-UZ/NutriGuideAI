"""In-memory rate limits (#132). Auth routes are limited here; the others wait for their routes.

Behind a reverse proxy the server must run with trusted proxy headers so the
address below is the client's, not the proxy's.
"""

from __future__ import annotations

import time
from typing import Final

from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from starlette.responses import Response

from app.api.errors import problem_response
from app.core.config import get_settings

AUTH_RATE_LIMIT: Final = "10/minute"
PLAN_GENERATION_RATE_LIMIT: Final = "20/hour"
SYNC_RATE_LIMIT: Final = "60/hour"
DEFAULT_RATE_LIMIT: Final = "300/minute"


def _client_address(request: Request) -> str:
    return get_remote_address(request)


limiter = Limiter(
    key_func=_client_address,
    enabled=get_settings().RATE_LIMIT_ENABLED,
    storage_uri="memory://",
)


def rate_limit_handler(request: Request, _exc: Exception) -> Response:
    """429 RATE_LIMITED in the problem format, with Retry-After."""
    response = problem_response(429, "RATE_LIMITED", "Rate limited", "Too many requests")
    view_limit = getattr(request.state, "view_rate_limit", None)
    if view_limit is not None:
        item, args = view_limit
        window_stats = limiter.limiter.get_window_stats(item, *args)
        retry_after = max(int((1 + window_stats[0]) - time.time()), 1)
        response.headers["Retry-After"] = str(retry_after)
    else:
        response.headers["Retry-After"] = "60"
    return response
