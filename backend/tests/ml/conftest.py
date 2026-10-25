"""Learning-layer tests. DB tests use the migrated integrity database and roll back."""

from __future__ import annotations

from collections.abc import Iterator

import pytest
from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.ml.features import clear_feature_cache
from app.ml.replay import clear_replay_cache
from app.seed.f1_loader import DEFAULT_DATA_DIR, load_f1_slice
from tests.services.conftest import NOW


@pytest.fixture(autouse=True)
def _clear_caches() -> Iterator[None]:
    # Each test rolls back, so a cache key seen in one test can mean other rows in the next.
    clear_feature_cache()
    clear_replay_cache()
    yield
    clear_feature_cache()
    clear_replay_cache()


@pytest.fixture
def session(integrity_conn: Connection) -> Iterator[Session]:
    with Session(bind=integrity_conn, join_transaction_mode="create_savepoint") as s:
        yield s


@pytest.fixture
def slice_session(session: Session) -> Session:
    load_f1_slice(session, DEFAULT_DATA_DIR, now=NOW)
    return session
