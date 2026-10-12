"""Layer 1 coverage of the loaded catalog (Decision #100).

    uv run python -m scripts.catalog_coverage_report

Five synthetic profiles share one body and differ by condition. Screening, targets, and
limits are the same code path the scenario report uses. The transaction is rolled back.
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from datetime import UTC, date, datetime
from decimal import Decimal
from pathlib import Path

from sqlalchemy import create_engine, func, select, text
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.orm import Session

from app.core.config import REPO_ROOT, get_settings
from app.db.models import Food, HealthCondition, Meal
from app.db.models.user import MealSlot, TargetReason
from app.services.condition_limits import ResolvedLimits, resolve_condition_limits
from app.services.meal_filter import INACTIVE, evaluate_meals
from app.services.screening import screen_user
from app.services.tag_rules import TAG_RULES_VERSION
from app.services.targets import create_user_target
from tests.builders import make_user, make_user_health_condition, make_user_profile, make_weight_log

REFERENCE_DATE: date = date(2026, 10, 7)
REFERENCE_NOW: datetime = datetime(2026, 10, 7, 5, 0, tzinfo=UTC)
OUTPUT_PATH: Path = REPO_ROOT / "docs" / "reports" / "catalog_coverage_report.md"
ELIGIBLE_TARGET = 8
MAIN_SLOTS = (MealSlot.BREAKFAST, MealSlot.LUNCH, MealSlot.DINNER)
PROFILES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("NONE", ()),
    ("DIABETES_T2", ("DIABETES_T2",)),
    ("HYPERTENSION", ("HYPERTENSION",)),
    ("HEART_DISEASE", ("HEART_DISEASE",)),
    ("HYPERTENSION + DIABETES_T2", ("HYPERTENSION", "DIABETES_T2")),
)
# P2 body (female, born 1971-01-15, 160 cm, 70 kg, maintain) with moderate activity.
BODY = {
    "sex": "FEMALE",
    "birth_date": date(1971, 1, 15),
    "height_cm": 160,
    "activity_level": "MODERATE",
    "goal_type": "MAINTAIN",
    "timezone": "Africa/Tripoli",
}


def _table(headers: tuple[str, ...], rows: list[list[object]]) -> str:
    head = "| " + " | ".join(headers) + " |"
    sep = "| " + " | ".join("---" for _ in headers) + " |"
    body = ["| " + " | ".join(str(cell) for cell in row) + " |" for row in rows]
    return "\n".join([head, sep, *body])


def _public_counts(session: Session) -> list[tuple[str, int]]:
    names = list(
        session.execute(
            text(
                "SELECT c.relname FROM pg_class c "
                "JOIN pg_namespace n ON n.oid = c.relnamespace "
                "WHERE n.nspname = 'public' AND c.relkind = 'r' "
                "ORDER BY c.relname"
            )
        ).scalars()
    )
    counts: list[tuple[str, int]] = []
    for name in names:
        if not name.isidentifier():
            raise RuntimeError(name)
        count = session.execute(text(f"SELECT count(*) FROM {name}")).scalar_one()
        counts.append((name, int(count)))
    return counts


def _condition_id(session: Session, code: str) -> int:
    return session.execute(
        select(HealthCondition.condition_id).where(HealthCondition.code == code)
    ).scalar_one()


def _profile_limits(
    session: Session, label: str, conditions: tuple[str, ...], index: int
) -> tuple[int, ResolvedLimits]:
    conn: Connection = session.connection()
    user = make_user(conn, email=f"coverage.{index}@example.com")
    make_user_profile(conn, user_id=user, **BODY)
    for code in conditions:
        make_user_health_condition(conn, user_id=user, condition_id=_condition_id(session, code))
    make_weight_log(
        conn,
        user_id=user,
        measured_on=REFERENCE_DATE,
        weight_kg=Decimal(70),
        updated_at=REFERENCE_NOW,
    )
    session.expire_all()
    screening = screen_user(session, user, REFERENCE_DATE)
    if not screening.eligible:
        raise RuntimeError(f"{label} screening failed: {screening.reasons}")
    target = create_user_target(session, user, TargetReason.INITIAL, REFERENCE_NOW)
    return user, resolve_condition_limits(session, user, target.target_kcal)


def render_report(session: Session) -> str:
    versions = list(
        session.execute(
            select(Meal.dataset_version).distinct().order_by(Meal.dataset_version)
        ).scalars()
    )
    active = int(
        session.execute(
            select(func.count()).select_from(Meal).where(Meal.is_active.is_(True))
        ).scalar_one()
    )
    foods = int(session.execute(select(func.count()).select_from(Food)).scalar_one())
    lines = [
        "# Catalog coverage report",
        "",
        f"Reference date {REFERENCE_DATE.isoformat()}. "
        "Five profiles share one body and differ by condition. "
        "Limits come from screening, targets, and `resolve_condition_limits`. "
        "Each slot is `evaluate_meals` at multiplier 1.0 over active meals.",
        "",
        "## 1. Data and versions",
        "",
        _table(
            ("field", "value"),
            [
                ["reference_date", REFERENCE_DATE.isoformat()],
                ["dataset_version", ", ".join(versions) if versions else "—"],
                ["tag_rules_version", TAG_RULES_VERSION],
                ["active meals", active],
                ["foods", foods],
            ],
        ),
        "",
        "## 2. Layer 1 eligibility",
        "",
    ]
    table_rows: list[list[object]] = []
    eligible_refs: dict[tuple[str, str], list[str]] = {}
    for index, (label, conditions) in enumerate(PROFILES):
        user, limits = _profile_limits(session, label, conditions, index)
        for slot in MealSlot:
            evaluations = [
                item
                for item in evaluate_meals(session, user, slot, limits, Decimal("1.0"))
                if INACTIVE not in item.exclusion_codes
            ]
            eligible = [item for item in evaluations if item.eligible]
            removed = Counter(code for item in evaluations for code in item.exclusion_codes)
            removing = (
                ", ".join(f"{code} {count}" for code, count in sorted(removed.items())) or "—"
            )
            table_rows.append([label, slot, len(eligible), len(evaluations), removing])
            if slot in MAIN_SLOTS:
                eligible_refs[(label, slot)] = sorted(
                    item.ref_external or str(item.meal_id) for item in eligible
                )
    lines += [
        _table(("profile", "slot", "eligible", "evaluated", "removing codes"), table_rows),
        "",
    ]
    lines += ["## 3. Main-slot target", ""]
    for label, _conditions in PROFILES:
        for slot in MAIN_SLOTS:
            count = len(eligible_refs[(label, slot)])
            verdict = "PASS" if count >= ELIGIBLE_TARGET else f"BELOW TARGET ({count})"
            lines.append(f"{label} {slot}: {verdict}")
    lines.append("")
    lines += ["## 4. Eligible meals", ""]
    for label, _conditions in PROFILES:
        for slot in MAIN_SLOTS:
            refs = eligible_refs[(label, slot)]
            lines.append(f"### {label} {slot}")
            lines.append("")
            lines.append(", ".join(refs) if refs else "(none)")
            lines.append("")
    text = "\n".join(lines)
    if not text.endswith("\n"):
        text += "\n"
    return text


def write_coverage_report(engine: Engine, output_path: Path) -> int:
    """Write the report inside one transaction and always roll it back."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    before: list[tuple[str, int]] = []
    after: list[tuple[str, int]] = []
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            with Session(bind=conn) as session:
                before = _public_counts(session)
                output_path.write_text(render_report(session), encoding="utf-8")
        finally:
            trans.rollback()
        with Session(bind=conn) as session:
            after = _public_counts(session)
    print(output_path)
    if before != after:
        print("row counts changed; rollback failed", file=sys.stderr)
        return 1
    print("row counts unchanged")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Write the catalog coverage report. The transaction is rolled back."
    )
    parser.parse_args(argv)
    engine = create_engine(get_settings().DATABASE_URL)
    try:
        return write_coverage_report(engine, OUTPUT_PATH)
    finally:
        engine.dispose()


if __name__ == "__main__":
    sys.exit(main())
