"""Run the F.1-e scenario on the dev database and write docs/reports/f1_scenario_report.md.

The scenario runs inside one transaction that is always rolled back. Catalog rows already on
the dev database are left untouched; persona rows created by the scenario are discarded.
"""

from __future__ import annotations

import sys
from collections import Counter
from collections.abc import Mapping, Sequence
from datetime import UTC, date, datetime
from decimal import Decimal
from statistics import median
from typing import Final

from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session

from app.core.config import REPO_ROOT, get_settings
from app.db.models import ConsumptionLog, Food, Meal, MealNutrient, MealPlan, Nutrient, User
from app.db.models.user import MealSlot
from app.services.condition_limits import ResolvedLimits
from app.services.meal_filter import evaluate_meals
from app.services.meal_nutrition import COMPUTATION_VERSION
from app.services.planner import PLANNER_VERSION
from app.services.tag_rules import TAG_RULES_VERSION
from app.services.targets import FORMULA_VERSION
from tests.scenario.f1_scenario import PersonaResult, ScenarioResult, run_f1_scenario

START_DATE: Final = date(2026, 10, 7)
START_NOW: Final = datetime(2026, 10, 7, 5, 0, tzinfo=UTC)
OUTPUT_PATH: Final = REPO_ROOT / "docs" / "reports" / "f1_scenario_report.md"
TIMING_HEADING: Final = "## 6. Planner timing"


def _count(session: Session, model: type[object]) -> int:
    return int(session.execute(select(func.count()).select_from(model)).scalar_one())


def _counts(session: Session) -> tuple[int, int, int]:
    return (
        _count(session, User),
        _count(session, MealPlan),
        _count(session, ConsumptionLog),
    )


