"""Compare greedy_v1 and cpsat_v1 on the F.1 personas (Step H.1, #119).

    uv run python -m scripts.planner_comparison_report
    uv run python -m scripts.planner_comparison_report --keep-db

Section 1 uses the isolated F.1 bench. Section 2 uses the database in DATABASE_URL
(the dev catalog when run by hand). Both run inside a transaction that is always
rolled back. Planning time is reported only in section 3.

C1 limits are re-resolved the way the plan was built: resolve_condition_limits at the
frozen target kcal, then apply_general_limits when algorithm_version is cpsat_v1.
The stored target_snapshot is not trusted for the pass/fail flags.
"""

from __future__ import annotations

import argparse
import importlib.metadata
import sys
import time
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path
from statistics import median
from typing import Final, cast

import yaml
from sqlalchemy import create_engine, select
from sqlalchemy.engine import URL, Connection, Engine, make_url
from sqlalchemy.orm import Session

from app.core.config import REPO_ROOT, get_settings
from app.db.models import MealPlanItem, Nutrient
from app.pipeline.build import DEFAULT_DATA_DIR
from app.pipeline.manifest import manifest_path
from app.services.condition_limits import (
    ENERGY_NUTRIENT,
    GENERAL_SATURATED_FAT_PERCENT_ENERGY,
    GENERAL_SODIUM_MG_PER_DAY,
    ResolvedLimits,
    apply_general_limits,
    resolve_condition_limits,
)
from app.services.meal_filter import (
    MealFacts,
    UserPreferences,
    evaluate_meal,
    load_meal_facts,
    load_user_preferences,
)
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.optimizer import (
    LIKED_BONUS,
    W_FIBER,
    W_KCAL,
    W_KCAL_RELAXED,
    W_MACRO,
    W_SLOT,
    optimize_day,
)
from app.services.optimizer import PLANNER_VERSION as CPSAT_VERSION
from app.services.planner import (
    KCAL_TOLERANCE,
    NoFeasiblePlanError,
    PlannerName,
    PlanTarget,
    create_day_plan,
    unmet_minimums,
)
from app.services.planner import PLANNER_VERSION as GREEDY_VERSION
from app.services.tag_rules import TAG_RULES_VERSION
from app.services.targets import FORMULA_VERSION, KCAL_PER_G_FAT
from scripts.f1_scenario_report import (
    START_DATE,
    START_NOW,
    _counts,
    drop_f1_bench,
    f1_bench_name,
    setup_f1_bench,
)
from tests.scenario.f1_scenario import setup_p1, setup_p2

OUTPUT_PATH: Final = REPO_ROOT / "docs" / "reports" / "planner_comparison_report.md"
TIMING_HEADING: Final = "## 3. Planning time"
VERDICT_HEADING: Final = "## 4. Verdict"
PLANNERS: Final[tuple[PlannerName, ...]] = ("greedy", "cpsat")
PERSONAS: Final = ("P1", "P2")
# Literals assigned in optimizer._configure. They are not module constants.
SOLVER_WORKERS: Final = 1
SOLVER_SEED: Final = 0
SOLVER_DETERMINISTIC_TIME: Final = 10.0
FIBER_NUTRIENT: Final = "fiber"
SODIUM_NUTRIENT: Final = "sodium"
SATURATED_FAT_NUTRIENT: Final = "saturated_fat"
PROTEIN_CODE: Final = "protein"
C2_PASS: Final = "PASS"
C2_FAIL: Final = "FAIL"
C2_NA: Final = "N/A (proven infeasible)"
C2_FOOTNOTE: Final = (
    "* phase 1 (hard limits + ±10% kcal band) proven INFEASIBLE by CP-SAT; "
    "not a feasible day under #88 (Decision #121)"
)
BINDING_CAP: Final = "the #87 general cap is the binding constraint on this slice"
SLICE_PREVENTS_BAND: Final = (
    "the condition limits and the slice size alone already prevent the band"
)


@dataclass(frozen=True)
class PlannedItem:
    meal: MealFacts
    slot: str
    multiplier: Decimal


