"""Nested cross-validation of the slot tag classifier, and a label audit (Step L.3, #298, #299).

    uv run python -m scripts.ml_tag_eval

Reads the active catalog from DATABASE_URL in a read-only transaction that is rolled back.
Outer loop: KFold(5, shuffled) repeated 5 times (25 fits); every hyperparameter is chosen
inside the outer training fold only. Threshold 0.5. Writes scripts/out/ml_tags/summary.md
and review_candidates.md. Nothing is written to the database: the review list is for the
team to read, never an automatic change.
"""

from __future__ import annotations

import argparse
import sys
import time
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Final

import numpy as np
import sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, f1_score, hamming_loss
from sklearn.model_selection import RepeatedKFold
from sklearn.multiclass import OneVsRestClassifier
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.ml.features import FloatMatrix
from app.ml.tag_classifier import (
    RANDOM_STATE,
    TagDataset,
    build_tag_dataset,
    logistic_search,
    positive_probabilities,
)

BACKEND_ROOT: Final = Path(__file__).resolve().parent.parent
OUT_DIR: Final = BACKEND_ROOT / "scripts" / "out" / "ml_tags"
OUTER_FOLDS: Final = 5
OUTER_REPEATS: Final = 5
THRESHOLD: Final = 0.5
TOP_FEATURES: Final = 5
REVIEW_HIGH: Final = 0.8
REVIEW_LOW: Final = 0.2

PRIOR: Final = "prior (frequency >= 0.5)"
KCAL_ONLY: Final = "kcal-only logistic regression"
LOGISTIC: Final = "logistic regression (one-vs-rest)"
FOREST: Final = "random forest"
MODELS: Final = (PRIOR, KCAL_ONLY, LOGISTIC, FOREST)


class _Prior:
    """Each tag is present iff its training-fold frequency is at least 0.5."""

    def fit(self, X: FloatMatrix, Y: np.ndarray) -> _Prior:
        self.rate = Y.mean(axis=0)
        return self

    def predict_proba(self, X: FloatMatrix) -> FloatMatrix:
        return np.tile(self.rate, (len(X), 1))


class _KcalOnly:
    """Logistic regression on the kcal column alone, one per tag."""

    def __init__(self, column: int) -> None:
        self.column = column

    def fit(self, X: FloatMatrix, Y: np.ndarray) -> _KcalOnly:
        self.model = OneVsRestClassifier(
            LogisticRegression(
                solver="liblinear", class_weight="balanced", random_state=RANDOM_STATE
            )
        ).fit(X[:, [self.column]], Y)
        return self

    def predict_proba(self, X: FloatMatrix) -> FloatMatrix:
        return np.asarray(self.model.predict_proba(X[:, [self.column]]), dtype=np.float64)


def _forest() -> RandomForestClassifier:
    return RandomForestClassifier(
        n_estimators=300,
        class_weight="balanced_subsample",
        min_samples_leaf=2,
        random_state=RANDOM_STATE,
    )


def factories(dataset: TagDataset, inner_folds: int) -> dict[str, Callable[[], Any]]:
    kcal = dataset.feature_names.index("kcal_per_serving")
    return {
        PRIOR: _Prior,
        KCAL_ONLY: lambda: _KcalOnly(kcal),
        LOGISTIC: lambda: logistic_search(inner_folds),
        FOREST: _forest,
    }


@dataclass
class Scores:
    per_tag: list[np.ndarray]
    micro: list[float]
    macro: list[float]
    hamming: list[float]
    subset: list[float]


@dataclass
class Evaluation:
    scores: dict[str, Scores]
    oof: dict[str, FloatMatrix]  # mean out-of-fold probability per meal, per model
    folds: int

    def mean_macro(self, name: str) -> float:
        return float(np.mean(self.scores[name].macro))


def evaluate(
    dataset: TagDataset,
    outer_folds: int = OUTER_FOLDS,
    repeats: int = OUTER_REPEATS,
    inner_folds: int = 3,
) -> Evaluation:
    X, Y = dataset.X, dataset.Y
    makers = factories(dataset, inner_folds)
    scores = {name: Scores([], [], [], [], []) for name in makers}
    sums = {name: np.zeros(Y.shape) for name in makers}
    counts = np.zeros(len(Y))
    splitter = RepeatedKFold(n_splits=outer_folds, n_repeats=repeats, random_state=RANDOM_STATE)
    folds = 0
    for train, test in splitter.split(X):
        folds += 1
        counts[test] += 1
        for name, make in makers.items():
            model = make().fit(X[train], Y[train])
            probabilities = positive_probabilities(model, X[test])
            sums[name][test] += probabilities
            predicted = (probabilities >= THRESHOLD).astype(np.int64)
            truth = Y[test]
            s = scores[name]
            s.per_tag.append(f1_score(truth, predicted, average=None, zero_division=0))
            s.micro.append(float(f1_score(truth, predicted, average="micro", zero_division=0)))
            s.macro.append(float(f1_score(truth, predicted, average="macro", zero_division=0)))
            s.hamming.append(float(hamming_loss(truth, predicted)))
            s.subset.append(float(accuracy_score(truth, predicted)))
    oof = {name: total / counts[:, None] for name, total in sums.items()}
    return Evaluation(scores, oof, folds)


