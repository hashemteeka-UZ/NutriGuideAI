"""Simulation evaluation of the learning layer (Step L.1, #289).

    uv run python -m scripts.ml_simulate
    uv run python -m scripts.ml_simulate --no-write-config

Simulated users with hidden preferences choose from the real catalog's mf_v1 features (read
from DATABASE_URL in a read-only transaction that is rolled back, or from --features-npz).
Nothing is written to any database and no model is trained for real users: the only outputs
are files under scripts/out/ml_sim/ and, unless --no-write-config, DEFAULT_ALPHA in
app/ml/config.py.

Each round, every user gets 20 random candidates (standing in for the Layer 1 safe set), the
policy picks one, and the user accepts it with probability sigmoid(x . theta*). Regret is the
expected one: the best candidate's acceptance probability minus the chosen one's. All policies
of one seed see the same candidates and the same random draws.

Two scenarios run: independent (every user's taste drawn alone) and shared_taste (most of
each user's taste comes from one population taste), so the shared part of the hybrid model is
also measured where there is something shared to learn.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
import time
from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Final, Protocol

import numpy as np
from numpy.typing import NDArray
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.ml.features import BIAS, FloatMatrix, FloatVector, MealFeatureMatrix, build_meal_features
from app.ml.linucb import DisjointLinUCB, HybridLinUCB

BACKEND_ROOT: Final = Path(__file__).resolve().parent.parent
OUT_DIR: Final = BACKEND_ROOT / "scripts" / "out" / "ml_sim"
CONFIG_PATH: Final = BACKEND_ROOT / "app" / "ml" / "config.py"

ALPHAS: Final = (0.1, 0.25, 0.5, 1.0)
SEEDS: Final = (1, 2, 3, 4, 5)
USERS: Final = 50
ROUNDS: Final = 200
CANDIDATES: Final = 20
CHECKPOINTS: Final = (50, 100, 200)
LAST_WINDOW: Final = 50
COLD_START_ROUNDS: Final = 20
INDEPENDENT: Final = "independent"
SHARED_TASTE: Final = "shared_taste"
SCENARIOS: Final = (INDEPENDENT, SHARED_TASTE)
POPULATION_SHARE: Final = 0.7
CONTENT_LIKES: Final = 3
# Hidden preference: a direction toward 3 random meals' profiles, plus one favourite cuisine.
PREFERENCE_MEALS: Final = 3
PREFERENCE_SCALE: Final = 4.0
CUISINE_BIAS: Final = 1.0
BASE_LOGIT: Final = -0.5

HYBRID: Final = "linucb_hybrid"
DISJOINT: Final = "linucb_disjoint"
RANDOM: Final = "random"
POPULARITY: Final = "popularity"
CONTENT: Final = "content_only"

IntArray = NDArray[np.int64]


class Policy(Protocol):
    def choose(self, user: int, candidates: IntArray) -> int: ...

    def observe(self, user: int, meal: int, reward: float) -> None: ...


@dataclass
class RandomPolicy:
    rng: np.random.Generator

    def choose(self, user: int, candidates: IntArray) -> int:
        return int(self.rng.integers(len(candidates)))

    def observe(self, user: int, meal: int, reward: float) -> None:
        return None


@dataclass
class PopularityPolicy:
    """Most accepted meal so far over all users; ties at random."""

    rng: np.random.Generator
    meals: int
    accepts: FloatVector = field(init=False)

    def __post_init__(self) -> None:
        self.accepts = np.zeros(self.meals)

    def choose(self, user: int, candidates: IntArray) -> int:
        counts = self.accepts[candidates]
        best = np.flatnonzero(counts == counts.max())
        return int(self.rng.choice(best))

    def observe(self, user: int, meal: int, reward: float) -> None:
        self.accepts[meal] += reward


@dataclass
class ContentPolicy:
    """Mean cosine to the user's first 3 accepted meals; random until the first one."""

    rng: np.random.Generator
    x: FloatMatrix
    liked: dict[int, list[int]] = field(default_factory=dict)

    def choose(self, user: int, candidates: IntArray) -> int:
        liked = self.liked.get(user)
        if not liked:
            return int(self.rng.integers(len(candidates)))
        rows = self.x[candidates]
        profile = self.x[liked]
        norms = np.linalg.norm(rows, axis=1)[:, None] * np.linalg.norm(profile, axis=1)[None, :]
        cosine = (rows @ profile.T) / np.where(norms > 0, norms, 1.0)
        return int(np.argmax(cosine.mean(axis=1)))

    def observe(self, user: int, meal: int, reward: float) -> None:
        liked = self.liked.setdefault(user, [])
        if reward > 0 and len(liked) < CONTENT_LIKES:
            liked.append(meal)


