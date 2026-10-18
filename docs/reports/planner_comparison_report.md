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
| dataset_version | catalog_v3 |

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
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2315.9995 (2316) | 110.895 | 2401.6925 | 34.357 | 12.402 | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2315.9995 (2316) | 110.895 | 2401.6925 | 34.357 | 12.402 | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2315.9995 (2316) | 110.895 | 2401.6925 | 34.357 | 12.402 | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2315.805 (2316) | 117.35 | 1897.0285 | 26.3015 | 17.4445 | FEASIBLE | false |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2301.9665 (2316) | 121.2695 | 1906.546 | 28.0735 | 11.3695 | FEASIBLE | false |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2328.2195 (2316) | 119.442 | 1980.536 | 19.229 | 15.928 | FEASIBLE | false |
| P2 | greedy | 0 | PASS | PASS | FAIL | PASS | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a |
| P2 | greedy | 1 | PASS | PASS | FAIL | FAIL | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a |
| P2 | greedy | 2 | PASS | PASS | FAIL | FAIL | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a |
| P2 | cpsat | 0 | PASS | PASS | PASS | PASS | 1785.926 (1738) | 79.785 | 1659.699 | 27.322 | 10.944 | FEASIBLE | false |
| P2 | cpsat | 1 | PASS | PASS | PASS | PASS | 1735.791 (1738) | 82.135 | 1736.748 | 37.339 | 14.732 | OPTIMAL | false |
| P2 | cpsat | 2 | PASS | PASS | PASS | PASS | 1739.9885 (1738) | 69.1985 | 1932.1915 | 33.22 | 9.0325 | FEASIBLE | false |

general limits #87 (informational; greedy is not required to meet them, cpsat is):

| persona | planner | day | sodium mg | sodium limit mg | sodium within | sat fat g | sat fat limit g | sat fat within |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 2401.6925 | 2000 | FAIL | 12.402 | 25.7333 | PASS |
| P1 | greedy | 1 | 2401.6925 | 2000 | FAIL | 12.402 | 25.7333 | PASS |
| P1 | greedy | 2 | 2401.6925 | 2000 | FAIL | 12.402 | 25.7333 | PASS |
| P1 | cpsat | 0 | 1897.0285 | 2000 | PASS | 17.4445 | 25.7333 | PASS |
| P1 | cpsat | 1 | 1906.546 | 2000 | PASS | 11.3695 | 25.7333 | PASS |
| P1 | cpsat | 2 | 1980.536 | 2000 | PASS | 15.928 | 25.7333 | PASS |
| P2 | greedy | 0 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | greedy | 1 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | greedy | 2 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | cpsat | 0 | 1659.699 | 2000 | PASS | 10.944 | 19.3111 | PASS |
| P2 | cpsat | 1 | 1736.748 | 2000 | PASS | 14.732 | 19.3111 | PASS |
| P2 | cpsat | 2 | 1932.1915 | 2000 | PASS | 9.0325 | 19.3111 | PASS |

