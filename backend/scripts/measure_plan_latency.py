"""Measure plan generation over HTTP against a running server.

uv run python -m scripts.measure_plan_latency --base-url http://127.0.0.1:8000 --days 3
"""

from __future__ import annotations

import argparse
import math
import os
import platform
import subprocess
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any
from uuid import uuid4
from zoneinfo import ZoneInfo

import httpx

REPO_ROOT = Path(__file__).resolve().parents[2]
REPORT_PATH = REPO_ROOT / "docs" / "reports" / "plan_latency_http.md"
PASSWORD = "latency-password-1"
TIMEZONE = "Africa/Tripoli"
# The reference activity list has no ACTIVE. HIGH is the next step after MODERATE.
ACTIVE_ACTIVITY = "HIGH"
ACTIVE_NOTE = (
    "Persona 5 asked for activity 'active'. The reference list has no ACTIVE code; "
    f"{ACTIVE_ACTIVITY} is the closest (between MODERATE and ATHLETE)."
)


@dataclass(frozen=True)
class Persona:
    name: str
    sex: str
    age_years: int
    height_cm: float
    weight_kg: float
    activity: str
    goal: str
    conditions: tuple[str, ...]
    allergen: str | None


@dataclass(frozen=True)
class RequestRow:
    persona: str
    day: str
    wall_ms: int
    http_status: int
    plan_status: str
    slot_band_pass: str
    solve_seconds: str
    day_kcal: str
    target_kcal: str


@dataclass(frozen=True)
class ProbeRow:
    persona: str
    http_status: int
    code: str
    retry_after: str


PERSONAS: tuple[Persona, ...] = (
    Persona("1", "MALE", 35, 178, 92, "MODERATE", "LOSE", ("HYPERTENSION",), None),
    Persona("2", "FEMALE", 52, 160, 78, "LIGHT", "LOSE", ("DIABETES_T2",), None),
    Persona("3", "MALE", 60, 172, 85, "SEDENTARY", "MAINTAIN", ("HEART_DISEASE",), None),
    Persona("4", "FEMALE", 28, 165, 60, "MODERATE", "MAINTAIN", (), "GLUTEN"),
    Persona("5", "MALE", 22, 180, 62, ACTIVE_ACTIVITY, "GAIN", (), None),
    Persona(
        "6",
        "FEMALE",
        45,
        158,
        70,
        "LIGHT",
        "LOSE",
        ("DIABETES_T2", "HYPERTENSION"),
        None,
    ),
)


def _birth_date(today: date, age_years: int) -> date:
    try:
        return today.replace(year=today.year - age_years)
    except ValueError:
        return date(today.year - age_years, today.month, 28)


def _percentile(values: list[int], percent: float) -> int:
    ordered = sorted(values)
    if not ordered:
        return 0
    if len(ordered) == 1:
        return ordered[0]
    rank = (len(ordered) - 1) * percent / 100
    low = math.floor(rank)
    high = math.ceil(rank)
    if low == high:
        return ordered[low]
    weight = rank - low
    return round(ordered[low] * (1 - weight) + ordered[high] * weight)


def _object(body: object) -> dict[str, Any]:
    if not isinstance(body, dict):
        raise RuntimeError("expected a JSON object")
    return body


def _text(value: object) -> str:
    if value is None:
        return ""
    return str(value)


def _git_commit() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return "unknown"
    if result.returncode != 0:
        return "unknown"
    return result.stdout.strip() or "unknown"


def _profile(persona: Persona, today: date, allergen: str | None) -> dict[str, object]:
    target: float | None
    rate: float | None
    if persona.goal == "LOSE":
        target, rate = persona.weight_kg - 8, 0.5
    elif persona.goal == "GAIN":
        target, rate = persona.weight_kg + 6, 0.25
    else:
        target, rate = None, None
    return {
        "sex": persona.sex,
        "birth_date": _birth_date(today, persona.age_years).isoformat(),
        "height_cm": persona.height_cm,
        "activity_level": persona.activity,
        "goal_type": persona.goal,
        "target_weight_kg": target,
        "weekly_rate_kg": rate,
        "timezone": TIMEZONE,
        "wake_time": "07:00",
        "sleep_time": "23:00",
        "current_weight_kg": persona.weight_kg,
        "conditions": [{"code": code, "severity": "MODERATE"} for code in persona.conditions],
        "allergens": [] if allergen is None else [{"code": allergen, "severity": "AVOID"}],
        "ingredient_prefs": [],
        "cuisines": [],
    }