@dataclass
class LinUCBPolicy:
    model: HybridLinUCB | DisjointLinUCB
    x: FloatMatrix

    def choose(self, user: int, candidates: IntArray) -> int:
        _, ucb = self.model.score(user, self.x[candidates])
        return int(np.argmax(ucb))

    def observe(self, user: int, meal: int, reward: float) -> None:
        self.model.update(user, self.x[meal], reward)


@dataclass(frozen=True)
class PolicySpec:
    name: str
    alpha: float | None
    make: Callable[[np.random.Generator, FloatMatrix], Policy]

    @property
    def label(self) -> str:
        return self.name if self.alpha is None else f"{self.name} (alpha {self.alpha:g})"


def _disjoint(alpha: float) -> Callable[[np.random.Generator, FloatMatrix], Policy]:
    def make(rng: np.random.Generator, x: FloatMatrix) -> Policy:
        return LinUCBPolicy(DisjointLinUCB(x.shape[1], alpha=alpha), x)

    return make


def _hybrid(alpha: float) -> Callable[[np.random.Generator, FloatMatrix], Policy]:
    def make(rng: np.random.Generator, x: FloatMatrix) -> Policy:
        return LinUCBPolicy(HybridLinUCB(x.shape[1], alpha=alpha), x)

    return make


def policy_specs(alphas: Sequence[float]) -> list[PolicySpec]:
    specs = [
        PolicySpec(RANDOM, None, lambda rng, x: RandomPolicy(rng)),
        PolicySpec(POPULARITY, None, lambda rng, x: PopularityPolicy(rng, len(x))),
        PolicySpec(CONTENT, None, lambda rng, x: ContentPolicy(rng, x)),
    ]
    specs += [PolicySpec(DISJOINT, alpha, _disjoint(alpha)) for alpha in alphas]
    specs += [PolicySpec(HYBRID, alpha, _hybrid(alpha)) for alpha in alphas]
    return specs


def _preference_body(
    x: FloatMatrix, cuisine_columns: Sequence[int], rng: np.random.Generator
) -> FloatVector:
    """One hidden taste without the bias: toward 3 random meals' profiles, plus a cuisine."""
    body = x[:, :-1]
    centered = body - body.mean(axis=0)
    picks = rng.choice(len(x), size=PREFERENCE_MEALS, replace=False)
    direction = centered[picks].mean(axis=0)
    norm = float(np.linalg.norm(direction))
    if norm > 0:
        direction /= norm
    taste = PREFERENCE_SCALE * direction
    if cuisine_columns:
        taste[int(rng.choice(cuisine_columns))] += CUISINE_BIAS
    return taste


def hidden_preferences(
    x: FloatMatrix,
    names: Sequence[str],
    users: int,
    rng: np.random.Generator,
    scenario: str = INDEPENDENT,
) -> FloatMatrix:
    """theta* per user, drawn from the feature space with a favourite-cuisine bias.

    independent: every user's taste is drawn alone.
    shared_taste: one population taste per seed (drawn the same way, first), and each user's
    taste is POPULATION_SHARE of it plus the rest of the user's own, rescaled to the norm of
    the user's own taste.
    """
    if scenario not in SCENARIOS:
        raise ValueError(f"unknown scenario {scenario!r}")
    body = x[:, :-1]
    cuisine_columns = [i for i, name in enumerate(names) if name.startswith("cuisine:")]
    population = _preference_body(x, cuisine_columns, rng) if scenario == SHARED_TASTE else None
    theta = np.zeros((users, x.shape[1]))
    for user in range(users):
        taste = _preference_body(x, cuisine_columns, rng)
        if population is not None:
            mixed = POPULATION_SHARE * population + (1.0 - POPULATION_SHARE) * taste
            mixed_norm = float(np.linalg.norm(mixed))
            if mixed_norm > 0:
                taste = mixed * (float(np.linalg.norm(taste)) / mixed_norm)
        theta[user, :-1] = taste
        theta[user, -1] = BASE_LOGIT - float((body @ taste).mean())
    return theta


@dataclass(frozen=True)
class World:
    """Everything random about one seed, shared by every policy."""

    probabilities: FloatMatrix  # users x meals
    candidates: NDArray[np.int64]  # rounds x users x candidates
    draws: FloatMatrix  # rounds x users


def make_world(
    x: FloatMatrix,
    names: Sequence[str],
    users: int,
    rounds: int,
    size: int,
    seed: int,
    scenario: str = INDEPENDENT,
) -> World:
    rng = np.random.default_rng(seed)
    theta = hidden_preferences(x, names, users, rng, scenario)
    probabilities = 1.0 / (1.0 + np.exp(-(theta @ x.T)))
    keys = rng.random((rounds, users, len(x)))
    candidates = np.argsort(keys, axis=2)[:, :, :size].astype(np.int64)
    draws = rng.random((rounds, users))
    return World(probabilities, candidates, draws)


