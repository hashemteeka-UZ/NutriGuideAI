"""Compare cpsat_v1 and cpsat_v2_learned on one user's week (Step L.2, #296).

    uv run python -m scripts.ml_compare_week
    uv run python -m scripts.ml_compare_week --user-id 12 --start 2026-10-26

Seven days are built in memory twice from DATABASE_URL inside a read-only transaction that is
rolled back: cpsat_v1 (no learned terms) and cpsat_v2_learned (learned bonus from the user's
real events, and the weekly variety penalty over the days built before it). Each day excludes
the previous day's meals, as create_day_plan does; day 1 excludes the stored plan of the day
before the start. Nothing is written to any database.

A second run, labelled "simulation", adds made-up events for the user in memory only (a taste
for one cuisine): they are replayed into a copy of the model and never written.
Output: scripts/out/ml_compare/summary.md.
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from pathlib import Path
from statistics import mean, median
from typing import Final

import numpy as np
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.models import Meal, Nutrient, User, UserTarget
from app.ml.config import MAX_LEARNED_BONUS
from app.ml.features import MealFeatureMatrix
from app.ml.linucb import HybridLinUCB
from app.ml.planning import reason_meal_ids, relative_bonus
from app.ml.replay import ModelState, replay, replay_events
from app.ml.rewards import InteractionEvent
from app.services.condition_limits import (
    ENERGY_NUTRIENT,
    ResolvedLimits,
    apply_general_limits,
    resolve_condition_limits,
)
from app.services.meal_filter import (
    MealFacts,
    UserPreferences,
    load_meal_facts,
    load_user_preferences,
)
from app.services.optimizer import (
    LEARNED_PLANNER_VERSION,
    PLANNER_VERSION,
    VARIETY_DAYS,
    OptimizedDay,
    layer1_candidate_ids,
    optimize_day,
    variety_penalty_for_age,
)
from app.services.planner import PlanError, PlanTarget, _previous_meal_ids

BACKEND_ROOT: Final = Path(__file__).resolve().parent.parent
OUT_DIR: Final = BACKEND_ROOT / "scripts" / "out" / "ml_compare"
DEFAULT_EMAIL: Final = "k4api1025015003@example.com"
DAYS: Final = 7
SIMULATION_SEED: Final = 7
SIMULATION_EVENTS: Final = 12


@dataclass(frozen=True)
class DayResult:
    day: date
    meal_ids: tuple[int, ...]
    kcal: Decimal
    status: str
    seconds: float


@dataclass(frozen=True)
class WeekResult:
    label: str
    version: str
    days: tuple[DayResult, ...]
    target_kcal: Decimal

    @property
    def distinct(self) -> int:
        return len({meal for day in self.days for meal in day.meal_ids})

    @property
    def max_repeats(self) -> int:
        counts = Counter(meal for day in self.days for meal in day.meal_ids)
        return max(counts.values(), default=0)

    @property
    def deviations(self) -> list[float]:
        return [abs(float(day.kcal - self.target_kcal)) for day in self.days]


@dataclass(frozen=True)
class Context:
    meals: Sequence[MealFacts]
    preferences: UserPreferences
    limits: ResolvedLimits
    target: PlanTarget
    nutrient_codes: tuple[str, ...]
    first_excluded: frozenset[int]


def _day(result: OptimizedDay, day: date) -> DayResult:
    kcal = result.plan.totals.get(ENERGY_NUTRIENT) or Decimal(0)
    return DayResult(
        day=day,
        meal_ids=tuple(item.meal_id for item in result.plan.items),
        kcal=kcal,
        status=result.solver_status + (" (kcal relaxed)" if result.kcal_relaxed else ""),
        seconds=result.solve_seconds,
    )


def build_week(
    context: Context,
    start: date,
    label: str,
    learned: tuple[Mapping[int, int], frozenset[int]] | None,
) -> WeekResult:
    """Seven in-memory days; learned=None is cpsat_v1, else (bonus, reason meal ids)."""
    days: list[DayResult] = []
    for offset in range(DAYS):
        day = start + timedelta(days=offset)
        excluded = frozenset(days[-1].meal_ids) if days else context.first_excluded
        penalty: dict[int, int] = {}
        if learned is not None:
            for age in range(2, VARIETY_DAYS + 1):
                if offset - age >= 0:
                    for meal_id in days[offset - age].meal_ids:
                        penalty[meal_id] = penalty.get(meal_id, 0) + variety_penalty_for_age(age)
        try:
            result = optimize_day(
                context.meals,
                context.preferences,
                context.limits,
                context.target,
                day,
                context.nutrient_codes,
                excluded,
                learned_bonus=None if learned is None else learned[0],
                variety_penalty=penalty,
                learned_reason_meal_ids=frozenset() if learned is None else learned[1],
                planner_version=PLANNER_VERSION if learned is None else LEARNED_PLANNER_VERSION,
            )
        except PlanError as exc:
            days.append(DayResult(day, (), Decimal(0), type(exc).__name__, 0.0))
            continue
        days.append(_day(result, day))
    version = PLANNER_VERSION if learned is None else LEARNED_PLANNER_VERSION
    return WeekResult(label, version, tuple(days), context.target.kcal)


def simulated_state(state: ModelState, user_id: int, rng: np.random.Generator) -> ModelState:
    """A copy of the model with made-up events for user_id, in memory only (never written)."""
    features: MealFeatureMatrix = state.features
    cuisine_columns = [
        i
        for i, name in enumerate(features.names)
        if name.startswith("cuisine:") and features.matrix[:, i].any()
    ]
    column = int(rng.choice(cuisine_columns))
    liked = [
        int(m) for m, row in zip(features.meal_ids, features.matrix, strict=True) if row[column]
    ]
    other = [
        int(m) for m, row in zip(features.meal_ids, features.matrix, strict=True) if not row[column]
    ]
    picks_liked = rng.choice(liked, size=min(SIMULATION_EVENTS, len(liked)), replace=False)
    picks_other = rng.choice(other, size=min(SIMULATION_EVENTS // 2, len(other)), replace=False)
    at = datetime(2026, 1, 1, tzinfo=UTC)
    events = [
        InteractionEvent(-(i + 1), user_id, int(meal), "COOK", at + timedelta(minutes=i))
        for i, meal in enumerate(picks_liked)
    ] + [
        InteractionEvent(-(100 + i), user_id, int(meal), "SKIP", at + timedelta(hours=1, minutes=i))
        for i, meal in enumerate(picks_other)
    ]
    model = HybridLinUCB(state.model.d, alpha=state.model.alpha, ridge=state.model.ridge)
    model.a0 = state.model.a0.copy()
    model.b0 = state.model.b0.copy()
    for user, part in state.model.users.items():
        model.users[user] = type(part)(part.a.copy(), part.b_cross.copy(), part.b.copy())
    counts: Counter[int] = Counter(state.user_events)
    replay_events(model, features, events, None, None, counts)
    return ModelState(model, features, None, state.taught, state.pseudo, dict(counts))


def learned_terms(
    state: ModelState, user_id: int, candidates: frozenset[int]
) -> tuple[dict[int, int], frozenset[int]]:
    ranked = state.scorer().rank(user_id, sorted(candidates))
    return relative_bonus(ranked), reason_meal_ids(state, user_id, ranked)


def bonus_lines(bonuses: Mapping[str, Sequence[int]]) -> list[str]:
    lines = [
        "Learned bonus over the user's Layer 1 candidates (objective units, 0-60):",
        "",
        "| run | candidates | min | median | max | at 60 | above 0 |",
        "|---|---|---|---|---|---|---|",
    ]
    for label, values in bonuses.items():
        if not values:
            continue
        lines.append(
            f"| {label} | {len(values)} | {min(values)} | {median(values):g} | {max(values)} | "
            f"{sum(1 for v in values if v == MAX_LEARNED_BONUS)} | "
            f"{sum(1 for v in values if v > 0)} |"
        )
    return [*lines, ""]


def summary(
    weeks: Sequence[WeekResult],
    user_events: int,
    sim_events: int,
    names: Mapping[int, str],
    bonuses: Mapping[str, Sequence[int]] | None = None,
) -> str:
    lines = [
        "# L.2 week comparison",
        "",
        f"User real events: {user_events}. Simulation adds {sim_events} in-memory events "
        "(never written).",
        "",
        "| run | version | distinct meals | max repeats | mean abs kcal dev | max abs kcal dev "
        "| mean solve s |",
        "|---|---|---|---|---|---|---|",
    ]
    for week in weeks:
        deviations = week.deviations
        lines.append(
            f"| {week.label} | {week.version} | {week.distinct} | {week.max_repeats} | "
            f"{mean(deviations):.1f} | {max(deviations):.1f} | "
            f"{mean(day.seconds for day in week.days):.3f} |"
        )
    lines += ["", "Solver status per day:", ""]
    lines.append("| run | " + " | ".join(f"day {i + 1}" for i in range(DAYS)) + " |")
    lines.append("|---|" + "---|" * DAYS)
    for week in weeks:
        lines.append(f"| {week.label} | " + " | ".join(day.status for day in week.days) + " |")
    lines.append("")
    if bonuses:
        lines += bonus_lines(bonuses)
    lines += ["Meals per day:", ""]
    for week in weeks:
        lines.append(f"- {week.label}:")
        for day in week.days:
            meals = ", ".join(names.get(meal_id, str(meal_id)) for meal_id in day.meal_ids)
            lines.append(f"  - {day.day.isoformat()}: {meals}")
    lines.append("")
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--user-id", type=int, default=None)
    parser.add_argument("--start", type=date.fromisoformat, default=None)
    args = parser.parse_args(argv)

    engine = create_engine(get_settings().DATABASE_URL)
    try:
        with Session(engine) as session:
            session.execute(text("SET TRANSACTION READ ONLY"))
            user_id = (
                args.user_id
                or session.execute(
                    select(User.user_id).where(User.email == DEFAULT_EMAIL)
                ).scalar_one()
            )
            start = args.start or datetime.now(UTC).date() + timedelta(days=1)
            current = session.execute(
                select(UserTarget).where(
                    UserTarget.user_id == user_id, UserTarget.valid_to.is_(None)
                )
            ).scalar_one()
            target = PlanTarget.from_user_target(current)
            limits = apply_general_limits(resolve_condition_limits(session, user_id, target.kcal))
            meals = load_meal_facts(session)
            preferences = load_user_preferences(session, user_id)
            context = Context(
                meals=meals,
                preferences=preferences,
                limits=limits,
                target=target,
                nutrient_codes=tuple(
                    session.scalars(select(Nutrient.code).order_by(Nutrient.nutrient_id))
                ),
                first_excluded=_previous_meal_ids(session, user_id, start),
            )
            names = dict(session.execute(select(Meal.meal_id, Meal.name)).tuples().all())
            candidates = layer1_candidate_ids(meals, preferences, limits)
            state = replay(session)
            simulated = simulated_state(state, user_id, np.random.default_rng(SIMULATION_SEED))
            real_terms = learned_terms(state, user_id, candidates)
            sim_terms = learned_terms(simulated, user_id, candidates)
            weeks = [
                build_week(context, start, "real user", None),
                build_week(context, start, "real user", real_terms),
                build_week(context, start, "simulation", None),
                build_week(context, start, "simulation", sim_terms),
            ]
            bonuses = {
                "real user": [real_terms[0].get(meal, 0) for meal in sorted(candidates)],
                "simulation": [sim_terms[0].get(meal, 0) for meal in sorted(candidates)],
            }
            user_events = state.user_events.get(user_id, 0)
            sim_events = simulated.user_events.get(user_id, 0) - user_events
            session.rollback()
    finally:
        engine.dispose()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    text_out = summary(weeks, user_events, sim_events, names, bonuses)
    (OUT_DIR / "summary.md").write_text(text_out, encoding="utf-8")
    sys.stdout.write(text_out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
