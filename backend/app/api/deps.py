"""Request-scoped dependencies. Endpoints stay synchronous (#123)."""

from collections.abc import Iterator
from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends
from sqlalchemy.orm import Session

from app.db.session import SessionLocal


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