@dataclass(frozen=True)
class RunResult:
    cum_regret: FloatVector  # mean over users, per round
    last_acceptance: float


def run_policy(world: World, policy: Policy) -> RunResult:
    rounds, users, _ = world.candidates.shape
    regret = np.zeros((rounds, users))
    rewards = np.zeros((rounds, users))
    for t in range(rounds):
        for user in range(users):
            candidates = world.candidates[t, user]
            p = world.probabilities[user, candidates]
            pick = policy.choose(user, candidates)
            meal = int(candidates[pick])
            reward = 1.0 if world.draws[t, user] < p[pick] else 0.0
            policy.observe(user, meal, reward)
            regret[t, user] = float(p.max() - p[pick])
            rewards[t, user] = reward
    window = min(LAST_WINDOW, rounds)
    return RunResult(
        cum_regret=np.cumsum(regret, axis=0).mean(axis=1),
        last_acceptance=float(rewards[-window:].mean()),
    )


@dataclass
class SimulationResult:
    runs: dict[tuple[str, float | None, int], RunResult]
    specs: list[PolicySpec]
    seeds: tuple[int, ...]
    rounds: int
    users: int
    size: int
    scenario: str = INDEPENDENT

    def regret_at(self, spec: PolicySpec, t: int) -> FloatVector:
        return np.array(
            [self.runs[(spec.name, spec.alpha, seed)].cum_regret[t - 1] for seed in self.seeds]
        )

    def cold_start_regret(self, spec: PolicySpec) -> FloatVector:
        """Mean regret per round over the first COLD_START_ROUNDS rounds, per seed."""
        t = min(COLD_START_ROUNDS, self.rounds)
        return self.regret_at(spec, t) / t

    def best_alpha(self, name: str = HYBRID) -> float:
        scored = [
            (float(self.regret_at(spec, self.rounds).mean()), spec.alpha)
            for spec in self.specs
            if spec.name == name and spec.alpha is not None
        ]
        return min(scored)[1]


def simulate(
    x: FloatMatrix,
    names: Sequence[str],
    users: int = USERS,
    rounds: int = ROUNDS,
    size: int = CANDIDATES,
    seeds: Sequence[int] = SEEDS,
    alphas: Sequence[float] = ALPHAS,
    specs: Sequence[PolicySpec] | None = None,
    scenario: str = INDEPENDENT,
) -> SimulationResult:
    chosen = list(specs) if specs is not None else policy_specs(alphas)
    size = min(size, len(x))
    runs: dict[tuple[str, float | None, int], RunResult] = {}
    for seed in seeds:
        world = make_world(x, names, users, rounds, size, seed, scenario)
        for index, spec in enumerate(chosen):
            rng = np.random.default_rng([seed, index])
            runs[(spec.name, spec.alpha, seed)] = run_policy(world, spec.make(rng, x))
    return SimulationResult(runs, chosen, tuple(seeds), rounds, users, size, scenario)


def _mean_std(values: FloatVector) -> str:
    return f"{values.mean():.2f} ({values.std():.2f})"


def result_table(result: SimulationResult, chosen_alpha: float) -> list[str]:
    """One markdown table of one scenario; the configured hybrid alpha is marked."""
    checkpoints = [t for t in CHECKPOINTS if t <= result.rounds]
    cold = min(COLD_START_ROUNDS, result.rounds)
    lines = [
        "| scenario | policy | "
        + " | ".join(f"regret T={t}" for t in checkpoints)
        + f" | regret/round t≤{cold} | acceptance |",
        "|---|---|" + "---|" * (len(checkpoints) + 2),
    ]
    for spec in result.specs:
        cells = [_mean_std(result.regret_at(spec, t)) for t in checkpoints]
        cells.append(f"{result.cold_start_regret(spec).mean():.3f}")
        acceptance = np.mean(
            [result.runs[(spec.name, spec.alpha, seed)].last_acceptance for seed in result.seeds]
        )
        marker = " **chosen**" if spec.name == HYBRID and spec.alpha == chosen_alpha else ""
        lines.append(
            f"| {result.scenario} | {spec.label}{marker} | "
            + " | ".join(cells)
            + f" | {acceptance:.3f} |"
        )
    return lines