def _register(client: httpx.Client, persona: Persona) -> str:
    email = f"latency-{persona.name}-{uuid4().hex[:8]}@example.com"
    response = client.post("/api/v1/auth/register", json={"email": email, "password": PASSWORD})
    response.raise_for_status()
    token = _object(response.json())["access_token"]
    if not isinstance(token, str):
        raise RuntimeError("register did not return an access token")
    return token


def _save_profile(
    client: httpx.Client, token: str, persona: Persona, today: date, allergen: str | None
) -> None:
    response = client.put(
        "/api/v1/me/profile",
        json=_profile(persona, today, allergen),
        headers={"Authorization": f"Bearer {token}"},
    )
    if response.status_code != 200:
        raise RuntimeError(
            f"persona {persona.name} profile {response.status_code}: {response.text}"
        )


def _plan_row(persona: str, day: date, response: httpx.Response, wall_ms: int) -> RequestRow:
    plan_status = ""
    solve_seconds = ""
    day_kcal = ""
    target_kcal = ""
    if response.status_code == 201:
        body = _object(response.json())
        stats = body.get("stats")
        totals = body.get("totals")
        target = body.get("target")
        if isinstance(stats, dict):
            plan_status = _text(stats.get("solver_status"))
            solve_seconds = _text(stats.get("solve_seconds"))
        if isinstance(totals, dict):
            day_kcal = _text(totals.get("kcal"))
        if isinstance(target, dict):
            target_kcal = _text(target.get("kcal"))
    return RequestRow(
        persona=persona,
        day=day.isoformat(),
        wall_ms=wall_ms,
        http_status=response.status_code,
        plan_status=plan_status,
        slot_band_pass="n/a",
        solve_seconds=solve_seconds,
        day_kcal=day_kcal,
        target_kcal=target_kcal,
    )


def _generate(client: httpx.Client, token: str, persona: str, day: date) -> RequestRow:
    started = time.perf_counter()
    response = client.post(
        "/api/v1/plans/days",
        json={"date": day.isoformat()},
        headers={"Authorization": f"Bearer {token}"},
    )
    wall_ms = round((time.perf_counter() - started) * 1000)
    return _plan_row(persona, day, response, wall_ms)


def _probe(
    client: httpx.Client, token: str, persona: str, day: date, gate: threading.Barrier
) -> ProbeRow:
    gate.wait()
    response = client.post(
        "/api/v1/plans/days",
        json={"date": day.isoformat()},
        headers={"Authorization": f"Bearer {token}"},
    )
    code = ""
    if response.status_code != 201:
        try:
            code = _text(_object(response.json()).get("code"))
        except (ValueError, RuntimeError):
            code = ""
    return ProbeRow(
        persona=persona,
        http_status=response.status_code,
        code=code,
        retry_after=response.headers.get("retry-after", ""),
    )


def _delete(client: httpx.Client, token: str) -> None:
    client.delete("/api/v1/me", headers={"Authorization": f"Bearer {token}"})


def _codes(value: object) -> set[str]:
    if not isinstance(value, list):
        return set()
    found: set[str] = set()
    for row in value:
        if not isinstance(row, dict):
            continue
        code = row.get("code")
        if isinstance(code, str):
            found.add(code)
    return found


def _reference_notes(client: httpx.Client) -> tuple[str | None, list[str]]:
    response = client.get("/api/v1/reference")
    response.raise_for_status()
    body = _object(response.json())
    notes = [ACTIVE_NOTE]
    allergen: str | None = "GLUTEN"
    codes = _codes(body.get("allergens"))
    if "GLUTEN" not in codes:
        allergen = next(iter(sorted(codes)), None)
        chosen = allergen if allergen is not None else "none"
        notes.append(f"Allergen GLUTEN is not in the reference list; persona 4 uses {chosen}.")
    present = _codes(body.get("health_conditions"))
    missing = sorted({"HYPERTENSION", "DIABETES_T2", "HEART_DISEASE"} - present)
    if missing:
        notes.append("Missing condition codes: " + ", ".join(missing) + ".")
    return allergen, notes