| persona | planner | day | slot | ref_external | multiplier | kcal |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 0 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 0 | SNACK | NG-S14 | 2 | 347.4 |
| P1 | greedy | 1 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 1 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 1 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 1 | SNACK | NG-S14 | 2 | 347.4 |
| P1 | greedy | 2 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 2 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 2 | SNACK | NG-S14 | 2 | 347.4 |
| P1 | cpsat | 0 | BREAKFAST | F1-B03 | 1.5 | 519.705 |
| P1 | cpsat | 0 | LUNCH | F1-L02-CH | 1.5 | 844.785 |
| P1 | cpsat | 0 | DINNER | NG-L23 | 1.5 | 659.94 |
| P1 | cpsat | 0 | SNACK | NG-S33 | 1.5 | 209.625 |
| P1 | cpsat | 0 | SNACK | NG-S31 | 0.5 | 81.75 |
| P1 | cpsat | 1 | BREAKFAST | NG-B31 | 1.5 | 516.1395 |
| P1 | cpsat | 1 | LUNCH | NG-L10 | 1.5 | 635.679 |
| P1 | cpsat | 1 | DINNER | NG-L28 | 1 | 526.343 |
| P1 | cpsat | 1 | SNACK | NG-D19 | 1 | 276.405 |
| P1 | cpsat | 1 | SNACK | NG-S14 | 2 | 347.4 |
| P1 | cpsat | 2 | BREAKFAST | NG-B33 | 1.5 | 552.4995 |
| P1 | cpsat | 2 | LUNCH | NG-L31 | 1 | 494.265 |
| P1 | cpsat | 2 | DINNER | F1-L02-CH | 1 | 563.19 |
| P1 | cpsat | 2 | SNACK | NG-D22 | 2 | 654.74 |
| P1 | cpsat | 2 | SNACK | NG-S21 | 0.5 | 63.525 |
| P2 | greedy | 0 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 0 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 0 | DINNER | NG-D22 | 1 | 327.37 |
| P2 | greedy | 0 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 1 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 1 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 1 | DINNER | NG-D22 | 1 | 327.37 |
| P2 | greedy | 1 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 2 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 2 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 2 | DINNER | NG-D22 | 1 | 327.37 |
| P2 | greedy | 2 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | cpsat | 0 | BREAKFAST | NG-B26 | 1 | 459.063 |
| P2 | cpsat | 0 | LUNCH | NG-L47 | 1 | 541.22 |
| P2 | cpsat | 0 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 0 | SNACK | NG-S18 | 1 | 193.618 |
| P2 | cpsat | 0 | SNACK | NG-S26 | 1.5 | 153.9 |
| P2 | cpsat | 1 | BREAKFAST | NG-B34 | 1 | 394.167 |
| P2 | cpsat | 1 | LUNCH | NG-L43 | 1.5 | 538.134 |
| P2 | cpsat | 1 | DINNER | NG-D23 | 1.5 | 431.865 |
| P2 | cpsat | 1 | SNACK | NG-S06 | 1.5 | 211.425 |
| P2 | cpsat | 1 | SNACK | NG-S32 | 1.5 | 160.2 |
| P2 | cpsat | 2 | BREAKFAST | NG-B10 | 1.5 | 420.465 |
| P2 | cpsat | 2 | LUNCH | NG-L33 | 0.5 | 254.8365 |
| P2 | cpsat | 2 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 2 | SNACK | NG-L59 | 1 | 338.362 |
| P2 | cpsat | 2 | SNACK | NG-B32 | 0.5 | 288.2 |

greedy: criteria 1-4 passed on 1/6 persona-days (0 days C2 N/A, proven infeasible)
cpsat: criteria 1-4 passed on 6/6 persona-days (0 days C2 N/A, proven infeasible)

## 3. Planning time

### F.1 benchmark

greedy: n=6, median=24.534 ms, max=31.807 ms
cpsat: n=6, median=1599.548 ms, max=5901.089 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 31.807 | n/a | n/a |
| P1 | greedy | 1 | 22.043 | n/a | n/a |
| P1 | greedy | 2 | 19.995 | n/a | n/a |
| P1 | cpsat | 0 | 2619.513 | OPTIMAL | false |
| P1 | cpsat | 1 | 5901.089 | OPTIMAL | false |
| P1 | cpsat | 2 | 2864.772 | OPTIMAL | false |
| P2 | greedy | 0 | 25.518 | n/a | n/a |
| P2 | greedy | 1 | 23.966 | n/a | n/a |
| P2 | greedy | 2 | 25.101 | n/a | n/a |
| P2 | cpsat | 0 | 245.564 | OPTIMAL | true |
| P2 | cpsat | 1 | 579.584 | OPTIMAL | true |
| P2 | cpsat | 2 | 190.887 | OPTIMAL | true |

Diagnostic solves (not included in the planner medians):

| persona | planner | day | ms |
| --- | --- | --- | --- |
| P2 | cpsat | 0 | 291.187 |
| P2 | cpsat | 1 | 313.580 |
| P2 | cpsat | 2 | 145.065 |

### Full catalog

greedy: n=6, median=102.349 ms, max=146.070 ms
cpsat: n=6, median=17419.806 ms, max=19226.124 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 96.720 | n/a | n/a |
| P1 | greedy | 1 | 107.978 | n/a | n/a |
| P1 | greedy | 2 | 146.070 | n/a | n/a |
| P1 | cpsat | 0 | 19226.124 | FEASIBLE | false |
| P1 | cpsat | 1 | 17777.778 | FEASIBLE | false |
| P1 | cpsat | 2 | 17864.422 | FEASIBLE | false |
| P2 | greedy | 0 | 93.977 | n/a | n/a |
| P2 | greedy | 1 | 124.934 | n/a | n/a |
| P2 | greedy | 2 | 96.312 | n/a | n/a |
| P2 | cpsat | 0 | 17052.985 | FEASIBLE | false |
| P2 | cpsat | 1 | 15163.533 | OPTIMAL | false |
| P2 | cpsat | 2 | 17061.834 | FEASIBLE | false |

## 4. Verdict

cpsat_v1 meets all #88 criteria on the F.1 benchmark: YES
strict reading (N/A counted as FAIL): NO
cpsat_v1 meets all #88 criteria on the catalog: YES
strict reading (N/A counted as FAIL): YES
