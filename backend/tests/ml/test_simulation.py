"""Simulation sanity (#289): in memory only, fixed seeds."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from scripts.ml_simulate import (
    HYBRID,
    INDEPENDENT,
    RANDOM,
    SCENARIOS,
    SHARED_TASTE,
    SimulationResult,
    choose_alpha,
    hidden_preferences,
    policy_specs,
    read_default_alpha,
    simulate,
    summary_markdown,
    write_default_alpha,
)
from tests.ml.test_replay import _synthetic


def _tiny() -> tuple[np.ndarray, tuple[str, ...]]:
    features = _synthetic(40, 8, 5)
    names = ("cuisine:A", "cuisine:B", *features.names[2:])
    return features.matrix, names


def test_hybrid_beats_random_at_t100() -> None:
    x, names = _tiny()
    specs = [s for s in policy_specs((0.25,)) if s.name in {RANDOM, HYBRID}]
    result = simulate(x, names, users=10, rounds=100, size=10, seeds=[1], specs=specs)
    random_regret = result.regret_at(specs[0], 100).mean()
    hybrid_regret = result.regret_at(specs[1], 100).mean()
    assert hybrid_regret < random_regret
    assert result.best_alpha() == 0.25


def test_simulation_is_deterministic() -> None:
    x, names = _tiny()
    specs = policy_specs((0.5,))
    first = simulate(x, names, users=4, rounds=20, size=8, seeds=[2], specs=specs)
    second = simulate(x, names, users=4, rounds=20, size=8, seeds=[2], specs=specs)
    for key, run in first.runs.items():
        assert np.array_equal(run.cum_regret, second.runs[key].cum_regret)


def test_shared_taste_is_deterministic_and_shares_taste() -> None:
    x, names = _tiny()
    specs = [s for s in policy_specs((0.25,)) if s.name in {RANDOM, HYBRID}]

    def run() -> SimulationResult:
        return simulate(
            x, names, users=6, rounds=30, size=8, seeds=[3], specs=specs, scenario=SHARED_TASTE
        )

    first, second = run(), run()
    assert first.scenario == SHARED_TASTE
    for key, result in first.runs.items():
        assert np.array_equal(result.cum_regret, second.runs[key].cum_regret)
    assert first.cold_start_regret(specs[0]).shape == (1,)

    def mean_cosine(theta: np.ndarray) -> float:
        unit = theta[:, :-1] / np.linalg.norm(theta[:, :-1], axis=1, keepdims=True)
        cosine = unit @ unit.T
        return float(cosine[np.triu_indices(len(theta), 1)].mean())

    shared = hidden_preferences(x, names, 20, np.random.default_rng(3), SHARED_TASTE)
    alone = hidden_preferences(x, names, 20, np.random.default_rng(3), INDEPENDENT)
    assert mean_cosine(shared) > mean_cosine(alone) + 0.3
    with pytest.raises(ValueError):
        hidden_preferences(x, names, 2, np.random.default_rng(3), "other")


def test_alpha_changes_only_when_every_scenario_agrees() -> None:
    x, names = _tiny()
    results = [
        simulate(x, names, users=3, rounds=30, size=8, seeds=[1], alphas=(0.1, 1.0), scenario=s)
        for s in SCENARIOS
    ]
    best = {result.best_alpha() for result in results}
    expected = best.pop() if len(best) == 1 and 0.5 not in best else 0.5
    assert choose_alpha(0.5, results) == expected
    same = results[0].best_alpha()
    assert choose_alpha(same, results) == same


def test_summary_and_config_writer(tmp_path: Path) -> None:
    x, names = _tiny()
    results = [
        simulate(x, names, users=3, rounds=60, size=8, seeds=[1, 2], alphas=(0.1, 1.0), scenario=s)
        for s in SCENARIOS
    ]
    features = _synthetic(40, 8, 5)
    text = summary_markdown(results, features, 1.0, 0.1)
    assert "| independent | linucb_hybrid (alpha 0.1) **chosen**" in text
    assert "| shared_taste | linucb_hybrid (alpha 0.1) **chosen**" in text
    assert "regret/round t≤20" in text
    config = tmp_path / "config.py"
    config.write_text("X = 1\nDEFAULT_ALPHA: Final = 0.25\n", encoding="utf-8")
    assert read_default_alpha(config) == 0.25
    write_default_alpha(1.0, config)
    assert "DEFAULT_ALPHA: Final = 1.0\n" in config.read_text(encoding="utf-8")