@dataclass(frozen=True)
class Criteria:
    """#88 criteria 1-4, recomputed from items. Timing is not a criterion.

    ``c2`` is PASS, FAIL, or ``N/A (proven infeasible)`` (#121). ``passed`` follows #121:
    a proven-infeasible band does not fail the day. ``passed_strict`` counts that band as FAIL.
    """

    c1_layer1_and_maxima: bool
    c2_kcal_band: bool
    c3_minima: bool
    c4_no_repeat: bool
    c2: str

    @property
    def passed(self) -> bool:
        return (
            self.c1_layer1_and_maxima
            and self.c2 != C2_FAIL
            and self.c3_minima
            and self.c4_no_repeat
        )

    @property
    def passed_strict(self) -> bool:
        return (
            self.c1_layer1_and_maxima
            and self.c2 == C2_PASS
            and self.c3_minima
            and self.c4_no_repeat
        )


@dataclass(frozen=True)
class ItemView:
    meal_id: int
    slot: str
    ref_external: str | None
    multiplier: Decimal
    kcal: Decimal | None


@dataclass(frozen=True)
class BandDiagnosis:
    """Condition-limits-only re-solve of a day whose kcal band was proven infeasible."""

    solver_status: str
    kcal_relaxed: bool | None
    kcal: Decimal | None
    sodium_mg: Decimal | None
    sat_fat_g: Decimal | None
    sodium_of_cap: str
    sat_fat_of_cap: str
    sentence: str
    elapsed_ms: float


@dataclass(frozen=True)
class DayReport:
    persona: str
    planner: str
    day: int
    feasible: bool
    error_slot: str
    error_reasons: str
    items: tuple[ItemView, ...]
    criteria: Criteria | None
    kcal: Decimal | None
    target_kcal: Decimal | None
    protein_g: Decimal | None
    sodium_mg: Decimal | None
    fiber_g: Decimal | None
    sat_fat_g: Decimal | None
    solver_status: str
    kcal_relaxed: str
    sodium_within_general: bool | None
    sat_fat_within_general: bool | None
    sat_fat_limit_g: Decimal | None
    elapsed_ms: float
    diagnosis: BandDiagnosis | None = None


def _total(items: Sequence[PlannedItem], nutrient: str) -> Decimal | None:
    total = Decimal(0)
    for item in items:
        amount = item.meal.amount(nutrient, item.multiplier)
        if amount is None:
            return None
        total += amount
    return total


def _general_sat_limit(target_kcal: Decimal) -> Decimal:
    return GENERAL_SATURATED_FAT_PERCENT_ENERGY / Decimal(100) * target_kcal / KCAL_PER_G_FAT


def _inside_band(kcal: Decimal | None, target_kcal: Decimal) -> bool:
    return kcal is not None and abs(kcal - target_kcal) <= KCAL_TOLERANCE * target_kcal


def _c2_outcome(inside: bool, *, kcal_relaxed: bool) -> tuple[bool, str]:
    """PASS, FAIL, or N/A when CP-SAT proved the band infeasible (#121)."""
    if inside:
        return True, C2_PASS
    if kcal_relaxed:
        return False, C2_NA
    return False, C2_FAIL


def evaluate_criteria(
    items: Sequence[PlannedItem],
    preferences: UserPreferences,
    limits: ResolvedLimits,
    target_kcal: Decimal,
    previous_meal_ids: frozenset[int],
    *,
    kcal_relaxed: bool = False,
) -> Criteria:
    """Recompute #88 criteria 1-4 from exact Decimal amounts. Does not read the database.

    ``kcal_relaxed`` is the stored plan's phase-2 flag. It is true only for a cpsat plan
    whose phase 1 (hard limits plus the kcal band) was INFEASIBLE. Greedy callers leave it
    false, so a greedy day never receives C2 N/A.
    """
    eligible = all(
        evaluate_meal(item.meal, preferences, item.slot, limits, item.multiplier).eligible
        for item in items
    )
    maxima = all(
        (total := _total(items, nutrient)) is not None and total <= limit.value
        for nutrient, limit in limits.max_per_day.items()
    )
    kcal = _total(items, ENERGY_NUTRIENT)
    minima_totals = {nutrient: _total(items, nutrient) for nutrient in limits.min_per_day}
    meal_ids = {item.meal.meal_id for item in items}
    inside, c2 = _c2_outcome(_inside_band(kcal, target_kcal), kcal_relaxed=kcal_relaxed)
    return Criteria(
        c1_layer1_and_maxima=eligible and maxima,
        c2_kcal_band=inside,
        c3_minima=not unmet_minimums(minima_totals, limits),
        c4_no_repeat=meal_ids.isdisjoint(previous_meal_ids),
        c2=c2,
    )


