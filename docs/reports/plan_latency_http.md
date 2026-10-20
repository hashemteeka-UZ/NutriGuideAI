# Plan generation latency over HTTP

- Date: 2026-10-20
- API version: 1.0.0
- Git commit: b2329f006707a42cc1593a67b1edcd566b8ebc88
- Machine: 8 CPUs, Linux-6.18.33.2-microsoft-standard-WSL2-x86_64-with-glibc2.43
- Base URL: http://127.0.0.1:8000
- Days per persona: 3
- slot_band_pass: n/a. POST /plans/days exposes solver_status and solve_seconds in stats. slot_band_pass is stored on the plan snapshot and is not in the HTTP body.
- Percentiles: linear interpolation on sorted wall milliseconds, rounded to an integer.

## Notes

- Persona 5 asked for activity 'active'. The reference list has no ACTIVE code; HIGH is the closest (between MODERATE and ATHLETE).

## Requests

| persona | day | wall_ms | http_status | plan_status | slot_band_pass | solve_seconds | day_kcal | target_kcal |
|---|---|---:|---:|---|---|---:|---:|---:|
| 1 | 2026-10-20 | 5516 | 201 | FEASIBLE | n/a | 5.288 | 2338.998 | 2337 |
| 2 | 2026-10-20 | 6166 | 201 | FEASIBLE | n/a | 6.035 | 1318.204 | 1319 |
| 3 | 2026-10-20 | 5458 | 201 | FEASIBLE | n/a | 5.292 | 1951.177 | 1956 |
| 4 | 2026-10-20 | 2944 | 201 | OPTIMAL | n/a | 2.789 | 2064.025 | 2062 |
| 5 | 2026-10-20 | 1983 | 201 | OPTIMAL | n/a | 1.864 | 3104.26 | 3104 |
| 6 | 2026-10-20 | 5017 | 201 | FEASIBLE | n/a | 4.903 | 1237.395 | 1240 |
| 1 | 2026-10-21 | 4195 | 201 | OPTIMAL | n/a | 4.068 | 2337.248 | 2337 |
| 2 | 2026-10-21 | 2809 | 201 | OPTIMAL | n/a | 2.709 | 1317.466 | 1319 |
| 3 | 2026-10-21 | 4449 | 201 | FEASIBLE | n/a | 4.321 | 1955.737 | 1956 |
| 4 | 2026-10-21 | 1511 | 201 | OPTIMAL | n/a | 1.339 | 2061.519 | 2062 |
| 5 | 2026-10-21 | 1156 | 201 | OPTIMAL | n/a | 1.024 | 3101.736 | 3104 |
| 6 | 2026-10-21 | 3901 | 201 | OPTIMAL | n/a | 3.801 | 1237.196 | 1240 |
| 1 | 2026-10-22 | 4216 | 201 | FEASIBLE | n/a | 4.099 | 2329.652 | 2337 |
| 2 | 2026-10-22 | 4082 | 201 | FEASIBLE | n/a | 3.975 | 1325.789 | 1319 |
| 3 | 2026-10-22 | 3892 | 201 | FEASIBLE | n/a | 3.791 | 1957.23 | 1956 |
| 4 | 2026-10-22 | 2126 | 201 | OPTIMAL | n/a | 2.034 | 2064.025 | 2062 |
| 5 | 2026-10-22 | 1803 | 201 | OPTIMAL | n/a | 1.618 | 3104.26 | 3104 |
| 6 | 2026-10-22 | 2315 | 201 | OPTIMAL | n/a | 2.198 | 1237.395 | 1240 |

## Summary

- count: 18
- p50_wall_ms: 3896
- p95_wall_ms: 5613
- max_wall_ms: 6166
- http_statuses: 201 18
- plan_statuses: FEASIBLE 8, OPTIMAL 10
- slowest: persona 2 day 2026-10-20 wall_ms 6166

## Concurrency probe

Three POST /plans/days at one new date, one each for personas 1, 2, and 3. The server allows two solves at once, so one request is expected to be 503 PLANNER_BUSY with Retry-After.

| persona | http_status | code | retry_after |
|---|---:|---|---|
| 1 | 201 |  |  |
| 2 | 503 | PLANNER_BUSY | 5 |
| 3 | 201 |  |  |
