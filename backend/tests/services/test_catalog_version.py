"""Catalog version comes from the manifest when active batches match (#183)."""

from __future__ import annotations

import logging

import pytest
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.services.catalog_version import active_dataset_version
from tests.builders import make_meal

_BATCHES = (
    "team_recipes_v1",
    "team_recipes_v2",
    "team_recipes_v3",
    "team_recipes_v4",
    "team_recipes_v5",
)


def _meals(conn, versions: tuple[str, ...]) -> None:
    for version in versions:
        make_meal(conn, dataset_version=version, is_active=True)


def _warnings(caplog: pytest.LogCaptureFixture) -> list[logging.LogRecord]:
    return [record for record in caplog.records if record.name == "app.services.catalog_version"]


def test_five_batches_return_catalog_v3(session: Session, integrity_conn) -> None:
    _meals(integrity_conn, _BATCHES)
    make_meal(integrity_conn, dataset_version="ignored_inactive", is_active=False)
    assert active_dataset_version(session) == "catalog_v3"


def test_a_missing_batch_warns_once_and_returns_none(
    session: Session, integrity_conn, caplog: pytest.LogCaptureFixture
) -> None:
    _meals(integrity_conn, _BATCHES[:-1])
    caplog.set_level(logging.WARNING, logger="app.services.catalog_version")
    assert active_dataset_version(session) is None
    warnings = _warnings(caplog)
    assert len(warnings) == 1
    message = warnings[0].getMessage()
    assert "team_recipes_v5" in message
    assert "expected" in message
    assert "found" in message


def test_an_extra_batch_warns_once_and_returns_none(
    session: Session, integrity_conn, caplog: pytest.LogCaptureFixture
) -> None:
    _meals(integrity_conn, (*_BATCHES, "team_recipes_v9"))
    caplog.set_level(logging.WARNING, logger="app.services.catalog_version")
    assert active_dataset_version(session) is None
    assert len(_warnings(caplog)) == 1
    assert "team_recipes_v9" in _warnings(caplog)[0].getMessage()


def test_a_missing_manifest_warns_once_and_returns_none(
    session: Session, tmp_path, monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    missing = tmp_path / "DATASET_MANIFEST.yaml"
    monkeypatch.setattr(get_settings(), "CATALOG_MANIFEST_PATH", missing)
    caplog.set_level(logging.WARNING, logger="app.services.catalog_version")
    assert active_dataset_version(session) is None
    warnings = _warnings(caplog)
    assert len(warnings) == 1
    assert "missing or unreadable" in warnings[0].getMessage()
