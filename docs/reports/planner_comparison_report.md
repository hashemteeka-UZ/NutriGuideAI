# Planner comparison

## 0. Versions and solver

| name | version |
| --- | --- |
| tag_rules_version | tags_v2 |
| computation_version | calc_v1 |
| formula_version | targets_v1 |
| greedy planner_version | greedy_v1 |
| cpsat planner_version | cpsat_v1 |
| ortools | 9.15.6755 |
| dataset_version | catalog_v1 |

Solver parameters from optimizer._configure: num_workers=1, random_seed=0, max_deterministic_time=10.0, log_search_progress=False.
Objective weights: W_KCAL=3, W_KCAL_RELAXED=50, W_MACRO=1, W_FIBER=1, W_SLOT=1, LIKED_BONUS=10.
C1 re-resolves limits the way the plan was built: resolve_condition_limits at the frozen target kcal, then apply_general_limits when algorithm_version is cpsat_v1. Day totals are recomputed from stored items with exact Decimal amounts.

## 1. F.1 benchmark

| persona | planner | day | C1 | C2 | C3 | C4 | kcal (target) | protein g | sodium mg | fiber g | sat fat g | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2310.64 (2316) | 130.3425 | 1886.185 | 20.913 | 19.632 | OPTIMAL | false |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2324.9145 (2316) | 98.793 | 1987.3075 | 46.4445 | 11.2735 | OPTIMAL | false |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2310.64 (2316) | 130.3425 | 1886.185 | 20.913 | 19.632 | OPTIMAL | false |
| P2 | greedy | 0 | PASS | FAIL | FAIL | PASS | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a |
| P2 | greedy | 1 | PASS | FAIL | FAIL | FAIL | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a |
| P2 | greedy | 2 | PASS | FAIL | FAIL | FAIL | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a |
| P2 | cpsat | 0 | PASS | N/A* | PASS | PASS | 1474.4025 (1738) | 66.981 | 1997.0195 | 40.3185 | 8.9355 | OPTIMAL | true |
| P2 | cpsat | 1 | PASS | N/A* | PASS | PASS | 1302.1815 (1738) | 89.4585 | 1771.174 | 25.2 | 6.941 | OPTIMAL | true |
| P2 | cpsat | 2 | PASS | N/A* | PASS | PASS | 1474.4025 (1738) | 66.981 | 1997.0195 | 40.3185 | 8.9355 | OPTIMAL | true |

* phase 1 (hard limits + ±10% kcal band) proven INFEASIBLE by CP-SAT; not a feasible day under #88 (Decision #121)

general limits #87 (informational; greedy is not required to meet them, cpsat is):

| persona | planner | day | sodium mg | sodium limit mg | sodium within | sat fat g | sat fat limit g | sat fat within |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 3269.0775 | 2000 | FAIL | 10.868 | 25.7333 | PASS |
| P1 | greedy | 1 | 3269.0775 | 2000 | FAIL | 10.868 | 25.7333 | PASS |
| P1 | greedy | 2 | 3269.0775 | 2000 | FAIL | 10.868 | 25.7333 | PASS |
| P1 | cpsat | 0 | 1886.185 | 2000 | PASS | 19.632 | 25.7333 | PASS |
| P1 | cpsat | 1 | 1987.3075 | 2000 | PASS | 11.2735 | 25.7333 | PASS |
| P1 | cpsat | 2 | 1886.185 | 2000 | PASS | 19.632 | 25.7333 | PASS |
| P2 | greedy | 0 | 1950.8175 | 2000 | PASS | 7.5615 | 19.3111 | PASS |
| P2 | greedy | 1 | 1950.8175 | 2000 | PASS | 7.5615 | 19.3111 | PASS |
| P2 | greedy | 2 | 1950.8175 | 2000 | PASS | 7.5615 | 19.3111 | PASS |
| P2 | cpsat | 0 | 1997.0195 | 2000 | PASS | 8.9355 | 19.3111 | PASS |
| P2 | cpsat | 1 | 1771.174 | 2000 | PASS | 6.941 | 19.3111 | PASS |
| P2 | cpsat | 2 | 1997.0195 | 2000 | PASS | 8.9355 | 19.3111 | PASS |

