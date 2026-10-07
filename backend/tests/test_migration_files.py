"""Committed Alembic migrations are immutable (§20.1, Decision #73). No database needed."""

import hashlib
from pathlib import Path

import pytest

VERSIONS_DIR = Path(__file__).resolve().parents[1] / "alembic" / "versions"

# A new migration records its hash here in the same commit (§20.1).
MIGRATION_SHA256: dict[str, str] = {
    "0001_initial_schema.py": "ffd95272e80226bb973b03b214a7d304ad0f8862c7569307b62b99d4258acda6",
    "0002_meal_plan_items_unique_slot.py": (
        "f2f0c45c7679470be517f07815e791278b5e5cbd1a0b39c09aea42391304ff62"
    ),
    "0003_codes_variants_optional_qc.py": (
        "75371f5d06195665c308a57efd8c95504948a770b211b18ce712e86ef00fc6fe"
    ),
}

EDITED_MESSAGE = (
    "Committed migrations must never be edited; create a new revision instead "
    "(PROJECT_CONTEXT §20.1)."
)


def test_every_migration_file_has_a_recorded_hash() -> None:
    on_disk = {path.name for path in VERSIONS_DIR.glob("*.py")}
    recorded = set(MIGRATION_SHA256)
    assert on_disk == recorded, (
        f"without a recorded hash: {sorted(on_disk - recorded)}; "
        f"recorded but missing: {sorted(recorded - on_disk)}"
    )


@pytest.mark.parametrize("file_name", sorted(MIGRATION_SHA256))
def test_migration_file_unchanged(file_name: str) -> None:
    path = VERSIONS_DIR / file_name
    assert path.is_file(), f"{file_name} is missing from {VERSIONS_DIR}"
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    assert actual == MIGRATION_SHA256[file_name], (
        f"{file_name}: SHA-256 {actual} != recorded {MIGRATION_SHA256[file_name]}. "
        + EDITED_MESSAGE
    )
