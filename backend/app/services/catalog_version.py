"""The catalog version shared by /health, /reference, and the offline snapshot (#183).

Each meal stores its batch id in meals.dataset_version. The catalog version lives in
DATASET_MANIFEST.yaml and is returned only when the active meals' batch ids are exactly
the manifest's meal_batches.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import yaml
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.models import Meal

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class _Manifest:
    dataset_version: str
    batches: frozenset[str]


@lru_cache(maxsize=4)
def _read_manifest(path: str) -> _Manifest | None:
    """Parse the manifest once per path per process. None when it cannot be used."""
    try:
        loaded = yaml.safe_load(Path(path).read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError):
        return None
    if not isinstance(loaded, dict):
        return None
    version = loaded.get("dataset_version")
    batches = loaded.get("meal_batches")
    if not isinstance(version, str) or not version or not isinstance(batches, dict) or not batches:
        return None
    found: set[str] = set()
    for entry in batches.values():
        if not isinstance(entry, dict):
            return None
        batch_version = entry.get("dataset_version")
        if not isinstance(batch_version, str) or not batch_version:
            return None
        found.add(batch_version)
    if not found:
        return None
    return _Manifest(dataset_version=version, batches=frozenset(found))


def active_dataset_version(session: Session) -> str | None:
    """Manifest dataset_version when active meal batches match it, else None.

    A missing or unreadable manifest, or a different set of active batch ids, is a warning
    and None. It is never an error.
    """
    path = get_settings().CATALOG_MANIFEST_PATH
    manifest = _read_manifest(str(path))
    if manifest is None:
        logger.warning("catalog manifest missing or unreadable: %s", path)
        return None
    found = set(
        session.scalars(
            select(Meal.dataset_version).where(Meal.is_active.is_(True)).distinct()
        ).all()
    )
    if found == set(manifest.batches):
        return manifest.dataset_version
    logger.warning(
        "catalog meal batches differ from the manifest: expected %s, found %s",
        ", ".join(sorted(manifest.batches)),
        ", ".join(sorted(found)),
    )
    return None
