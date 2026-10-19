"""Request-scoped dependencies. Endpoints stay synchronous (#123)."""

from collections.abc import Iterator
from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.errors import ApiError
from app.db.models import User
from app.db.session import SessionLocal
from app.services.auth import TokenInvalidError, decode_access

# Declared on protected routers so OpenAPI shows the bearer scheme.
bearer = HTTPBearer(auto_error=False)


def get_db() -> Iterator[Session]:
    """One session per request. Write endpoints call session.commit() themselves before
    returning; on any exception the session is rolled back. Always closed."""
    session = SessionLocal()
    try:
        yield session
    except BaseException:
        session.rollback()
        raise
    finally:
        session.close()


def get_now() -> datetime:
    """Server time, timezone-aware UTC. Overridden in tests."""
    return datetime.now(UTC)


DbSession = Annotated[Session, Depends(get_db)]
Now = Annotated[datetime, Depends(get_now)]


def _unauthorized() -> ApiError:
    return ApiError(
        401,
        "UNAUTHORIZED",
        "Unauthorized",
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    session: DbSession,
    now: Now,
) -> int:
    """User id from a valid access token. Missing, bad, expired, or deleted → 401."""
    if credentials is None or credentials.scheme.lower() != "bearer" or not credentials.credentials:
        raise _unauthorized()
    try:
        user_id = decode_access(credentials.credentials, now)
    except TokenInvalidError:
        raise _unauthorized() from None
    exists = session.execute(
        select(User.user_id).where(User.user_id == user_id)
    ).scalar_one_or_none()
    if exists is None:
        raise _unauthorized()
    return user_id


CurrentUser = Annotated[int, Depends(get_current_user)]