def _flag(value: bool | None) -> str:
    if value is None:
        return "n/a"
    return "PASS" if value else "FAIL"


def _fmt(value: Decimal | None) -> str:
    if value is None:
        return "n/a"
    shown = value.quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)
    text = format(shown, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text or "0"


def _table(headers: Sequence[str], rows: Sequence[Sequence[object]]) -> str:
    head = "| " + " | ".join(headers) + " |"
    rule = "| " + " | ".join("---" for _ in headers) + " |"
    body = ["| " + " | ".join(str(cell) for cell in row) + " |" for row in rows]
    return "\n".join([head, rule, *body])


def _dataset_version() -> str:
    loaded = yaml.safe_load(manifest_path(DEFAULT_DATA_DIR).read_text(encoding="utf-8"))
    if not isinstance(loaded, dict):
        raise RuntimeError("DATASET_MANIFEST.yaml is not a mapping")
    version = loaded.get("dataset_version")
    if not isinstance(version, str):
        raise RuntimeError("dataset_version is missing from DATASET_MANIFEST.yaml")
    return version


def _solver_mapping(snapshot: Mapping[str, object]) -> Mapping[str, object] | None:
    solver = snapshot.get("solver")
    if not isinstance(solver, dict):
        return None
    return solver


def _solver_fields(snapshot: Mapping[str, object]) -> tuple[str, str, bool]:
    solver = _solver_mapping(snapshot)
    if solver is None:
        return "n/a", "n/a", False
    status = solver.get("solver_status", "n/a")
    relaxed = solver.get("kcal_relaxed")
    return str(status), str(relaxed).lower(), relaxed is True


def _excluded_ids(snapshot: Mapping[str, object]) -> frozenset[int]:
    solver = _solver_mapping(snapshot)
    if solver is None:
        return frozenset()
    raw = solver.get("excluded_meal_ids", [])
    if not isinstance(raw, list):
        return frozenset()
    return frozenset(int(item) for item in raw)


def _target_from_snapshot(snapshot: Mapping[str, object]) -> PlanTarget:
    target = snapshot["target"]
    if not isinstance(target, dict):
        raise RuntimeError("target_snapshot target is not a mapping")
    return PlanTarget(
        formula_version=str(snapshot["formula_version"]),
        kcal=Decimal(str(target["kcal"])),
        protein_g=Decimal(str(target["protein_g"])),
        carb_g=Decimal(str(target["carb_g"])),
        fat_g=Decimal(str(target["fat_g"])),
        fiber_g=Decimal(str(target["fiber_g"])),
    )


def _cap_ratio(total: Decimal | None, limit: Decimal) -> str:
    if total is None:
        return f"n/a / {_fmt(limit)}"
    percent = (total / limit * Decimal(100)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"{_fmt(total)} / {_fmt(limit)} ({_fmt(percent)}%)"


def _band_diagnosis(
    session: Session,
    user_id: int,
    meals: Sequence[MealFacts],
    preferences: UserPreferences,
    snapshot: Mapping[str, object],
    target_kcal: Decimal,
    plan_date: date,
    sodium_mg: Decimal | None,
    sat_fat_g: Decimal | None,
    sat_limit: Decimal,
) -> BandDiagnosis:
    """Re-solve with condition limits only. Writes nothing."""
    limits = resolve_condition_limits(session, user_id, target_kcal)
    codes = tuple(session.execute(select(Nutrient.code).order_by(Nutrient.nutrient_id)).scalars())
    started = time.perf_counter()
    try:
        optimized = optimize_day(
            meals,
            preferences,
            limits,
            _target_from_snapshot(snapshot),
            plan_date,
            codes,
            excluded_meal_ids=_excluded_ids(snapshot),
        )
    except NoFeasiblePlanError:
        elapsed_ms = (time.perf_counter() - started) * 1000
        return BandDiagnosis(
            solver_status="INFEASIBLE",
            kcal_relaxed=None,
            kcal=None,
            sodium_mg=None,
            sat_fat_g=None,
            sodium_of_cap=_cap_ratio(sodium_mg, GENERAL_SODIUM_MG_PER_DAY),
            sat_fat_of_cap=_cap_ratio(sat_fat_g, sat_limit),
            sentence=SLICE_PREVENTS_BAND,
            elapsed_ms=elapsed_ms,
        )
    elapsed_ms = (time.perf_counter() - started) * 1000
    totals = optimized.plan.totals
    kcal = totals.get(ENERGY_NUTRIENT)
    inside = optimized.kcal_relaxed is False and _inside_band(kcal, target_kcal)
    return BandDiagnosis(
        solver_status=optimized.solver_status,
        kcal_relaxed=optimized.kcal_relaxed,
        kcal=kcal,
        sodium_mg=totals.get(SODIUM_NUTRIENT),
        sat_fat_g=totals.get(SATURATED_FAT_NUTRIENT),
        sodium_of_cap=_cap_ratio(sodium_mg, GENERAL_SODIUM_MG_PER_DAY),
        sat_fat_of_cap=_cap_ratio(sat_fat_g, sat_limit),
        sentence=BINDING_CAP if inside else SLICE_PREVENTS_BAND,
        elapsed_ms=elapsed_ms,
    )


def _limits_built_against(
    session: Session, user_id: int, snapshot: Mapping[str, object], version: str
) -> tuple[ResolvedLimits, Decimal]:
    target = snapshot["target"]
    if not isinstance(target, dict):
        raise RuntimeError("target_snapshot target is not a mapping")
    target_kcal = Decimal(str(target["kcal"]))
    limits = resolve_condition_limits(session, user_id, target_kcal)
    if version == CPSAT_VERSION:
        limits = apply_general_limits(limits)
    return limits, target_kcal


def _infeasible(
    persona: str, planner: str, offset: int, exc: NoFeasiblePlanError, elapsed_ms: float
) -> DayReport:
    reasons = ", ".join(f"{rule} {count}" for rule, count in exc.reasons.items())
    return DayReport(
        persona=persona,
        planner=planner,
        day=offset,
        feasible=False,
        error_slot=exc.slot,
        error_reasons=reasons,
        items=(),
        criteria=None,
        kcal=None,
        target_kcal=None,
        protein_g=None,
        sodium_mg=None,
        fiber_g=None,
        sat_fat_g=None,
        solver_status="n/a",
        kcal_relaxed="n/a",
        sodium_within_general=None,
        sat_fat_within_general=None,
        sat_fat_limit_g=None,
        elapsed_ms=elapsed_ms,
    )


def _capture(
    session: Session,
    user_id: int,
    persona: str,
    planner: PlannerName,
    offset: int,
    previous_meal_ids: frozenset[int],
) -> DayReport:
    plan_date = START_DATE + timedelta(days=offset)
    now = START_NOW + timedelta(days=offset)
    started = time.perf_counter()
    try:
        plan = create_day_plan(session, user_id, plan_date, now, planner=planner)
    except NoFeasiblePlanError as exc:
        return _infeasible(persona, planner, offset, exc, (time.perf_counter() - started) * 1000)
    elapsed_ms = (time.perf_counter() - started) * 1000
    meal_list = load_meal_facts(session)
    facts = {meal.meal_id: meal for meal in meal_list}
    preferences = load_user_preferences(session, user_id)
    snapshot = cast(Mapping[str, object], plan.target_snapshot)
    limits, target_kcal = _limits_built_against(session, user_id, snapshot, plan.algorithm_version)
    stored = session.scalars(
        select(MealPlanItem).where(MealPlanItem.plan_id == plan.plan_id).order_by(MealPlanItem.id)
    ).all()
    planned = tuple(
        PlannedItem(facts[row.meal_id], row.slot, Decimal(str(row.servings_multiplier)))
        for row in stored
    )
    status, relaxed, relaxed_flag = _solver_fields(snapshot)
    criteria = evaluate_criteria(
        planned,
        preferences,
        limits,
        target_kcal,
        previous_meal_ids,
        kcal_relaxed=relaxed_flag,
    )
    items = tuple(
        ItemView(
            meal_id=item.meal.meal_id,
            slot=item.slot,
            ref_external=item.meal.ref_external,
            multiplier=item.multiplier,
            kcal=item.meal.amount(ENERGY_NUTRIENT, item.multiplier),
        )
        for item in planned
    )
    sodium = _total(planned, SODIUM_NUTRIENT)
    sat_fat = _total(planned, SATURATED_FAT_NUTRIENT)
    sat_limit = _general_sat_limit(target_kcal)
    diagnosis = None
    if planner == "cpsat" and criteria.c2 == C2_NA:
        diagnosis = _band_diagnosis(
            session,
            user_id,
            meal_list,
            preferences,
            snapshot,
            target_kcal,
            plan_date,
            sodium,
            sat_fat,
            sat_limit,
        )
    return DayReport(
        persona=persona,
        planner=planner,
        day=offset,
        feasible=True,
        error_slot="",
        error_reasons="",
        items=items,
        criteria=criteria,
        kcal=_total(planned, ENERGY_NUTRIENT),
        target_kcal=target_kcal,
        protein_g=_total(planned, PROTEIN_CODE),
        sodium_mg=sodium,
        fiber_g=_total(planned, FIBER_NUTRIENT),
        sat_fat_g=sat_fat,
        solver_status=status,
        kcal_relaxed=relaxed,
        sodium_within_general=sodium is not None and sodium <= GENERAL_SODIUM_MG_PER_DAY,
        sat_fat_within_general=sat_fat is not None and sat_fat <= sat_limit,
        sat_fat_limit_g=sat_limit,
        elapsed_ms=elapsed_ms,
        diagnosis=diagnosis,
    )


def _plan_persona_days(
    session: Session, users: Mapping[str, int], planner: PlannerName
) -> list[DayReport]:
    """Plan three days, then roll back so the other planner cannot see these plans."""
    nested = session.begin_nested()
    try:
        reports: list[DayReport] = []
        previous: dict[str, frozenset[int]] = {name: frozenset() for name in PERSONAS}
        for offset in range(3):
            for persona in PERSONAS:
                report = _capture(
                    session, users[persona], persona, planner, offset, previous[persona]
                )
                reports.append(report)
                previous[persona] = frozenset(item.meal_id for item in report.items)
        return reports
    finally:
        nested.rollback()


def collect_section(session: Session, conn: Connection) -> list[DayReport]:
    """Create P1 and P2 once, then plan each planner inside its own savepoint."""
    users = {
        "P1": setup_p1(session, conn, START_DATE, START_NOW),
        "P2": setup_p2(session, conn, START_DATE, START_NOW),
    }
    reports: list[DayReport] = []
    for planner in PLANNERS:
        reports.extend(_plan_persona_days(session, users, planner))
    return reports


def _sort_key(day: DayReport) -> tuple[str, int, int]:
    return (day.persona, PLANNERS.index(cast(PlannerName, day.planner)), day.day)


def _c2_cell(criteria: Criteria) -> str:
    if criteria.c2 == C2_NA:
        return "N/A*"
    return C2_PASS if criteria.c2_kcal_band else C2_FAIL


def _criteria_rows(days: Sequence[DayReport]) -> list[list[object]]:
    rows: list[list[object]] = []
    for day in sorted(days, key=_sort_key):
        criteria = day.criteria
        if not day.feasible or criteria is None:
            flags = ("FAIL", "FAIL", "FAIL", "FAIL")
            kcal = f"no feasible plan ({day.error_slot}): {day.error_reasons}"
        else:
            flags = (
                _flag(criteria.c1_layer1_and_maxima),
                _c2_cell(criteria),
                _flag(criteria.c3_minima),
                _flag(criteria.c4_no_repeat),
            )
            kcal = f"{_fmt(day.kcal)} ({_fmt(day.target_kcal)})"
        rows.append(
            [
                day.persona,
                day.planner,
                day.day,
                *flags,
                kcal,
                _fmt(day.protein_g),
                _fmt(day.sodium_mg),
                _fmt(day.fiber_g),
                _fmt(day.sat_fat_g),
                day.solver_status,
                day.kcal_relaxed,
            ]
        )
    return rows


def _item_rows(days: Sequence[DayReport]) -> list[list[object]]:
    rows: list[list[object]] = []
    for day in sorted(days, key=_sort_key):
        if not day.items:
            rows.append(
                [
                    day.persona,
                    day.planner,
                    day.day,
                    "n/a",
                    f"no feasible plan ({day.error_slot})",
                    "n/a",
                    "n/a",
                ]
            )
            continue
        for item in day.items:
            rows.append(
                [
                    day.persona,
                    day.planner,
                    day.day,
                    item.slot,
                    item.ref_external or "n/a",
                    _fmt(item.multiplier),
                    _fmt(item.kcal),
                ]
            )
    return rows


def _general_rows(days: Sequence[DayReport]) -> list[list[object]]:
    rows: list[list[object]] = []
    for day in sorted(days, key=_sort_key):
        rows.append(
            [
                day.persona,
                day.planner,
                day.day,
                _fmt(day.sodium_mg),
                _fmt(GENERAL_SODIUM_MG_PER_DAY) if day.feasible else "n/a",
                _flag(day.sodium_within_general),
                _fmt(day.sat_fat_g),
                _fmt(day.sat_fat_limit_g),
                _flag(day.sat_fat_within_general),
            ]
        )
    return rows


def _summary_lines(days: Sequence[DayReport]) -> list[str]:
    lines: list[str] = []
    for planner in PLANNERS:
        owned = [day for day in days if day.planner == planner]
        passed = sum(1 for day in owned if day.criteria is not None and day.criteria.passed)
        na_days = sum(1 for day in owned if day.criteria is not None and day.criteria.c2 == C2_NA)
        lines.append(
            f"{planner}: criteria 1-4 passed on {passed}/{len(owned)} persona-days "
            f"({na_days} days C2 N/A, proven infeasible)"
        )
    return lines


def _failed_names(criteria: Criteria, *, strict: bool) -> list[str]:
    c2_ok = criteria.c2 == C2_PASS or (not strict and criteria.c2 == C2_NA)
    names = (
        ("C1", criteria.c1_layer1_and_maxima),
        ("C2", c2_ok),
        ("C3", criteria.c3_minima),
        ("C4", criteria.c4_no_repeat),
    )
    return [name for name, ok in names if not ok]


def _failures(days: Sequence[DayReport], *, strict: bool) -> list[str]:
    lines: list[str] = []
    for day in sorted(days, key=_sort_key):
        if day.planner != "cpsat":
            continue
        if not day.feasible or day.criteria is None:
            lines.append(f"- {day.persona} day {day.day}: no feasible plan ({day.error_slot})")
            continue
        failed = _failed_names(day.criteria, strict=strict)
        if failed:
            lines.append(f"- {day.persona} day {day.day}: {', '.join(failed)}")
    return lines


def meets_88(days: Sequence[DayReport]) -> str:
    """#121: a proven-infeasible kcal band is not a failure."""
    return "YES" if not _failures(days, strict=False) else "NO"


def meets_88_strict(days: Sequence[DayReport]) -> str:
    """Same days, counting C2 N/A as FAIL."""
    return "YES" if not _failures(days, strict=True) else "NO"


def verdict_lines(scope: str, days: Sequence[DayReport]) -> tuple[str, str]:
    return (
        f"cpsat_v1 meets all #88 criteria on the {scope}: {meets_88(days)}",
        f"strict reading (N/A counted as FAIL): {meets_88_strict(days)}",
    )


def _timing_block(label: str, days: Sequence[DayReport]) -> list[str]:
    lines = [f"### {label}", ""]
    for planner in PLANNERS:
        samples = sorted(day.elapsed_ms for day in days if day.planner == planner)
        if not samples:
            lines.append(f"{planner}: n=0")
            continue
        lines.append(
            f"{planner}: n={len(samples)}, median={median(samples):.3f} ms, "
            f"max={max(samples):.3f} ms"
        )
    lines += [
        "",
        _table(
            ("persona", "planner", "day", "ms", "solver status", "kcal_relaxed"),
            [
                (
                    day.persona,
                    day.planner,
                    day.day,
                    f"{day.elapsed_ms:.3f}",
                    day.solver_status,
                    day.kcal_relaxed,
                )
                for day in sorted(days, key=_sort_key)
            ],
        ),
        "",
    ]
    diagnosed = [day for day in sorted(days, key=_sort_key) if day.diagnosis is not None]
    if diagnosed:
        lines += [
            "Diagnostic solves (not included in the planner medians):",
            "",
            _table(
                ("persona", "planner", "day", "ms"),
                [
                    (
                        day.persona,
                        day.planner,
                        day.day,
                        f"{day.diagnosis.elapsed_ms:.3f}" if day.diagnosis is not None else "n/a",
                    )
                    for day in diagnosed
                ],
            ),
            "",
        ]
    return lines


def _diagnosis_lines(days: Sequence[DayReport]) -> list[str]:
    diagnosed = [day for day in sorted(days, key=_sort_key) if day.diagnosis is not None]
    if not diagnosed:
        return []
    lines = ["### Why no plan reaches the band", ""]
    for day in diagnosed:
        diagnosis = day.diagnosis
        if diagnosis is None:
            continue
        relaxed = "n/a" if diagnosis.kcal_relaxed is None else str(diagnosis.kcal_relaxed).lower()
        lines += [
            f"#### {day.persona} day {day.day}",
            "",
            (
                "Condition limits only: "
                f"solver status {diagnosis.solver_status}, kcal_relaxed {relaxed}, "
                f"day kcal {_fmt(diagnosis.kcal)}, sodium mg {_fmt(diagnosis.sodium_mg)}, "
                f"saturated fat g {_fmt(diagnosis.sat_fat_g)}."
            ),
            (
                "Stored plan against the #87 caps: "
                f"sodium {diagnosis.sodium_of_cap}, saturated fat {diagnosis.sat_fat_of_cap}."
            ),
            diagnosis.sentence,
            "",
        ]
    return lines


def _section_body(title: str, days: Sequence[DayReport]) -> list[str]:
    lines = [
        f"## {title}",
        "",
        _table(
            (
                "persona",
                "planner",
                "day",
                "C1",
                "C2",
                "C3",
                "C4",
                "kcal (target)",
                "protein g",
                "sodium mg",
                "fiber g",
                "sat fat g",
                "solver status",
                "kcal_relaxed",
            ),
            _criteria_rows(days),
        ),
        "",
    ]
    if any(day.criteria is not None and day.criteria.c2 == C2_NA for day in days):
        lines += [C2_FOOTNOTE, ""]
    lines += [
        "general limits #87 (informational; greedy is not required to meet them, cpsat is):",
        "",
        _table(
            (
                "persona",
                "planner",
                "day",
                "sodium mg",
                "sodium limit mg",
                "sodium within",
                "sat fat g",
                "sat fat limit g",
                "sat fat within",
            ),
            _general_rows(days),
        ),
        "",
        _table(
            ("persona", "planner", "day", "slot", "ref_external", "multiplier", "kcal"),
            _item_rows(days),
        ),
        "",
        *_summary_lines(days),
        "",
        *_diagnosis_lines(days),
    ]
    return lines


def render_report(f1_days: Sequence[DayReport], catalog_days: Sequence[DayReport]) -> str:
    versions = _table(
        ("name", "version"),
        [
            ("tag_rules_version", TAG_RULES_VERSION),
            ("computation_version", COMPUTATION_VERSION),
            ("formula_version", FORMULA_VERSION),
            ("greedy planner_version", GREEDY_VERSION),
            ("cpsat planner_version", CPSAT_VERSION),
            ("ortools", importlib.metadata.version("ortools")),
            ("dataset_version", _dataset_version()),
        ],
    )
    lines = [
        "# Planner comparison",
        "",
        "## 0. Versions and solver",
        "",
        versions,
        "",
        (
            f"Solver parameters from optimizer._configure: num_workers={SOLVER_WORKERS}, "
            f"random_seed={SOLVER_SEED}, "
            f"max_deterministic_time={SOLVER_DETERMINISTIC_TIME}, "
            "log_search_progress=False."
        ),
        (
            f"Objective weights: W_KCAL={W_KCAL}, W_KCAL_RELAXED={W_KCAL_RELAXED}, "
            f"W_MACRO={W_MACRO}, W_FIBER={W_FIBER}, W_SLOT={W_SLOT}, "
            f"LIKED_BONUS={LIKED_BONUS}."
        ),
        (
            "C1 re-resolves limits the way the plan was built: resolve_condition_limits at the "
            "frozen target kcal, then apply_general_limits when algorithm_version is cpsat_v1. "
            "Day totals are recomputed from stored items with exact Decimal amounts."
        ),
        "",
        *_section_body("1. F.1 benchmark", f1_days),
        *_section_body("2. Full catalog", catalog_days),
        TIMING_HEADING,
        "",
        *_timing_block("F.1 benchmark", f1_days),
        *_timing_block("Full catalog", catalog_days),
        VERDICT_HEADING,
        "",
        *verdict_lines("F.1 benchmark", f1_days),
        *verdict_lines("catalog", catalog_days),
    ]
    f1_failures = _failures(f1_days, strict=False)
    catalog_failures = _failures(catalog_days, strict=False)
    if f1_failures:
        lines.append("")
        lines.append("F.1 benchmark failures:")
        lines.extend(f1_failures)
    if catalog_failures:
        lines.append("")
        lines.append("Catalog failures:")
        lines.extend(catalog_failures)
    lines.append("")
    return "\n".join(lines)


def _run_on(engine: Engine, label: str) -> tuple[list[DayReport], int]:
    before = (0, 0, 0)
    after = (0, 0, 0)
    reports: list[DayReport] = []
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            with Session(bind=conn) as session:
                before = _counts(session)
                reports = collect_section(session, conn)
        finally:
            trans.rollback()
        with Session(bind=conn) as session:
            after = _counts(session)
    print(f"{label} users {before[0]} -> {after[0]}")
    print(f"{label} meal_plans {before[1]} -> {after[1]}")
    print(f"{label} consumption_logs {before[2]} -> {after[2]}")
    if before != after:
        print(f"{label} row counts changed; rollback failed", file=sys.stderr)
        return reports, 1
    return reports, 0


def write_comparison_report(base_url: URL, output_path: Path, *, keep_db: bool = False) -> int:
    """Write the comparison. The bench is created from `base_url` and dropped unless keep_db."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bench = setup_f1_bench(base_url)
    catalog = create_engine(base_url)
    try:
        f1_days, f1_code = _run_on(bench, "f1")
        catalog_days, catalog_code = _run_on(catalog, "catalog")
        output_path.write_text(render_report(f1_days, catalog_days), encoding="utf-8")
        print(output_path)
        return 1 if f1_code or catalog_code else 0
    finally:
        bench.dispose()
        catalog.dispose()
        if not keep_db:
            drop_f1_bench(base_url)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compare greedy_v1 and cpsat_v1 day plans.")
    parser.add_argument(
        "--keep-db",
        action="store_true",
        help="Leave the F.1 bench database in place after the report is written.",
    )
    args = parser.parse_args(argv)
    base_url = make_url(get_settings().DATABASE_URL)
    print(f1_bench_name(base_url.database))
    return write_comparison_report(base_url, OUTPUT_PATH, keep_db=args.keep_db)


if __name__ == "__main__":
    sys.exit(main())
