"""Write the OpenAPI contract to docs/api/openapi.json.

uv run python -m scripts.export_openapi
uv run python -m scripts.export_openapi --check
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from app.api.main import create_app
from app.core.config import REPO_ROOT

OUTPUT_PATH: Path = REPO_ROOT / "docs" / "api" / "openapi.json"
STALE_MESSAGE = (
    "docs/api/openapi.json is stale: run `uv run python -m scripts.export_openapi` from backend/"
)


def openapi_text() -> str:
    schema = create_app().openapi()
    return json.dumps(schema, indent=2, ensure_ascii=False, sort_keys=True) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if docs/api/openapi.json is missing or differs",
    )
    args = parser.parse_args(argv)
    text = openapi_text()
    if args.check:
        if not OUTPUT_PATH.is_file() or OUTPUT_PATH.read_text(encoding="utf-8") != text:
            print(STALE_MESSAGE, file=sys.stderr)
            return 1
        return 0
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(text, encoding="utf-8")
    print(f"wrote {OUTPUT_PATH.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