def summary_markdown(
    results: Sequence[SimulationResult],
    features: MealFeatureMatrix,
    seconds: float,
    chosen_alpha: float,
) -> str:
    first = results[0]
    lines = [
        "# L.1 simulation summary",
        "",
        f"Features {features.version}: {len(features.meal_ids)} meals, d = {features.d}. "
        f"{first.users} users per seed, T = {first.rounds}, {first.size} candidates a round, "
        f"seeds {list(first.seeds)}.",
        "",
        "Mean cumulative expected regret (std over seeds); regret/round over the first "
        f"{COLD_START_ROUNDS} rounds (cold start); acceptance = mean reward in the last "
        f"{LAST_WINDOW} rounds. independent: every user's taste is drawn alone. shared_taste: "
        f"{POPULATION_SHARE:g} of a population taste + {1 - POPULATION_SHARE:g} of the user's own.",
        "",
    ]
    for result in results:
        lines += [f"## {result.scenario}", "", *result_table(result, chosen_alpha), ""]
        lines.append(
            f"Lowest hybrid regret at T={result.rounds} in {result.scenario}: "
            f"alpha {result.best_alpha():g}."
        )
        lines.append("")
    lines += [f"Configured alpha: {chosen_alpha:g}.", f"Runtime: {seconds:.1f} s.", ""]
    return "\n".join(lines)


def choose_alpha(current: float, results: Sequence[SimulationResult]) -> float:
    """Keep the configured alpha unless every scenario's best hybrid alpha agrees on another."""
    best = {result.best_alpha() for result in results}
    if len(best) == 1 and current not in best:
        return best.pop()
    return current


def read_default_alpha(path: Path = CONFIG_PATH) -> float:
    found = re.search(r"^DEFAULT_ALPHA: Final = (.*)$", path.read_text(encoding="utf-8"), re.M)
    if found is None:
        raise RuntimeError(f"DEFAULT_ALPHA not found in {path}")
    return float(found.group(1))


def write_regret_csv(results: Sequence[SimulationResult], path: Path) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["scenario", "policy", "alpha", "seed", "t", "cum_regret"])
        for result in results:
            for (name, alpha, seed), run in result.runs.items():
                for t, value in enumerate(run.cum_regret, start=1):
                    writer.writerow(
                        [
                            result.scenario,
                            name,
                            "" if alpha is None else alpha,
                            seed,
                            t,
                            f"{value:.6f}",
                        ]
                    )


def write_default_alpha(alpha: float, path: Path = CONFIG_PATH) -> None:
    source = path.read_text(encoding="utf-8")
    updated, count = re.subn(
        r"^DEFAULT_ALPHA: Final = .*$", f"DEFAULT_ALPHA: Final = {alpha!r}", source, flags=re.M
    )
    if count != 1:
        raise RuntimeError(f"DEFAULT_ALPHA not found once in {path}")
    path.write_text(updated, encoding="utf-8")


def load_features(npz: Path | None) -> MealFeatureMatrix:
    if npz is not None and npz.exists():
        data = np.load(npz, allow_pickle=False)
        return MealFeatureMatrix(
            data["meal_ids"].astype(np.int64),
            data["matrix"].astype(np.float64),
            tuple(str(name) for name in data["names"]),
            str(data["version"]),
        )
    engine = create_engine(get_settings().DATABASE_URL)
    try:
        with Session(engine) as session:
            session.execute(text("SET TRANSACTION READ ONLY"))
            features = build_meal_features(session)
            session.rollback()
    finally:
        engine.dispose()
    return features


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--features-npz", type=Path, default=None)
    parser.add_argument("--users", type=int, default=USERS)
    parser.add_argument("--rounds", type=int, default=ROUNDS)
    parser.add_argument("--seeds", type=int, nargs="+", default=list(SEEDS))
    parser.add_argument("--no-write-config", action="store_true")
    args = parser.parse_args(argv)

    started = time.perf_counter()
    features = load_features(args.features_npz)
    if features.names[-1] != BIAS:
        raise RuntimeError("feature matrix must end with the bias column")
    results = [
        simulate(
            features.matrix,
            features.names,
            users=args.users,
            rounds=args.rounds,
            seeds=args.seeds,
            scenario=scenario,
        )
        for scenario in SCENARIOS
    ]
    chosen_alpha = choose_alpha(read_default_alpha(), results)
    seconds = time.perf_counter() - started

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    np.savez(
        OUT_DIR / "features.npz",
        meal_ids=features.meal_ids,
        matrix=features.matrix,
        names=np.array(features.names),
        version=np.array(features.version),
    )
    write_regret_csv(results, OUT_DIR / "regret.csv")
    summary = summary_markdown(results, features, seconds, chosen_alpha)
    (OUT_DIR / "summary.md").write_text(summary, encoding="utf-8")
    if not args.no_write_config:
        write_default_alpha(chosen_alpha)
    sys.stdout.write(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
