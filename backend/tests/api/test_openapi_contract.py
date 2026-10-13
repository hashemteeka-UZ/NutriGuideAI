"""The committed OpenAPI document is the schema create_app() serves."""

from __future__ import annotations

import json

from app.api.main import create_app
from app.core.config import REPO_ROOT

CONTRACT = REPO_ROOT / "docs" / "api" / "openapi.json"
_STALE = (
    "docs/api/openapi.json is stale: run `uv run python -m scripts.export_openapi` from backend/"
)


def test_committed_openapi_matches_generated_schema() -> None:
    schema = create_app().openapi()
    expected = json.dumps(schema, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    assert CONTRACT.is_file(), _STALE
    assert CONTRACT.read_text(encoding="utf-8") == expected, _STALE


def test_openapi_paths_are_versioned() -> None:
    schema = json.loads(CONTRACT.read_text(encoding="utf-8"))
    assert schema["paths"]
    for path in schema["paths"]:
        assert path.startswith("/api/v1/")


def test_problem_detail_is_in_components() -> None:
    schema = json.loads(CONTRACT.read_text(encoding="utf-8"))
    assert "ProblemDetail" in schema["components"]["schemas"]