| persona | planner | day | slot | ref_external | multiplier | kcal |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | BREAKFAST | F1-B02 | 2 | 593.426 |
| P1 | greedy | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 0 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 0 | SNACK | F1-B04 | 1 | 333.18 |
| P1 | greedy | 1 | BREAKFAST | F1-B02 | 2 | 593.426 |
| P1 | greedy | 1 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 1 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 1 | SNACK | F1-B04 | 1 | 333.18 |
| P1 | greedy | 2 | BREAKFAST | F1-B02 | 2 | 593.426 |
| P1 | greedy | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 2 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 2 | SNACK | F1-B04 | 1 | 333.18 |
| P1 | cpsat | 0 | BREAKFAST | F1-B07 | 2 | 629 |
| P1 | cpsat | 0 | LUNCH | F1-L07 | 2 | 728.8 |
| P1 | cpsat | 0 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | cpsat | 0 | SNACK | F1-S01 | 0.5 | 128.4 |
| P1 | cpsat | 0 | SNACK | F1-S02 | 1 | 244 |
| P1 | cpsat | 1 | BREAKFAST | F1-B03 | 1.5 | 519.705 |
| P1 | cpsat | 1 | LUNCH | F1-D05 | 1.5 | 702.3195 |
| P1 | cpsat | 1 | DINNER | F1-L02-CH | 1 | 563.19 |
| P1 | cpsat | 1 | SNACK | F1-B08 | 1.5 | 539.7 |
| P1 | cpsat | 2 | BREAKFAST | F1-B07 | 2 | 629 |
| P1 | cpsat | 2 | LUNCH | F1-L07 | 2 | 728.8 |
| P1 | cpsat | 2 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | cpsat | 2 | SNACK | F1-S01 | 0.5 | 128.4 |
| P1 | cpsat | 2 | SNACK | F1-S02 | 1 | 244 |
| P2 | greedy | 0 | BREAKFAST | F1-B01 | 1 | 447.93 |
| P2 | greedy | 0 | LUNCH | F1-D04 | 1 | 403.875 |
| P2 | greedy | 0 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 0 | SNACK | F1-S01 | 0.5 | 128.4 |
| P2 | greedy | 1 | BREAKFAST | F1-B01 | 1 | 447.93 |
| P2 | greedy | 1 | LUNCH | F1-D04 | 1 | 403.875 |
| P2 | greedy | 1 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 1 | SNACK | F1-S01 | 0.5 | 128.4 |
| P2 | greedy | 2 | BREAKFAST | F1-B01 | 1 | 447.93 |
| P2 | greedy | 2 | LUNCH | F1-D04 | 1 | 403.875 |
| P2 | greedy | 2 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 2 | SNACK | F1-S01 | 0.5 | 128.4 |
| P2 | cpsat | 0 | BREAKFAST | F1-B02 | 1 | 296.713 |
| P2 | cpsat | 0 | LUNCH | F1-L03 | 0.5 | 354.425 |
| P2 | cpsat | 0 | DINNER | F1-L02 | 0.5 | 290.22 |
| P2 | cpsat | 0 | SNACK | F1-S01 | 0.5 | 128.4 |
| P2 | cpsat | 0 | SNACK | F1-S04 | 1.5 | 404.6445 |
| P2 | cpsat | 1 | BREAKFAST | F1-B03 | 0.5 | 173.235 |
| P2 | cpsat | 1 | LUNCH | F1-L07 | 2 | 728.8 |
| P2 | cpsat | 1 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | cpsat | 1 | SNACK | F1-S03 | 0.5 | 72.25 |
| P2 | cpsat | 1 | SNACK | F1-S06 | 0.5 | 93.79 |
| P2 | cpsat | 2 | BREAKFAST | F1-B02 | 1 | 296.713 |
| P2 | cpsat | 2 | LUNCH | F1-L03 | 0.5 | 354.425 |
| P2 | cpsat | 2 | DINNER | F1-L02 | 0.5 | 290.22 |
| P2 | cpsat | 2 | SNACK | F1-S01 | 0.5 | 128.4 |
| P2 | cpsat | 2 | SNACK | F1-S04 | 1.5 | 404.6445 |

greedy: criteria 1-4 passed on 1/6 persona-days (0 days C2 N/A, proven infeasible)
cpsat: criteria 1-4 passed on 6/6 persona-days (3 days C2 N/A, proven infeasible)

### Why no plan reaches the band

#### P2 day 0

Condition limits only: solver status OPTIMAL, kcal_relaxed true, day kcal 1474.4025, sodium mg 1997.0195, saturated fat g 8.9355.
Stored plan against the #87 caps: sodium 1997.0195 / 2000 (99.85%), saturated fat 8.9355 / 19.3111 (46.27%).
the condition limits and the slice size alone already prevent the band

#### P2 day 1

Condition limits only: solver status OPTIMAL, kcal_relaxed true, day kcal 1302.1815, sodium mg 1771.174, saturated fat g 6.941.
Stored plan against the #87 caps: sodium 1771.174 / 2000 (88.56%), saturated fat 6.941 / 19.3111 (35.94%).
the condition limits and the slice size alone already prevent the band

#### P2 day 2

