# PROJECT_CONTEXT.md — v4.21
# Fresh-Start Data Architecture & PostgreSQL Rebuild — Nutrition / Meal Recommendation Project

> **Purpose:** This document is the authoritative compact handoff for the project and for any AI assistant/coding agent working on it (chat AI or IDE coding agent).
>
> **Read this file first.** Do not reconstruct prior conversation history to recover project decisions — everything that matters is captured here. This file supersedes `PROJECT_CONTEXT_v4_20.md`, `PROJECT_CONTEXT_v4_19.md`, `PROJECT_CONTEXT_v4_18.md`, `PROJECT_CONTEXT_v4_17.md`, `PROJECT_CONTEXT_v4_16.md`, `PROJECT_CONTEXT_v4_15.md`, `PROJECT_CONTEXT_v4_14.md`, `PROJECT_CONTEXT_v4_13.md`, `PROJECT_CONTEXT_v4_12.md`, `PROJECT_CONTEXT_v4_11.md`, `PROJECT_CONTEXT_v4_10.md`, `PROJECT_CONTEXT_v4_9.md`, `PROJECT_CONTEXT_v4_8.md`, `PROJECT_CONTEXT_v4_7.md`, `PROJECT_CONTEXT_v4_6.md`, `PROJECT_CONTEXT_v4_5.md`, `PROJECT_CONTEXT_v4_4.md`, `PROJECT_CONTEXT_v4_3.md`, `PROJECT_CONTEXT_v4_2.md`, `PROJECT_CONTEXT_v4_1.md`, `PROJECT_CONTEXT_v4.md` and `PROJECT_CONTEXT_v3.md`.
>
> **Critical clarification:** This project is a **fresh rebuild from scratch**. The previous (pre-v2) project is not the codebase to be repaired or extended. Its architecture, code, migrations, generated data, and implementation are not the foundation of the new system. Previous work is used only as lessons, requirements, and evidence about what the new architecture must avoid.
>
> **Role split:** The user does the architectural thinking together with an AI assistant (Claude) in chat. Implementation (actual code, models, migrations) is executed separately by the user with **Cursor Pro** as the IDE coding agent. This document is a **decision record**, not a place to look for ready-made code.

---

## CHANGELOG — v4.20 → v4.21

v4.21 records the **closure of Step I (the API phase, 2026-10-12 → 2026-10-20; DEV_JOURNAL J-038 to J-046)**. No schema change after migration `0006`; `alembic check` clean; the frozen #88 reports are unchanged except the deliberate regeneration in I.5b (#200). The full decision text (Arabic) is in `claude/steps/STEP_I_plan.md`; this changelog gives the binding summary.

**Passes and commits (all CI green):** I.0 foundation `62b1336` · I.0b schema `08055df` · I.0c data `c2b2553` · I.0d removal pass (migration `0006`) · I.1 full contract `b5c8607` · I.2 auth `93e66f7` · I.3 profile and targets `6643183` · I.4 catalog `fda54da` · I.5 plans `3c2b467` · I.5b optimizer search fix `e75a63c` · I.6 logging `49e04ce` · I.7 sync `b2329f0` · I.8 closure `f37ac8e`. Final suite: 1561 tests, 0 skipped.

| # | Topic | Binding rule (summary) |
|---|---|---|
| #123–#124 | Execution and layout | Sync `def` endpoints in the threadpool with one session per request and an explicit commit in the router; all routes under `/api/v1`; `app/api` (`main`, `deps`, `errors`, `observability`, `routers/`, `schemas/`); business rules only in `app/services`; services never import `app/api`. |
| #125, #173 | Contract first (P-07) | Every operation defined in I.1 with full Pydantic schemas before implementation; `docs/api/openapi.json` generated and drift-tested; operation id = function name (Dart client); each operation lists its error codes; pagination `limit/offset`; date ranges ≤ 31 days for plans and ≤ 92 days for progress; realistic examples for a mock server. |
| #126, #212 | Errors | RFC 9457 `application/problem+json` with a stable upper-case `code` and `request_id`; one service-exception → (status, code) table. User-fixable input raises `InputRejectedError(ValueError)` → `422 VALIDATION_ERROR`; any other `ValueError` is a programming error → generic 500 without internal detail. |
| #127–#129 | Time, numbers, language | Server `now` from an injectable UTC clock; device times only for `consumed_at` and weight `updated_at`; measures as JSON numbers rounded to 3 dp (Decimal inside); ISO 8601 / RFC 3339; `Accept-Language` `ar` (default) or `en` with Arabic fallback; reason and error codes sent as codes. |
| #130, #170, #174 | Authentication and account | `pwdlib` Argon2id; JWT HS256 access 15 min; opaque 32-byte refresh token stored as SHA-256, 30 days, rotated on every use, reuse revokes the family; login password max 128; `DELETE /me` removes the account and all its data; `GET /me` returns `has_profile`. |
| #131, #192 | Plans over HTTP | One day per request (`POST /plans/days`, default planner `cpsat_v1`), dates from local yesterday to +13 days; a week = 7 client calls; at most 2 concurrent solves per server, the excess gets `503 PLANNER_BUSY` with `Retry-After: 5`; 20 generations per user per hour; regenerating a day is allowed and the newest plan is current (#72). |
| #132–#133 | Rate limits and observability | `slowapi` in memory: auth 10/min per IP, plans 20/h per user, sync 60/h per user, others 300/min per user → `429 RATE_LIMITED`. JSON logs to stdout; `request_id` accepted from a safe `X-Request-ID` or generated, returned in the header, the problem body and every log line; no bodies, passwords, tokens or health values in logs. |
| #134, #190, #193, #196 | Home day view | `GET /days/{date}` returns plan items (meal summary, `reason_codes`, logged flag), daily adherence (§30.5), water total and goal. A plan is always shown with the target frozen in its snapshot; totals are null when any item value is missing; meal windows derived from wake/sleep times (none when awake < 10 h). |
| #135, #179, #204 | Water | `app/services/water.py`: `water_goal` per §30.7 (user value; heart condition → no default goal and reminders off; ineligible → no goal), `log_water` idempotent by `client_uuid` (`CLIENT_UUID_CONFLICT` on different content), `delete_water` tombstone with server time. |
| #136, #176–#178 | Profile and targets | `PUT /me/profile` replaces the profile in one transaction; condition, allergen, ingredient and cuisine lists replaced by difference (unchanged rows keep their timestamps); at most one new target per save, reason priority `GOAL_CHANGE` → `PROFILE_CHANGE` → `WEIGHT_UPDATE`, `INITIAL` only for a user who never had one; the weight sent with the profile is written as today's local weight via `upsert_weight` without the automatic recompute. |
| #137, #194 | Alternatives and swap | One read-only eligibility check shared by `GET /plan-items/{id}/alternatives` and the swap, so every listed alternative is accepted; ordered by energy closeness, max 10, none for a logged item; the swap writes `SWAP_OUT` with `replaced_by`. |
| #168, #172, #203 | Logging scope | Single foods are logged by grams through ingredient search (`GET /ingredients`, the ingredient's default `food_id`); the free-form multi-ingredient off-catalog dish is **deferred to Future Work** (user decision): `consumption_logs.entry_group` / `entry_label` (§11.9) stay reserved and are never written by the API. |
| #169, #182, #201, #205 | Learning signals | The app sends IMPRESSION/VIEW/SAVE/RATE/COOK/SKIP via `POST /interactions` (`app/services/interactions.py`, idempotent by `client_uuid`); the server alone writes ACCEPT (first log of a plan item, with plan, item, slot, algorithm and eaten/planned ratio), SWAP_OUT and PREF_* (only on a real state change). Every plan-linked event carries `plan_id`, `plan_item_id`, `algorithm_version`. |
| #171, #195 | Shopping list | `GET /shopping-list` sums grams of non-optional ingredients over the current plans of a date range. |
| #180–#181, #185 | Reference lists and search | `GET /reference` is public, read from the database, cached 1 h. Ingredient and meal search share `app/services/text_search.py`: the single normalizer (§15.9), partial match plus `pg_trgm` similarity; ranking exact → prefix → contains → similarity. |
| #183–#189 | Catalog | Catalog version read from `DATASET_MANIFEST.yaml` and checked against the active batches (mismatch → null + warning, never a failure); energy shown from stored `calc_v1` values; `GET /catalog/snapshot` with a strong SHA-256 ETag per language, 304 and gzip; browsing is not filtered by conditions (only the planner applies hard filters) but meals carry allergen codes; a meal missing energy or a macro is never shown as zero (excluded, details 404). |
| #191, #197–#200 | Optimizer in production | Solver seconds and candidate counts added to the plan snapshot (JSONB only). Search fix: `linearization_level = 2`, deterministic budget 2.0 with one retry at 10 on `UNKNOWN`, a first pass restricted to main-slot candidates within 0.7–1.4 of the slot's energy share; comparison report regenerated on a catalog-only database. |
| #202 | Log time window | Food and water: `consumed_at` ≤ server now + 5 min (`CLOCK_SKEW`), not older than 30 local days; a plan-item log must fall on its plan date. |
| #206 | Adherence range | `GET /adherence` uses `adherence_range` (92 days ≈ 463 queries, 0.5 s; re-measured at hosting). |
| #208–#211, #213 | Offline sync (§33.4) | `POST /sync/batch` (≤ 500 ops) runs each op in order inside its own `SAVEPOINT` through the same request services as the single routes; a known error marks only that op `REJECTED` with its code; an unknown error is a 500 for the whole batch (safe to resend). Statuses `CREATED` / `UPDATED` / `DUPLICATE` / `REJECTED`; idempotent duplicates for creates, corrections, repeated deletes of the user's own tombstone and stale weights. The phone never sends a correction or delete for an unconfirmed create: it edits or drops the queued op (outbox compaction). `GET /sync/changes?since=` with `since` ≤ now + 5 min and ≥ now − 30 days (else full reload), queried from `since − 2 min` (overlap), returning new and tombstoned logs and water, all weights of the last 30 local days, the full meal-preference list, current plans from local yesterday that changed (including swaps), `profile_changed`, and `server_time` as the next `since`. Weight reads moved to `weight.weights_between`. |
| #214 | Target instants | `targets.target_instant(current_valid_from, now) = max(now, current_valid_from + 1 µs)` closes the current target and opens the next one (also when `profile` closes a target for an ineligible user). Removes the last 500 on weight recompute (two same-day weights in one sync batch share `now`, or two concurrent requests); history stays append-only and `CHECK valid_to > valid_from` holds; one warning log line (user id only) when the instant is advanced. |
| #215 | Solver timeout | A slot-banded pass still `UNKNOWN` after its retry is treated like `INFEASIBLE` and the optimizer continues; when the last pass has no accepted status, `PlannerTimeoutError(PlanError)` → `503 PLANNER_TIMEOUT` (no `Retry-After`), only on `POST /plans/days`. Worst-case path: 36 deterministic-time units (not a wall-clock guarantee). |
| #216 | Closure | End-to-end scenario test over HTTP (register → … → `DELETE /me`); `scripts/measure_plan_latency.py` and `docs/reports/plan_latency_http.md` (6 personas × 3 days: p50 3.9 s, p95 5.6 s, max 6.2 s; 10 OPTIMAL, 8 FEASIBLE; concurrency probe 2 × 201 + 1 × `503 PLANNER_BUSY`). **Contract frozen at `1.0.0`:** later changes are additive only (new optional fields, endpoints, codes); clients ignore unknown fields and treat unknown codes as generic errors; a breaking change goes to `/api/v2`. |

**Theory:** DEV_JOURNAL J-038 (contract), J-039 (auth), J-040 (profile), J-041 (catalog), J-042 (plans), J-043 (optimizer fix), J-044 (logging), J-045 (sync), J-046 (closure and evaluation).

---

## CHANGELOG — v4.19 → v4.20

v4.20 records the **fourth use of the post-freeze policy (§20.1)**: the removal pass after Step I.0c (2026-10-19, DEV_JOURNAL J-037). Step I.0c (data) is committed: catalog_v3, 158 meals, 477 preparation steps on 121 meals, dev database rebuilt from the catalog only.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #167 | Scope: supported conditions (user decision, final, 2026-10-19) | The project serves **only** type 2 diabetes (not insulin-treated), hypertension and heart disease. **Kidney disease, pregnancy, lactation and gout are cancelled permanently**, in the code and in the theory part. Removed: `user_profiles.physiological_status` with its two CHECKs (migration `0006`), the `PhysiologicalStatus` enum, the screening reason `PREGNANT_OR_LACTATING`, the condition `CKD` from every reference seed (catalog, F.1 slice, test fixtures), and every mention in the current documentation, report chapters and UI prototype. Kept: under-18 screening and `DIABETES_INSULIN` as the one recognized-unsupported condition (an insulin user is a diabetes user; carbohydrate planning tied to insulin dosing is not covered, so they get the general mode). The water rule `fluid_goal_requires_clinician` now applies to `HEART_DISEASE` only. **Reason:** the user wants the project focused on one direction and finished well; each of these populations needs its own clinical rules, data and validation. **Frozen artifacts (approved by the user):** the F.1 benchmark persona P3 changes from `CKD` to `DIABETES_INSULIN` (same purpose: an unsupported condition gets no personalized plan), so `f1_scenario_report.md` is regenerated once; the catalog reference seed loses `CKD`, so `DATASET_MANIFEST.yaml` gets a new hash (`dataset_version` stays `catalog_v3`, meals unchanged). **Known limitation (one line in the report):** the app is designed for adults with type 2 diabetes, hypertension or heart disease, or no condition; it is not designed for pregnancy, lactation, kidney disease or gout. | **Yes** |
| #175 | Scope: goals (user decision, final, 2026-10-19) | Only three goals: `LOSE`, `MAINTAIN`, `GAIN`. The muscle-building path is **cancelled permanently**, not deferred: the `MUSCLE` goal and `targets_v2` (#153), protein preference (#144), the protein floor and per-meal protein rules (#154, #155), training days and time (#156) and their reason codes and badges (#157). None of these was ever implemented in code, so no migration is needed; the UI prototype and the documentation were cleaned. `ATHLETE` stays as an activity level (it only sets PAL 1.9 and the athlete protein factor of `targets_v1`). Batch 02 recipes chosen for protein coverage stay as ordinary catalog meals. | No |

---

## CHANGELOG — v4.18 → v4.19