def _render(
    *,
    run_date: str,
    api_version: str,
    commit: str,
    base_url: str,
    days: int,
    notes: list[str],
    rows: list[RequestRow],
    probes: list[ProbeRow],
) -> str:
    walls = [row.wall_ms for row in rows]
    http_counts = Counter(str(row.http_status) for row in rows)
    plan_counts = Counter(row.plan_status or "(none)" for row in rows)
    slowest = max(rows, key=lambda row: row.wall_ms)
    lines = [
        "# Plan generation latency over HTTP",
        "",
        f"- Date: {run_date}",
        f"- API version: {api_version}",
        f"- Git commit: {commit}",
        f"- Machine: {os.cpu_count()} CPUs, {platform.platform()}",
        f"- Base URL: {base_url}",
        f"- Days per persona: {days}",
        "- slot_band_pass: n/a. POST /plans/days exposes solver_status and solve_seconds "
        "in stats. slot_band_pass is stored on the plan snapshot and is not in the HTTP body.",
        "- Percentiles: linear interpolation on sorted wall milliseconds, rounded to an integer.",
        "",
        "## Notes",
        "",
    ]
    lines.extend(f"- {note}" for note in notes)
    lines.extend(
        [
            "",
            "## Requests",
            "",
            "| persona | day | wall_ms | http_status | plan_status | slot_band_pass | "
            "solve_seconds | day_kcal | target_kcal |",
            "|---|---|---:|---:|---|---|---:|---:|---:|",
        ]
    )
    for row in rows:
        lines.append(
            f"| {row.persona} | {row.day} | {row.wall_ms} | {row.http_status} | "
            f"{row.plan_status} | {row.slot_band_pass} | {row.solve_seconds} | "
            f"{row.day_kcal} | {row.target_kcal} |"
        )
    lines.extend(
        [
            "",
            "## Summary",
            "",
            f"- count: {len(rows)}",
            f"- p50_wall_ms: {_percentile(walls, 50)}",
            f"- p95_wall_ms: {_percentile(walls, 95)}",
            f"- max_wall_ms: {max(walls) if walls else 0}",
            "- http_statuses: "
            + ", ".join(f"{code} {http_counts[code]}" for code in sorted(http_counts)),
            "- plan_statuses: "
            + ", ".join(f"{code} {plan_counts[code]}" for code in sorted(plan_counts)),
            f"- slowest: persona {slowest.persona} day {slowest.day} wall_ms {slowest.wall_ms}",
            "",
            "## Concurrency probe",
            "",
            "Three POST /plans/days at one new date, one each for personas 1, 2, and 3. "
            "The server allows two solves at once, so one request is expected to be "
            "503 PLANNER_BUSY with Retry-After.",
            "",
            "| persona | http_status | code | retry_after |",
            "|---|---:|---|---|",
        ]
    )
    for probe in probes:
        lines.append(
            f"| {probe.persona} | {probe.http_status} | {probe.code} | {probe.retry_after} |"
        )
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--days", type=int, default=3)
    args = parser.parse_args(argv)
    if args.days < 1:
        print("--days must be at least 1", file=sys.stderr)
        return 2

    today = datetime.now(ZoneInfo(TIMEZONE)).date()
    tokens: list[str] = []
    rows: list[RequestRow] = []
    probes: list[ProbeRow] = []
    notes: list[str] = []
    api_version = "unknown"
    with httpx.Client(base_url=args.base_url, timeout=180.0) as client:
        try:
            health = client.get("/api/v1/health")
            health.raise_for_status()
            version = _object(health.json()).get("api_version")
            api_version = version if isinstance(version, str) else "unknown"
            allergen, notes = _reference_notes(client)
            saved: list[tuple[Persona, str]] = []
            for persona in PERSONAS:
                token = _register(client, persona)
                tokens.append(token)
                used = allergen if persona.allergen is not None else None
                _save_profile(client, token, persona, today, used)
                saved.append((persona, token))
            for offset in range(args.days):
                day = today + timedelta(days=offset)
                for persona, token in saved:
                    rows.append(_generate(client, token, persona.name, day))
            probe_day = today + timedelta(days=args.days)
            gate = threading.Barrier(3)
            with ThreadPoolExecutor(max_workers=3) as pool:
                futures = [
                    pool.submit(_probe, client, token, persona.name, probe_day, gate)
                    for persona, token in saved[:3]
                ]
                probes = [future.result() for future in futures]
        finally:
            for token in tokens:
                try:
                    _delete(client, token)
                except httpx.HTTPError:
                    print("failed to delete a latency user", file=sys.stderr)

    if not rows:
        print("no plan requests were recorded", file=sys.stderr)
        return 1
    report = _render(
        run_date=datetime.now(UTC).date().isoformat(),
        api_version=api_version,
        commit=_git_commit(),
        base_url=args.base_url,
        days=args.days,
        notes=notes,
        rows=rows,
        probes=probes,
    )
    REPORT_PATH.write_text(report, encoding="utf-8")
    print(f"wrote {REPORT_PATH.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