Condition limits only: solver status OPTIMAL, kcal_relaxed true, day kcal 1474.4025, sodium mg 1997.0195, saturated fat g 8.9355.
Stored plan against the #87 caps: sodium 1997.0195 / 2000 (99.85%), saturated fat 8.9355 / 19.3111 (46.27%).
the condition limits and the slice size alone already prevent the band

## 2. Full catalog

| persona | planner | day | C1 | C2 | C3 | C4 | kcal (target) | protein g | sodium mg | fiber g | sat fat g | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2315.407 (2316) | 117.9885 | 2749.795 | 34.9975 | 11.4355 | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2315.407 (2316) | 117.9885 | 2749.795 | 34.9975 | 11.4355 | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2315.407 (2316) | 117.9885 | 2749.795 | 34.9975 | 11.4355 | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2317.979 (2316) | 126.3985 | 1983.287 | 32.934 | 15.6115 | OPTIMAL | false |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2314.646 (2316) | 128.7605 | 1992.061 | 37.08 | 12.726 | OPTIMAL | false |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2317.979 (2316) | 126.3985 | 1983.287 | 32.934 | 15.6115 | OPTIMAL | false |
| P2 | greedy | 0 | PASS | PASS | FAIL | PASS | 1631.3085 (1738) | 92.012 | 1947.992 | 24.266 | 16.6725 | n/a | n/a |
| P2 | greedy | 1 | PASS | PASS | FAIL | FAIL | 1631.3085 (1738) | 92.012 | 1947.992 | 24.266 | 16.6725 | n/a | n/a |
| P2 | greedy | 2 | PASS | PASS | FAIL | FAIL | 1631.3085 (1738) | 92.012 | 1947.992 | 24.266 | 16.6725 | n/a | n/a |
| P2 | cpsat | 0 | PASS | PASS | PASS | PASS | 1744.715 (1738) | 82.921 | 1501.585 | 28.834 | 9.3165 | OPTIMAL | false |
| P2 | cpsat | 1 | PASS | PASS | PASS | PASS | 1738.5035 (1738) | 100.61 | 1971.7555 | 46.194 | 10.228 | OPTIMAL | false |
| P2 | cpsat | 2 | PASS | PASS | PASS | PASS | 1744.715 (1738) | 82.921 | 1501.585 | 28.834 | 9.3165 | OPTIMAL | false |

general limits #87 (informational; greedy is not required to meet them, cpsat is):

| persona | planner | day | sodium mg | sodium limit mg | sodium within | sat fat g | sat fat limit g | sat fat within |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 2749.795 | 2000 | FAIL | 11.4355 | 25.7333 | PASS |
| P1 | greedy | 1 | 2749.795 | 2000 | FAIL | 11.4355 | 25.7333 | PASS |
| P1 | greedy | 2 | 2749.795 | 2000 | FAIL | 11.4355 | 25.7333 | PASS |
| P1 | cpsat | 0 | 1983.287 | 2000 | PASS | 15.6115 | 25.7333 | PASS |
| P1 | cpsat | 1 | 1992.061 | 2000 | PASS | 12.726 | 25.7333 | PASS |
| P1 | cpsat | 2 | 1983.287 | 2000 | PASS | 15.6115 | 25.7333 | PASS |
| P2 | greedy | 0 | 1947.992 | 2000 | PASS | 16.6725 | 19.3111 | PASS |
| P2 | greedy | 1 | 1947.992 | 2000 | PASS | 16.6725 | 19.3111 | PASS |
| P2 | greedy | 2 | 1947.992 | 2000 | PASS | 16.6725 | 19.3111 | PASS |
| P2 | cpsat | 0 | 1501.585 | 2000 | PASS | 9.3165 | 19.3111 | PASS |
| P2 | cpsat | 1 | 1971.7555 | 2000 | PASS | 10.228 | 19.3111 | PASS |
| P2 | cpsat | 2 | 1501.585 | 2000 | PASS | 9.3165 | 19.3111 | PASS |