v4.19 is the **third use of the post-freeze policy (§20.1)**: Step I.0b, the only schema change of Step I (2026-10-17, DEV_JOURNAL J-036). It adds migration `0005` for the product decisions taken during the UI design and the catalog batch 02 work (#141–#164), before the API contract (I.1) is written, so the contract is built on the final columns. **Scope change by the user (2026-10-17):** the muscle-gain path (#144, #153–#157: `MUSCLE` goal, protein preference, training days and time) is a topic of its own and is **deferred** to a later dedicated step *(superseded in v4.20 by #175: cancelled permanently)*; this pass does not touch `goal_type`, `targets_v1` or protein. Data loading (`meal_steps` rows, `dish_form` values) and the dev-database rebuild are a separate data pass, I.0c (#166). The planner, `calc_v1`, `targets_v1`, `greedy_v1` and `cpsat_v1` behave exactly as before; the #88 F.1 report must stay byte-identical.

**Product decisions recorded (from `knowledge/claude/ui/UI_v2_changes_and_sources.md`, `UI_v3_athlete_and_personal_theme_sources.md`, `steps/g3_data/batch_02_theory_notes.md`; sources are listed there):**

| # | Topic | Schema? |
|---|---|---|
| #141 | Wellness tone and UI language (dietary considerations, not treatment) | No |
| #142 | Adaptive onboarding (options shown from the user's data) | No |
| #143 | General mode instead of "not eligible" (§30.1 screening result returned, profile still saved) | No |
| #144 | Protein preference for active users (by goal / 1.8 / 2.0 g per kg) and a new targets formula version | **Cancelled (v4.20, #175)** |
| #145 | Wake and sleep times; meal windows computed from them | **Yes** (`wake_time`, `sleep_time`, I.0b) |
| #146 | Water sessions in the UI | No |
| #147 | Portion shown in grams | No |
| #148 | Optimizer statistics in the plan response | No |
| #149 | Favourite and disliked meals: dislike = hard exclusion in Layer 1; favourite = small objective bonus | **Yes** (`user_meal_prefs`, I.0b) |
| #150 | Shopping list (computed) | No |
| #151 | Weekly report (computed) | No |
| #152 | Computed badges | No |
| #153 | Fourth goal `MUSCLE`: fixed small surplus (~275 kcal/day, inside the 500 kcal gain cap), no target weight or rate; formula `targets_v2` | **Cancelled (v4.20, #175)** |
| #154 | `MUSCLE` protein is a floor with a 2.2 g/kg ceiling (one-sided deviation in CP-SAT) | **Cancelled (v4.20, #175)** |
| #155 | 25 g protein per main meal for `MUSCLE` (soft first, then hard) | **Cancelled (v4.20, #175)** |
| #156 | Training days per week (2–6) and usual training time; pre/post-workout slot rule | **Cancelled (v4.20, #175)** |
| #157 | Reason codes, badges and home ordering for the `MUSCLE` path | **Cancelled (v4.20, #175)** |
| #158 | Protein recipe batch 02 | No (data, delivered in catalog_v2) |
| #159 | App accent follows the goal, stored on the device only | No |
| #160 | Gendered address and avatar, device only | No |
| #161 | Preparation steps per meal (`meal_steps`) and `meals.dish_form` (schema.org `recipeInstructions` / `HowToStep`) | **Yes** |
| #162 | Dish composition rule (one dish vs plate, Plate Method) | No |
| #163 | Team review applied to batch 01 (soft delete, quinoa → bulgur) | No (data) |
| #164 | `catalog_v2` frozen (75 active meals, tag `dataset-v2`) | No (data) |

**New decisions in this version:**

| # | Topic | Change | Schema? |
|---|---|---|---|
| #165 | Step I.0b schema (migration `0005`) | `user_profiles`: `wake_time`, `sleep_time` `TIME NOT NULL DEFAULT '07:00'` / `'23:00'`, `CHECK (wake_time <> sleep_time)` (#145). New table `user_meal_prefs` (§11.14, #149). New table `meal_steps` (§10.7) and `meals.dish_form` (§10.1) (#161). `user_interactions.event_type` adds `PREF_LIKE`, `PREF_DISLIKE`, `PREF_CLEAR` (§11.6): every preference change is also logged as an event, so the history survives for the later ML layer while `user_meal_prefs` keeps only the current state (user goal 2026-10-18: beta with classmates, then ML trained on real usage). New table `user_cuisine_prefs` (§11.15): the cuisines a user prefers, a **soft** preference (objective bonus, never a filter; no rows = all cuisines). `consumption_logs` adds `entry_group` (`UUID` nullable) and `entry_label` (`TEXT` nullable) so an off-plan dish that is not in the catalog can be logged as several food rows (ingredients in grams) that the app shows and sums as one entry (§11.9). Nothing else: `goal_type`, `goal_requires_target`, `targets_v1` and every planner are unchanged. | **Yes** |
| #166 | Step I.0c data pass | `meal_steps` rows and `dish_form` values are loaded by the catalog pipeline from a versioned steps file (`team_recipe_steps_v2`, 38 batch-02 meals); steps for the 37 batch-01 meals are written by the team later through the same file format. The dev database is rebuilt from the catalog only (the 110 F.1 slice meals no longer active in dev; the F.1 benchmark keeps its own isolated database, #101). Not schema. | No |

**Why cuisine is a soft preference and not a filter (user request 2026-10-18):** catalog_v2 has 37 general, 26 Libyan, 7 Levantine and 5 Egyptian meals (before deactivations); breakfasts and snacks of one cuisine alone are too few, so a hard filter would repeat the same meals or miss protein and fibre targets, or make days infeasible for users with conditions. A bonus in the objective (like favourites) leans the plan toward the chosen cuisines while Layer 1 safety and the nutrient targets keep priority.

**Why off-catalog dishes need no new table yet:** the user enters the ingredients in grams; each becomes a `food_id` + `grams_consumed` row (already supported, nutrients from `foods`), tied together by `entry_group` and named by `entry_label`. Saving a personal recipe for reuse would need user-owned meals, which stay Future Work (#59, §29). Ready-made foods (FNDDS, deferred G.4) would make this search much more useful before the beta.

**Why `user_meal_prefs` is a new table and not `user_interactions`:** a preference is current *state* the planner reads every day (one row per user and meal, changed in place), while `user_interactions` is an append-only *event* log for analysis. Mixing them would make "is this meal disliked now?" a query over history. Same pattern as `user_ingredient_prefs` (§11.5).

---

## CHANGELOG — v4.17 → v4.18

v4.18 **closes Step H (Layer 3 optimizer)** (2026-10-12, DEV_JOURNAL J-035). Commits: H.0 `18b6803` (pure optimizer + general limits), H.1 `e9d72b7` (database wiring + comparison report), H.2 = commit `feat(planner): Step H.2 cpsat_v1 default planner (#122)`; CI green; 1287 tests, 0 skipped. No schema change, no migration, no data change (`catalog_v1` and `DATASET_MANIFEST.yaml` unchanged). Decisions taken by the assistant under the user's delegation (J-030); "optimizer first, API after" chosen by the user. Plan and status log: `claude/steps/STEP_H_plan.md`.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #108 | Solver | Google OR-Tools CP-SAT (`ortools>=9.12,<10`, locked 9.15.6755, Apache-2.0): free, deterministic with one worker and a fixed seed, proves optimality or infeasibility. PuLP/CBC rejected (slower, determinism harder). | No |
| #109 | Model scope | One day per solve, same inputs as `plan_day`. Boolean `x[position, meal, step]` only for (meal, step) pairs that pass Layer 1 at that step (`evaluate_meal`), so Layer 1 is never re-modelled. Positions breakfast, lunch, dinner (exactly one each) and `snack_1`, `snack_2` (optional; `snack_2` only with `snack_1`, symmetry breaking). Weekly (7-day) model is Future Work. | No |
| #110 | Hard constraints | Each meal and each `variant_group` at most once per day; every `max_per_day`; every `min_per_day` (hard, #81); `LIMIT` tag servings in the day ≤ the weekly number (same accounting as greedy, #89; half-servings as integers); meals of the previous day's current plan excluded (#88 criterion 4). A pair whose energy or any limited or macro nutrient is unknown is not a candidate (missing ≠ zero, §9.8). | No |
| #111 | General limits implemented (#87) | Pure `apply_general_limits(limits)` in `condition_limits.py` adds `GENERAL_POPULATION` sources (sodium 2000 mg/day, WHO 2012; saturated fat 10% of energy as grams, WHO 2023, "< 10%" applied as "≤ 10%") and merges them by §28.2 (strictest wins, conflict check re-run, idempotent). Applied **only on the optimizer path**; `greedy_v1` stays the unchanged baseline. | No |
| #112 | Energy phases | Phase 1: energy hard within ±10%. If INFEASIBLE, phase 2: the band is removed and its deviation weighted 50 in the objective, `kcal_relaxed = true`. If phase 2 is INFEASIBLE: `NoFeasiblePlanError`. No health limit is ever relaxed, no slot dropped. | No |
| #113 | Objective | Integer units of 0.1 kcal-equivalent: 3 × abs(kcal − target) + 1 × (abs(protein − target)×4 + abs(carbohydrate − target)×4 + abs(fat − target)×9) + 1 × fiber shortfall×4 + 1 × Σ main-slot abs(slot kcal − share × target) (25/35/25%) − 10 per item with a liked ingredient (Layer 2). Absolute values linearised with auxiliary integer variables. | No |
| #114 | Numeric exactness | Amounts scaled ×1000 to integers with outward rounding (upper bounds: coefficients ceil, bound floor; lower bounds the reverse); objective coefficients half-up. Every hard rule is re-checked on the chosen items with exact `Decimal` (`_verify`); a failure is an `AssertionError` (programming error, never hidden). | No |
| #115 | Determinism | `num_workers = 1`, `random_seed = 0`, `max_deterministic_time = 10.0`, variables created in a fixed order (position, `sort_key`, step). Same inputs → same plan; input order does not matter (tested). | No |
| #116 | Integration rule | The optimizer becomes the default only if it meets the five #88 criteria in a side-by-side report; greedy stays the baseline. | No |
| #117 | Planner selection | `create_day_plan(..., planner="greedy" \| "cpsat")` is the single entry point. The cpsat path applies #111, excludes the previous day's current plan (`current_plan_id`), stores `generated_by = "cpsat"`, `algorithm_version = "cpsat_v1"`, the merged limits and a `"solver"` entry (status, `kcal_relaxed`, objective, excluded meal ids) in `target_snapshot`. Greedy snapshots are unchanged (no `"solver"` key). | No |
| #118 | Swap consistency | A swap on a `cpsat_v1` plan is checked against the same merged limits (#111), so a swap cannot break the general sodium cap; greedy plans keep their behaviour. | No |
| #119 | Comparison report | `scripts/planner_comparison_report.py` → `docs/reports/planner_comparison_report.md`: P1 and P2, three consecutive days per planner, each planner in its own SAVEPOINT, on the isolated F.1 bench (the #88 benchmark) and on the full catalog; criteria recomputed independently from stored items with exact `Decimal`; verdict computed, not hand-written. | No |
| #120 | Step H tests | Pure optimizer tests (19), general-limit tests, cpsat integration on the F.1 slice, swap test, `evaluate_criteria` PASS/FAIL per criterion, report determinism (timing stripped), end-to-end default-planner test (plan → log → adherence). | No |
| #121 | "Feasible day" in #88 | A cpsat day whose phase 1 was proven INFEASIBLE (`kcal_relaxed = true` and kcal outside ±10%) is not a feasible day in the #88 sense: C2 is `N/A*`, not FAIL. Greedy days never get N/A (no proof). The report also prints a strict verdict counting N/A as FAIL, and a diagnostic solve without the #87 caps for each such day. | No |
| #122 | Default planner | `DEFAULT_PLANNER = "cpsat"`. `greedy_v1` stays the fixed #88 baseline: the F.1 scenario, its reports and greedy-specific tests pass `planner="greedy"` explicitly. `planner.PLANNER_VERSION` stays `greedy_v1`, so `DATASET_MANIFEST.yaml` keeps recording the planner `catalog_v1` was frozen against. | No |

**Results (`planner_comparison_report.md`):** full catalog: cpsat meets criteria 1–4 on 6/6 persona-days (all phase 1, `OPTIMAL`), greedy on 1/6. F.1 benchmark: cpsat 6/6 under #121 (3 P2 days `N/A*`), greedy 1/6; strict reading NO on F.1 only. Diagnostic: the P2 F.1 days stay out of band even without the #87 caps, so the condition limits and the 35-meal slice alone make the band impossible. Planning time: greedy ≈ 25–40 ms; cpsat median ≈ 1.4 s (F.1) and ≈ 3.8 s (catalog), max ≈ 13 s.

---

## CHANGELOG — v4.16 → v4.17

v4.17 **closes Step G (dataset engineering)** (2026-10-12, DEV_JOURNAL J-034). Commits: G.0 `b6c5e4e`, G.1 `93a9615`, G.2 `aad2ca7`, G.3a `bf214ff`, G.3b `6a09ea9`, G.5 `f5e10f0`; git tag `dataset-v1`; CI green; 1248 tests, 0 skipped. No schema change after G.0. Decisions taken by the assistant under the user's delegation (J-030), scope reduction requested by the user.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #101 | Step G scope reduction (user, 2026-10-11/12) | The project values correct algorithms and results over data volume. Step G closes with **one recipe batch** (`team_recipes_batch_01.yaml`, 40 meals, `team_recipes_v1`) plus the F.1 slice (75 active meals in the dev database). **Postponed to Future Work:** G.4 FNDDS ready foods (#98), the FNDDS dish cross-check and the weighed sample (#96). Closure criteria revised: the per-slot coverage rule of #100 stays and is met; the totals of #100 (≥ 150 meals, slot minimums, `LIBYAN` ≥ 35%, ≥ 100 ready foods) are dropped. The user asked for mostly `GENERAL` recipes (batch 01: `GENERAL` 22, `LIBYAN` 13, `EGYPTIAN` 2, `LEVANTINE` 2, `MAGHREBI` 1). More recipes are wanted later: the team reviews the 183-dish proposal (`claude/steps/g2_data/dish_list_proposal.xlsx`) and each new batch is one more file in `backend/data/catalog/meals/` (no code or schema change; the manifest is re-written and reviewed). §31.7, §29 | No |
| #102 | #93 revised by evidence (G-01) | On the real files 2083 of 7793 SR Legacy foods miss a mandatory nutrient (3174 gaps, mostly sugars and fiber) and the FNDDS fill closes only 17 (one used: chia seed sugars). The fill step stays (safe, rare); the working rule is **choose an SR Legacy item that is already complete** (5710 exist). 485 of 15049 shared values differ by > 5% between FNDDS and SR (G-02, no effect because SR is first). §31.7 | No |
| #103 | Reference layer result | `ingredients.yaml`: 196 ingredients, **177 approved**, 19 quarantined (15 missing a mandatory nutrient, 4 failing the energy gate) and kept `PENDING`, never used in recipes (substitutes: lentils 16069 for red lentils, standard dates for Medjool, flour for semolina, yeast for baking powder; spices without sugars dropped). An extractor report `reports/ingredient_lookup.md` checks every NDB number against its SR description and proposes complete candidates. Gelatin moved from excluded to quarantine (`uncertain_keywords`, G-03). Camel meat stays out (no published complete source, #93 step 4). Cuisines `EGYPTIAN`, `MAGHREBI` and category 2500 added. A recipe may show a local display name through `label_ar` (e.g. low-fat cottage cheese shown as «جبن أبيض طري»); the ingredient row is unchanged. §9.10, §31.7 | No |
| #104 | Benchmark isolation (G-04) and one re-baseline | `scripts/f1_scenario_report.py` builds a sibling database `{dev_db}_f1_bench`, migrates it, loads the F.1 slice, runs the scenario in a rolled-back transaction and drops it (`--keep-db` keeps it). The #88 report changed **once**, in G.3a, only through `tags_v2` (`F1-S05` gains `high_sugar`; no plan or reason code changed) and the removal of leftover dev rows; that file is the final #88 baseline, fixed before any optimizer exists. `--catalog` runs the same personas on the dev database (catalog + slice) and writes `docs/reports/catalog_scenario_report.md`: graduation evidence, not the benchmark. §28.4b | No |
| #105 | `SUM_OF_INGREDIENTS` for absorbed-water dishes | §10.1 relaxed: `SUM_OF_INGREDIENTS` is also allowed for cooked dishes whose added water is counted as an ingredient and stays in the dish (rice, pasta, stews); dishes where water clearly evaporates use `YIELD_FACTOR` (`TEAM_ESTIMATE`, tier `SILVER`). Per-serving nutrients, which the planner uses, do not depend on the weight method; only `amount_per_100g` (threshold tags) does. #96 GOLD wording follows. Weighing remains Future Work. §10.1, §31.7 | No |
| #106 | Coverage result and Layer 1 meaning (G-05) | `docs/reports/catalog_coverage_report.md`: all 15 main-slot rows pass (≥ 8 eligible meals at multiplier 1.0; tightest `DIABETES_T2` breakfast 22). `HYPERTENSION` and `HEART_DISEASE` filter exactly like `NONE` at meal level because their nutrient limits are **per day** (applied by the planner over the day) and `high_sodium` is a `LIMIT` tag (servings); only `DIABETES_T2` removes meals per meal (`added_sugar` AVOID, carbohydrate max per meal). This is by design. §28.1 | No |
| #107 | Dataset freeze implemented (#99) | `app/pipeline/manifest.py` (`--write` / `--check`) writes `backend/data/catalog/DATASET_MANIFEST.yaml`: `catalog_v1`, SHA-256 of every curated file (reference seed, ingredients, meal batches, source manifest and subsets; generated reports excluded), raw files from the source manifest, classification counts and meal tiers from the build, rule versions (`calc_v1`, `tags_v2`, `greedy_v1`). A CI test fails when a curated file changes without `--write`. Tag `dataset-v1` on `f5e10f0`. §22 | No |

---

## CHANGELOG — v4.15 → v4.16

v4.16 **opens Step G (dataset engineering)** (2026-10-11, DEV_JOURNAL J-033). Plan: `claude/steps/STEP_G_plan.md`. All decisions were taken by the assistant under the user's delegation (J-030). Step G is split so that schema work and data work never share a step: **Step G.0** is the only schema change (migration `0004`, §20.1) and closes on its own; data passes G.1–G.5 change no schema.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #90 | Step G structure | Step G.0 = schema only (migration `0004`), closed with its own commit and CI before any data work; passes G.1–G.5 = data only. §18.4 (no large ETL) is lifted for Step G. The F.1 slice data and scenario stay frozen as the #88 benchmark (G.0 only adds codes/references, no number changes). §25, §31.7 | — |
| #91 | Migration `0004` | `ingredients.code` `TEXT NOT NULL UNIQUE` + `CHECK (code ~ '^[A-Z][A-Z0-9_]*$')` — ingredient natural key (F-01, #77); `condition_tag_restrictions.source_reference` `TEXT NOT NULL` (provenance gap, #89, §14). Existing rows backfilled inside the migration, then NOT NULL. §9.10, §9.5c | **Yes** |
| #92 | Pipeline architecture | New package `app/pipeline` (source hash check → `pandera` profiling of raw tables → normalize/map → business gates → accepted / quarantine / excluded with reasons → idempotent load → committed reports). Raw files stay outside git with a SHA-256 manifest; only used subsets are committed. The loader rejects manual threshold tags. `f1_loader` stays for the slice. §13, §31.7 | No |
| #93 | Ingredient nutrient source order (F-03) | SR Legacy → same SR code in FNDDS 2021–2023 *Ingredient Nutrient Values* for a missing mandatory nutrient (noted in `foods.source_reference`) → an equivalent SR Legacy / Foundation item → a published regional source (`external_source = 'MANUAL'`, full citation) for items absent from USDA (e.g. camel meat). The project never writes a zero of its own ("structural zero" rejected, §9.8); otherwise quarantine. §31.7 | No |
| #94 | Data-entry format | Git-tracked YAML files in `backend/data/catalog/` replace the teammate's xlsx template (one developer; reviewable diffs; gates in code replace the sheet formula). Recipes reference ingredients by `ingredients.code`. §4.2, §31.7 | No |
| #95 | Catalog authoring | The team edits a dish list proposed by the assistant; the assistant drafts grams per §31.4; the team reviews each batch (`reviewed_by`). `ref_external` prefix `NG-`, `dataset_version = team_recipes_v1`; the 35 F.1 recipes are re-entered under new codes. The dev database is loaded from the catalog; the slice is for tests only. §31.7 | No |
| #96 | Quality tier rule | `GOLD` = reviewed + every ingredient complete + `total_grams` from `WEIGHED`, `SUM_OF_INGREDIENTS` (no-cook) or a **published** yield factor + cross-check not failed; otherwise `SILVER` (team-estimated yield, or reviewed deviation). A weighed sample of ≥ 10 dishes measures the yield-factor error. §10.1, §31.7 | No |
| #97 | `tags_v2` drink thresholds | Meals tagged `beverage` use UK FSA drink thresholds per 100 ml: `high_sugar` > 11.25 g, `high_sodium` > 300 mg; reason codes `LOW_SUGAR` ≤ 2.5 g, `LOW_SATURATED_FAT` ≤ 0.75 g (`LOW_SODIUM` stays 120 mg). 100 ml ≈ 100 g assumed for water/milk-based drinks. Other meals keep `tags_v1` thresholds. §10.5, §28.4b | No |
| #98 | FNDDS ready foods | ≈150 items (`FNDDS_FOOD`) with published values and FNDDS portions into `portions_food`; same gates; never planned. §31.2 | No |
| #99 | Dataset freeze | `backend/data/catalog/DATASET_MANIFEST.yaml` (version `catalog_v1`, SHA-256 of every raw and curated file, stage counts, gate results, rule versions) + a CI hash test + git tag `dataset-v1`. No versioning table (§18.8 kept). §22 | No |
| #100 | Coverage acceptance | For each supported condition alone and for `HYPERTENSION` + `DIABETES_T2`, Layer 1 leaves ≥ 8 eligible meals per main slot at multiplier 1.0. Plus ≥ 150 active verified meals (breakfast ≥ 35, lunch ≥ 45, dinner ≥ 35, snack ≥ 25; `LIBYAN` ≥ 35%) and ≥ 100 ready foods. §31.7 | No |

---

## CHANGELOG — v4.14 → v4.15

v4.15 **closes Step F.1** (2026-10-10, DEV_JOURNAL J-032). The vertical slice ran end to end on 35 team-reviewed meals: data load → calc_v1 → derived data → screening and targets → Layer 1 → one-day plan → consumption logging → adherence → weight log and target recompute, plus a three-persona scenario report (`docs/reports/f1_scenario_report.md`). Commits `5eff2a0` (F.1-a), `18f304f` (F.1-b), `6e5bd92` (F.1-r, migration `0003`), `33427af` (F.1-c), `21c9452` (F.1-d), `6e1e5d7` (F.1-e); 1190 tests, 0 skipped, CI green. **No schema change in v4.15**: all items below are application rules decided by the assistant during F.1 (user delegation, J-030) and recorded here, or direction for later steps. Findings F-05 … F-14 are listed in `claude/steps/STEP_F1_plan.md`.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #80 | Baseline planner `greedy_v1` | Deterministic one-day greedy planner from Step F.1 recorded as the **baseline** of §28.4: slot energy shares, portion steps, lookahead on daily maxima, variant rule, tie-breaks, reason-code thresholds. §28.4b | No |
| #81 | Condition minimums (F-05) | #68 clarified: a condition `min_per_day` (e.g. `DIABETES_T2` fiber 25 g) is a hard requirement for the Layer 3 optimizer; `greedy_v1` cannot guarantee it and reports every unmet minimum (`unmet_minimums`), never hides it. §30.4b | No |
| #82 | Layer 1 details | Rule 5 is checked at the planned portion multiplier, not one serving; an unknown amount of a limited nutrient counts as a violation (fail closed, §9.8); `LIMIT` tags do not exclude in Layer 1; `SUITS_CONDITION_<CODE>` is not given to a meal carrying that condition's `LIMIT` tag. §28.1, §28.6 | No |
| #83 | Consumption logging rules | `client_uuid` required; same uuid + same content = duplicate, different content = conflict; `nutrients_snapshot` shape fixed; meals/foods with an unknown mandatory nutrient cannot be logged; one active log per plan item; a correction never changes the logged meal/food. §11.9 | No |
| #84 | Plan-item swap rules | A swap must pass Layer 1 at the item's slot and multiplier plus the day rules (no repeat, no second variant, daily maxima, `LIMIT` servings); refused once the item is logged; the plan's `target_snapshot` is never changed. §11.8 | No |
| #85 | Adherence and screening details | Inclusive status bands; ±10% energy with an exceeded maximum falls to the ±25% band; past days use the user's **current** conditions (no condition history — known limitation); current plan ties broken by `plan_id`; screening uses the user's local date. §11.7, §30.1, §30.5 | No |
| #86 | Weight log rules | Device clock skew tolerance 5 minutes; `measured_on` after the local today rejected; only the latest `measured_on` can trigger `WEIGHT_UPDATE`; no current target → none created; if the new target cannot be computed (screening fails or the goal becomes invalid) the weight is kept and the old target stays. §11.10, §30.6 | No |
| #87 | General population limits (F-06) | Partly supersedes #69: users get a **general daily maximum of 2000 mg sodium** (WHO 2012) and **saturated fat < 10% of energy** (WHO 2023), resolved together with condition limits by §28.2 (strictest wins). Implemented together with the Layer 3 optimizer (#88), not in `greedy_v1`. Total-sugars limit for everyone stays out (#69: no added-sugar data). §30.1 | No |
| #88 | Optimizer acceptance criteria (F-13, F-14) | The F.1-e scenario is the fixed benchmark; Layer 3 must beat `greedy_v1` on it: kcal within ±10% on every feasible day, 0 hard-limit violations, condition minimums met, no meal repeated on consecutive days. §28.4b, §28.5 | No |
| #89 | Step F.1 closed | Known limitations carried to Step G / later: no cross-day variety in `greedy_v1`; weekly `LIMIT` servings counted within one day only; `condition_tag_restrictions` has no `source_reference` (provenance gap, §14 — a §20.1 change in Step G); no condition history; ingredient natural key (#77). Editorial: §10.1 variant example corrected (F-07). §24, §25 | No |

---

## CHANGELOG — v4.13 → v4.14

v4.14 is the **first post-freeze schema change** (2026-10-06, DEV_JOURNAL J-031), made through the §20.1 path during Step F.1. Sources: Step F.1 findings F-01, F-02, F-04 and the team's recipe review. One new migration, `0003`; migrations `0001` and `0002` are untouched.

| # | Topic | Change | Schema? |
|---|---|---|---|
| #74 | Threshold tags (finding F-02) | `high_sodium` / `high_sugar` are derived at **meal level** from `meal_nutrients.amount_per_100g` with UK FSA "high" thresholds (sodium > 600 mg, sugars > 22.5 g per 100 g), rules version `tags_v1`. Ingredient-union derivation stays for presence tags (`added_sugar`). §9.5c, §9.13, §10.5 | No |
| #75 | Optional ingredients | `meal_ingredients.is_optional`; nutrients computed on the full recipe; allergens of optional ingredients still count. §10.2 | **Yes** |
| #76 | Dish variants | `meals.variant_group` links versions of one dish (e.g. lamb / chicken couscous); planner never places two of a group in one day; "switch meat" = swap to a sibling. §10.1 | **Yes** |
| #77 | Stable codes (finding F-01) | `cuisines.code`, `allergens.code` (`UNIQUE NOT NULL`); `categories` `UNIQUE (name_en)`. Ingredient natural key stays deferred to Step G. §9.1–§9.3 | **Yes** |
| #78 | QC columns (finding F-04) | `meals.yield_factor`, `meals.yield_factor_source`, `meals.reviewed_by`; `meal_tags.rule_version` for `DERIVED` rows. §10.1, §10.5 | **Yes** |
| #79 | Seed reload rule | A meal removed from a seed file is deactivated (`is_active = false`), never deleted (§15.8); `meal_ingredients.text_original` stores the recipe's own wording of an ingredient. §10.2, §31 | No |

---

## CHANGELOG — v4.12 → v4.13

v4.13 records the **implementation of the freeze** (Step F, 2026-10-04, DEV_JOURNAL J-029). **No new decision and no schema change** beyond what v4.12 decided. Corrections found while implementing:

| Topic | Change | Schema? |
|---|---|---|
| Step F dates | v4.12 marked the freeze as 2026-10-02 in advance; it was implemented on 2026-10-04 (migration `0002`, tag `schema-v1`). §20, §24, §25 corrected; §24 order fixed | No |
| Partial unique indexes | There are now **two** (`ix_user_targets_user_id`, `ix_meal_plan_items_plan_id_day_index_slot`). §16 and §19 updated; the integrity suite reads them from `pg_index` and a completeness test fails if a new one has no case | No |
| Test count | 903 tests, 0 skipped (§19) | No |
| Line endings | `.gitattributes` marks `backend/alembic/versions/*.py` as `-text`, so a Windows checkout with `core.autocrlf` cannot change the bytes the migration-hash test checks (§20.1) | No |

---

## CHANGELOG — v4.11 → v4.12

v4.12 is the **schema freeze** (Step F, 2026-10-02). A pre-freeze review walked every Core Now feature (§29) and the whole Step F.1 path against the committed schema (`claude/reviews/pre_freeze_review_v4_11_2026-10-02.md`, DEV_JOURNAL J-028). The user approved all recommendations. After this version the initial schema is **frozen** (git tag `schema-v1`); changes follow §20.1.

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 70 | Off-plan logging only accepts catalog meals or `foods`; the import scope (#38) holds only raw recipe ingredients, so ready foods eaten outside the plan (bakery items, sweets, drinks) cannot be logged and adherence looks better than reality | **Import scope widened (Phase 2 data):** add a curated set of ≈100–200 common ready foods from FNDDS (`external_source = 'FNDDS_FOOD'`, complete published nutrient values) for off-plan logging (§31.2). Rejected: a kcal-only "quick add" (breaks missing ≠ zero, needs a schema change) | No |
| 71 | Nothing stopped two lunches on the same plan day | Partial unique index on `meal_plan_items (plan_id, day_index, slot) WHERE slot <> 'SNACK'` (name `ix_meal_plan_items_plan_id_day_index_slot`); more than one snack per day stays allowed. Migration `0002` (§11.8) | Yes (one index) |
| 72 | Four application rules left implicit | Current plan for a day = newest plan covering it (§11.7); `deleted_at` is server receive time, enabling delta sync (§33.4); the target for a local day = latest `valid_from` before the end of that day in the user's timezone (§30.5); one `dataset_version` per catalog release (§33.4) | No |
| 73 | Freeze mechanics | Committed migrations are immutable, enforced by a SHA-256 test in CI; post-freeze change policy (§20.1); tag `schema-v1` | No |

---

## CHANGELOG — v4.10 → v4.11

v4.11 closes **Step E** (integrity validation + CI, 2026-10-02, commit `79329b2`, DEV_JOURNAL J-027). **No new decision and no schema change**: the schema passed every test unchanged. The edits below record how the tests are built and correct one test example.

| Topic | Change | Schema? |
|---|---|---|
| §19 v4.8 example `lang = 'ARA'` | `VARCHAR(2)` rejects `'ARA'` for length (SQLSTATE `22001`) before the CHECK runs, so it does not prove `ck_meal_translations_lang_iso639_1`. Corrected: `'AR'` → rejected by the CHECK; `'ar'` → accepted; `'ara'` → rejected by length | No |
| §19 test infrastructure | New subsection "How the tests are built (Step E)" | No |
| §34.7 CI | Records the actual workflow (quality gates, second test database, skip = failure) | No |
| §24 / §25 | Steps D and E done; Step F (schema freeze) is current | No |

---

## CHANGELOG — v4.9 → v4.10

v4.10 settles the gaps found while explaining the target calculation of §30 (2026-10-02, guide `claude/guides/calorie_macro_targets_explained_2026-10-02.md`, DEV_JOURNAL J-026). The user approved #64–#67 and delegated #68–#69 to the assistant ("apply what is suitable and necessary"). **No schema change**: all items are application logic in §30, so Step E (in progress) is not affected. `formula_version` stays `targets_v1`, because §30 has not been implemented yet and no `user_targets` row exists.

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 64 | §30.4 gave protein as a range but stored a "single chosen value" without saying which | Use the **midpoint** of the range: `LOSE` 1.4, `MAINTAIN` 1.0, `GAIN` 1.8 g/kg | No |
| 65 | Protein per kg of actual weight overestimates for users with obesity | **Protein reference weight**: actual weight if BMI < 30; otherwise adjusted body weight `IBW + 0.4 × (W − IBW)` with `IBW = 25 × (H/100)²` (§30.4) | No |
| 66 | `ATHLETE` is an activity level, not a goal; the protein rule mixed both | `ATHLETE` uses 1.6–2.0 g/kg (midpoint 1.8) **whatever the goal**; other activity levels use the goal range | No |
| 67 | Carbohydrate is the remainder and could fall very low (calorie floor + high protein) | Carbohydrate minimum **130 g/day** (RDA, adults). If the remainder is lower: fat down toward 25%, then protein down toward the low end of its range; if still lower, the calorie floor wins and the case is logged (§30.4) | No |
| 68 | Fiber was only a diabetes minimum; no general fiber target existed | **General fiber target for every user: 14 g per 1000 kcal** of `target_kcal` (DRI). Computed, not stored in `user_targets`; frozen in `meal_plans.target_snapshot`; a **soft** target in the optimizer; not part of the day status (§30.4b). The `DIABETES_T2` condition minimum stays a hard limit | No |
| 69 | No sodium / sugar / saturated-fat limits for users without a condition | **Not added.** Accepted known limitation (§30.1): such limits stay condition-driven only. Reasons: the dataset has total `sugars`, not added sugars; hard limits for everyone shrink the candidate pool and raise infeasibility; the app is not a medical device | No |

---

## CHANGELOG — v4.8 → v4.9

v4.9 closes **Step C** (SQLAlchemy models, 2026-10-01). The 34 tables were implemented by Cursor in three reviewed passes (C-1 Reference `0024f8a`, C-2 Catalog `2d688dd`, C-3 User `7ea053f`). Each pass surfaced details the document left implicit; the user approved the resolutions below during the passes (DEV_JOURNAL J-024). No table was added or removed.

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 61 | FK delete policy for relationships §15.7 did not list | Default `RESTRICT` for every unlisted FK, **except** `food` → `food_nutrients`, `portions_food` = `CASCADE` (fully owned child data). Full list in §15.7 | Yes (FK actions) |
| 62 | FK index coverage and long names | Partial (`WHERE`) and GIN indexes do **not** count as FK coverage (§15.3) → plain `user_id` indexes on `consumption_logs`, `water_logs`; `refresh_tokens.replaced_by_token_id` indexed. A convention name longer than 63 characters gets a shorter explicit name (§17), e.g. `uq_condition_nutrient_limits_condition_nutrient_basis` | Yes (indexes, one name) |
| 63 | Nullability, defaults and small constraints left implicit | `meals.ref_external` nullable + `UNIQUE (source, ref_external)`; `meal_ingredients.text_original` and `meal_translations.description` nullable; defaults `meals.is_verified = false`, `meals.ingested_at = now()`, `meal_plan_items.was_swapped = false`, `user_interactions.context = '{}'` (NOT NULL), `refresh_tokens.issued_at = now()`; `weight_logs.updated_at` has **no** default (device time, §33.4); `condition_tag_restrictions` `max_servings_positive`; `foods.fdc_id` `INTEGER`. Columns not stated as nullable are `NOT NULL` | Yes (constraints/defaults) |

---

## CHANGELOG — v4.7 → v4.8

v4.8 records the **pre-Step-C consistency audit** of v4.7 (2026-10-01, report `claude/reviews/consistency_audit_v4_7_2026-10-01.md`, DEV_JOURNAL J-023). All items were approved by the user on 2026-10-01. They are applied before any model or migration exists, so there is no migration cost. Step B is closed (DEV_JOURNAL J-022, Decision #55: SQLAlchemy pinned `>=2.0,<2.1`).

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 56 | Primary-key types were unspecified; SQLAlchemy would default to `SERIAL` | Every surrogate PK is `BIGINT GENERATED ALWAYS AS IDENTITY` (§15.1). Client-generated identifiers (`client_uuid`, `family_id`) stay `UUID`. Phase 2 ETL links rows by natural keys (`external_code`, `code`), never by internal IDs | Yes (types) |
| 57 | PostgreSQL does not index FK columns automatically; 20+ FK columns had no index, including the hard-filtering path | Rule §15.3: every FK column is indexed unless it is the leading column of the PK, a UNIQUE constraint or an existing composite index; automated metadata test (§19, v4.8) | Yes (indexes) |
| 58 | `numeric` without precision; SQLAlchemy returns `Decimal`, the optimizer/ML work with `float` | Rule §15.2: measured values are `NUMERIC(12,3)`, mapped with `asdecimal=False` (Python `float`). Exceptions: `servings_multiplier` `NUMERIC(3,2)`; `*_confidence` `NUMERIC(4,3)`; naturally whole quantities stay `INTEGER` | Yes (types) |
| 59 | `meals.owner_user_id` made CATALOG depend on USER (violates §8), had no workable delete policy, and no Core feature uses user-owned meals | `meals.owner_user_id` and `meals.visibility` **removed**. All catalog meals are system meals. User-authored private meals moved to Documented Future Work (§29) as a separate table that respects the dependency direction | Yes (2 columns removed) |
| 60 | Implicit details that would force the coding agent to guess | Made explicit: `ON DELETE RESTRICT` on the three `meal_id` history FKs (§15.7); full enum-like column list (§17); types for `meals.servings`, `user_interactions.value`, `foods.data_type`, `meal_ingredients.mapping_confidence`, `ingredient_aliases.confidence/source`, `ingredients.review_status`; `meal_nutrients` NOT NULL + `>= 0`; `meal_ingredients.position >= 1`; language-code CHECK (§15.5); lowercase `users.email`; `refresh_tokens.issued_at` acts as `created_at` (§15.10); composite lookup indexes on `user_targets` and `meal_plans`; stale status text (§20, §24, §25) and `consumption_logs.client_uuid` placement fixed | Yes (constraints/indexes) |

---

## CHANGELOG — v4.6 → v4.7

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 54 | Gout requires purine data that USDA FoodData Central does not provide, plus a separate tagging effort and rules; the team judged the cost too high for the project | **Gout removed from the project entirely** (user decision, 2026-09-29): not a supported condition, not seeded as a recognized-unsupported condition, no purine data, no gout rules or tags. Supported conditions are now `DIABETES_T2`, `HYPERTENSION`, `HEART_DISEASE`. Accepted known limitation: a user with gout cannot declare it and receives a standard plan — stated in the disclaimer and in the thesis limitations (§30.1). The `ingredient_tags` / `condition_tag_restrictions` mechanism stays (used for e.g. `high_sodium`, `high_glycemic`) | No structural change (seed data and examples only) |

---

## CHANGELOG — v4.5 → v4.6

v4.6 records a **scope change** approved on 2026-09-29 after a change-impact analysis (DEV_JOURNAL J-019, J-020): water tracking moves from Documented Future Work into Core, with a fluid-safety rule for conditions where a clinician may restrict fluids; reminders are specified as on-device local notifications; a UI/UX direction is recorded; the chatbot stays deferred with its design constraints now fixed.

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 49 | Water tracking was Future Work (§18.10, §29); user requested it now. Adding it before the freeze costs one table; adding it after would reopen the frozen schema | **Scope change:** new append-only table `water_logs` (same pattern as `consumption_logs`: `client_uuid`, `log_date`, tombstone) + nullable `user_profiles.water_goal_ml`. Water is **not** part of the daily adherence status (§30.5 unchanged) | Yes |
| 50 | Heart-failure patients are often under clinician-ordered fluid restriction; "drink more" goals/reminders could harm them. CKD (recognized, unsupported) had the same issue *(CKD removed in v4.20, #167)* | **Fluid-safety rule (§30.7):** data-driven flag `health_conditions.fluid_goal_requires_clinician`; for flagged users no default water goal is computed, water reminders are off by default, a "consult your doctor" notice is shown, and only a user-entered (clinician-set) goal is used | Yes (1 column) |
| 51 | Reminders were mapped only to FCM (server push) | Water and **meal-logging** reminders are **local notifications** scheduled on the device (`flutter_local_notifications`), fully offline; reminder settings live on the device only (no table). FCM stays for server-initiated messages only | No |
| 52 | UI/UX quality was not an explicit direction; UX drives pilot data volume and the SUS score (§28.5) | UI/UX direction recorded (§29): RTL-first design, one-tap logging from the plan, progress rings/streaks derived from §30.5; inspired by principles of existing apps, never copying another product's visual identity. Wireframes may start in parallel; implementation in the app phase | No |
| 53 | Chatbot via a free LLM tier: the Gemini API unpaid-tier terms allow Google to use content for product improvement and human review, forbid sensitive/personal data and medical advice | Chatbot **stays deferred** (after F.1). Binding design constraints recorded in §29: free tier for development with synthetic data only; paid tier (or Claude API) for any real-user data; server-side calls only; topic guard + grounding via function calling; never bypasses Layer 1; fixed responses for medical emergencies; per-user rate limit. Open item: team budget for the paid tier — decided when the chatbot phase starts | No (tables stay deferred) |

---

## CHANGELOG — v4.4 → v4.5

v4.5 turns the professional-practices backlog (P-01…P-11, approved in principle) into **binding specifications**, after a change-impact analysis against the whole project (DEV_JOURNAL J-017, J-018). The analysis surfaced conflicts that are resolved here, including one gap in the v4.4 offline-sync design itself (#43).

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 42 | P-04 audit columns: `updated_at` is meaningless on append-only tables | **Audit-column rule by table class** (§15.10): mutable entities get `created_at` + `updated_at`; append-only/versioned rows get `created_at` only; pure junction/derived rows get none (parent or `computed_at` covers them) | Yes |
| 43 | Gap in v4.4 sync design: "logs are append-only, no conflicts" ignored that users must be able to **correct or delete** a wrong log, including offline | `consumption_logs.deleted_at` **tombstone** (soft delete); an edit = tombstone the old row + create a new row with a new `client_uuid`; tombstones sync by `client_uuid`; adherence ignores tombstoned rows (§11.9, §33.4) | Yes |
| 44 | Weight "last write wins" needs a comparable timestamp; same-day replacement is an update, not an insert | `weight_logs.updated_at` (client-supplied time of the edit, validated server-side); upsert on `(user_id, measured_on)`; newer `updated_at` wins (§11.10, §33.4) | Yes |
| 45 | P-05 refresh-token rotation with reuse detection needs server state; offline users must not lose queued logs when a token expires | New table `refresh_tokens` (hash only, family, expiry, revocation) in USER domain; access 15 min / refresh 30 days rotating; device keeps the upload queue until re-login (§11.12, §34) | Yes |
| 46 | P-11 explanations must work offline and must not come from bandit parameters | `meal_plan_items.reason_codes` JSONB: machine codes produced at plan time from Layer 1 rules and targets (e.g. `LOW_SODIUM`, `FITS_KCAL_TARGET`), rendered in Arabic/English on the device (§11.8, §28.6) | Yes |
| 47 | P-01 naming convention must exist before the first migration | Fixed `MetaData(naming_convention=…)` specified in §17; every CHECK constraint given an explicit short name | Yes (naming) |
| 48 | P-02, P-03, P-06, P-07, P-08, P-09, P-10 | Specified in §34 with their integration constraints (batch sync endpoint with its own limit; API↔drift mapper; env-based config; CI with migration round-trip) | No |

---

## CHANGELOG — v4.3 → v4.4

v4.4 records the results of a full programmatic compatibility audit of the five FNDDS 2021–2023 files against the v4.3 schema (§6), and the decisions that followed. All items were **approved by the user**.

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 37 | Does the app need a network connection? Can it work locally? | **Offline-first hybrid architecture** (§33): PostgreSQL + FastAPI server remains the system of record; the Flutter app keeps a local SQLite (`drift`) copy of the catalog and of the user's own data, works offline for viewing plans, logging food/weight and viewing progress, and syncs when connected. Plan generation and ML learning stay server-side. Provenance columns are plain stored text and never require a connection | Yes (small): `client_uuid` on offline-created rows |
| 38 | Import scope | **Curated subset only:** import only the ingredients/foods the team's recipes actually use (≈300–500), plus a small selected set of simple FNDDS foods as `SILVER` meals — not the whole of FNDDS (§31.2, §6.4) | No |
| 39 | `fdc_id` alone cannot identify every reference food (608 FNDDS sub-recipe foods and 16 FNDDS ingredients have no FDC ID; team/template foods have none) | Added `foods.external_source` + `foods.external_code`, `UNIQUE (external_source, external_code)`; `fdc_id` stays optional (§9.6) | Yes |
| 40 | §6.2 claimed 608 ingredient codes had no nutrition | **Corrected:** all 608 are FNDDS **sub-recipes** (FNDDS food codes used as ingredients, nesting depth up to 6) and **all 608 have complete per-100 g values** in `FNDDS Nutrient Values`. They are loaded as `foods` rows (`state = cooked`, `external_source = 'FNDDS_FOOD'`) when needed — no quarantine, no mapping problem (§6.2, §18.5) | No |
| 41 | Per-value provenance (`food_nutrients.value_source`) | **Deferred** — with a small curated dataset, food-level `source_reference` + `external_source/external_code` is sufficient (§18.8) | No |

---

## CHANGELOG — v4.2 → v4.3

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 34 | The app and its users are Muslim; non-permissible food must never exist in the system, so a per-ingredient permissibility state and filter are unnecessary | Permissibility column and its filtering rule **removed**. Replaced by an **ingestion-time exclusion policy**: non-permissible ingredients/foods are never loaded; uncertain ones are quarantined until resolved (§31.6). Permissibility is guaranteed by the data itself, not by a runtime filter | Yes (column removed) |
| 35 | Four detail decisions introduced during v4.2 drafting needed explicit approval | **Approved by the user:** `code` columns on `nutrients` / `dietary_tags`; `condition_tag_restrictions.max_servings_per_week`; `servings_multiplier` limited to (0.5, 1.0, 1.5, 2.0) | — (already in v4.2) |
| 36 | Technology direction | **All v4.2 technology decisions approved and adopted**, replacing the earlier ones: contextual bandit (LinUCB) as the primary ML component (replaces K-Means), OR-Tools CP-SAT / PuLP (replaces greedy as the primary optimizer; greedy kept only as a comparison baseline), optional supervised curation classifier, pre-trained embeddings + `pgvector` (optional, later), `uv`, `pytest` + `testcontainers`, `pg_trgm`, `pandera`, Riverpod, `drift`, FCM | No |

---

## CHANGELOG — v4.1 → v4.2

v4.2 incorporates a full consultant-style review of v4.1 against the product vision (goal-based targets, activity levels, chronic conditions, weekly plans, daily completion tracking, progress tracking, ML-based recommendation). All items below were **approved by the user** before being written here. Items #18–#28 change the Phase 1 schema and must be implemented **before** the schema freeze (Step F). Items #29–#33 are documentation/direction decisions (no Phase 1 tables).

| # | Topic | Resolution (short) | Schema? |
|---|---|---|---|
| 18 | `condition_nutrient_limits` could only express an absolute maximum; real rules need %-of-energy limits (e.g. saturated fat < 10% kcal) and minimums (e.g. fiber) | Added `limit_basis` (`ABSOLUTE` / `PERCENT_ENERGY`) and `min_per_day`; documented the multi-condition **strictest-limit-wins** rule (§9.5b, §28.2) | Yes |
| 19 | No weight history → no real progress tracking | New table `weight_logs` (§11.10); `user_profiles.weight_kg` removed — current weight = latest `weight_logs` row | Yes |
| 20 | Goal was only `goal_type` — no target weight, no rate, no safety limits | Added `user_profiles.target_weight_kg`, `weekly_rate_kg` + CHECKs; safety floors/caps documented as application rules (§30) | Yes |
| 21 | Two conflicting sources of truth for "was it eaten" (`meal_plan_items.was_consumed` vs `consumption_logs.servings_consumed`); no partial or off-plan logging | `consumption_logs` becomes the **single source of truth**: optional `plan_item_id`, nullable `meal_id`, direct `food_id + grams_consumed` for off-plan food, `log_date`, `nutrients_snapshot`. `was_consumed` **removed** (derived). Adherence is computed, not stored (§11.9, §30.5) | Yes |
| 22 | `target_*` columns in `user_profiles` were overwritten on every recompute → past days could not be evaluated against the targets valid at that time | New versioned table `user_targets` (§11.11); `target_*` columns **removed** from `user_profiles` | Yes |
| 23 | High-purine (and similar) is an **ingredient** property; manual tagging of meals is error-prone | New junction table `ingredient_tags` (§9.13); `meal_tags.source` (`MANUAL` / `DERIVED`) so recompute only replaces derived rows (§10.5) | Yes |
| 24 | `dietary_tags` mixed dietary, occasion and condition semantics in one flat list, and had no stable machine key | Added `dietary_tags.tag_group` (`DIETARY` / `OCCASION` / `CONDITION`) and `dietary_tags.code` UNIQUE (§9.4) | Yes |
| 25 | `meals.total_grams` had no defined meaning (raw sum vs cooked weight) → `amount_per_100g` could be wrong | `total_grams` = **final as-served (cooked) weight of the whole recipe**; new `meals.weight_method` (`WEIGHED` / `YIELD_FACTOR` / `SUM_OF_INGREDIENTS`) (§10.1, §10.3) | Yes |
| 26 | Teammate template collects only 5 macros → chronic-condition filtering would be impossible (no sodium, sat fat, cholesterol, sugars) | **Mandatory nutrient set** of 9 nutrients defined; `nutrients.code` UNIQUE stable key; `nutrients.is_mandatory`; missing ≠ zero rule (§9.7, §31.3) | Yes (small) + data requirement |
| 27 | Unsupported populations (under-18, insulin-treated diabetes; pregnancy, lactation and CKD were here until v4.20, #167) had no representation → app could generate plans for people the equations/rules do not cover | `user_profiles.physiological_status`; `health_conditions.is_supported`; screening rules (§30.1) | Yes |
| 28 | ML personalization and offline evaluation need impressions/accepts, not just views/swaps; Arabic search had no normalized field | `user_interactions.event_type` CHECK widened (`IMPRESSION`, `ACCEPT`); normalized Arabic search columns + `pg_trgm` (§11.6, §15.9) | Yes (small) |
| 29 | ML direction: K-Means as "the ML part" is academically weak; greedy optimizer cannot enforce weekly constraints | §28 rewritten: honest ML/non-ML classification; primary ML component = **contextual bandit personalization (LinUCB)** + optional supervised auto-tagging assistant; optimizer = **OR-Tools CP-SAT** (or PuLP MILP) | No (direction only) |
| 30 | Energy/target calculation had no documented scientific basis | §30: Mifflin-St Jeor, PAL multipliers, goal adjustment, calorie floors, rate caps, macro split, recompute triggers | No (application logic) |
| 31 | Root cause of the old failure (the meal database) had no documented content strategy | §31: Curated Recipe Catalog strategy (150–300 GOLD meals, FDC Foundation/SR Legacy, Arabic reference cross-check, LLM-draft rules, OFF deferred) | No (Phase 2 direction) |
| 32 | Supporting tools not selected | §32: technology additions with the phase in which each one is introduced | No |
| 33 | Risk of discovering integration problems late | New **Step F.1 — Vertical slice** after freeze (§25), no renumbering | No |

---

## CHANGELOG — v4 → v4.1

| # | Topic | Resolution (short) |
|---|---|---|
| 16 | `meal_plan_items.slot` recorded where a meal is *placed* in a plan, but nothing recorded whether a meal is actually *suitable* for that slot | Reuse `dietary_tags` + `meal_tags` with occasion tag values — refined in v4.2 by `tag_group = 'OCCASION'` |
| 17 | IDE coding agent was left as two options | Confirmed: **Cursor Pro** |

---

## CHANGELOG — v3 → v4

| # | Topic | Resolution (short) |
|---|---|---|
| 9 | No table stored ingredient-level allergen data | New junction table `ingredient_allergens` |
| 10 | (ingredient permissibility flag) | **Superseded in v4.3 by Decision #34** — replaced by an ingestion-time exclusion policy; no column |
| 11 | `foods` had no explicit raw/cooked distinction | `foods.state` (`raw`/`cooked`/`as_purchased`) |
| 12 | `foods` had no generic provenance field beyond `fdc_id` | `foods.source_reference` (required) |
| 13 | `health_conditions` could not restrict a diet | `condition_nutrient_limits` + `condition_tag_restrictions` |
| 14 | Feature wishlist had no scope boundary | MVP scoping in §29 |
| 15 | Recommendation assumed to be "one ML model" | 3-layer hybrid system (§28) — refined in v4.2 |

---

## 1. Project Identity

This is a graduation project (BSc Computer Science, Faculty of IT — team of three) for a mobile health and nutrition application whose purpose is to collect user information and preferences, represent health/dietary constraints, maintain a trustworthy structured food/meal dataset, compute each user's daily nutritional needs, and provide suitable meals and daily/weekly meal plans — including for users with common chronic conditions and allergies, so the app serves a wide segment of the population, not just healthy users. The app also tracks what the user actually eats, whether each day's targets were met, and the user's progress toward their goal.

### Current technology direction

- **Mobile:** Flutter
- **Backend:** FastAPI
- **ORM:** SQLAlchemy 2.0
- **Migrations:** Alembic
- **Database:** PostgreSQL (with `pg_trgm` enabled in the initial migration — §15.9)
- **Local PostgreSQL:** Docker Compose
- **Recommendation:** hybrid rules + ML personalization + mathematical optimization (see §28), deliberately postponed in implementation until the data foundation is stable
- **Deployment model:** offline-first hybrid — server is the system of record, the phone keeps a local SQLite copy and syncs (§33)
- **Supporting tools:** see §32

The database needs to be extensible without requiring a fundamental redesign every time a new feature is added.

---

# 2. CRITICAL — Fresh Rebuild, Not a Rewrite of the Old Project

### Do NOT
- reuse old database migrations
- patch the old SQLite/database schema
- assume the previous schema is authoritative
- import old synthetic users or generated ratings
- copy old ETL/import scripts merely because they already exist
- reproduce old tables without checking whether they belong in the new requirements
- begin by improving the previous recommendation algorithms
- make the new architecture dependent on the old repository

### What may be reused conceptually
- lessons learned
- requirements discovered through failure
- useful concepts that still satisfy the new requirements
- terminology where it remains appropriate
- evidence about data-quality problems
- general technology choices when they are still justified

### Core principle
> **The new project is designed from requirements and data requirements first. The old project is reference material, not the implementation foundation.**

---

# 3. The Main Problem We Are Solving Now

> **Data requirements determine the architecture and supported features; features do not dictate an unsuitable dataset.**

Current problem is **not** "how do we repair the old dataset?" — it is:

> **"How do we build a professional, normalized, extensible data architecture that can later be populated from trustworthy sources?"**

v4.2 note: the old project's main failure was a **content-strategy** failure (no trustworthy, licensed, gram-based meal source), not only a schema failure. The schema now supports the fix; the content strategy itself is recorded in §31 and executed in Phase 2.

---

# 4. Dataset Architecture vs Database Architecture

## 4.1 Database architecture — NOW
tables, columns, data types, primary keys, foreign keys, relationships, unique constraints, check constraints, indexes, source references, quality/status fields, multilingual support, nutrition representation, meal/ingredient representation, user-related structures, future extensibility.

The database can and should be created locally **before the final meal dataset exists**.

## 4.2 Dataset population — LATER

```text
Trusted Sources → Extract → Profile/Inspect → Structure → Normalize
→ Map to Reference Foods/Nutrients → Validate → Quality Control
→ Accept / Quarantine / Reject → Load into PostgreSQL
```

A teammate-built data-entry template (`ingredients_master_template.xlsx`) already demonstrates this discipline at the ingredient level: sequential external IDs, controlled category lists, mandatory `raw`/`cooked`/`as_purchased` state, mandatory allergen flags with no silent defaulting, mandatory `source_reference`, and an automatic macro-vs-calorie consistency check formula.

**v4.2 required template change (Decision #26):** the template must be extended from 5 macro columns to the full **mandatory nutrient set** (§9.7): add `sugars`, `saturated_fat`, `cholesterol`, `sodium`. `potassium` is recommended. An empty cell means *unknown*, never zero (§31.3).

---

# 5. Why the FNDDS Investigation Still Matters

USDA FNDDS 2021–2023 was downloaded and audited in Google Colab. Files investigated: `FNDDS Ingredients.xlsx`, `FNDDS Nutrient Values.xlsx`, `Foods and Beverages.xlsx`, `Ingredient Nutrient Values.xlsx`, `Portions and Weights.xlsx`.

Purpose was **not** to force FNDDS to become the final complete dataset, but to understand required fields, weight representability, food/nutrient/portion relationships, and source-data gaps. Audit reached **Step 10 — COMPLETE**.

---

# 6. FNDDS Audit Findings That Influence the New Architecture

## 6.1 Ingredient structure
- Ingredient rows: 18,584 | Unique ingredient codes: 2,336 | Foods with ingredient records: 5,431
- Missing/zero/negative ingredient weights: 0 | Valid positive weights: 18,584 (100% coverage)

**Architectural consequence:** ingredient quantity/weight must be a **first-class numeric value** (grams). Original text may be retained for traceability, but nutrition calculation must use normalized numeric data.

## 6.2 Nutrition structure — CORRECTED in v4.4 (Decision #40)
- Nutrition rows: 112,320 (1,728 NDB ingredients × 65 nutrients, **0 null values**) | Ingredients with FDC IDs: 1,712 | Unique FDC IDs: 1,822
- The 2,336 ingredient codes in `FNDDS Ingredients` are of two kinds:
  - **1,728 NDB ingredient codes** (basic ingredients) — **all** have nutrient rows in `Ingredient Nutrient Values`.
  - **608 FNDDS food codes used as ingredients (sub-recipes)**, incl. the 37 `999xxxxx` "… as ingredient" codes (e.g. "Chicken as ingredient in recipes") — affecting 4,214 ingredient rows / 2,578 foods. **All 608 have complete per-100 g values in `FNDDS Nutrient Values`.** Sub-recipe nesting depth: 0 levels for 2,853 foods, up to 6 levels at most.
- **Earlier conclusion ("608 codes without nutrition") was wrong** — they were never missing, they are resolved one level up.

**Decision:** when a selected recipe needs a sub-recipe, the sub-recipe is loaded as a `foods` row with its published per-100 g values (`state = cooked`, `external_source = 'FNDDS_FOOD'`, `external_code = <food code>`). No recursive flattening, no quarantine. Source files remain untouched.

## 6.3 Compatibility audit of all five FNDDS files — NEW in v4.4

| FNDDS file | Maps to | Result |
|---|---|---|
| `Ingredient Nutrient Values` (1,728 ingredients) | `foods` + `food_nutrients` | ✅ every ingredient has all 65 nutrients **including all 9 mandatory nutrients** (§9.7); 0 nulls. "Assumed zero" values (366) affect only non-mandatory vitamins/fatty acids |
| `FNDDS Ingredients` (18,584 rows) | `meal_ingredients` | ✅ 100% positive gram weights |
| `FNDDS Nutrient Values` (5,431 foods) | benchmark for `meal_nutrients`; values for sub-recipe `foods` | ✅ all 9 mandatory nutrients present for every food |
| `Moisture change (%)` column (976 foods) | `meals.total_grams` with `weight_method = YIELD_FACTOR` | ✅ `total_grams = Σ ingredient grams × (1 + moisture % / 100)` |
| `Retention code` (3,005 rows) | — | `calc_v1` ignores retention factors → our computed values will differ slightly from FNDDS published values (documented limitation, §10.3) |
| `Portions and Weights` (22,046 rows, 5,395 foods) | `portions_food`; default serving size for imported FNDDS meals | ✅ one zero-weight row ("Quantity not specified") → rejected |
| `Foods and Beverages` (5,432) | `meals` (selected subset only) | ⚠️ American-centric (172 WWEIA categories); few Middle-Eastern items (hummus, falafel, tabbouleh, couscous, bulgur, baklava, basbousa, stuffed grape leaves, kabob); **no Libyan dishes**; 508 generic "NFS/NS" entries not useful as meals |

Additional audit findings:
- **Provenance is per value, not per food:** one FNDDS ingredient can mix SR Legacy, Foundation, "Informed by …", "Nutrient as ingredient" and "Assumed zero" values; 109 ingredients use more than one FDC ID; 4,195 value rows have no FDC ID → `fdc_id` cannot be the only external identity (Decision #39).
- **Non-permissible content is common:** a first keyword/alcohol scan flags ≈734 of 5,432 foods (≈13.5%), 91 foods with alcohol > 0 g, and 106 NDB ingredients. Keyword scans produce false positives (e.g. "chicken sausage"), so §31.6 exclusion requires manual review of flagged items.
- **Energy consistency:** 58 foods deviate > 20% between stated kcal and 4/4/9/7 recomputation → review queue in the quality gate.
- **Units:** `mcg_RAE` / `mcg_DFE` are stored as unit `mcg`; the equivalence is part of the nutrient's name (`Vitamin A, RAE`, `Folate, DFE`) — no change to the unit CHECK.
- **No Arabic names:** every imported item needs `name_ar` / Arabic aliases.
- **License:** USDA FNDDS is public domain.

## 6.4 How FNDDS is used (Decision #38)
| Use | Decision |
|---|---|
| Reference layer (ingredients + nutrients + portions) | ✅ Primary source — but only for ingredients the team's recipes use (≈300–500) |
| Meals | ✅ A small selected subset of simple foods (breakfast items, dairy, breads, fruits, salads, the Middle-Eastern items above) as `SILVER`, after exclusion review and translation |
| Local / Libyan dishes | ❌ Not in FNDDS → team-authored `GOLD` recipes built on FNDDS ingredients (§31.2) |
| Validation | ✅ Published FNDDS per-100 g values used as a benchmark for our `calc_v1` results |

---

# 7. Current Objective — Database First, Data Later

## PHASE 1 — DATABASE ARCHITECTURE (CURRENT)
1. Define data domains → 2. entities → 3. tables → 4. columns → 5. PostgreSQL types → 6. PKs → 7. FKs → 8. composite keys → 9. unique constraints → 10. CHECK constraints → 11. indexes → 12. nullability → 13. relationship direction → 14. verify tables work together → 15. create PostgreSQL schema → 16. initial Alembic migration → 17. apply to clean local DB → 18. integrity tests → 19. freeze initial schema.

**Explicitly NOT part of Phase 1:** final meal collection, large dataset import, FNDDS cleanup, recommendation algorithms, bandit/embedding/optimizer implementation, synthetic rating generation, ML model training, chatbot implementation, sports/Ramadan features (see §29). *(Water tracking is in Phase 1 scope since v4.6 — Decision #49.)*

## PHASE 2 — DATASET BUILDING AND POPULATION (LATER)

```text
Source discovery → Source/license verification → Raw download → Immutable raw storage
→ Profiling → Field extraction → Normalization → Ingredient mapping → Nutrition mapping
→ Unit/gram conversion → Nutrition calculation → Quality gates
→ Accepted/Quarantine/Rejected → Database loading → Post-load validation → Dataset version freeze
```

Final data does not have to come exclusively from FNDDS — architecture must accept trustworthy data from FNDDS, USDA FoodData Central, teammate-prepared templates, team-authored recipes (§31), or other properly licensed/curated sources.

---

# 8. Authoritative Architecture

```text
┌──────────────────────┐
│ REFERENCE DOMAIN      │  Trusted food/nutrition definitions + health rules
└──────────┬────────────┘
           ↓
┌──────────────────────┐
│ CATALOG DOMAIN        │  Curated meals/recipes
└──────────┬────────────┘
           ↓
┌──────────────────────┐
│ USER DOMAIN           │  Profiles, targets, weight, plans, consumption, interactions
└──────────────────────┘
```

Dependency direction: **USER → CATALOG → REFERENCE**. Reference must never depend on Catalog or User. (`consumption_logs.food_id` is a USER → REFERENCE reference, which respects the direction.)

---

# 9. DOMAIN 1 — REFERENCE

## 9.1 `categories`
Food/category classification (used by `foods` only; NOT used for `meals`, which use `cuisine_id` + `meal_tags`).
- `category_id` PK, `name_en`, `name_ar`

Initial seed values (Phase 2 data): `grains_starches`, `legumes`, `vegetables`, `fruits`, `proteins_meat_poultry`, `proteins_seafood`, `dairy_eggs`, `fats_oils`, `nuts_seeds`, `spices_herbs`, `sweeteners`, `beverages`.

- `UNIQUE (name_en)` — **NEW in v4.14 (#77)**: the seed loader matches categories by name (for FDC data, the FDC food-category description), so a reload never duplicates them.

## 9.2 `cuisines`
- `cuisine_id` PK, `name_en`, `name_ar`
- `code` — **NEW in v4.14 (#77)** — `VARCHAR NOT NULL UNIQUE`, stable key used by seeds and the application (e.g. `LIBYAN`, `LEVANTINE`, `GENERAL`). Migration `0003` backfills existing rows from `name_en` (upper case, spaces → `_`).

## 9.3 `allergens`
- `allergen_id` PK, `name_en`, `name_ar`
- `code` — **NEW in v4.14 (#77)** — `VARCHAR NOT NULL UNIQUE` (e.g. `GLUTEN`, `TREE_NUTS`); same backfill rule as §9.2.

## 9.4 `dietary_tags` — CHANGED in v4.2 (Decision #24)
Reusable classification tags for meals and ingredients.
- `tag_id` PK
- `code` — **NEW** — `VARCHAR NOT NULL UNIQUE`, stable machine key used by application rules (e.g. `high_sodium`, `breakfast_suitable`, `vegetarian`). Application logic must reference tags by `code`, never by `tag_id` or display name.
- `name_en`, `name_ar`
- `tag_group` — **NEW** — `VARCHAR NOT NULL` + CHECK (`DIETARY`, `OCCASION`, `CONDITION`)
  - `DIETARY`: vegetarian, vegan, keto, …
  - `OCCASION`: meal time-suitability tags (§9.4b)
  - `CONDITION`: health-relevant food properties used by `condition_tag_restrictions` (e.g. `high_sodium`, `high_glycemic`)

The allowed tag set is determined during data-definition work (Phase 2 seed), not hard-coded in the schema.

### 9.4b Meal Occasion / Time-Suitability Tags (v4.1 Decision #16, refined in v4.2)

`meal_plan_items.slot` records *where* a meal is placed; occasion tags record whether a meal is *suitable* for that slot. Seed tags with `tag_group = 'OCCASION'`:
- `breakfast_suitable`, `lunch_suitable`, `dinner_suitable`, `snack_suitable`, `beverage`, `nuts_seeds_snack`

A meal may carry more than one occasion tag. Occasion tags are assigned **manually** at meal level (`meal_tags.source = 'MANUAL'`) — they are not derivable from ingredients. See §28.1 for the matching hard-filtering rule and §28.3 for the optional ML auto-tagging assistant.

## 9.5 `health_conditions` — CHANGED in v4.2 (Decision #27)
- `condition_id` PK
- `code` UNIQUE (`DIABETES_T2`, `HYPERTENSION`, `HEART_DISEASE`, `DIABETES_INSULIN`)
- `name_en`, `name_ar`
- `is_supported` — **NEW** — `BOOLEAN NOT NULL DEFAULT false`. `true` = the app has validated rules and may generate personalized plans for users with this condition. `false` = the condition is *recognized* (so users can declare it honestly) but the app does **not** generate personalized plans for such users (§30.1).
- `fluid_goal_requires_clinician` — **NEW in v4.6 (Decision #50)** — `BOOLEAN NOT NULL DEFAULT false`. `true` = a clinician may restrict this user's fluid intake, so the app never computes a default water goal and keeps water reminders off by default (§30.7). Seed: `true` for `HEART_DISEASE`, `false` for the others (v4.20, #167). Kept as data, not hard-coded condition codes in the app (§15.6).

In-scope supported conditions (§29): `DIABETES_T2`, `HYPERTENSION`, `HEART_DISEASE`. *(`GOUT` removed from the project in v4.7 — Decision #54; not seeded at all.)*
Recognized but unsupported (seed): `DIABETES_INSULIN` (insulin-treated diabetes — carbohydrate planning is tied to medication dosing). No other condition is recognized (v4.20, #167).

## 9.5b `condition_nutrient_limits` — CHANGED in v4.2 (Decision #18)
Turns a condition into enforceable numeric constraints.
- `id` PK
- `condition_id` FK → `health_conditions`
- `nutrient_id` FK → `nutrients`
- `limit_basis` — **NEW** — `VARCHAR NOT NULL` + CHECK (`ABSOLUTE`, `PERCENT_ENERGY`)
  - `ABSOLUTE`: values are in the nutrient's own unit (e.g. mg sodium).
  - `PERCENT_ENERGY`: values are % of energy — per-day values refer to the user's daily `target_kcal`; per-meal values refer to that meal's energy. Only valid for energy-yielding nutrients (fat, saturated fat, carbohydrate, sugars, protein) — validated in application/seed QC.
- `max_per_meal` (nullable, numeric)
- `max_per_day` (nullable, numeric)
- `min_per_day` — **NEW** — (nullable, numeric) e.g. minimum fiber
- `severity_note` (text, optional)
- `source_reference` — **NEW** — `TEXT NOT NULL` — which guideline the rule comes from (consistent with the provenance-first principle, §14)

Constraints:
- `CHECK (max_per_meal IS NOT NULL OR max_per_day IS NOT NULL OR min_per_day IS NOT NULL)`
- `CHECK (min_per_day IS NULL OR max_per_day IS NULL OR min_per_day <= max_per_day)`
- `CHECK` all non-null values `>= 0`; when `limit_basis = 'PERCENT_ENERGY'`, all non-null values `<= 100`
- `UNIQUE (condition_id, nutrient_id, limit_basis)`

Example rows (Phase 2 data, to be reviewed by a dietitian — §30.6): hypertension → `sodium` `ABSOLUTE` `max_per_day`; heart disease → `saturated_fat` `PERCENT_ENERGY` `max_per_day`, `cholesterol` `ABSOLUTE` `max_per_day`; diabetes → `carbohydrate` `ABSOLUTE` `max_per_meal`, `sugars` `PERCENT_ENERGY` `max_per_day`, `fiber` `ABSOLUTE` `min_per_day`.

Multi-condition resolution is application logic — see §28.2 (strictest limit wins).

## 9.5c `condition_tag_restrictions`
Condition rules expressed as "avoid/limit this kind of food".
- `id` PK
- `condition_id` FK → `health_conditions`
- `tag_id` FK → `dietary_tags` (application/seed QC: tag must have `tag_group = 'CONDITION'`)
- `restriction_type` — `AVOID` / `LIMIT` (VARCHAR + CHECK)
- `max_servings_per_week` — **NEW in v4.2** — nullable integer, meaningful only for `LIMIT` (`CHECK (restriction_type = 'LIMIT' OR max_servings_per_week IS NULL)`). Gives `LIMIT` an enforceable meaning for the optimizer (§28, Layer 3).
- `CHECK (max_servings_per_week IS NULL OR max_servings_per_week > 0)` (name `max_servings_positive`, v4.9, #63). A `LIMIT` row may leave it NULL.
- `UNIQUE (condition_id, tag_id)`
- `source_reference` — **NEW in v4.16 (#91)** — `TEXT NOT NULL`: the guideline or project rule each restriction comes from (§14); rows existing before migration `0004` are backfilled and then overwritten by the loader.

Example: hypertension → `LIMIT` `high_sodium`. Presence tags (e.g. `added_sugar`) are applied at ingredient level (`ingredient_tags`, §9.13) and propagated to meals; threshold tags (`high_sodium`, `high_sugar`) are derived at meal level from the meal's own nutrients (§10.5, v4.14 #74).

## 9.6 `foods`
`food_id` = internal PK, `fdc_id` = external USDA/FDC identifier (kept separate).
- `food_id` PK, `fdc_id` UNIQUE where applicable (nullable — the *primary* FDC ID when one exists), `description`, `data_type`, `category_id` FK, `basis_grams`
- `fdc_id` — `INTEGER` (v4.9)
- `data_type` — `VARCHAR` nullable — the source's own data-type label (e.g. FDC `foundation_food`), stored for traceability only; no CHECK (v4.8, #60)
- `external_source` — **NEW in v4.4 (Decision #39)** — `VARCHAR NOT NULL` + CHECK (initial set: `FNDDS_INGREDIENT`, `FNDDS_FOOD`, `FDC`, `TEAM_TEMPLATE`, `MANUAL`) — which source system the row was imported from
- `external_code` — **NEW in v4.4** — `VARCHAR NOT NULL` — the row's identifier inside that source (e.g. NDB number `1001`, FNDDS food code `99992405`, template ID `ING-0001`)
- `UNIQUE (external_source, external_code)` — prevents duplicate imports and gives every food a queryable way back to its source, with or without an FDC ID
- `state` — `raw` / `cooked` / `as_purchased` (VARCHAR + CHECK)
- `source_reference` — `TEXT NOT NULL`
- Constraint: `basis_grams = 100`

## 9.7 `nutrients` — CHANGED in v4.2 (Decision #26)
- `nutrient_id` PK
- `code` — **NEW** — `VARCHAR NOT NULL UNIQUE`, stable internal key (independent of any source's numbering)
- `source_code` — the external source's nutrient number (e.g. FDC nutrient number), nullable
- `name`, `unit` (CHECK: `g`, `mg`, `mcg`, `kcal`, `IU`)
- `is_mandatory` — **NEW** — `BOOLEAN NOT NULL DEFAULT false`

**Mandatory nutrient set (seed, `is_mandatory = true`):**

| `code` | unit | Why mandatory |
|---|---|---|
| `energy_kcal` | kcal | all targets |
| `protein` | g | macro targets |
| `carbohydrate` | g | macro targets, diabetes |
| `total_fat` | g | macro targets |
| `fiber` | g | diabetes (minimum), general quality |
| `sugars` | g | diabetes |
| `saturated_fat` | g | heart disease |
| `cholesterol` | mg | heart disease |
| `sodium` | mg | hypertension, heart disease |

Recommended (not mandatory): `potassium` (mg) for hypertension/DASH-style scoring.

A `foods` row may only be loaded into the accepted reference layer if it has a `food_nutrients` row for **every** mandatory nutrient (quality gate, Phase 2 — §31.3). This is enforced by the ingestion pipeline, not by a DB constraint.

## 9.8 `food_nutrients`
- `food_id` FK, `nutrient_id` FK, `amount_per_100g` (`NOT NULL`, `CHECK >= 0`)
- PK: `(food_id, nutrient_id)`
- **Missing ≠ zero:** an unknown value is represented by the *absence* of a row, never by `0`. `0` means "measured/known to be zero".
- **Consequences (v4.15, #82, #83):** a meal or food with an unknown mandatory nutrient is not recommended (§10.3) and cannot be logged; in Layer 1 an unknown amount of a limited nutrient counts as a violation (fail closed).
- Calculation model: `meal nutrient total = Σ (ingredient grams / 100) × food nutrient per 100 g`

Data-entry templates may collect the mandatory nutrients as wide columns; Phase 2 ETL pivots each row into `food_nutrients` rows.

## 9.9 `portions_food`
- `portion_id` PK, `food_id` FK, `unit_text`, `amount`, `gram_weight` (`CHECK > 0`)
- Example: `1 cup → 246 g`.

## 9.10 `ingredients`
Culinary ingredient concept layer.
- `ingredient_id` PK, `canonical_name`, `canonical_name_ar`, `default_food_id` FK → `foods`, `review_status`
- `review_status` — `VARCHAR NOT NULL DEFAULT 'PENDING'` + CHECK (`PENDING`, `APPROVED`, `REJECTED`) (v4.8, #60)
- `code` — **NEW in v4.16 (#91)** — `TEXT NOT NULL UNIQUE`, `CHECK (code ~ '^[A-Z][A-Z0-9_]*$')`: the ingredient's natural key (F-01, #77). Recipes reference ingredients by code, so changing an ingredient's `default_food_id` never breaks a recipe, and reloads are idempotent.

Every ingredient in this table is, by policy, permissible for the app's users — non-permissible ingredients are never ingested (Decision #34, §31.6). There is therefore no permissibility column and no permissibility filter anywhere in the system.

## 9.11 `ingredient_aliases` — CHANGED in v4.2 (Decision #28)
- `alias_id` PK, `ingredient_id` FK, `alias_text`, `lang`, `confidence`, `source`
- `confidence` — `NUMERIC(4,3)` nullable, `CHECK (confidence BETWEEN 0 AND 1)`; `source` — `VARCHAR` nullable, free-text provenance (v4.8, #60)
- `alias_normalized` — **NEW** — `TEXT NOT NULL`, normalized search form (§15.9), GIN `pg_trgm` index
- Uniqueness: `(alias_text, lang)`

## 9.12 `ingredient_allergens`
- `ingredient_id` FK → `ingredients`, `allergen_id` FK → `allergens`
- PK: `(ingredient_id, allergen_id)`

## 9.13 `ingredient_tags` — NEW in v4.2 (Decision #23)
Source of truth for ingredient-level **presence** properties — `tag_group = 'CONDITION'` tags such as `added_sugar`, and ingredient-level `DIETARY` facts where relevant. **Threshold tags (`high_sodium`, `high_sugar`) must never be stored here** (v4.14 #74): a pinch of salt would otherwise tag every savoury meal; they are derived per meal (§10.5) and the recompute raises if one appears here.
- `ingredient_id` FK → `ingredients` (CASCADE)
- `tag_id` FK → `dietary_tags` (RESTRICT)
- PK: `(ingredient_id, tag_id)`

`OCCASION` tags must **not** be stored here (they are meal-level judgments) — seed/application QC.

---

# 10. DOMAIN 2 — CATALOG

## 10.1 `meals` — CHANGED in v4.2 (Decisions #25, #28)
- `meal_id` PK
- `ref_external` — external/source identifier — nullable (team-authored recipes may have none); `UNIQUE (source, ref_external)` prevents importing the same recipe twice; NULLs are distinct (v4.9, #63)
- `name` — source-language name; `default_lang`
- `name_normalized` — **NEW** — normalized search form of `name` (§15.9), GIN `pg_trgm` index
- `servings` — `INTEGER NOT NULL` (v4.8); `total_grams` — `NUMERIC(12,3) NOT NULL`
- `weight_method` — **NEW** — `VARCHAR NOT NULL` + CHECK (`WEIGHED`, `YIELD_FACTOR`, `SUM_OF_INGREDIENTS`)
- *(`owner_user_id` and `visibility` removed in v4.8 — Decision #59: all catalog meals are system meals; user-authored meals are Future Work, §29)*
- `cuisine_id` FK → `cuisines`, nullable
- `source`, `source_license`
- `quality_tier` — `GOLD` / `SILVER`
- `is_verified` — `BOOLEAN NOT NULL DEFAULT false` (v4.9)
- `is_active` — `BOOLEAN NOT NULL DEFAULT true` (soft delete, §15.8)
- `ingested_at` — `TIMESTAMPTZ NOT NULL DEFAULT now()` (v4.9), `dataset_version`
- `variant_group` — **NEW in v4.14 (#76)** — `VARCHAR` nullable, indexed. Meals sharing a value are versions of one dish that differ in a main ingredient (e.g. `couscous`: lamb and chicken). Each version is a full meal with its own nutrients, allergens and tags, so Layer 1 and the daily limits check each one exactly. *(v4.15, F-07: in the F.1 slice the chicken versions have less saturated fat but slightly more cholesterol and sodium than the lamb versions, and `HEART_DISEASE` has daily limits only, so a difference shows in the daily check, not in Layer 1.)* The planner never places two meals of one group on the same day; the app's "switch meat" action swaps a plan item to a sibling of its group (`meal_plan_items.was_swapped = true`). Free ingredient substitution at use time is Future Work (§29).
- `yield_factor` — **NEW in v4.14 (#78)** — `NUMERIC(12,3)` nullable; `CHECK (yield_factor IS NULL OR (yield_factor > 0 AND yield_factor <= 3))`; `CHECK (weight_method = 'YIELD_FACTOR' OR yield_factor IS NULL)`. The loader sets it for every `YIELD_FACTOR` meal.
- `yield_factor_source` — **NEW in v4.14 (#78)** — `TEXT` nullable: where the factor comes from.
- `reviewed_by` — **NEW in v4.14 (#78)** — `TEXT` nullable: the team member who reviewed an LLM-drafted recipe (§31.4); `is_verified = (reviewed_by IS NOT NULL)` is enforced by the loader.

- `dish_form` — **NEW in v4.19 (#161, #165)** — `TEXT` nullable, CHECK (`ONE_DISH`, `PLATE`) (name `dish_form_valid`). `ONE_DISH` = ingredients cooked or mixed together; `PLATE` = separate components served side by side (#162). `NULL` = not yet documented (batch-01 meals until their steps are written).

Constraints: `servings > 0`, `total_grams > 0`

**`total_grams` definition (Decision #25):** the **final as-served weight of the whole recipe (all servings)** — i.e. after cooking, not the sum of raw ingredient weights. How it was obtained is recorded in `weight_method`:
- `WEIGHED` — the prepared dish was physically weighed (preferred for GOLD).
- `YIELD_FACTOR` — computed as Σ(raw ingredient grams) × a documented cooking yield factor (factor and its source stored in `meals.yield_factor` / `yield_factor_source`, v4.14).
- `SUM_OF_INGREDIENTS` — no-cook meals (salads, yogurt bowls, drinks) where weight does not change, and (v4.17, #105) cooked dishes whose added water is listed as an ingredient and stays in the dish (rice, pasta, stews). Dishes where water clearly evaporates use `YIELD_FACTOR`. Per-serving nutrients do not depend on this choice; `amount_per_100g` does.

## 10.2 `meal_ingredients`
- `meal_id` FK, `position`, `ingredient_id` FK, `food_id` FK (nullable when mapping not yet accepted)
- `grams` numeric NOT NULL — the weight **as added to the recipe**, in the `state` of the referenced `foods` row (normally `raw`)
- `text_original` (nullable — v4.9): the recipe's own wording of the ingredient (e.g. "حبوب الشربة" for a pasta food); the app shows it in the recipe, and the ingredient's canonical name elsewhere (v4.14 #79). `mapping_confidence` — `NUMERIC(4,3)` nullable, `CHECK (mapping_confidence BETWEEN 0 AND 1)` (v4.8)
- `is_optional` — **NEW in v4.14 (#75)** — `BOOLEAN NOT NULL DEFAULT false`: an ingredient people may leave out (e.g. lemon juice in ful). Nutrients are computed on the **full** recipe, including optional ingredients (the plan recommends the full recipe and the difference is small). Allergens of optional ingredients **still count** (safety first). Logging a meal without its optional ingredients is app-phase work. Water, salt, oil and an ingredient named in the dish's name are never optional (seed QC).
- PK: `(meal_id, position)`
- `CHECK (grams > 0)`, `CHECK (position >= 1)` (v4.8)

## 10.3 `meal_nutrients`
- `meal_id`, `nutrient_id`, `amount_per_serving`, `amount_per_100g`, `computed_at`, `computation_version`
- PK: `(meal_id, nutrient_id)`
- `amount_per_serving`, `amount_per_100g`, `computed_at`, `computation_version` — all `NOT NULL`; `CHECK (amount_per_serving >= 0)`, `CHECK (amount_per_100g >= 0)` (v4.8, #60)

Calculation (`calc_v1`):
```text
total(n)            = Σ over meal_ingredients (grams / 100) × food_nutrients(food_id, n)
amount_per_serving  = total(n) / servings
amount_per_100g     = total(n) / total_grams × 100
```
A meal is eligible for recommendation only if every mandatory nutrient could be computed (all ingredients mapped to foods that carry all mandatory nutrients). `calc_v1` does **not** apply nutrient retention factors for cooking losses — documented limitation; a later `calc_v2` may add them.

## 10.4 `meal_allergens`
Derived cache: `meal_id`, `allergen_id` — PK `(meal_id, allergen_id)`. Fully recomputed by application logic `recompute_meal_derived(meal_id)` from `meal_ingredients` ⋈ `ingredient_allergens` whenever a meal's ingredients change. Not a DB trigger.

## 10.5 `meal_tags` — CHANGED in v4.2 (Decision #23)
- `meal_id`, `tag_id` — PK: `(meal_id, tag_id)`
- `source` — **NEW** — `VARCHAR NOT NULL` + CHECK (`MANUAL`, `DERIVED`)
- `rule_version` — **NEW in v4.14 (#78)** — `VARCHAR` nullable; `CHECK (source = 'DERIVED' OR rule_version IS NULL)`. The tag-rules version that produced a `DERIVED` row (`tags_v2` since v4.17; `tags_v1` before), like `meal_nutrients.computation_version`.

Rules:
- `DERIVED` rows (v4.14 #74) = (a) the union of the meal's ingredients' `ingredient_tags` with `tag_group = 'CONDITION'` (presence tags, e.g. `added_sugar`; `DIETARY` ingredient tags are not unioned), plus (b) threshold tags from the meal's own `meal_nutrients.amount_per_100g`: `high_sodium` when sodium > 600 mg, `high_sugar` when sugars > 22.5 g (UK FSA front-of-pack "high" thresholds for foods). **`tags_v2` (v4.16 #97, built in G.3a):** a meal carrying the manual `beverage` tag uses the FSA drink thresholds per 100 ml instead — `high_sodium` > 300 mg, `high_sugar` > 11.25 g (100 ml ≈ 100 g assumed for water- and milk-based drinks). An unknown nutrient derives no threshold tag. Recomputed by the same `recompute_meal_derived(meal_id)` routine as `meal_allergens`, after `meal_nutrients`; recompute deletes and rebuilds **only** `DERIVED` rows. The seed loader runs it for every loaded meal.
- `MANUAL` rows = curator judgments (all `OCCASION` tags, most `DIETARY` tags). Never touched by recompute.
- If a curator manually adds a tag that is also derived, the `DERIVED` row wins on recompute (PK prevents duplicates; recompute upserts `source='DERIVED'`).

## 10.6 `meal_translations` — CHANGED in v4.2 (Decision #28)
- `meal_id`, `lang`, `name`, `description` — PK: `(meal_id, lang)`
- `description` — nullable (v4.9, #63); `meals` has no description column
- `name_normalized` — **NEW** — normalized search form (§15.9), GIN `pg_trgm` index

Holds only additional (non-default) languages. Fallback: `meals.name` + `meals.default_lang`.

## 10.7 `meal_steps` — NEW in v4.19 (Decisions #161, #165)
Ordered preparation steps of a meal, per language (schema.org `Recipe.recipeInstructions` as a list of `HowToStep`).
- `meal_id` FK → `meals` (CASCADE), `lang` (same `lang_check` as §10.6), `position` `SMALLINT NOT NULL`, `text` `TEXT NOT NULL`, `created_at`, `updated_at` — PK: `(meal_id, lang, position)`
- `CHECK (position >= 1)` (name `position_positive`), `CHECK (length(btrim(text)) > 0)` (name `text_not_blank`)
- Unlike §10.6, the default language is stored here too (a meal has no steps column). Loaded only by the catalog pipeline (#166); positions are 1..n with no gaps (pipeline gate, not a DB rule).

---

# 11. DOMAIN 3 — USER

## 11.1 `users`
- `user_id` PK, `email` UNIQUE, `hashed_password` (Argon2id — §34), `created_at`, `updated_at`
- `email` is stored lowercase: the application lowercases on write and `CHECK (email = lower(email))` (name `email_lowercase`) guarantees it, so the same address cannot register twice with different letter case (v4.8, #60)

## 11.2 `user_profiles` — CHANGED in v4.2 (Decisions #19, #20, #22, #27)
1:1 with `users`.
- `user_id` PK/FK
- `sex` — CHECK (`MALE`, `FEMALE`) — required by the energy equation (§30.2)
- `birth_date`
- `height_cm` — `CHECK (height_cm BETWEEN 100 AND 250)`
- `activity_level` — CHECK (`SEDENTARY`, `LIGHT`, `MODERATE`, `HIGH`, `ATHLETE`) — maps to PAL multipliers in §30.2
- `goal_type` — `LOSE` / `MAINTAIN` / `GAIN`
- `target_weight_kg` — **NEW** — nullable numeric, `CHECK (target_weight_kg BETWEEN 30 AND 300)`
- `weekly_rate_kg` — **NEW** — nullable numeric, `CHECK (weekly_rate_kg > 0 AND weekly_rate_kg <= 1.0)`
- `timezone` — **NEW** — IANA name (e.g. `Africa/Tripoli`), `NOT NULL` — needed to compute the user's local day for daily adherence
- `water_goal_ml` — **NEW in v4.6 (Decision #49)** — nullable integer, `CHECK (water_goal_ml BETWEEN 500 AND 5000)` (name `water_goal_range`). `NULL` = no user-entered goal; the app then derives the default goal (§30.7) unless the fluid-safety rule applies
- `wake_time`, `sleep_time` — **NEW in v4.19 (#145)** — `TIME NOT NULL`, defaults `07:00` and `23:00`, `CHECK (wake_time <> sleep_time)` (name `wake_sleep_differ`). Local times in the user's `timezone`; sleep may be after midnight (e.g. wake 07:00, sleep 01:00). Meal windows are computed from them in the service layer.
- `CHECK (goal_type = 'MAINTAIN' OR (target_weight_kg IS NOT NULL AND weekly_rate_kg IS NOT NULL))`

**Removed in v4.2:**
- `weight_kg` → current weight is the latest row in `weight_logs` (§11.10). One source of truth.
- `target_kcal`, `target_protein_g`, `target_carb_g`, `target_fat_g`, `targets_computed_at` → moved to versioned `user_targets` (§11.11).

Direction consistency between `goal_type` and `target_weight_kg` vs current weight (e.g. `LOSE` requires target < current) is validated in application logic, because current weight lives in another table.

## 11.3 `user_health_conditions`
- `id` PK, `user_id` FK, `condition_id` FK → `health_conditions`, `severity`, `diagnosed`
- `severity` — `VARCHAR` nullable + CHECK (`MILD`, `MODERATE`, `SEVERE`); `diagnosed` — `BOOLEAN NOT NULL DEFAULT false` (values made explicit in v4.8, #60; informational only — rules never read `severity`)
- `UNIQUE (user_id, condition_id)` — **NEW in v4.2**

## 11.4 `user_allergen_prefs`
- `user_id`, `allergen_id`, `severity` (`AVOID` / `SEVERE`) — PK: `(user_id, allergen_id)`

## 11.5 `user_ingredient_prefs`
- `user_id`, `ingredient_id`, `stance` (`LIKE` / `DISLIKE` / `EXCLUDE`) — PK: `(user_id, ingredient_id)`

## 11.6 `user_interactions` — CHANGED in v4.2 (Decision #28)
- `id`, `user_id`, `meal_id`, `event_type`, `value`, `context` JSONB, `created_at`
- `value` — `SMALLINT` nullable — the rating for `RATE` events: `CHECK (value IS NULL OR value BETWEEN 1 AND 5)` and `CHECK (event_type <> 'RATE' OR value IS NOT NULL)` (v4.8, #60)
- `event_type` CHECK widened to: `IMPRESSION`, `ACCEPT`, `VIEW`, `SAVE`, `RATE`, `COOK`, `SKIP`, `SWAP_OUT`, and (v4.19, #165) `PREF_LIKE`, `PREF_DISLIKE`, `PREF_CLEAR`
  - `PREF_*` — written in the same transaction as every change to `user_meal_prefs` (§11.14), so preference history is kept for training while the table holds only the current state
  - `SWAP_OUT` — `meal_id` is the replaced meal; `context.replaced_by` is the chosen one
  - `IMPRESSION` — the system showed/recommended this meal to the user (needed so the ML layer and its offline evaluation know what was offered, not only what was chosen)
  - `ACCEPT` — the user kept/accepted a recommended meal
- `context` — `JSONB NOT NULL DEFAULT '{}'` (v4.9, #63)
- `context` convention (documented, not enforced): `{"plan_id":…, "plan_item_id":…, "slot":…, "algorithm_version":…, "score":…, "position":…}`. Learning signals are recorded from the beta onward; safety filters (Layer 1) stay rule-based and a future ML layer only reorders safe options (§18). Planned vs eaten comes from `consumption_logs.plan_item_id` (§11.9). No synthetic ratings are ever stored.
- `client_uuid` — **NEW in v4.4 (Decision #37)** — `UUID` nullable, `UNIQUE` — generated on the phone when the event is recorded offline; makes sync idempotent (a retried upload never creates a duplicate)
- Index: `(user_id, created_at)`
- This table is **data collection only** — no ML tables are created in Phase 1 (§18).

## 11.7 `meal_plans`
- `plan_id`, `user_id`, `date_from`, `date_to`, `generated_by`, `algorithm_version`, `target_snapshot` JSONB
- `target_id` — **NEW in v4.2** — FK → `user_targets` (nullable, SET NULL): which target version the plan was generated against. `target_snapshot` stays as an immutable copy (including the resolved condition limits at generation time).
- `CHECK (date_to >= date_from)`
- Index: `(user_id, date_from)` (v4.8, #60)
- **Current plan rule (v4.12, #72):** plans are never deleted when a new one is generated for days an older plan already covers. For a given user and day, the **current** plan is the newest one (`created_at`, ties broken by the larger `plan_id` — v4.15, #85) whose `date_from … date_to` covers that day; older plans stay as history so `consumption_logs.plan_item_id` links are never broken. Plan completion (§30.5) counts only the current plan's items.

## 11.8 `meal_plan_items` — CHANGED in v4.2 (Decision #21)
- `id`, `plan_id`, `day_index`, `slot`, `meal_id`, `servings_multiplier`, `was_swapped`, `created_at`, `updated_at`
- `was_swapped` — `BOOLEAN NOT NULL DEFAULT false` (v4.9)
- `reason_codes` — **NEW in v4.5 (Decision #46)** — `JSONB NOT NULL DEFAULT '[]'` — list of explanation codes generated at plan time from Layer-1 rules and targets (§28.6); cached with the plan so explanations work offline
- `slot` CHECK (`BREAKFAST`, `LUNCH`, `DINNER`, `SNACK`); Ramadan mode later widens it (`SUHOOR`, `IFTAR`) — §29
- `servings_multiplier` — `CHECK (servings_multiplier IN (0.5, 1.0, 1.5, 2.0))` — discrete steps, matching the optimizer's decision variables (§28, Layer 3)
- `CHECK (day_index >= 0)`
- Partial unique index `(plan_id, day_index, slot) WHERE slot <> 'SNACK'` (name `ix_meal_plan_items_plan_id_day_index_slot`) — one breakfast, lunch and dinner per plan day; several snacks allowed (v4.12, #71, migration `0002`). The plain `(plan_id)` index stays for FK coverage (§15.3: partial indexes do not count).
- **Removed:** `was_consumed` — now derived: an item is consumed iff a `consumption_logs` row references it via `plan_item_id` (§11.9).
- **Swap rules (v4.15, #84):** the new meal must pass Layer 1 (§28.1) for the item's slot at the item's multiplier, with the user's condition limits resolved at the kcal frozen in the plan's `target_snapshot`; inside the plan day it must not repeat a meal or add a second meal of one `variant_group`, and the day totals must stay within every resolved `max_per_day` and `LIMIT` servings. A swap is refused once the item has an active log. On success: `meal_id` changes, `was_swapped = true`, `reason_codes` are recomputed, `updated_at` = service time; `target_snapshot` never changes.

## 11.9 `consumption_logs` — CHANGED in v4.2 (Decision #21) — single source of truth for what was eaten
- `id` PK
- `user_id` FK
- `consumed_at` — `TIMESTAMPTZ NOT NULL`
- `log_date` — `DATE NOT NULL` — the user's **local** calendar day (computed from `consumed_at` + `user_profiles.timezone` at write time); daily adherence groups by this column
- `slot` — nullable, same CHECK set as `meal_plan_items.slot`
- `plan_item_id` — FK → `meal_plan_items`, nullable, `ON DELETE SET NULL`
- `meal_id` — FK → `meals`, **nullable** (was NOT NULL)
- `food_id` — **NEW** — FK → `foods`, nullable — for off-plan / off-catalog food logged directly
- `servings_consumed` — nullable numeric (for meals; supports partial, e.g. 0.5)
- `grams_consumed` — **NEW** — nullable numeric (for foods)
- `created_at` — `TIMESTAMPTZ NOT NULL` (server receive time)
- `entry_group` — **NEW in v4.19 (#165); reserved, never written by the API — the off-catalog dish entry is Future Work (v4.21, #172/#203)** — `UUID` nullable, indexed: rows with the same value are one eaten dish entered as ingredients (off-catalog); set by the phone, only on `food_id` rows: `CHECK (entry_group IS NULL OR food_id IS NOT NULL)` (name `entry_group_food_only`)
- `entry_label` — **NEW in v4.19 (#165)** — `TEXT` nullable, the user's name for that dish (e.g. a restaurant meal); `CHECK (entry_label IS NULL OR (entry_group IS NOT NULL AND length(btrim(entry_label)) > 0))` (name `entry_label_needs_group`). The same label is repeated on every row of the group.
- `deleted_at` — **NEW in v4.5 (Decision #43)** — `TIMESTAMPTZ` nullable — **tombstone**: a log is never physically deleted or edited; a correction tombstones the old row and inserts a new one (new `client_uuid`). Adherence, summaries and ML rewards ignore rows with `deleted_at IS NOT NULL`
- `client_uuid` — **NEW in v4.4 (Decision #37)** — `UUID` nullable — generated on the phone for offline-created logs; idempotent sync (listed here as a column in v4.8; previously under Constraints)
- `nutrients_snapshot` — **NEW** — `JSONB NOT NULL` — the consumed amounts of the mandatory nutrients, computed at log time with the then-current `computation_version` (so later recomputation of meals never rewrites history; same pattern as `target_snapshot`)

Constraints:
- Exactly one target: `CHECK ((meal_id IS NOT NULL) <> (food_id IS NOT NULL))`
- `CHECK (meal_id IS NULL OR (servings_consumed > 0 AND grams_consumed IS NULL))`
- `CHECK (food_id IS NULL OR (grams_consumed > 0 AND servings_consumed IS NULL))`
- `CHECK (plan_item_id IS NULL OR meal_id IS NOT NULL)`
- `UNIQUE (client_uuid)`
- Index: `(user_id, log_date) WHERE deleted_at IS NULL` (partial index — active logs only) + plain index `(user_id)` for FK coverage (v4.9, #62)

Application rule: when `plan_item_id` is set, `meal_id` must equal that plan item's `meal_id` (a swapped meal is recorded by first updating the plan item, `was_swapped = true`).

**Logging rules (v4.15, #83):**
- Every log carries a `client_uuid`. A repeated `client_uuid` with identical content (user, target, amount, `consumed_at`, `slot`) returns the existing row (`duplicate`); with different content it is rejected (`conflict`). A tombstoned row keeps its uuid, so a new log always needs a new uuid.
- `nutrients_snapshot` = `{"computation_version": "calc_v1", "nutrients": {<mandatory nutrient code>: "<exact decimal string>"}}` with exactly the mandatory nutrients (§9.7): meal = `amount_per_serving × servings_consumed`; food = `amount_per_100g × grams_consumed / 100`. Computed once, never rewritten.
- A meal that is not nutritionally complete, or a food with an unknown mandatory nutrient, cannot be logged (§9.8). Inactive meals can be logged (the user ate them).
- A plan item has at most one active log; logging it again needs a tombstone first. Partial and larger-than-planned servings are allowed.
- A correction tombstones the old row and inserts a new one for the **same** meal/food/plan item; changing what was eaten is a delete plus a new log.

## 11.10 `weight_logs` — NEW in v4.2 (Decision #19)
- `id` PK
- `user_id` FK (CASCADE)
- `measured_on` — `DATE NOT NULL`
- `weight_kg` — numeric, `CHECK (weight_kg BETWEEN 20 AND 400)`
- `source` — CHECK (`MANUAL`) — widened later if device sync is added
- `created_at`
- `updated_at` — **NEW in v4.5 (Decision #44)** — `TIMESTAMPTZ NOT NULL` — time of the last edit as recorded on the device (server rejects values in the future beyond a small clock-skew tolerance)
  - No server default and no ORM `onupdate`: the client must send it; a server-supplied time could wrongly win last-write-wins (v4.9, #63)
- `UNIQUE (user_id, measured_on)` — one value per day; a same-day entry is an **upsert**, and the row with the newer `updated_at` wins (last-write-wins, §33.4)

**Weight rules (v4.15, #86):** `updated_at` may not be later than server time + 5 minutes (clock-skew tolerance); `measured_on` after the user's local today is rejected; a same-day write with an equal or older `updated_at` is ignored (last-write-wins).

Current weight = row with the latest `measured_on`. Onboarding writes the first row. Future body measurements (waist, body-fat %) are Documented Future Work, not a Phase 1 table.

## 11.11 `user_targets` — NEW in v4.2 (Decision #22)
Versioned history of computed daily targets.
- `target_id` PK
- `user_id` FK (CASCADE)
- `valid_from` — `TIMESTAMPTZ NOT NULL`
- `valid_to` — `TIMESTAMPTZ` nullable (`NULL` = current)
- `based_on_weight_kg` — numeric NOT NULL (snapshot of the weight used)
- `bmr_kcal`, `tdee_kcal`, `target_kcal`, `target_protein_g`, `target_carb_g`, `target_fat_g` — numeric NOT NULL, all `> 0`
- `formula_version` — e.g. `targets_v1` (§30)
- `reason` — CHECK (`INITIAL`, `WEIGHT_UPDATE`, `GOAL_CHANGE`, `PROFILE_CHANGE`, `FORMULA_CHANGE`)
- `was_floor_applied` — BOOLEAN NOT NULL — whether the calorie floor (§30.3) overrode the raw calculation (traceability for the report)
- `CHECK (valid_to IS NULL OR valid_to > valid_from)`
- Partial unique index: `UNIQUE (user_id) WHERE valid_to IS NULL` — exactly one current target per user
- Index: `(user_id, valid_from)` — history lookups (v4.8, #60)

Condition limits are **not** copied here — they are resolved at plan-generation time and frozen in `meal_plans.target_snapshot`.

## 11.12 `refresh_tokens` — NEW in v4.5 (Decision #45)
Server state for refresh-token rotation with reuse detection (§34.2).
- `token_id` PK
- `user_id` FK → `users` (CASCADE)
- `token_hash` — `TEXT NOT NULL UNIQUE` — SHA-256 of the token; the raw token is **never** stored
- `family_id` — `UUID NOT NULL` — all tokens produced by rotating one login session share a family
- `issued_at` — `TIMESTAMPTZ NOT NULL` — also serves as the row's creation time (no separate `created_at`, §15.10)
- `expires_at` — `TIMESTAMPTZ NOT NULL`, `CHECK (expires_at > issued_at)`
- `revoked_at` — `TIMESTAMPTZ` nullable
- `replaced_by_token_id` — FK → `refresh_tokens` (SET NULL), nullable
- Index: `(user_id)`, `(family_id)`, `(replaced_by_token_id)` (FK coverage, v4.9)
- `issued_at` default `now()` (v4.9)

Rule: using a refresh token that was already rotated (reuse) revokes the **whole family** — standard theft detection.

## 11.13 `water_logs` — NEW in v4.6 (Decision #49)
Append-only log of drinking water, same pattern as `consumption_logs` (§11.9).
- `id` PK
- `user_id` FK → `users` (CASCADE)
- `consumed_at` — `TIMESTAMPTZ NOT NULL`
- `log_date` — `DATE NOT NULL` — user's local day (from `consumed_at` + `user_profiles.timezone` at write time)
- `amount_ml` — integer `NOT NULL`, `CHECK (amount_ml BETWEEN 1 AND 2000)` (name `amount_range`) — one drink, not a daily total
- `client_uuid` — `UUID` nullable, `UNIQUE` — idempotent offline sync (§33.4)
- `created_at` — `TIMESTAMPTZ NOT NULL` (server receive time)
- `deleted_at` — `TIMESTAMPTZ` nullable — tombstone; corrections = tombstone + new row (same rule as §11.9)
- Index: `(user_id, log_date) WHERE deleted_at IS NULL` (partial index) + plain index `(user_id)` for FK coverage (v4.9, #62)

Daily water total = `SUM(amount_ml)` of active rows for `(user_id, log_date)` — computed, not stored (§18.11). Water is shown next to adherence but does **not** change the day status of §30.5. Only plain water is logged here; other beverages with energy/nutrients are logged as foods/meals in `consumption_logs`. Reminder settings are **not** stored in the database (Decision #51).

## 11.14 `user_meal_prefs` — NEW in v4.19 (Decisions #149, #165)
Current like/dislike state of a user for a catalog meal (state, not an event log; see the v4.19 changelog).
- `user_id` FK → `users` (CASCADE), `meal_id` FK → `meals` (RESTRICT, indexed — soft-delete protected like §11.6), `stance` `TEXT NOT NULL` CHECK (`LIKE`, `DISLIKE`) (name `stance_valid`), `created_at`, `updated_at` — PK: `(user_id, meal_id)`
- Removing a preference deletes the row; every change is also logged in `user_interactions` as `PREF_LIKE` / `PREF_DISLIKE` / `PREF_CLEAR` (§11.6). `DISLIKE` is a hard exclusion in Layer 1; `LIKE` is a small bonus in the planner objective (implemented in I.5; users without rows plan exactly as before).


## 11.15 `user_cuisine_prefs` — NEW in v4.19 (Decision #165)
Cuisines the user would like to see more of in plans (soft preference).
- `user_id` FK → `users` (CASCADE), `cuisine_id` FK → `cuisines` (RESTRICT, indexed), `created_at` — PK: `(user_id, cuisine_id)`
- No rows = no preference (all cuisines equal). The planner gives meals of a preferred cuisine a small objective bonus (I.5); it never excludes other cuisines, so safety rules and nutrient targets keep priority (see the v4.19 changelog).
---

# 12. Relationship Map

```text
REFERENCE

categories ────────< foods
                       │
                       ├────< food_nutrients >──── nutrients
                       │
                       └────< portions_food

foods <──────────── ingredients
                       │
                       ├────< ingredient_aliases
                       ├────< ingredient_allergens >──── allergens
                       └────< ingredient_tags >──────── dietary_tags        (NEW — v4.2)

health_conditions ──< condition_nutrient_limits >──── nutrients
health_conditions ──< condition_tag_restrictions >──── dietary_tags


CATALOG

meals >──── cuisines      (no USER reference — v4.8, Decision #59)
                        │
                        ├────< meal_ingredients >──── ingredients
                        │             │
                        │             └────────────── foods
                        │
                        ├────< meal_nutrients >────── nutrients
                        ├────< meal_allergens >────── allergens       (derived)
                        ├────< meal_tags >─────────── dietary_tags    (MANUAL + DERIVED)
                        ├────< meal_translations
                        └────< meal_steps                              (NEW — v4.19)


USER

users ───── 1:1 ───── user_profiles
  │
  ├────< weight_logs                                               (NEW — v4.2)
  ├────< refresh_tokens                                            (NEW — v4.5)
  ├────< water_logs                                                (NEW — v4.6)
  ├────< user_targets                                              (NEW — v4.2)
  ├────< user_health_conditions >──── health_conditions
  ├────< user_allergen_prefs >──── allergens
  ├────< user_ingredient_prefs >── ingredients
  ├────< user_meal_prefs >──────── meals   (soft-delete protected)    (NEW — v4.19)
  ├────< user_cuisine_prefs >───── cuisines                           (NEW — v4.19)
  ├────< user_interactions >────── meals   (soft-delete protected)
  ├────< meal_plans ────────────── user_targets (target_id)
  │          └────< meal_plan_items >──── meals   (soft-delete protected)
  │                        ▲
  │                        │ plan_item_id (optional)
  └────< consumption_logs ─┴──── meals (optional, soft-delete protected)
                           └──── foods (optional — off-plan food)
```

---

# 13. Source Data and Future Dataset Management

```text
data/
├── raw/
│   ├── FNDDS/
│   ├── FDC/
│   ├── teammate_ingredient_templates/
│   ├── team_recipes/
│   └── other_sources/
│
├── processed/
│   ├── accepted/
│   ├── quarantine/
│   └── excluded/
│
└── reference/
```

**Raw:** immutable, never silently edited (v4.16, #92: large raw downloads stay outside git under `backend/data/raw/`; git holds a manifest with URL + SHA-256 and the extracted subset actually used). **Processed:** transformation/mapping/QC/exclusion happens outside authoritative reference tables. **Accepted:** only validated data. **Quarantine:** unresolved/review-required records (including foods missing a mandatory nutrient and ingredients of uncertain permissibility — §31.6). **Excluded:** records that cannot satisfy requirements, provenance preserved.

---

# 14. Data Provenance Is a First-Class Requirement

Internal identity ≠ external source identity. Meals preserve `ref_external`; reference foods carry `external_source` + `external_code` (v4.4). `foods.source_reference` covers non-FDC sources and manual estimates. `condition_nutrient_limits.source_reference` (v4.2) records which clinical guideline each rule comes from. LLM-assisted drafts are recorded explicitly as such (§31.4).

---

# 15. Core Database Design Principles

## 15.1 Internal IDs vs external IDs
Never make a source identifier the internal identity. Applies to teammate template IDs (`ING-0001`) too. Stable machine **codes** (`nutrients.code`, `dietary_tags.code`, `health_conditions.code`) are internal, project-owned keys for application rules — distinct from both PKs and source IDs.

**PK type (v4.8, Decision #56):** every surrogate PK is `BIGINT GENERATED ALWAYS AS IDENTITY` (SQLAlchemy: `mapped_column(BigInteger, Identity(always=True), primary_key=True)`); FK columns referencing them are `BIGINT`. Composite PKs of junction tables are made of those FKs. Identifiers generated on the phone (`client_uuid`, `refresh_tokens.family_id`) are `UUID`. Data loading (Phase 2) never supplies internal IDs; it resolves rows by natural keys (`external_source` + `external_code`, `code`).

## 15.2 Numeric measurements must be numeric
grams, nutrition amounts, portion weights, servings, weights, targets — always numeric types.

**Precision rule (v4.8, Decision #58):**

| Kind of value | Type |
|---|---|
| Measured/computed amounts (grams, nutrient amounts, weights, energy, targets, servings consumed) | `NUMERIC(12,3)` |
| `meal_plan_items.servings_multiplier` | `NUMERIC(3,2)` |
| `condition_nutrient_limits.max_per_meal` / `max_per_day` / `min_per_day` | `NUMERIC(12,3)` like other amounts (e.g. sodium `2300` mg; `PERCENT_ENERGY` values are additionally capped at `100` by CHECK) |
| `*_confidence` columns | `NUMERIC(4,3)`, range 0–1 |
| Naturally whole quantities (`servings`, `water_goal_ml`, `amount_ml`, `day_index`, `position`, `max_servings_per_week`) | `INTEGER` / `SMALLINT` |

All `Numeric` columns are mapped with `asdecimal=False`, so application code works with Python `float`; the database keeps exact decimal storage, and CHECK constraints compare exact values.

## 15.3 Constraints protect the dataset
`NOT NULL`, `FOREIGN KEY`, `UNIQUE`, `CHECK`, appropriate indexes.

**FK index rule (v4.8, Decision #57):** PostgreSQL does not create an index for a foreign key. Every FK column gets an index (`index=True`, named by the §17 convention) **unless** it is the leading column of the table's PK, of a UNIQUE constraint, or of a composite index already declared (leftmost-prefix rule). Example: in `meal_tags` PK `(meal_id, tag_id)` covers `meal_id`, so `tag_id` needs its own index — this is the hard-filtering path (§28.1). An automated test enforces the rule (§19, v4.8). **Partial and GIN indexes do not count as coverage** (PostgreSQL cannot use them for the lookups behind FK actions) — v4.9, #62.

## 15.4 Normalize first, denormalize only deliberately
Intentional derived/snapshot structures and their justification:
- `meal_allergens`, `meal_tags (DERIVED)` — fast filtering; fully recomputable from ingredient-level sources.
- `meal_plans.target_snapshot`, `consumption_logs.nutrients_snapshot` — **historical immutability**; they record what was true at that moment and must never be recomputed.

## 15.5 Multilingual support belongs in the data model
`name_en` / `name_ar` for small controlled reference entities; translation tables for scalable content.

**Language codes (v4.8, #60):** `meals.default_lang`, `meal_translations.lang` and `ingredient_aliases.lang` are ISO 639-1 codes: `VARCHAR(2) NOT NULL` + `CHECK (<col> ~ '^[a-z]{2}$')`. The set of languages is not restricted by the schema.

## 15.6 Do not encode business rules only in application code
Integrity rules in the DB (CHECK, FK). Health rules live in the DB **as data** (`condition_*` tables); *applying* them is application logic (traceable, testable, no PL/pgSQL).

## 15.7 Foreign Key delete/update policy

| Relationship | On delete of parent | Rationale |
|---|---|---|
| `meal` → `meal_ingredients`, `meal_nutrients`, `meal_allergens`, `meal_tags`, `meal_translations` | `CASCADE` | Fully owned child data |
| `ingredient` referenced by `meal_ingredients` | `RESTRICT` | Deprecate, don't delete |
| `ingredient` → `ingredient_allergens`, `ingredient_tags`, `ingredient_aliases` | `CASCADE` | Fully owned child data |
| `dietary_tags` referenced by `meal_tags`, `ingredient_tags`, `condition_tag_restrictions` | `RESTRICT` | A tag in use by rules/data must not vanish silently |
| `food` → `food_nutrients`, `portions_food` (NEW v4.9, #61) | `CASCADE` | Fully owned child data |
| `food` referenced by `ingredients.default_food_id` | `SET NULL` | Ingredient concept survives |
| `food` referenced by `meal_ingredients.food_id` | `SET NULL` | Uncertain mappings shouldn't break the meal |
| `food` referenced by `consumption_logs.food_id` | `RESTRICT` | Never corrupt user history |
| `health_conditions` → `condition_nutrient_limits`, `condition_tag_restrictions` | `CASCADE` | Fully owned rule data |
| `health_conditions` referenced by `user_health_conditions` | `RESTRICT` | Users' declared conditions must not vanish |
| `user` → `user_profiles`, `weight_logs`, `water_logs`, `user_targets`, `refresh_tokens`, `user_health_conditions`, `user_allergen_prefs`, `user_ingredient_prefs`, `user_interactions`, `meal_plans`, `consumption_logs` | `CASCADE` | Fully owned by the user (account deletion) |
| `meal_plans` → `meal_plan_items` | `CASCADE` | Fully owned |
| `meal_plan_items` referenced by `consumption_logs.plan_item_id` | `SET NULL` | Eating history survives plan deletion |
| `user_targets` referenced by `meal_plans.target_id` | `SET NULL` | Snapshot remains in `target_snapshot` |
| `meal` referenced by `user_interactions` / `meal_plan_items` / `consumption_logs` | `RESTRICT` (explicit, v4.8) — and **no hard delete, §15.8** | Preserve user history; RESTRICT is the safety net if a hard delete is ever attempted |

**Default for any FK not listed above (v4.9, #61): `RESTRICT`.** These are: `foods.category_id`, `food_nutrients.nutrient_id`, `condition_nutrient_limits.nutrient_id`, `ingredient_allergens.allergen_id`, `meals.cuisine_id`, `meal_nutrients.nutrient_id`, `meal_allergens.allergen_id`, `user_allergen_prefs.allergen_id`, `user_ingredient_prefs.ingredient_id`. Reference/classification rows in use must not vanish silently.

## 15.8 Meals use soft delete, never hard delete
`meals.is_active BOOLEAN NOT NULL DEFAULT true`. Inactive meals are excluded from search/recommendation but remain intact for history.

## 15.9 Arabic-aware search — NEW in v4.2 (Decision #28)
PostgreSQL `unaccent` does not normalize Arabic. Search therefore uses **normalized columns** (`ingredient_aliases.alias_normalized`, `meals.name_normalized`, `meal_translations.name_normalized`) filled by one application-level function `normalize_search_text()` (single implementation, unit-tested) and indexed with GIN `gin_trgm_ops` (`pg_trgm` extension created in the initial migration).

Normalization rules (v1): lowercase Latin; strip Arabic diacritics (tashkeel) and tatweel; unify `أ إ آ ٱ → ا`; `ة → ه`; `ى → ي`; `ؤ → و`, `ئ → ي`; collapse whitespace; convert Arabic-Indic digits to ASCII digits.

## 15.10 Audit-column rule — NEW in v4.5 (Decision #42)
All timestamps are `TIMESTAMPTZ` (UTC in the database). Columns are assigned by table class, not ad hoc:

| Class | Columns | Tables |
|---|---|---|
| **Mutable entities** | `created_at` + `updated_at` (both `NOT NULL`, `updated_at` maintained by the ORM on update) | `users`, `user_profiles`, `foods`, `ingredients`, `meals`, `meal_plans`, `meal_plan_items`, `user_health_conditions`, `user_allergen_prefs`, `user_ingredient_prefs`, `condition_nutrient_limits`, `condition_tag_restrictions`, `categories`, `cuisines`, `allergens`, `dietary_tags`, `health_conditions`, `nutrients`, `weight_logs` (client-supplied `updated_at`, §11.10) |
| **Append-only / versioned** | `created_at` only (rows are never updated, except the documented closing/tombstone column) | `consumption_logs` (+ `deleted_at` tombstone), `water_logs` (+ `deleted_at` tombstone, v4.6), `user_interactions`, `user_targets` (+ `valid_to` closing), `refresh_tokens` (+ `revoked_at`) |
| **Junction / derived / child detail** | none — covered by the parent's `updated_at`, by `computed_at`, or by `dataset_version` | `food_nutrients`, `portions_food`, `ingredient_aliases`, `ingredient_allergens`, `ingredient_tags`, `meal_ingredients`, `meal_nutrients` (`computed_at`), `meal_allergens`, `meal_tags`, `meal_translations` |

`refresh_tokens.issued_at` serves as that table's creation timestamp; no separate `created_at` is added (v4.8, #60).

`meals.ingested_at` is kept as the provenance timestamp (when the source record entered the system) and is distinct from `created_at`.

---

# 16. PostgreSQL Decision

PostgreSQL over SQLite: relational integrity, FK/UNIQUE/CHECK enforcement, partial unique indexes (used by `user_targets` and `meal_plan_items`), JSONB (snapshots), transactions, concurrency, mature indexing, extensions (`pg_trgm` now; `pgvector` later — §28, §32). Local dev via Docker Compose.

---

# 17. SQLAlchemy / Alembic Structure

```text
app/
└── db/
    ├── base.py
    ├── models/
    │   ├── reference.py
    │   ├── catalog.py
    │   ├── user.py
    │   └── __init__.py
    └── ...
```
One shared `Base` (defined with the naming convention below — see "Constraint naming convention"). Alembic must import all model metadata.

**Enum implementation note:** use `sqlalchemy.Enum(..., native_enum=False)` (or `String` + explicit `CheckConstraint`) for **all** enum-like columns — never `native_enum=True`. v4.2 additions covered by this rule: `dietary_tags.tag_group`, `condition_nutrient_limits.limit_basis`, `meal_tags.source`, `meals.weight_method`, `user_profiles.sex`, `user_profiles.activity_level`, `weight_logs.source`, `user_targets.reason`, `consumption_logs.slot`, and the widened `user_interactions.event_type`. v4.4 addition: `foods.external_source`. **Complete list made explicit in v4.8 (#60)** — also covered: `meals.quality_tier`, `foods.state`, `nutrients.unit`, `ingredients.review_status`, `condition_tag_restrictions.restriction_type`, `user_profiles.goal_type`, `user_health_conditions.severity`, `user_allergen_prefs.severity`, `user_ingredient_prefs.stance`, `meal_plan_items.slot` (`consumption_logs.slot` uses the same value set). Any new enum-like column follows the same rule.

**Type mapping (v4.8, Decisions #56, #58):** surrogate PK → `mapped_column(BigInteger, Identity(always=True), primary_key=True)`; measured values → `Numeric(12, 3, asdecimal=False)` (exceptions in §15.2); FK columns → `index=True` per §15.3.

**Migration note:** the initial migration must include `CREATE EXTENSION IF NOT EXISTS pg_trgm;` before creating the GIN indexes.

**Constraint naming convention — NEW in v4.5 (Decision #47, P-01) — must be in place before the first migration is generated:**
```python
NAMING_CONVENTION = {
    "pk": "pk_%(table_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
}
class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)
```
Every `CheckConstraint` receives an explicit short `name=` (e.g. `grams_positive`, `one_target`), producing names like `ck_meal_ingredients_grams_positive`. Names longer than PostgreSQL's 63-character limit must be shortened manually in the model, never truncated silently (the only case so far: `uq_condition_nutrient_limits_condition_nutrient_basis`, v4.9). Text columns are mapped as `String()` and appear as `VARCHAR` (no length) in the DDL — identical to `TEXT` in PostgreSQL. This makes autogenerated migrations deterministic, reviewable and reversible.

---

# 18. What Must NOT Be Added Yet

- **18.1** No ML tables (no cluster tables, no embedding columns/`pgvector`, no bandit-parameter tables, no model registry) — §28 is direction only
- **18.2** No recommendation algorithm implementation yet — *exception (v4.15): the deterministic baseline planner `greedy_v1` built for the Step F.1 vertical slice (§28.4b). Layer 2 (bandit) and Layer 3 (optimizer) remain unbuilt.*
- **18.3** No synthetic ratings
- **18.4** ~~No large ETL pipeline yet~~ — **lifted for Step G in v4.16 (#90, #92):** the pipeline of §31.7
- **18.5** ~~No forced FNDDS mapping for the 608 unresolved records~~ — **resolved in v4.4:** the 608 are sub-recipes with complete published values (§6.2); nothing to force
- **18.6** No final dataset freeze before the schema itself is frozen
- **18.7** No unit-conversion system in the schema — Phase 2 ingestion only
- **18.8** No dedicated versioning/provenance table yet — conventioned version strings suffice. Per-value provenance (`food_nutrients.value_source`) also deferred (Decision #41)
- **18.9** No chatbot tables yet — §29 (design constraints fixed in v4.6, Decision #53; tables still deferred)
- **18.10** No sports/exercise or Ramadan-mode tables yet — §29. *(Water tracking removed from this list in v4.6 — Decision #49; it is now Core, §11.13.)*
- **18.11 (NEW in v4.2)** No `daily_summaries` / adherence cache table — adherence is computed on demand from `consumption_logs` (§30.5); a cache is added only if performance requires it
- **18.12 (NEW in v4.2)** No body-measurement table beyond `weight_logs`

---

# 19. Schema Validation Strategy

Use only small temporary/dummy records (via `pytest` + a throwaway PostgreSQL — §32). Verify:
1. Reference records insert correctly
2. Food→category, Food→nutrient, Food→portion relationships work
3. Ingredient→default food, alias, allergen, **tag** relationships work
4. Meal→ingredient, nutrient, allergen, tag, translation relationships work
5. User→profile, preferences, interactions, **weight_logs**, **user_targets** relationships work
6. User→meal plan→meal, User→consumption log→(plan item | meal | food) relationships work
7. Health condition→nutrient limit, Health condition→tag restriction relationships work
8. FKs reject invalid references; UNIQUE rejects duplicates; NOT NULL rejects missing values; CHECK rejects invalid values

**Mandatory negative tests (v4.1):**
```text
meal_ingredients.grams = 0        → rejected
meal_ingredients.grams = -5       → rejected
```
- Deleting an `ingredient` referenced by `meal_ingredients` → rejected (RESTRICT)
- Deleting a `food` referenced by `ingredients.default_food_id` → FK becomes NULL
- "Deleting" a meal referenced by `user_interactions` → `is_active = false`; rows intact
- Out-of-set values for any enum-like column → rejected
- Deleting an `ingredient` referenced by `ingredient_allergens` → CASCADE, no error

**New tests (v4.2):**
- `condition_nutrient_limits` with all three limit columns NULL → rejected
- `condition_nutrient_limits` with `min_per_day > max_per_day` → rejected
- `condition_nutrient_limits` with `limit_basis = 'PERCENT_ENERGY'` and value `150` → rejected
- `consumption_logs` with both `meal_id` and `food_id` set → rejected; with neither set → rejected
- `consumption_logs` with `food_id` and `servings_consumed` (no grams) → rejected
- `consumption_logs` with `plan_item_id` but `meal_id` NULL → rejected
- Deleting a `meal_plan` → its items CASCADE, referencing `consumption_logs.plan_item_id` becomes NULL, log rows survive
- Two `user_targets` rows with `valid_to IS NULL` for the same user → rejected (partial unique index)
- Two `weight_logs` rows for the same user and day → rejected
- `user_profiles` with `goal_type = 'LOSE'` and NULL `target_weight_kg` → rejected
- `meal_plan_items.servings_multiplier = 0.7` → rejected
- `weekly_rate_kg = 1.5` → rejected
- Deleting a `dietary_tags` row referenced by `ingredient_tags` → rejected (RESTRICT)
- Duplicate `nutrients.code` or `dietary_tags.code` → rejected

**New tests (v4.4):**
- Two `foods` rows with the same `(external_source, external_code)` → rejected
- `foods` with `external_source` outside the CHECK set → rejected
- `foods` with NULL `fdc_id` but valid `external_source/external_code` → accepted
- Two `consumption_logs` (or `user_interactions`) rows with the same `client_uuid` → rejected; rows with NULL `client_uuid` → accepted

**New tests (v4.5):**
- Every constraint and index in the migrated database has a name matching the §17 convention (automated check against `pg_constraint` / `pg_indexes`)
- Migration round-trip: `upgrade head → downgrade base → upgrade head` succeeds on an empty database (P-02)
- Tombstoned `consumption_logs` row is excluded from the adherence query; the row still exists
- Two `refresh_tokens` with the same `token_hash` → rejected; `expires_at <= issued_at` → rejected
- Deleting a user cascades to `refresh_tokens`
- `meal_plan_items.reason_codes` defaults to an empty JSON array

**New tests (v4.6):**
- `water_logs.amount_ml = 0` → rejected; `amount_ml = 2001` → rejected; `amount_ml = 250` → accepted
- Two `water_logs` rows with the same `client_uuid` → rejected; rows with NULL `client_uuid` → accepted
- Tombstoned `water_logs` row is excluded from the daily water total query; the row still exists
- Deleting a user cascades to `water_logs`
- `user_profiles.water_goal_ml = 100` → rejected; `NULL` → accepted
- `health_conditions.fluid_goal_requires_clinician` defaults to `false`

**New tests (v4.8):**
- Every FK column is covered by an index (leading column of PK, UNIQUE or an index) — automated check over the SQLAlchemy metadata / `pg_index`
- Every surrogate PK column is `bigint` with `attidentity = 'a'` (GENERATED ALWAYS) — automated check against `pg_attribute`
- Inserting an explicit value into an identity PK without `OVERRIDING SYSTEM VALUE` → rejected
- A `Numeric` column read through the ORM returns a Python `float`
- `users.email = 'A@x.com'` → rejected (`email_lowercase`)
- `meal_translations.lang = 'AR'` → rejected (`ck_meal_translations_lang_iso639_1`); `'ar'` → accepted; `'ara'` → rejected by `VARCHAR(2)` length, not by the CHECK (corrected in v4.11)
- `meal_ingredients.position = 0` → rejected
- `meal_nutrients.amount_per_serving = -1` → rejected
- `user_interactions` with `event_type = 'RATE'` and `value` NULL → rejected; `value = 6` → rejected
- Hard-deleting a `meal` referenced by `consumption_logs` → rejected (RESTRICT)
- `ingredients.review_status` defaults to `'PENDING'`

**New tests (v4.12):**
- Two `meal_plan_items` with the same `(plan_id, day_index, slot)` for `BREAKFAST` → rejected; two `SNACK` items on the same plan day → accepted
- Committed migration files are unchanged: SHA-256 of every file in `alembic/versions/` equals its recorded value (§20.1)

**How the tests are built (Step E, v4.11):**
- Integrity tests run on a separate database `<POSTGRES_TEST_DB>_integrity`, created and built by `alembic upgrade head` (never `create_all`) once per test session, and dropped at the end. `db_test` itself stays empty for the migration round-trip and the DDL smoke test.
- Each test runs inside a transaction that is rolled back; negative cases use SAVEPOINTs. No test leaves rows behind.
- `backend/tests/builders.py` inserts one valid row per table; each negative test changes exactly one value, so a rejection proves that one rule.
- Every CHECK is tested by a real insert (Alembic's autogenerate comparison does not detect CHECK changes). A registry holds one accepted boundary and one rejected value per CHECK, and the rejection must name the constraint (`diag.constraint_name`). A completeness test compares the registry with `pg_constraint`: a new CHECK without a test fails the suite.
- FKs (47, with their `ON DELETE` action), UNIQUE (16) and the partial unique indexes (2 since v4.13: `user_targets`, `meal_plan_items`; read from `pg_index`, with a completeness test), NOT NULL, enum-like columns and server defaults are generated from the database catalog, so new ones are covered automatically.
- Application rules (tombstones excluded from daily totals, soft-deleted meals keep history) are tested as SQL query patterns named `test_query_pattern_*`.
- Result at Step E closure: 894 tests passed, 0 skipped, locally and in CI. At Step F (v4.13): 903 passed, 0 skipped.

After testing, roll back or delete temporary test data.

---

# 20. Initial Schema Implementation Workflow

**Stage 1 — Environment:** PostgreSQL dev environment (Docker Compose); verify FastAPI/SQLAlchemy connection.
**Stage 2 — Schema design review:** ✅ done through v4.8 (pre-Step-C consistency audit); implementation details settled in v4.9.
**Stage 3 — SQLAlchemy models:** domain models using the shared Base.
**Stage 4 — Alembic:** initial migration (with `pg_trgm`).
**Stage 5 — Manual migration review:** PKs, composite PKs, FKs, delete behavior (§15.7), UNIQUE, partial unique index, CHECK, GIN indexes, nullability, JSONB.
**Stage 6 — Clean database creation.**
**Stage 7 — Integrity tests (§19).**
**Stage 8 — Schema correction** if something fails.
**Stage 9 — Freeze:** `INITIAL DATABASE SCHEMA = FROZEN` ✅ (decided in v4.12, implemented 2026-10-04): migrations `0001` + `0002`, commit `4116f89`, git tag `schema-v1`; CI run #3 green on `main` and on the tag.

## 20.1 Post-freeze change policy — NEW in v4.12 (Decision #73)
- A committed migration is **never edited**. A CI test stores the SHA-256 of every file in `backend/alembic/versions/`; editing one fails CI. A new migration adds its own hash in the same commit.
- Any schema change after the freeze (including new tables for deferred features such as the chatbot, §29) needs, in this order: a recorded decision with change-impact analysis; a new document version; a DEV_JOURNAL entry; a **new** Alembic revision (`0003`, …); updated integrity tests (the CHECK/UNIQUE/FK registries fail until new constraints are covered); a green CI run.
- Step F.1 findings that need a schema change reopen the freeze explicitly through the same path, never silently (§25).
- `.gitattributes` keeps migration files byte-exact on every platform (`backend/alembic/versions/*.py -text`), so the hash test only fails on a real edit (v4.13).
- Seed and reference **data** are not schema: loading them does not reopen the freeze.
- **First use (v4.14, 2026-10-06):** migration `0003` (decisions #75–#78) during Step F.1.
- **Second use (v4.16, 2026-10-11):** migration `0004` (decision #91) as Step G.0, closed before any Step G data work (#90).
- **Third use (v4.19, 2026-10-17):** migration `0005` (decision #165) as Step I.0b, before the API contract I.1; its data (#166) is a separate pass I.0c.
- **Fourth use (v4.20, 2026-10-19):** migration `0006` (decision #167) drops `user_profiles.physiological_status`; cancelled conditions removed.

---

# 21. Future Dataset Population Strategy

A source is accepted only if it satisfies: stable identity, clear provenance, acceptable license, structured food/meal information, structured ingredients, numeric/convertible quantities, trustworthy nutrition data or mapping (covering all mandatory nutrients), serving information, QC capability, appropriate coverage.

> **If a source does not satisfy the data requirements, the architecture should not be changed just to make that source fit.** Transform safely, combine with a trusted reference, quarantine problematic records, or choose another source.

The concrete strategy chosen for the meal catalog is in §31.

---

# 22. Future Dataset Versioning

```text
dataset_version:     "fndds_2021_2023_v1" / "team_recipes_v1"   (pattern: source_year_vN)
computation_version: "calc_v1"
formula_version:     "targets_v1"   (user_targets — §30)
algorithm_version:   "rec_v1"       (meal_plans / user_interactions.context — §28)
dataset_version:     "catalog_v1"   (whole frozen Step G catalog — v4.16, #99)
rule version:        "tags_v2"      (drink thresholds — v4.16, #97; active since G.3a)
```
A formal versioning/provenance table is still not needed (v4.16, #99): the frozen catalog is identified by `backend/data/catalog/DATASET_MANIFEST.yaml` (SHA-256 of every raw and curated file, stage counts, gate results), checked by a CI test, and git tag `dataset-v1` (v4.17, #107: created on `f5e10f0`).

---

# 23. Previous Project Lessons — What We Keep and What We Leave Behind

**Keep as lessons:** missing grams break nutrition calculation; raw source text isn't enough for computation; external IDs ≠ internal IDs; ingredient normalization needs a concept layer; nutrition needs a standard basis (per 100g); validate before loading; plan multilingual support; provenance matters; **the meal content source must be decided deliberately, not assumed (v4.2)**.

**Leave behind:** old migrations; old SQLite DB; old synthetic users; synthetic rating matrices; old ML clusters; old recipe ingestion assumptions; old schema as authority; any code whose only justification is that it existed.

---

# 24. Current Status

## Completed
- Fresh-start decision; previous project = lessons only
- FNDDS 2021–2023 audited (Step 10 complete); **v4.4 compatibility audit of all five files done — the 608 "missing" codes are resolved sub-recipes**
- Schema design separated from dataset population
- PostgreSQL direction; three-domain architecture; database-first strategy
- v3: 8 architectural gaps resolved
- v4: teammate template audited, 4 schema corrections; feature vision MVP-scoped
- v4.1: occasion-tag mechanism; Cursor Pro confirmed
- **v4.2: consultant review — 11 schema decisions (#18–#28) + 5 direction decisions (#29–#33) approved and recorded**
- **v4.3: permissibility handled by ingestion exclusion policy, column removed (#34); v4.2 detail decisions approved (#35); all v4.2 technology decisions adopted (#36)**
- **v4.4: offline-first hybrid (#37); curated import scope (#38); `foods.external_source/external_code` (#39); §6.2 corrected (#40); per-value provenance deferred (#41)**
- **v4.5: professional-practices backlog integrated after impact analysis (#42–#48); sync gap fixed with tombstones (#43)**
- **v4.7: gout removed from the project (#54)**
- **Step B done (2026-09-30):** Docker Compose PostgreSQL 16 + test DB profile, env-based settings, ruff/mypy/pre-commit, connection tests; SQLAlchemy pinned `>=2.0,<2.1` (#55)
- **Step C done (2026-10-01):** 34 tables in `backend/app/db/models/` (`reference.py`, `catalog.py`, `user.py`), metadata tests + DDL smoke test on the test DB; commits `0024f8a`, `2d688dd`, `7ea053f`
- **v4.9: Step C implementation details (#61–#63)**
- **Step D done (2026-10-01):** initial Alembic migration `0001`, round-trip and no-drift tests; commit `fe12089`
- **Step E done (2026-10-02):** integrity tests on a migrated database (all 63 CHECK, 16 UNIQUE + partial unique index, 47 FK actions, NOT NULL, defaults, naming, identity, ORM float, query patterns) and GitHub Actions CI; 894 passed, 0 skipped; commit `79329b2`, first CI run green
- **Step F done (2026-10-04): schema frozen** — pre-freeze review (#70–#73), migration `0002` (one partial unique index), migration-immutability test, `.gitattributes`; 903 passed locally, 0 skipped; commit `4116f89`, tag `schema-v1`, CI green (DEV_JOURNAL J-029)
- **v4.10: §30 target-calculation details (#64–#69), no schema change**
- **Step F.1 done (2026-10-10):** vertical slice end to end on 35 team-reviewed meals — passes F.1-a (loader, quality gates), F.1-b (calc_v1, derived tags, screening, targets_v1), F.1-r (recipe revision, migration `0003`), F.1-c (condition limits, Layer 1, `greedy_v1`), F.1-d (consumption logging, swap, adherence, weight recompute), F.1-e (three-persona scenario and report); 1190 tests, 0 skipped; last commit `6e1e5d7`, CI green (DEV_JOURNAL J-032)
- **v4.15: Step F.1 closure decisions (#80–#89), no schema change**
- **v4.16: Step G plan decisions (#90–#100); migration `0004` specified (#91)**
- **Step G done (2026-10-12, reduced scope #101):** migration `0004` (G.0), `app/pipeline` (G.1), 177 approved ingredients (G.2), `tags_v2` + isolated #88 bench database (G.3a), 40 catalog recipes + catalog scenario report (G.3b), coverage report + `DATASET_MANIFEST.yaml` + tag `dataset-v1` (G.5); 1248 tests, 0 skipped; last commit `f5e10f0`, CI green (DEV_JOURNAL J-034)
- **v4.17: Step G closure decisions (#101–#107), no schema change**
- **Step H done (2026-10-12):** Layer 3 optimizer `cpsat_v1` (OR-Tools CP-SAT) with the #87 general limits, database wiring, swap consistency and `planner_comparison_report.md`; cpsat meets #88 (#121) and is the default planner (#122); 1287 tests, 0 skipped; commits `18b6803`, `e9d72b7` and the H.2 commit, CI green (DEV_JOURNAL J-035)
- **v4.18: Step H decisions (#108–#122), no schema change**
- **v4.14: first post-freeze change (#74–#79), migration `0003`**
- **v4.8: pre-Step-C consistency audit — PK type (#56), FK index rule (#57), numeric precision (#58), `meals.owner_user_id` removed (#59), explicit details (#60)**
- **v4.19–v4.20 (Step I.0b–I.0d):** migration `0005` (wake/sleep, `user_meal_prefs`, `meal_steps`, `dish_form`), catalog_v3 data with 477 preparation steps, migration `0006` removing cancelled conditions (#165–#167, #175)
- **Step I done (2026-10-20): the API phase** — 37 operations under `/api/v1`, contract `1.0.0`, no 501 left, offline sync, end-to-end scenario test, HTTP latency report; 1561 tests, 0 skipped; last commit `f37ac8e`, CI green (DEV_JOURNAL J-038–J-046)
- **v4.21: Step I decisions (#123–#140, #168–#216), no schema change after `0006`**
- **v4.6: scope change — water tracking moved to Core with a fluid-safety rule (#49, #50); on-device reminders (#51); UI/UX direction (#52); chatbot design constraints fixed, still deferred (#53)**

## Current task
**Step J — Hosting (to be planned with the user):** deploy the frozen `1.0.0` API and PostgreSQL to a public host for the beta. Promised scope (§34, security notes): HTTPS only, CORS limited to the app's origins, trusted proxy headers so per-IP rate limits see the real client, secrets only in the host's environment, automated database backups with a tested restore, `pip-audit` dependency scan in CI, and re-measuring plan latency and the 92-day adherence read on the host. Then **Step K — Flutter app** (built by the user; flutter_secure_storage for tokens, feature-first layered structure, generated Dart client from `openapi.json`, local `drift` store and outbox per §33).

---

# 25. Immediate Next Steps

- **Step A — Final schema review:** ✅ done (v3 → v4 → v4.1 → v4.2 → v4.3 → v4.4 → v4.5 → v4.6 → v4.7 → v4.8)
- **Step B — PostgreSQL environment:** Docker Compose + env-based configuration (§34.1) + code-quality tooling (§34.6) ✅ done (2026-09-30)
- **Step C — SQLAlchemy model implementation** (user + Cursor Pro, based on this document) ✅ done (2026-10-01)
- **Step D — Alembic initial migration:** generate and manually review ✅ done (2026-10-01)
- **Step E — Integrity validation:** positive/negative tests (§19) + CI (§34.7) ✅ done (2026-10-02)
- **Step F — Schema freeze** ✅ done (2026-10-04, tag `schema-v1`; change policy §20.1)
- **Step F.1 — Vertical slice (NEW in v4.2, Decision #33)** ✅ done (2026-10-10, v4.15): after freeze, push ~30 real team-authored meals through the full path — entry → nutrient calculation → hard filtering → one daily plan → consumption logging → adherence → weight log/target recompute. Purpose: reveal integration problems before scaling data. Findings that require a schema change reopen the freeze explicitly (documented as a new version), never silently.
- **Step G — Dataset engineering** ✅ done (2026-10-12, v4.17, reduced scope #101; plan `claude/steps/STEP_G_plan.md`):
  - **G.0** schema only: migration `0004` (#91), closed with its own commit + CI
  - **G.1** pipeline foundation (`app/pipeline`, manifests, `pandera` profiling, gates, source order #93, reports)
  - **G.2** reference layer (ingredients with codes, aliases, allergens, tags; SR/FNDDS extraction; regional source)
  - **G.3** `tags_v2` (#97) + recipe batches (draft → team review → load → commit)
  - **G.4** FNDDS ready foods with portions (#98) — postponed to Future Work (#101)
  - **G.5** coverage report (#100) and manifest + `dataset-v1` (#99) done; cross-check and weighed sample (#96) postponed (#101)
- **Step H — Layer 3 optimizer** ✅ done (2026-10-12, v4.18; plan `claude/steps/STEP_H_plan.md`):
  - **H.0** pure CP-SAT `optimize_day` + `apply_general_limits` (#108–#116)
  - **H.1** database wiring, swap consistency, comparison report (#117–#121)
  - **H.2** `cpsat_v1` default planner (#122) + closure
- **Step I — API phase** ✅ done (2026-10-20, v4.21; plan `claude/steps/STEP_I_plan.md`): I.0 foundation, I.0b–I.0d schema/data/removal, I.1 contract, I.2 auth, I.3 profile, I.4 catalog, I.5/I.5b plans and optimizer search fix, I.6 logging, I.7 sync, I.8 closure
- **Step J — Hosting** ← **next, to be planned with the user** (see §24 Current task)
- **Step K — Flutter app** (user builds it; contract `1.0.0`, §33, §34.3)
  - The extended xlsx template is replaced by YAML files (#94).

---

# 26. Working Method for the AI Assistant

```text
Objective → Inspect current project state → Define exact change → Implement
→ Validate → Inspect result → Explain result → Update documentation → Move to next stage
```

### Important rules
- Do not invent existing project files or code.
- Inspect the actual repository before modifying it.
- Do not assume the old repository exists in the new project.
- Do not combine unrelated architecture and dataset tasks into one operation.
- If a stage fails, fix and rerun the same stage.
- Do not silently skip validation.
- Keep documentation synchronized after major architecture changes.
- **Chat AI (Claude) role:** architectural reasoning, decisions, review — not code generation for this project.
- **IDE coding agent role:** implementation with **Cursor Pro**, based on this document.

### Continuous documentation rule (added 2026-09-28, user request)
- Every step, decision, feature, technique, development stage and test result is recorded **immediately** as a new entry in `claude/DEV_JOURNAL.md` (Arabic, with English technical terms): problem → alternatives → decision → theoretical concept → impact → evidence → references.
- Entries are append-only; changes are recorded as new entries referencing the old one.
- `DEV_JOURNAL.md` is the source from which the thesis theoretical chapters will be extracted. `PROJECT_CONTEXT` stays the decision reference for implementation.
- The assistant proactively proposes professional-grade engineering practices; proposals live in the journal's backlog until approved.
- **Change impact analysis is mandatory:** no feature, technique or change is added (to this document or to code) before it is checked against the whole project: (1) schema impact, (2) offline-first/sync (§33), (3) safety & hard-filtering rules (§28.1, §30), (4) conflicts with earlier decisions and §18, (5) tests (§19) and the current step, (6) cost vs value. Findings are recorded in `DEV_JOURNAL.md`. Backlog P-01…P-11 is approved in principle with the integration constraints in DEV_JOURNAL J-017 (notably: P-01 naming convention must be applied before the first migration in Step C; `updated_at` only on mutable tables).

### Step numbering rule
Never renumber an unfinished step. Use `Step X continuation`, `Step X final investigation`, or a sub-step (`Step F.1`).

---

# 27. Final Project Direction

```text
                 NEW PROJECT
                     │
          ┌──────────┴──────────┐
          │                     │
   DATABASE ARCHITECTURE    DATASET ENGINEERING
          │                     │
       NOW FIRST             LATER
          │                     │
   PostgreSQL schema      Curated recipe catalog
   relationships          Normalization / mapping
   constraints            Nutrition calculation
   provenance             Quality control
   validation                   │
          │                     │
          └──────────┬──────────┘
                     ↓
              STABLE DATA LAYER
                     ↓
      VERTICAL SLICE → APPLICATION FEATURES
                     ↓
   RULES → ML PERSONALIZATION → OPTIMIZATION
```

> **Build the database structure first. Verify every relationship and constraint. Populate it later from trustworthy, traceable sources.**

---

# 28. ML / Recommendation Architecture Direction — REWRITTEN in v4.2 (documented only, not implemented)

**Nothing in this section is built in Phase 1.** Recorded so later implementation is deliberate and so the committee can see an honest, defensible answer to "where exactly is the ML, and why?".

## 28.0 Honest classification

| Layer | Technique | Role | Is it ML? |
|---|---|---|---|
| 1. Hard filtering | Deterministic rules over allergies, exclusions, conditions, occasion tags | Remove every unsafe/unsuitable meal before any scoring | **No — by design** (safety must never depend on a statistical guess) |
| 2a. Meal representation | Nutrient-profile vector + (later) text embedding from a **pre-trained** multilingual sentence model | Describe meals numerically so they can be compared | Uses a pre-trained ML model (inference/transfer learning) — **the project does not train it**; cosine similarity itself is not learning |
| 2b. **Personalization — primary ML component** | **Contextual bandit (LinUCB, or Thompson sampling)** | Learn, per user, which kinds of meals the user accepts vs swaps/skips, and rank candidates accordingly while still exploring | **Yes — real ML**: model parameters are learned from real user feedback and change the system's behavior; online learning that works from zero data (no synthetic ratings needed) |
| 2c. (Optional) Curation assistant | Supervised multi-label classifier (e.g. logistic regression / LightGBM) | Suggest occasion/dietary tags for new meals from ingredients + nutrients; a human always confirms | **Yes — real supervised ML**, trained on the team-labeled catalog; never auto-applies tags |
| 3. Plan optimization | **OR-Tools CP-SAT** (or PuLP MILP) | Choose meals + portion steps for a day/week meeting targets and all constraints | No — mathematical optimization |
| — | LLM (Gemini/Claude API) | Explanations, future chatbot, recipe-draft assistance | Generative AI used as a service — not the project's trained ML; never computes numbers or makes health decisions |

K-Means (the v4 direction) is technically unsupervised ML but is **dropped as the headline ML component**: diversity is achieved more reliably by explicit optimizer constraints and re-ranking (MMR — maximal marginal relevance), and clustering alone does not learn anything about the user.

## 28.1 Layer 1 — hard-filtering rules
A candidate meal for a given user and slot is excluded if any of these is true:
1. `meals.is_active = false`, or not all mandatory nutrients computed (§10.3)
2. It contains any allergen in `user_allergen_prefs` (via `meal_allergens`)
3. It contains any ingredient with stance `EXCLUDE` in `user_ingredient_prefs`
4. It carries a tag that is `AVOID` for any of the user's conditions (`condition_tag_restrictions` ⋈ `meal_tags`)
5. The planned portion (`amount_per_serving × servings_multiplier`) exceeds any resolved `max_per_meal` limit (§28.2); an unknown amount of a limited nutrient counts as exceeding (v4.15, #82)
6. It has no `OCCASION` tag matching the requested slot (v4.1 rule: `BREAKFAST → breakfast_suitable`, etc.)

`DISLIKE` does not exclude — it lowers the score in Layer 2. `LIMIT` tags do not exclude either; they are counted by the planner (§28.4b).

## 28.2 Multi-condition limit resolution (Decision #18)
For each nutrient, collect all rows from the user's conditions and resolve:
- effective **max** = the **minimum** of all maxima (after converting `PERCENT_ENERGY` to grams using the current `target_kcal` — fat/sat-fat 9 kcal/g, carbohydrate/sugars/protein 4 kcal/g)
- effective **min** = the **maximum** of all minima
- If effective min > effective max → **conflict**: no plan is generated; the user is told the combination needs professional guidance. Never silently relax a limit.
- `LIMIT` tag restrictions resolve to the smallest `max_servings_per_week`.
The resolved set is frozen into `meal_plans.target_snapshot`.

## 28.3 Layer 2 — personalization details (direction)
- **Arms/context:** each candidate meal is an action; context features = meal features (nutrient profile, cuisine, tags, later embedding) + user features (goal, conditions, time slot).
- **Reward:** from `user_interactions` — `ACCEPT`/`COOK`/eaten via `consumption_logs` = positive; `SWAP_OUT`/`SKIP` = negative; `RATE` scaled.
- **Cold start:** with no history the bandit falls back to content similarity to the user's `LIKE` ingredients and to popular meals, and explores.
- **Why this fits the project:** it learns from exactly the data the app collects, needs no synthetic ratings, and has a clear academic literature and evaluation method.
- **Storage (later, not Phase 1):** model parameters and any embedding column (`pgvector`) are added only when Layer 2 is implemented — §18.1.

## 28.4 Layer 3 — optimization details (direction; implemented as `cpsat_v1` in v4.18, see §28.4c)
CP-SAT decision variables: `x[day, slot, meal, step] ∈ {0,1}` with `step ∈ {0.5, 1.0, 1.5, 2.0}` (matches `meal_plan_items.servings_multiplier`). Constraints: exactly one meal per required slot; daily kcal within ±10% of target; daily macro ranges; resolved condition min/max per day; `LIMIT` tags ≤ weekly servings; no meal repeated within N days; only Layer-1-surviving candidates. Objective: minimize deviation from targets − λ × Layer-2 preference score. Greedy remains an acceptable fallback/baseline for comparison in the report. **General population limits (#87)** are added to the resolved limits when this layer is built.

## 28.4b Baseline planner `greedy_v1` — NEW in v4.15 (Decisions #80, #88)
Built in Step F.1 (`app/services/planner.py`); deterministic (same inputs → same plan); writes one day per call.
- **Slot energy shares** of `target_kcal`: breakfast 25%, lunch 35%, dinner 25%; the remaining 15% for at most 2 snacks. Portion steps `0.5, 1.0, 1.5, 2.0` (§11.8).
- **Main slots** in order breakfast, lunch, dinner. A candidate (meal, step) must pass Layer 1 at that step, must not repeat a meal or a `variant_group` already in the day, must keep every running total within every resolved `max_per_day`, and must pass a **lookahead**: running total + candidate + the smallest amount any eligible meal could add (at step 0.5) for each main slot still empty must stay within every `max_per_day`. `LIMIT` tag servings in the day must not exceed the weekly number (weekly accounting across days is not done — known limitation, #89).
- **Choice:** smallest |candidate kcal − slot target|; ties by protein closeness, then `ref_external`, then smaller step. A main slot with no valid candidate raises an error; no limit is ever relaxed and no main slot is dropped.
- **Snacks:** added while day energy < 90% of target, never above 110%, closest to the remaining gap.
- **Hard vs soft:** every Layer 1 rule and every maximum is hard; energy precision and condition minimums are soft — measured and reported (`kcal_within_10pct`, `unmet_minimums`), not enforced (#81).
- **Reason codes (§28.6):** `FITS_KCAL_TARGET` within ±15% of the slot target; `HIGH_PROTEIN` protein energy ≥ 20%; `LOW_SODIUM` ≤ 120 mg, `LOW_SUGAR` ≤ 5 g, `LOW_SATURATED_FAT` ≤ 1.5 g per 100 g (UK FSA "low"); for `beverage` meals (v4.17, #97) `LOW_SUGAR` ≤ 2.5 g and `LOW_SATURATED_FAT` ≤ 0.75 g (FSA drinks "low"); `HIGH_FIBER` ≥ 6 g per 100 g (EU "high fibre" claim).
- **Snapshot:** `target_snapshot` stores the target (kcal, macros, fiber), the resolved limits with their sources, and the versions (`targets_v1`, `tags_v2` since v4.17, `greedy_v1`, `calc_v1`).

**Measured limits of the baseline (F.1-e scenario report, F-13, F-14):** with tight condition limits the greedy order exhausts budgets early — the `HYPERTENSION` + `DIABETES_T2` persona (target 1738 kcal) receives ≈1214 kcal plans (−30%), so full compliance still scores `NOT_ACHIEVED`; plans repeat day after day (identical days for that persona; 6 distinct meals in 12 items for the healthy persona); the healthy persona reaches 3200–4300 mg sodium/day (#69, addressed by #87).

**On the real catalog (v4.17, #104, `catalog_scenario_report.md`, 75 meals):** every slot is filled, but one day per persona falls outside ±10% (P1 1935 vs 2316 kcal; P2 1416 vs 1738), the same breakfast repeats every day, and P2 misses the fiber minimum by < 1 g on two days — the same greedy limits, with more choice.

**Benchmark location (v4.17, #104):** the #88 report runs on an isolated database holding only the F.1 slice; its G.3a version is the fixed baseline.

**Acceptance criteria for Layer 3 (#88):** run on the same F.1-e scenario and report side by side with `greedy_v1`: (1) 0 violations of Layer 1 and of every maximum — required 100%; (2) energy within ±10% of target on every day where a feasible plan exists; (3) every condition minimum met; (4) no meal repeated on consecutive days; (5) planning time reported.

## 28.4c Layer 3 optimizer `cpsat_v1` — NEW in v4.18 (Decisions #108–#122)
Built in Step H (`app/services/optimizer.py`, pure `optimize_day`; `build_optimized_day_plan` loads the inputs). The default planner of `create_day_plan` (#122); `greedy_v1` (§28.4b) is kept as the #88 baseline.
- **Differences from the direction above:** one day per solve (#109) instead of a multi-day model; repetition is prevented against the previous day's current plan only (#110), so a meal may come back on day d+2; macros are in the objective (#113), not hard ranges; Layer 1 is applied before the model by keeping only eligible (meal, step) pairs (#109).
- **Limits:** condition limits merged with the #87 general limits (#111) — strictest wins; every maximum and minimum is hard (#110). Energy is hard within ±10% in phase 1 and soft only when phase 1 is proven infeasible (#112).
- **Guarantee:** status `OPTIMAL` means no better plan exists under the model; phase 1 `INFEASIBLE` is a proof that no plan within ±10% respects the health limits (#121). Greedy can give neither statement.
- **Exactness and reproducibility:** integer scaling with outward rounding, exact `Decimal` re-verification (#114); one worker, seed 0, deterministic time limit 10 (#115).
- **Snapshot:** `generated_by = cpsat`, `algorithm_version = cpsat_v1`, merged limits with `GENERAL_POPULATION` sources, and `"solver"` (status, `kcal_relaxed`, objective, excluded meal ids) (#117).
- **Result against #88:** see the v4.18 changelog and `docs/reports/planner_comparison_report.md`.
- **Latency (updated v4.21):** after the I.5b search fix (#197–#199) and over HTTP (#216): p50 3.9 s, p95 5.6 s, max 6.2 s for 18 persona-days; requests are bounded by 2 concurrent solves (`503 PLANNER_BUSY`) and an unsolved final pass returns `503 PLANNER_TIMEOUT` (#215). Original Step H note: seconds, not milliseconds (catalog median ≈ 3.8 s, max ≈ 13 s on the developer machine). Acceptable for one plan per day; the API phase must not block a request thread on it without a timeout policy, and catalog growth may turn `OPTIMAL` into `FEASIBLE` at the time limit (still deterministic and verified).

**Theoretical note (for the thesis):** `greedy_v1` is a constructive heuristic: it fixes one slot at a time and never revisits a choice, so an early choice can consume a sodium or energy budget and leave later slots without a good option; it can neither prove that its plan is the best nor that no better plan exists. `cpsat_v1` formulates the whole day as an integer linear program (binary choice variables, linear health constraints, a weighted linear objective) solved exactly by CP-SAT (constraint programming with SAT-based clause learning and linear relaxation). It returns a plan that is optimal under the model, or a certificate that no plan meets the hard constraints. The comparison report shows the practical effect: on the full catalog the optimizer meets every #88 criterion on all persona-days while greedy meets them on one; on the F.1 slice it proves that the energy band is unreachable for the hypertension + diabetes persona instead of silently returning a −30% plan.

## 28.5 Evaluation plan (direction)
- **Nutritional correctness (rules + optimizer):** % of generated days meeting kcal/macro ranges and 0 violations of condition limits/allergens — must be 100% for violations.
- **Personalization (bandit):** pilot study with 15–30 real users over ~2 weeks; compare against baselines (random-feasible, popularity, content-only) on accept rate, swap rate, and offline replay evaluation using logged `IMPRESSION` events.
- **Curation assistant (optional):** precision/recall/F1 on a held-out part of the labeled catalog.
- **User satisfaction:** short standardized questionnaire (e.g. SUS) at the end of the pilot.

## 28.6 Explainable recommendations (Decision #46, P-11)
Each `meal_plan_items` row stores `reason_codes` produced **at plan time** by deterministic logic only (Layer 1 rules + targets + Layer 3 fit), never from bandit parameters. `SUITS_CONDITION_<CODE>` is given only when the item respects every per-meal limit of that condition and carries none of its `AVOID` or `LIMIT` tags (v4.15, #82). Initial code set (extensible): `FITS_KCAL_TARGET`, `HIGH_PROTEIN`, `LOW_SODIUM`, `LOW_SATURATED_FAT`, `LOW_SUGAR`, `HIGH_FIBER`, `SUITS_CONDITION_<CODE>`, `MATCHES_LIKED_INGREDIENT`, `NEW_FOR_VARIETY`. The device renders codes in the user's language. Theoretical basis: explainable recommendation (post-hoc, rule-based explanation).

---

# 29. Feature Scope & Roadmap

## Core Now (supported by the v4.2 schema)
- Daily and weekly meal plans
- Goal-based targets (lose / maintain / gain) with target weight, rate, and safety floors (§30)
- Versioned daily targets (`user_targets`)
- Allergy and ingredient-preference filtering
- Meal swap within a plan
- Full ingredient/quantity visibility per meal
- **Daily completion tracking:** consumption logging (on-plan, partial, off-plan) + computed adherence (§30.5)
- **Progress tracking:** weight history (`weight_logs`) vs target weight
- **Water tracking (NEW in v4.6, Decision #49):** `water_logs` + optional goal, with the fluid-safety rule (§30.7)
- **Reminders (NEW in v4.6, Decision #51):** water and meal-logging reminders as on-device local notifications; settings stored on the device only
- **UI/UX direction (NEW in v4.6, Decision #52):** RTL-first (designed for Arabic, not mirrored from English); one-tap logging from the plan; progress rings and streaks derived from §30.5. Principles may be inspired by existing apps, but no other product's visual identity (style, colors, screen layouts) is copied. Low-fidelity wireframes may start in parallel with Phase 1 because they do not touch the schema

## Core Important — the project's differentiator
- Chronic-condition-aware recommendations for **diabetes (type 2, non-insulin), hypertension, and heart disease**, with %-of-energy limits, minimums, and multi-condition resolution; unsupported conditions recognized and handled safely

## Near-Future Addition
- **Chatbot:** two tables (`chat_conversations`, `chat_messages`) + external LLM API constrained to the app's domain, rate-limited. Deferred until after Step F.1. **Binding design constraints (v4.6, Decision #53):**
  - **Data policy:** a free/unpaid LLM tier may be used **only in development with synthetic data**. Any real-user context (conditions, weight, plans) is sent only to a paid tier whose terms exclude training on the data (Gemini paid tier or Claude API). Real users must never reach a free tier.
  - **Server-side only:** the LLM is called from FastAPI; the API key lives in the server environment (§34.1) and never in the Flutter app.
  - **Scope enforcement in layers**, not by system prompt alone: a topic guard rejects off-domain questions before the model; the model is **grounded** through function calling on the project's API and never produces nutrient numbers itself (§31.4); any meal it suggests comes only from the server's Layer-1-filtered candidates (§28.1); medical-emergency messages (e.g. chest pain, hypoglycemia) get a fixed "seek medical care now" response with no analysis.
  - Works online only (shown clearly in the UI); separate per-user rate limit (§34.4).
  - **Open item:** team budget for the paid tier during the pilot. If none, the fallback is a general-information assistant that receives no personal data.

## Documented Future Work (not designed, not scheduled)
- Suggested physical activity (`exercises`, `user_exercise_plans`)
- Ramadan mode (2-meal redistribution + widen `slot` CHECK with `SUHOOR`/`IFTAR`)
- Body measurements beyond weight (waist, body-fat %)
- Gout support (needs a licensed purine-content source + `high_purine` ingredient tagging) — removed from scope in v4.7 (Decision #54)
- Packaged-product barcode scanning (Open Food Facts — license review needed, §31.5)
- User-authored private meals (v4.8, Decision #59) — a separate USER-domain table referencing catalog data, so the dependency direction (§8) is kept
- Free ingredient substitution at use time (e.g. any meat for any meat with a gram ratio and re-filtering) — v4.14 chose dish variants (#76) instead
- Camel meat and other foods missing from USDA SR Legacy — need a documented regional food-composition source (still none in v4.17, #103)
- FNDDS ready foods with portions (#98), the FNDDS dish cross-check and a weighed sample of ≥ 10 dishes (#96) — postponed from Step G (v4.17, #101)
- More team recipe batches from the 183-dish proposal (#101): data work only, no design change
- Weekly (7-day) optimization in one CP-SAT model, with variety across the whole week instead of consecutive days only (v4.18, #109)
- Optimizer performance work if the catalog grows (warm start from greedy, symmetry breaking, solve-time budget per request) (v4.18, §28.4c)

None of these require a change to the existing Phase 1 tables (some would add new tables).

---

# 30. Nutrition Targets & Safety Rules — NEW in v4.2 (Decision #30) — application logic, `formula_version = targets_v1`

All values below are initial engineering defaults and **must be reviewed by a qualified dietitian** before the pilot (§30.6).

## 30.1 Screening (before any personalized plan)
The app does **not** generate personalized plans (it may show general information and allow logging) when:
- age < 18 (from `birth_date`)
- the user has any condition with `health_conditions.is_supported = false` (`DIABETES_INSULIN`)
- multi-condition limits conflict (§28.2)

**Known limitation (v4.7, Decision #54):** only the three supported conditions and the recognized-unsupported ones in §9.5 can be declared. Conditions outside that list are not recognized (v4.20, #167: not designed for pregnancy, lactation, kidney disease or gout); the disclaimer tells users with other medical conditions to consult their clinician before following a plan.

**Screening date (v4.15, #85):** screening is evaluated on the user's local date (`user_profiles.timezone`) at the time of the request.

**General population limits (v4.15, Decision #87 — partly supersedes #69):** every eligible user gets a daily maximum of **2000 mg sodium** (WHO 2012, adults) and **saturated fat < 10% of energy** (WHO 2023), merged with condition limits by §28.2 (strictest wins). Built together with the Layer 3 optimizer; `greedy_v1` (§28.4b) does not apply them. Implemented in v4.18 (#111) as `apply_general_limits`, applied to every `cpsat_v1` plan and swap (#117, #118). Total sugars stay without a general limit (no added-sugar data).

**Known limitation (v4.10, Decision #69, sodium and saturated fat superseded by #87):** users without a declared condition get no daily limit for sodium, sugars or saturated fat; these limits come only from `condition_nutrient_limits`. The dataset stores total `sugars`, not added sugars, so the WHO added-sugar guideline cannot be applied honestly. Stated in the thesis limitations.

Every screen presenting targets/plans shows a medical disclaimer: the app is not a medical device and does not replace a clinician.

## 30.2 Energy
- **BMR — Mifflin-St Jeor:** men `10·W + 6.25·H − 5·A + 5`; women `10·W + 6.25·H − 5·A − 161` (W kg from latest `weight_logs`, H cm, A years).
- **TDEE = BMR × PAL:** `SEDENTARY 1.2`, `LIGHT 1.375`, `MODERATE 1.55`, `HIGH 1.725`, `ATHLETE 1.9`.

## 30.3 Goal adjustment & safety
- Daily adjustment = `weekly_rate_kg × 7700 / 7` kcal (≈ 1100 kcal per 1 kg/week).
- `LOSE`: target = TDEE − adjustment, deficit capped at 1000 kcal/day and weekly rate capped at 1% of body weight.
- `GAIN`: target = TDEE + adjustment, `weekly_rate_kg` capped at 0.5 for `GAIN` (application validation), surplus capped at 500 kcal/day.
- **Calorie floor:** target never below 1200 kcal (women) / 1500 kcal (men); if applied, `user_targets.was_floor_applied = true` and the user is informed that the chosen rate was reduced.
- Goal reached (current weight within ±1 kg of `target_weight_kg`) → the app proposes switching to `MAINTAIN`.

## 30.4 Macronutrients — details settled in v4.10 (Decisions #64–#67)
- Protein ranges: `LOSE` 1.2–1.6 g/kg, `MAINTAIN` 1.0 g/kg, `GAIN` 1.6–2.0 g/kg. `ATHLETE` activity level uses 1.6–2.0 g/kg **whatever the goal** (#66).
- Chosen value = **midpoint** of the range (#64): `LOSE` 1.4, `MAINTAIN` 1.0, `GAIN` 1.8, `ATHLETE` 1.8. Stored as grams in `user_targets.target_protein_g`.
- **Protein reference weight** (#65): `BMI = W / (H/100)²`. If `BMI < 30` → reference = `W`. Otherwise → `IBW = 25 × (H/100)²` and reference = `IBW + 0.4 × (W − IBW)` (adjusted body weight). `protein_g = g_per_kg × reference`.
- Fat: 25–35% of energy (default 30%).
- Carbohydrate: remainder of energy, with a **minimum of 130 g/day** (#67). If the remainder is below 130 g, in this order: (1) lower fat toward 25% of energy; (2) lower protein toward the low end of its range (1.2 for `LOSE`, 1.6 for `GAIN`/`ATHLETE`; `MAINTAIN` has no range); (3) if still below 130 g, keep the result (the calorie floor and target take priority) and write an application log entry for the case.
- Condition limits (§28.2) are applied on top at plan-generation time.

## 30.4b Fiber — NEW in v4.10 (Decision #68)
- **General target for every user:** `target_fiber_g = round(14 × target_kcal / 1000)` (DRI: 14 g per 1000 kcal).
- **Not stored** in `user_targets`: it is fully determined by `target_kcal` and `formula_version`. Frozen with the other targets in `meal_plans.target_snapshot` at plan time. (If the report later needs it as a column, it is an additive change before the Step F freeze.)
- **Soft target:** the optimizer (§28.3) includes fiber in the "deviation from targets" term; it never excludes a meal and never blocks a plan.
- **Not part of the day status** (§30.5 unchanged); shown on the day screen for information.
- For `DIABETES_T2`, the condition's `fiber` `min_per_day` (§9.5b) stays a **hard** limit and is resolved by §28.2 as before. *Clarified in v4.15 (#81):* hard means the Layer 3 optimizer must meet it; the baseline `greedy_v1` cannot guarantee a minimum and reports every unmet one (`unmet_minimums`) to the user, never hiding it.

## 30.5 Daily adherence (computed, not stored)
For a user and `log_date`: sum `consumption_logs.nutrients_snapshot`, compare with the `user_targets` row valid on that date. **Valid on that date (v4.12, #72):** the latest row whose `valid_from` is before the end of that local day in `user_profiles.timezone`, so a target changed mid-day applies to that whole day.
- Day status `ACHIEVED` if kcal within ±10% of target **and** no resolved condition `max_per_day` exceeded; `PARTIAL` if kcal within ±25%; otherwise `NOT_ACHIEVED`.
- Plan completion = consumed plan items / total plan items for that day.
- **Details (v4.15, #85):** band edges are inclusive (exactly ±10% is within); a day within ±10% with an exceeded `max_per_day` falls to `PARTIAL` (if within ±25%) or `NOT_ACHIEVED`; a day without active logs is `NOT_ACHIEVED`; no target valid on that date → no status (`NO_TARGET`). Limits use the user's **current** conditions because condition history is not stored (known limitation). Condition minimums and the fiber target are shown, never part of the status. Completion is rounded to 3 decimals.
- Streaks and weekly summaries are derived from these daily statuses.

## 30.6 Recompute triggers
*(v4.15, #86: a weight triggers `WEIGHT_UPDATE` only when it is the user's latest `measured_on` and a current target exists; if the new target cannot be computed the weight is kept and the old target stays.)* A new `user_targets` row (closing the previous one) is created on: onboarding (`INITIAL`), a new weight differing ≥ 1 kg from `based_on_weight_kg` (`WEIGHT_UPDATE`), goal/rate/target-weight change (`GOAL_CHANGE`), activity/height/sex/birth-date change (`PROFILE_CHANGE`), or a new `formula_version` (`FORMULA_CHANGE`). *(v4.21, #214: the new row starts at `max(now, current.valid_from + 1 µs)`, so two recomputes at the same server instant, e.g. two same-day weights in one sync batch, never fail; profile saves create at most one target, #177.)*

## 30.7 Water goal & fluid safety — NEW in v4.6 (Decisions #49, #50)
- **Default goal** (used only when `user_profiles.water_goal_ml IS NULL`): beverage-water target derived from EFSA (2010) adequate intake of total water (2.0 L women / 2.5 L men), minus ~20% supplied by food → **1600 ml (women) / 2000 ml (men)**. Computed in application logic, not stored. The "8 glasses a day" rule is not used (no scientific basis).
- **Fluid-safety rule:** if the user has any condition with `health_conditions.fluid_goal_requires_clinician = true` (seed: `HEART_DISEASE`): no default goal is computed or shown, water reminders are **off by default**, and the water screen shows a notice to follow the fluid amount set by the user's doctor. The user may enter that clinician-set goal in `water_goal_ml`, and may turn reminders on explicitly.
- Users under 18 (excluded by screening, §30.1) may still log water; they get no default goal (the default above is for adults only).
- Water does not affect the day status of §30.5.

**Expert validation:** involve a dietitian to review §30 defaults, all `condition_nutrient_limits` / `condition_tag_restrictions` seed rows, and a sample of catalog meals. Record the review in the project report.

---

# 31. Meal Catalog Content Strategy — NEW in v4.2 (Decision #31) — Phase 2 direction

## 31.1 Diagnosis
No licensed, gram-based, nutrition-complete dataset of Libyan/Arab meals exists. Large recipe corpora (Recipe1M, Food.com) have restrictive licenses, text quantities ("a cup", "a pinch") and mostly Western cuisine. Forcing them in would repeat the old failure.

## 31.2 Strategy: Curated Recipe Catalog
- **Ingredient nutrition:** USDA FoodData Central — **Foundation Foods** and **SR Legacy** (public domain, official API, fits `fdc_id`). FNDDS remains a secondary reference.
- **Meals:** authored by the team as recipes (ingredients in grams + servings + as-served weight per §10.1); nutrition is **computed** (§10.3), never typed in.
- **Import scope (Decision #38):** only the ingredients/foods these recipes use (≈300–500 reference foods) are imported from FNDDS/FDC — not whole databases. A small reference layer is easier to review (exclusions, translation, QC) and small enough to ship to the phone (§33).
- **Off-plan ready foods (v4.12, #70):** in addition, a curated set of ≈100–200 common ready foods from FNDDS (`external_source = 'FNDDS_FOOD'`: breads, pastries, sweets, drinks, common dishes) is imported so users can log what they eat outside the plan. These are complete dishes with published values for every mandatory nutrient; the same quality gates (§31.3) and exclusion policy (§31.6) apply. They are logged through `consumption_logs.food_id` and are not recommended by the planner.
- **Target size:** 150–300 meals at `quality_tier = GOLD` for the MVP, balanced across slots (breakfast/lunch/dinner/snack) and covering local cuisine. Quality over quantity.
- **Cross-check references:** published Arab food-composition work (e.g. the Lebanese University report on traditional dishes and Arabic sweets; the Arabic myfood24 food-composition database of 2,016 items, built with a 6-step identify → clean → map → translate → portion → QC method) used to sanity-check computed values — not imported wholesale unless their licenses allow it.

## 31.3 Quality gates
- Every food carries all mandatory nutrients (§9.7), else quarantine (`reason = missing_mandatory_nutrient`).
- Missing ≠ zero (§9.8).
- Macro-vs-energy consistency check (4/4/9 kcal/g, tolerance defined in the pipeline).
- Non-permissible or uncertain ingredients → excluded/quarantined before loading (§31.6).
- Meal computed kcal/100 g compared with cross-check references when available; large deviations → review.

## 31.4 LLM-assisted drafting rules
LLMs may draft recipe ingredient lists and translations to speed up curation, only if: the draft is recorded (`meals.source = 'llm_draft_reviewed'` with the reviewer noted in QC records); a team member reviews every recipe; and the LLM **never** provides nutrient values or health rules.

## 31.5 Deferred sources
Open Food Facts (packaged products) — ODbL license with share-alike obligations; deferred to Future Work (barcode scanning).

## 31.6 Excluded-ingredients policy — NEW in v4.3 (Decision #34)
All food in the system is permissible for its users by construction. This is enforced **during ingestion**, not at recommendation time:
- **Never loaded (excluded, `reason = non_permissible_ingredient`):** pork and all pork derivatives (including lard, pork gelatin), alcohol and alcohol-containing ingredients (wine, beer, spirits, alcohol-based extracts), blood and blood products, and any other non-permissible animal product. Applies to both `foods` (e.g. FDC bulk data contains such items) and `ingredients`.
- **Uncertain source (quarantined, `reason = ingredient_status_uncertain`):** e.g. gelatin of unknown origin, animal rennet, commercial products with unclear ingredients. They stay in quarantine and are only loaded once confirmed permissible, or replaced by a clearly permissible alternative.
- The exclusion keyword list and the quarantine decisions are part of the Phase 2 pipeline configuration and QC records.
- Team-authored recipes (§31.2) use only permissible ingredients.
- The teammate template's former permissibility column is dropped; a data-entry person simply does not enter non-permissible items.

## 31.7 Step G pipeline and catalog rules — NEW in v4.16 (Decisions #90–#100), results in v4.17 (#101–#107)
- **Layout:** `backend/data/catalog/` holds the reference seed, `ingredients.yaml`, recipe batch files, `ready_foods.yaml`, source manifests with extracted subsets, `reports/` (committed run reports) and `DATASET_MANIFEST.yaml`. Raw downloads live in `backend/data/raw/` (not in git). `backend/data/f1_slice/` stays the frozen #88 benchmark fixture.
- **Stages (`app/pipeline`):** verify raw SHA-256 → profile raw tables with `pandera` → normalize and map (recipe → ingredient code → default food) → business gates (F.1 G1–G9 plus new ones) → classify each record as accepted / quarantine / excluded with a reason code → one-transaction idempotent load → recompute (`calc_v1`, derived tags) → run report.
- **Nutrient source order (#93):** SR Legacy → FNDDS 2021–2023 ingredient values for the same SR code (per-nutrient fill, recorded in `foods.source_reference`) → equivalent SR Legacy/Foundation item → published regional source (`MANUAL`). Never a project-written zero. In practice (v4.17, #102) the fill is rare (17 of 3174 gaps), so recipes use SR items that are already complete.
- **Authoring (#95):** dish list proposed by the assistant and edited by the team; grams drafted per §31.4; every recipe reviewed (`reviewed_by`); `ref_external` `NG-…`; `dataset_version = team_recipes_v1`.
- **Quality tier (#96, #105):** `GOLD` needs review, complete ingredients, `WEIGHED` / `SUM_OF_INGREDIENTS` (no-cook, or absorbed-water dish) / published yield factor, and no failed cross-check; else `SILVER`. Batch 01: 36 `GOLD`, 4 `SILVER` (team-estimated yield). Cross-check and weighed sample postponed (#101).
- **Drinks (#97):** `tags_v2` thresholds for `beverage` meals (FSA drinks).
- **Ready foods (#98):** ≈150 `FNDDS_FOOD` items with portions; logged, never planned. Postponed (v4.17, #101).
- **Coverage (#100, #101, #106):** ≥ 8 Layer-1-eligible meals per main slot for each supported condition and for `HYPERTENSION` + `DIABETES_T2` — met on all 15 rows (`docs/reports/catalog_coverage_report.md`). The totals (≥ 150 meals, `LIBYAN` ≥ 35%, ≥ 100 ready foods) were dropped by #101.
- **Freeze (#99, #107):** `catalog_v1` manifest + CI hash test + tag `dataset-v1` (done, `f5e10f0`); the F.1 scenario report stays identical (isolated bench database, #104). A new recipe batch = new file in `meals/` → build → `manifest --write` → review → commit (a new tag when the catalog version changes).

---

# 32. Technology Additions — NEW in v4.2 (Decision #32)

| Need | Tool | When |
|---|---|---|
| Python dependency management | `uv` | Phase 1 (now) |
| Schema integrity tests on real PostgreSQL | `pytest` + `testcontainers` (or a dedicated Docker Compose test DB) | Phase 1 (Step E) |
| Fuzzy/Arabic search | `pg_trgm` + normalized columns (§15.9) | Phase 1 (initial migration) |
| Data validation / quality gates | `pandas` or `polars` + `pandera` | Phase 2 |
| FDC access | FoodData Central API / bulk downloads | Phase 2 |
| Plan optimization | Google OR-Tools CP-SAT (or PuLP) | After F.1 |
| Personalization | contextual bandit (own implementation or a small library) | After optimizer works |
| Embeddings | pre-trained multilingual sentence model + `pgvector` | Optional, after bandit baseline |
| Flutter state management | Riverpod | App development |
| Offline-first local store | `drift` (SQLite on phone) with idempotent sync via `client_uuid` (§33) | App development |
| Local reminders (water, meal logging) — NEW in v4.6 (Decision #51) | `flutter_local_notifications` (scheduled on the device, work offline; settings on the device only) | App development |
| Server-initiated push notifications (e.g. new weekly plan ready) | Firebase Cloud Messaging | App development |
| LLM (explanations, chatbot) | Gemini / Claude API — paid tier for any real-user data (Decision #53) | Near-future (after F.1) |

Core stack (Flutter, FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL, Docker Compose) is unchanged.

---

# 33. Offline-First Hybrid Architecture — NEW in v4.4 (Decision #37)

## 33.1 Clarification
Provenance/reference columns (`source_reference`, `external_source`, `external_code`, `fdc_id`) are **plain stored values**. They never connect to USDA or any external service. External sources are used **once, at development time**, by the Phase 2 import pipeline; after that the project's database is fully independent. Network needs come only from the Client–Server split (phone ↔ the project's own server), not from data sources.

## 33.2 Architecture
```text
┌──────────────────────────────┐        sync when online        ┌─────────────────────────────┐
│ Flutter app                   │ ◄────────────────────────────► │ FastAPI + PostgreSQL         │
│ local SQLite (drift):         │                                 │ (system of record)          │
│  • catalog snapshot (read-only)│   catalog: download snapshot   │  • full schema (§9–§11)      │
│  • user's plans (cached)       │   user data: upload/download   │  • plan generation (CP-SAT)  │
│  • pending logs / weights      │                                 │  • ML personalization        │
└──────────────────────────────┘                                 └─────────────────────────────┘
```

## 33.3 What works offline vs online
| Feature | Offline | Needs connection |
|---|---|---|
| View current daily/weekly plan | ✅ (cached) | — |
| Log a meal / partial / off-plan food | ✅ (queued, `client_uuid`) | sync later |
| Correct or delete a wrong log | ✅ (tombstone old row + new row, both queued) | sync later |
| Log water (NEW v4.6) | ✅ (queued, `client_uuid`; corrections = tombstone + new row) | sync later |
| Water / meal-logging reminders (NEW v4.6) | ✅ (local notifications scheduled on the device) | — |
| Log weight | ✅ (queued; `UNIQUE (user_id, measured_on)` resolves same-day conflicts, last write wins) | sync later |
| View progress, adherence, targets | ✅ (computed locally from cached data using the same rules as §30) | — |
| Browse/search catalog | ✅ (local snapshot) | — |
| Generate a new plan, swap using the optimizer | — | ✅ server (OR-Tools runs in Python) |
| ML personalization updates | — | ✅ server (learns from synced interactions) |
| Account registration / login | — | ✅ server |

## 33.4 Sync rules (server side built in Step I.7, #208–#213; device side in Step K)
- **Catalog:** the device downloads a read-only snapshot tagged with `dataset_version`; when the server's version changes, the device replaces its snapshot (a curated catalog of ≈300 meals / ≈500 foods is only a few MB). No per-row catalog sync.
- **User data:** device → server uploads of offline-created rows carry `client_uuid`; the server upserts by `client_uuid` (idempotent). Server → device downloads plans and targets.
- **Weekly plans** are generated while online and cached, so the whole week remains usable offline.
- **Conflict policy (v1, corrected in v4.5):**
  - `consumption_logs`: immutable rows; corrections and deletions are **tombstones** (`deleted_at`) plus new rows — every change is an insert or a one-way tombstone, so two devices can never produce conflicting versions of the same row.
  - `weight_logs`: upsert on `(user_id, measured_on)`; the version with the newer `updated_at` wins (last-write-wins).
  - `water_logs` (v4.6): same as `consumption_logs` — immutable rows + tombstones.
  - `user_interactions`: append-only.
- **Tombstone time (v4.12, #72):** `deleted_at` on `consumption_logs` and `water_logs` is the **server receive time** of the tombstone, not the device time. Both `created_at` and `deleted_at` are therefore server times, and another device (or a reinstall) can download "changed since the last sync" with `created_at > T OR deleted_at > T`.
- **Catalog version (v4.12, #72):** every catalog release carries **one** `dataset_version`, written to all active meals by the import pipeline; the device compares that single value to decide whether to replace its snapshot.
- **Uploads use one batch endpoint** (`POST /sync/batch`, max 500 records per request) with its own rate limit (§34.4); each record is processed idempotently by `client_uuid` and the response reports per-record status (`created` / `duplicate` / `rejected`).
- **As built (v4.21):** statuses are `CREATED` / `UPDATED` / `DUPLICATE` / `REJECTED` (with the error code); each op runs in its own `SAVEPOINT` through the same services as the single routes; an unknown error fails the whole batch (500, nothing committed, safe to resend). Outbox compaction on the device (#210). Change feed `GET /sync/changes?since=`: bounds now + 5 min / now − 30 days, 2-minute overlap window, weights of the last 30 local days in full, the full meal-preference list, changed current plans from local yesterday (including swaps), `profile_changed`, and `server_time` as the next `since` (#211).
- **Auth while offline:** the upload queue is kept on the device until the user signs in again if the refresh token has expired; queued records are never discarded (§34.2).

## 33.5 Why not fully local (no server)
Rejected: it would discard the PostgreSQL architecture, OR-Tools does not run natively in Flutter/Dart, per-device ML would make centralized learning and the pilot evaluation (§28.5) impractical, and a Client–Server design is the stronger architecture for the project's academic evaluation.

---

# 34. Engineering Standards — NEW in v4.5 (Decision #48; backlog P-01…P-11)

Each item below passed the change-impact checklist (§26; DEV_JOURNAL J-017, J-018). Items marked *(later)* are specified now so later phases inherit the constraints.

## 34.1 Configuration (P-06) — Step B
All settings (database URL, secrets, token lifetimes) come from environment variables via `pydantic-settings`; a committed `.env.example` lists them without values; `.env` is git-ignored. No secret ever appears in code or in Docker Compose files committed to the repository.

## 34.2 Authentication (P-05) — built in Step I.2 (#130)
- Passwords: **Argon2id** (`argon2-cffi` / `pwdlib`).
- Access token: JWT, 15-minute lifetime. Refresh token: opaque random value, 30-day lifetime, **rotated on every use**, stored only as a hash in `refresh_tokens` (§11.12); reuse of a rotated token revokes the whole family.
- Offline interaction: an expired refresh token never causes loss of queued offline records (§33.4).

## 34.3 API contract (P-07) — built in Step I.1, frozen at 1.0.0 in I.8 (#125, #173, #216)
FastAPI's OpenAPI schema is the single contract; the Flutter API client is generated from it (`openapi-generator`, Dart). Local `drift` tables are defined independently and connected to API models through an explicit mapper layer — generated API models are never used as local table definitions.

## 34.4 Rate limiting (P-09) — built in Step I (#132, #192)
Per-user limits: strict on plan generation (computationally expensive optimizer), separate higher limit on `POST /sync/batch` so a device returning from a long offline period can upload its queue; auth endpoints limited per IP. Single-instance in-memory limiter is sufficient for the project (`slowapi`). As built: auth 10/min per IP, plans 20/h per user plus 2 concurrent solves per server, sync 60/h per user, others 300/min per user.

## 34.5 Observability (P-08) — built in Step I.0 (#133)
Structured JSON logs; every request gets a `request_id` (accepted from `X-Request-ID` or generated), returned in the response and included in every log line; sync batch responses echo it for tracing a device upload end-to-end.

## 34.6 Code quality (P-10) — Step B/C
`ruff` (lint + format), `mypy` (type checking), `pre-commit` hooks running both before every commit.

## 34.7 Testing & CI (P-02, P-03) — Step E
- Migration round-trip test (`upgrade → downgrade → upgrade`) on an empty database.
- Naming-convention test (§19, v4.5).
- GitHub Actions workflow: start PostgreSQL service → `alembic upgrade head` → run `pytest` (all §19 tests) on every push and pull request.
- As built in Step E (`.github/workflows/ci.yml`): one job with a `postgres:16` service and throwaway CI-only credentials; environment variables replace `.env`; a second database is created for tests. Order: `ruff check` → `ruff format --check` → `mypy` → `alembic upgrade head` on the main CI database → `pytest`. The test database is never migrated before `pytest`, because the round-trip test needs it empty. In CI a skipped database test counts as a failure (`CI=true` in `conftest.py` plus a check of the pytest summary).

## 34.8 Schema-level standards (P-01, P-04)
Naming convention: §17. Audit columns: §15.10.

## 34.9 Explainability (P-11)
§28.6 and `meal_plan_items.reason_codes` (§11.8).