def _fmt(value: Decimal | int | float | None) -> str:
    if value is None:
        return "—"
    if isinstance(value, int):
        return str(value)
    number = value if isinstance(value, Decimal) else Decimal(str(value))
    text = format(number, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text or "0"


def _cell(value: object) -> str:
    text = str(value).replace("|", "\\|")
    return text.replace("\n", " ")


def _table(headers: Sequence[str], rows: Sequence[Sequence[object]]) -> str:
    head = "| " + " | ".join(_cell(h) for h in headers) + " |"
    sep = "| " + " | ".join("---" for _ in headers) + " |"
    body = ["| " + " | ".join(_cell(c) for c in row) + " |" for row in rows]
    return "\n".join([head, sep, *body])


def _amount(item_nutrients: Mapping[str, Decimal], code: str) -> str:
    return _fmt(item_nutrients.get(code))


def _codes(codes: Sequence[str]) -> str:
    return ", ".join(codes) if codes else "—"


def _catalog(session: Session) -> list[str]:
    versions = list(
        session.execute(
            select(Meal.dataset_version).distinct().order_by(Meal.dataset_version)
        ).scalars()
    )
    meal_total = _count(session, Meal)
    active = int(
        session.execute(
            select(func.count()).select_from(Meal).where(Meal.is_active.is_(True))
        ).scalar_one()
    )
    inactive = meal_total - active
    foods = _count(session, Food)
    computation = session.execute(
        select(MealNutrient.computation_version)
        .distinct()
        .order_by(MealNutrient.computation_version)
    ).scalars()
    computation_versions = list(computation) or [COMPUTATION_VERSION]
    rows = [
        ("dataset_version", ", ".join(versions) if versions else "—"),
        ("computation_version", ", ".join(computation_versions)),
        ("tag_rules_version", TAG_RULES_VERSION),
        ("planner_version", PLANNER_VERSION),
        ("formula_version", FORMULA_VERSION),
        ("meals", meal_total),
        ("active meals", active),
        ("inactive meals", inactive),
        ("foods", foods),
    ]
    lines = [
        "# F.1-e scenario report",
        "",
        f"Generated from `run_f1_scenario` with `start_date` {START_DATE.isoformat()} "
        f"and `start_now` {START_NOW.isoformat()}.",
        "",
        "## 1. Data and versions",
        "",
        _table(("field", "value"), rows),
    ]
    return lines


def _limit_rows(limits: ResolvedLimits) -> list[list[object]]:
    rows: list[list[object]] = []
    groups = (
        ("max_per_day", limits.max_per_day),
        ("min_per_day", limits.min_per_day),
        ("max_per_meal", limits.max_per_meal),
        ("max_per_meal_percent_energy", limits.max_per_meal_percent_energy),
    )
    for kind, resolved in groups:
        for nutrient, limit in resolved.items():
            sources = "; ".join(
                f"{s.condition_code} {s.limit_basis} {s.source_reference}" for s in limit.sources
            )
            rows.append([kind, nutrient, _fmt(limit.value), sources])
    for tag in sorted(limits.avoid_tags):
        rows.append(["avoid_tag", tag, "AVOID", "—"])
    for tag, weekly in limits.limit_tags.items():
        rows.append(["limit_tag", tag, weekly if weekly is not None else "—", "—"])
    return rows


def _persona_section(persona: PersonaResult) -> list[str]:
    p = persona.profile
    lines = [
        f"## 2. {persona.key} profile, screening, targets, limits",
        "",
        _table(
            ("field", "value"),
            [
                ("sex", p.sex),
                ("age_years", p.age_years),
                ("height_cm", _fmt(p.height_cm)),
                ("start_weight_kg", _fmt(p.start_weight_kg)),
                ("activity_level", p.activity_level),
                ("goal_type", p.goal_type),
                ("target_weight_kg", _fmt(p.target_weight_kg)),
                ("weekly_rate_kg", _fmt(p.weekly_rate_kg)),
                ("conditions", ", ".join(p.conditions) if p.conditions else "none"),
                ("timezone", p.timezone),
                ("screening_eligible", persona.screening.eligible),
                (
                    "screening_reasons",
                    ", ".join(persona.screening.reasons) if persona.screening.reasons else "—",
                ),
            ],
        ),
        "",
    ]
    if persona.targets:
        lines += [
            _table(
                ("reason", "kcal", "protein_g", "carb_g", "fat_g", "fiber_g", "was_floor_applied"),
                [
                    (
                        t.reason,
                        _fmt(t.kcal),
                        _fmt(t.protein_g),
                        _fmt(t.carb_g),
                        _fmt(t.fat_g),
                        _fmt(t.fiber_g),
                        t.was_floor_applied,
                    )
                    for t in persona.targets
                ],
            ),
            "",
        ]
    else:
        lines += ["No `user_targets` rows.", ""]
    shown: ResolvedLimits | None = None
    for day in persona.days:
        if day.limits is not None:
            shown = day.limits
            break
    if shown is None:
        lines += ["Resolved limits: none (no target).", ""]
    elif shown.is_empty:
        lines += ["Resolved limits: none (#69).", ""]
    else:
        lines += [
            _table(("kind", "nutrient_or_tag", "value", "sources"), _limit_rows(shown)),
            "",
        ]
    return lines


def _plan_section(persona: PersonaResult) -> list[str]:
    lines = [f"## 3. {persona.key} plans", ""]
    for day in persona.days:
        lines.append(f"### {persona.key} day {day.offset} ({day.plan_date.isoformat()})")
        lines.append("")
        if not day.items:
            lines += ["No plan.", ""]
            continue
        plan_rows = [
            [
                item.slot,
                item.ref_external or "—",
                item.name_ar,
                _fmt(item.multiplier),
                _amount(item.nutrients, "energy_kcal"),
                _amount(item.nutrients, "protein"),
                _amount(item.nutrients, "carbohydrate"),
                _amount(item.nutrients, "sodium"),
                _amount(item.nutrients, "sugars"),
                _amount(item.nutrients, "fiber"),
                _amount(item.nutrients, "saturated_fat"),
                _codes(item.reason_codes),
            ]
            for item in day.items
        ]
        lines += [
            _table(
                (
                    "slot",
                    "meal",
                    "name_ar",
                    "multiplier",
                    "kcal",
                    "protein",
                    "carbohydrate",
                    "sodium",
                    "sugars",
                    "fiber",
                    "saturated_fat",
                    "reason_codes",
                ),
                plan_rows,
            ),
            "",
        ]
        target = day.target
        cmp_rows: list[list[object]] = []
        if target is not None:
            cmp_rows.append(
                [
                    "energy_kcal",
                    _fmt(day.plan_totals.get("energy_kcal")),
                    _fmt(target.kcal),
                    "target",
                ]
            )
            cmp_rows.append(
                ["protein", _fmt(day.plan_totals.get("protein")), _fmt(target.protein_g), "target"]
            )
            cmp_rows.append(
                [
                    "carbohydrate",
                    _fmt(day.plan_totals.get("carbohydrate")),
                    _fmt(target.carb_g),
                    "target",
                ]
            )
            cmp_rows.append(
                ["fat", _fmt(day.plan_totals.get("total_fat")), _fmt(target.fat_g), "target"]
            )
            cmp_rows.append(
                ["fiber", _fmt(day.plan_totals.get("fiber")), _fmt(target.fiber_g), "soft target"]
            )
        if day.limits is not None:
            for nutrient, limit in day.limits.max_per_day.items():
                cmp_rows.append(
                    [
                        f"max {nutrient}",
                        _fmt(day.plan_totals.get(nutrient)),
                        _fmt(limit.value),
                        "max_per_day",
                    ]
                )
            for nutrient, limit in day.limits.min_per_day.items():
                cmp_rows.append(
                    [
                        f"min {nutrient}",
                        _fmt(day.plan_totals.get(nutrient)),
                        _fmt(limit.value),
                        "min_per_day",
                    ]
                )
        lines += [
            _table(("quantity", "plan_total", "target_or_limit", "basis"), cmp_rows),
            "",
            f"kcal_within_10pct: {day.kcal_within_10pct}",
            "",
        ]
        if day.unmet_minimums:
            unmet = ", ".join(
                f"{u.nutrient} min {_fmt(u.minimum)} total {_fmt(u.total)}"
                for u in day.unmet_minimums
            )
            lines += [f"unmet_minimums: {unmet}", ""]
        else:
            lines += ["unmet_minimums: none", ""]
    return lines


def _log_section(persona: PersonaResult) -> list[str]:
    lines = [f"## 4. {persona.key} logs and adherence", ""]
    for day in persona.days:
        lines.append(f"### {persona.key} day {day.offset} ({day.plan_date.isoformat()})")
        lines.append("")
        if day.logs:
            lines += [
                _table(
                    ("kind", "item", "amount", "status"),
                    [(log.kind, log.item, _fmt(log.amount), log.status) for log in day.logs],
                ),
                "",
            ]
        else:
            lines += ["No logs.", ""]
        exceeded = (
            ", ".join(
                f"{e.nutrient} {_fmt(e.total)} > {_fmt(e.limit)}"
                for e in day.adherence.exceeded_max_per_day
            )
            or "none"
        )
        lines += [
            _table(
                ("field", "value"),
                [
                    ("status", day.adherence.status if day.adherence.status is not None else "—"),
                    ("reason", day.adherence.reason or "—"),
                    (
                        "completion",
                        "—"
                        if day.adherence.completion is None
                        else f"{day.adherence.completion:.3f}",
                    ),
                    ("exceeded_limits", exceeded),
                    ("log_count", day.adherence.log_count),
                ],
            ),
            "",
        ]
    lines += [f"Streak at last day: {persona.streak}", ""]
    return lines


def _layer1_section(session: Session, result: ScenarioResult) -> list[str]:
    lines = ["## 5. Layer 1 survivors and variety", ""]
    rows: list[list[object]] = []
    for key in ("P1", "P2"):
        persona = result.personas[key]
        day = persona.days[0]
        assert day.limits is not None
        for slot in MealSlot:
            evaluations = evaluate_meals(session, persona.user_id, slot, day.limits, Decimal("1.0"))
            survivors = sum(1 for e in evaluations if e.eligible)
            removed = Counter(code for e in evaluations for code in e.exclusion_codes)
            removing = (
                ", ".join(f"{code} {count}" for code, count in sorted(removed.items())) or "—"
            )
            rows.append([key, slot, survivors, len(evaluations), removing])
    lines += [
        _table(("persona", "slot", "survivors", "evaluated", "removing_codes"), rows),
        "",
    ]
    p1_items = [item for day in result.personas["P1"].days for item in day.items]
    distinct = {item.meal_id for item in p1_items}
    lines += [
        f"P1 variety across three days: {len(distinct)} distinct meals / {len(p1_items)} items.",
        "",
    ]
    return lines


def _timing_section(timings: Sequence[float]) -> list[str]:
    if not timings:
        body = _table(("statistic", "ms"), [("n", 0)])
    else:
        ordered = sorted(timings)
        body = _table(
            ("statistic", "ms"),
            [
                ("n", len(ordered)),
                ("min", f"{min(ordered):.3f}"),
                ("median", f"{median(ordered):.3f}"),
                ("max", f"{max(ordered):.3f}"),
            ],
        )
    return [TIMING_HEADING, "", body, ""]


def _observations(session: Session, result: ScenarioResult) -> list[str]:
    lines = ["## 7. Observations", ""]
    p1 = result.personas["P1"]
    p2 = result.personas["P2"]
    p3 = result.personas["P3"]
    for day in p1.days:
        sodium = day.plan_totals.get("sodium")
        lines.append(
            f"- P1 day {day.offset} sodium total: {_fmt(sodium)} mg; no limit applies (#69)."
        )
    p1_refs = [[item.ref_external for item in day.items] for day in p1.days]
    union = set().union(*p1_refs)
    shared = set(p1_refs[0]).intersection(*p1_refs[1:]) if p1_refs else set()
    lines.append(f"- The three P1 day plans share {len(shared)} of {len(union)} meals.")
    all_p1 = [ref for refs in p1_refs for ref in refs]
    lines.append(f"- P1 used {len(set(all_p1))} distinct meals across {len(all_p1)} planned items.")
    if p1.days[2].target is not None:
        lines.append(
            f"- P1 day-2 plan uses reason {p1.days[2].target.reason}; "
            f"INITIAL target closed={p1.targets[0].valid_to is not None}."
        )
    lines.append(
        f"- P2 day-2 weight {_fmt(p2.weight_events[-1].weight_kg)} kg "
        f"target_status={p2.weight_events[-1].target_status}."
    )
    for day in p2.days:
        if day.limits is None:
            continue
        parts = []
        for nutrient, limit in day.limits.max_per_day.items():
            parts.append(f"{nutrient} {_fmt(day.plan_totals.get(nutrient))}/{_fmt(limit.value)}")
        lines.append(f"- P2 day {day.offset} plan vs max_per_day: {'; '.join(parts)}.")
        lines.append(
            f"- P2 day {day.offset} kcal_within_10pct={day.kcal_within_10pct}; "
            f"unmet_minimums={len(day.unmet_minimums)}."
        )
    for day in p1.days:
        completion = "—" if day.adherence.completion is None else f"{day.adherence.completion:.3f}"
        lines.append(
            f"- P1 day {day.offset} kcal_within_10pct={day.kcal_within_10pct}; "
            f"adherence={day.adherence.status}; completion={completion}."
        )
    for key in ("P1", "P2"):
        day1 = result.personas[key].days[1]
        old, new = day1.lunch_swap or (None, None)
        lines.append(f"- {key} day 1 lunch swapped {old} → {new}.")
    lines.append(
        f"- P3 screening eligible={p3.screening.eligible} reasons="
        f"{', '.join(p3.screening.reasons)}; user_targets={len(p3.targets)}; "
        f"adherence status={p3.days[0].adherence.status} reason={p3.days[0].adherence.reason}."
    )
    n_mandatory = int(
        session.execute(
            select(func.count()).select_from(Nutrient).where(Nutrient.is_mandatory)
        ).scalar_one()
    )
    lines.append(f"- Mandatory nutrients in the loaded catalog: {n_mandatory}.")
    lines.append("")
    return lines


def render_report(session: Session, result: ScenarioResult) -> str:
    parts: list[str] = []
    parts += _catalog(session)
    parts.append("")
    for key in ("P1", "P2", "P3"):
        parts += _persona_section(result.personas[key])
    for key in ("P1", "P2", "P3"):
        parts += _plan_section(result.personas[key])
    for key in ("P1", "P2", "P3"):
        parts += _log_section(result.personas[key])
    parts += _layer1_section(session, result)
    parts += _timing_section(result.build_timings_ms)
    parts += _observations(session, result)
    text = "\n".join(parts)
    if not text.endswith("\n"):
        text += "\n"
    return text


def main() -> int:
    engine = create_engine(get_settings().DATABASE_URL)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    before = (0, 0, 0)
    after = (0, 0, 0)
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            with Session(bind=conn) as session:
                before = _counts(session)
                result = run_f1_scenario(session, conn, START_DATE, START_NOW)
                OUTPUT_PATH.write_text(render_report(session, result), encoding="utf-8")
        finally:
            trans.rollback()
        with Session(bind=conn) as session:
            after = _counts(session)
    print(OUTPUT_PATH)
    print(f"users {before[0]} -> {after[0]}")
    print(f"meal_plans {before[1]} -> {after[1]}")
    print(f"consumption_logs {before[2]} -> {after[2]}")
    if before != after:
        print("row counts changed; rollback failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