| persona | planner | day | slot | ref_external | multiplier | kcal |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 0 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 0 | SNACK | NG-B04 | 1 | 340.9 |
| P1 | greedy | 1 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 1 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 1 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 1 | SNACK | NG-B04 | 1 | 340.9 |
| P1 | greedy | 2 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 2 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 2 | SNACK | NG-B04 | 1 | 340.9 |
| P1 | cpsat | 0 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | cpsat | 0 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 0 | SNACK | NG-S05 | 1 | 167.7 |
| P1 | cpsat | 0 | SNACK | NG-S09 | 1 | 170.4 |
| P1 | cpsat | 1 | BREAKFAST | NG-B10 | 2 | 560.62 |
| P1 | cpsat | 1 | LUNCH | NG-L16 | 2 | 744.886 |
| P1 | cpsat | 1 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | cpsat | 1 | SNACK | F1-S01 | 1.5 | 385.2 |
| P1 | cpsat | 1 | SNACK | NG-S02 | 1 | 43.5 |
| P1 | cpsat | 2 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | cpsat | 2 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 2 | SNACK | NG-S09 | 1 | 170.4 |
| P1 | cpsat | 2 | SNACK | NG-S05 | 1 | 167.7 |
| P2 | greedy | 0 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 0 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 0 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 0 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 1 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 1 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 1 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 1 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 2 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 2 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 2 | DINNER | F1-D05 | 0.5 | 234.1065 |
| P2 | greedy | 2 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | cpsat | 0 | BREAKFAST | NG-B10 | 1.5 | 420.465 |
| P2 | cpsat | 0 | LUNCH | NG-L17 | 1 | 451.855 |
| P2 | cpsat | 0 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 0 | SNACK | NG-S06 | 1 | 140.95 |
| P2 | cpsat | 0 | SNACK | NG-B05 | 1 | 293.32 |
| P2 | cpsat | 1 | BREAKFAST | F1-B02 | 1 | 296.713 |
| P2 | cpsat | 1 | LUNCH | NG-L16 | 1.5 | 558.6645 |
| P2 | cpsat | 1 | DINNER | NG-D07 | 2 | 389.926 |
| P2 | cpsat | 1 | SNACK | NG-B04 | 1 | 340.9 |
| P2 | cpsat | 1 | SNACK | NG-B09 | 0.5 | 152.3 |
| P2 | cpsat | 2 | BREAKFAST | NG-B10 | 1.5 | 420.465 |
| P2 | cpsat | 2 | LUNCH | NG-L17 | 1 | 451.855 |
| P2 | cpsat | 2 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 2 | SNACK | NG-S06 | 1 | 140.95 |
| P2 | cpsat | 2 | SNACK | NG-B05 | 1 | 293.32 |

greedy: criteria 1-4 passed on 1/6 persona-days (0 days C2 N/A, proven infeasible)
cpsat: criteria 1-4 passed on 6/6 persona-days (0 days C2 N/A, proven infeasible)

## 3. Planning time

### F.1 benchmark

greedy: n=6, median=24.556 ms, max=33.140 ms
cpsat: n=6, median=1355.218 ms, max=5572.004 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 33.140 | n/a | n/a |
| P1 | greedy | 1 | 21.153 | n/a | n/a |
| P1 | greedy | 2 | 21.643 | n/a | n/a |
| P1 | cpsat | 0 | 3057.076 | OPTIMAL | false |
| P1 | cpsat | 1 | 5572.004 | OPTIMAL | false |
| P1 | cpsat | 2 | 2224.864 | OPTIMAL | false |
| P2 | greedy | 0 | 25.298 | n/a | n/a |
| P2 | greedy | 1 | 23.814 | n/a | n/a |
| P2 | greedy | 2 | 25.638 | n/a | n/a |
| P2 | cpsat | 0 | 283.364 | OPTIMAL | true |
| P2 | cpsat | 1 | 485.571 | OPTIMAL | true |
| P2 | cpsat | 2 | 129.116 | OPTIMAL | true |

Diagnostic solves (not included in the planner medians):

| persona | planner | day | ms |
| --- | --- | --- | --- |
| P2 | cpsat | 0 | 331.284 |
| P2 | cpsat | 1 | 217.720 |
| P2 | cpsat | 2 | 103.343 |

### Full catalog

greedy: n=6, median=38.543 ms, max=48.790 ms
cpsat: n=6, median=3828.499 ms, max=12937.402 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 48.790 | n/a | n/a |
| P1 | greedy | 1 | 35.599 | n/a | n/a |
| P1 | greedy | 2 | 34.789 | n/a | n/a |
| P1 | cpsat | 0 | 1655.371 | OPTIMAL | false |
| P1 | cpsat | 1 | 7020.857 | OPTIMAL | false |
| P1 | cpsat | 2 | 2021.897 | OPTIMAL | false |
| P2 | greedy | 0 | 40.120 | n/a | n/a |
| P2 | greedy | 1 | 37.314 | n/a | n/a |
| P2 | greedy | 2 | 39.771 | n/a | n/a |
| P2 | cpsat | 0 | 5183.645 | OPTIMAL | false |
| P2 | cpsat | 1 | 12937.402 | OPTIMAL | false |
| P2 | cpsat | 2 | 2473.354 | OPTIMAL | false |

## 4. Verdict

cpsat_v1 meets all #88 criteria on the F.1 benchmark: YES
strict reading (N/A counted as FAIL): NO
cpsat_v1 meets all #88 criteria on the catalog: YES
strict reading (N/A counted as FAIL): YES