def top_features(dataset: TagDataset, inner_folds: int = 3) -> dict[str, list[tuple[str, float]]]:
    """Largest positive coefficients per tag of the logistic model fit on all meals."""
    search = logistic_search(inner_folds).fit(dataset.X, dataset.Y)
    found: dict[str, list[tuple[str, float]]] = {}
    for tag, estimator in zip(
        dataset.target_names, search.best_estimator_.estimators_, strict=True
    ):
        coef = getattr(estimator, "coef_", None)
        if coef is None:
            found[tag] = []
            continue
        weights = np.asarray(coef).ravel()
        order = np.argsort(-weights)[:TOP_FEATURES]
        found[tag] = [(dataset.feature_names[i], float(weights[i])) for i in order]
    return found


@dataclass(frozen=True)
class Candidate:
    ref: str
    name: str
    tag: str
    label: int
    probability: float


def review_candidates(dataset: TagDataset, probabilities: FloatMatrix) -> list[Candidate]:
    found: list[Candidate] = []
    for row in range(len(dataset.meal_ids)):
        for column, tag in enumerate(dataset.target_names):
            label = int(dataset.Y[row, column])
            p = float(probabilities[row, column])
            if (label == 0 and p >= REVIEW_HIGH) or (label == 1 and p < REVIEW_LOW):
                found.append(Candidate(dataset.refs[row], dataset.names[row], tag, label, p))
    # Strongest disagreement first.
    return sorted(found, key=lambda c: (-abs(c.probability - c.label), c.ref, c.tag))


def _ms(values: Sequence[float] | np.ndarray) -> str:
    return f"{np.mean(values):.3f} ± {np.std(values):.3f}"


def summary_markdown(
    dataset: TagDataset,
    evaluation: Evaluation,
    best: str,
    features: dict[str, list[tuple[str, float]]],
    candidates: int,
    seconds: float,
) -> str:
    tags = dataset.target_names
    lines = [
        "# L.3 slot tag classifier",
        "",
        f"Features {dataset.version}: {len(dataset.meal_ids)} meals, {dataset.X.shape[1]} "
        f"features ({len(dataset.ingredient_codes)} ingredient codes used by >= 2 meals). "
        f"scikit-learn {sklearn.__version__}. Nested CV: {evaluation.folds} outer folds "
        f"(KFold {OUTER_FOLDS} shuffled x {OUTER_REPEATS} repeats), inner 3-fold grid for C, "
        f"threshold {THRESHOLD}, random_state {RANDOM_STATE}. Runtime {seconds:.1f} s.",
        "",
        "Mean ± std over the outer folds.",
        "",
        "| model | "
        + " | ".join(f"F1 {t.removesuffix('_suitable')}" for t in tags)
        + " | micro-F1 | macro-F1 | Hamming loss | subset accuracy |",
        "|---|" + "---|" * (len(tags) + 4),
    ]
    for name, s in evaluation.scores.items():
        per_tag = np.array(s.per_tag)
        cells = [_ms(per_tag[:, i]) for i in range(len(tags))]
        marker = " **best**" if name == best else ""
        lines.append(
            f"| {name}{marker} | "
            + " | ".join(cells)
            + f" | {_ms(s.micro)} | {_ms(s.macro)} | {_ms(s.hamming)} | {_ms(s.subset)} |"
        )
    prior = evaluation.mean_macro(PRIOR)
    verdict = "above" if evaluation.mean_macro(best) > prior else "NOT above"
    lines += [
        "",
        f"Best model by mean macro-F1: {best} ({evaluation.mean_macro(best):.3f}), "
        f"{verdict} the prior baseline ({prior:.3f}).",
        "",
        "Top positive features of the logistic model fit on all meals:",
        "",
    ]
    for tag, items in features.items():
        text_items = ", ".join(f"{name} ({weight:+.2f})" for name, weight in items)
        lines.append(f"- {tag}: {text_items}")
    lines += [
        "",
        f"Review candidates (out-of-fold, {best}): {candidates}, in review_candidates.md.",
        "",
    ]
    return "\n".join(lines)


def candidates_markdown(candidates: Sequence[Candidate], best: str) -> str:
    lines = [
        "# L.3 label review candidates",
        "",
        f"Mean out-of-fold probability of the {best}. Listed when p >= {REVIEW_HIGH} and the "
        f"team label is absent, or p < {REVIEW_LOW} and it is present. For the team to "
        "review; nothing was changed.",
        "",
        "| ref_external | name_ar | tag | label | probability |",
        "|---|---|---|---|---|",
    ]
    for c in candidates:
        lines.append(f"| {c.ref} | {c.name} | {c.tag} | {c.label} | {c.probability:.3f} |")
    return "\n".join([*lines, ""])


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.parse_args(argv)
    started = time.perf_counter()
    engine = create_engine(get_settings().DATABASE_URL)
    try:
        with Session(engine) as session:
            session.execute(text("SET TRANSACTION READ ONLY"))
            dataset = build_tag_dataset(session)
            session.rollback()
    finally:
        engine.dispose()
    evaluation = evaluate(dataset)
    best = max((LOGISTIC, FOREST), key=evaluation.mean_macro)
    features = top_features(dataset)
    candidates = review_candidates(dataset, evaluation.oof[best])
    seconds = time.perf_counter() - started
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = summary_markdown(dataset, evaluation, best, features, len(candidates), seconds)
    (OUT_DIR / "summary.md").write_text(summary, encoding="utf-8")
    (OUT_DIR / "review_candidates.md").write_text(
        candidates_markdown(candidates, best), encoding="utf-8"
    )
    sys.stdout.write(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
