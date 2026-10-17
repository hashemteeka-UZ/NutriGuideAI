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
| dataset_version | catalog_v2 |

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
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2316.507 (2316) | 115.1645 | 3040.701 | 40.2735 | 11.1495 | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2316.507 (2316) | 115.1645 | 3040.701 | 40.2735 | 11.1495 | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2316.507 (2316) | 115.1645 | 3040.701 | 40.2735 | 11.1495 | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2317.979 (2316) | 126.3985 | 1983.287 | 32.934 | 15.6115 | OPTIMAL | false |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2183.1055 (2316) | 129.178 | 1972.3585 | 33.775 | 8.5395 | FEASIBLE | false |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2317.979 (2316) | 126.3985 | 1983.287 | 32.934 | 15.6115 | OPTIMAL | false |
| P2 | greedy | 0 | PASS | PASS | FAIL | PASS | 1661.402 (1738) | 94.2685 | 1948.522 | 21.803 | 17.4735 | n/a | n/a |
| P2 | greedy | 1 | PASS | PASS | FAIL | FAIL | 1661.402 (1738) | 94.2685 | 1948.522 | 21.803 | 17.4735 | n/a | n/a |
| P2 | greedy | 2 | PASS | PASS | FAIL | FAIL | 1661.402 (1738) | 94.2685 | 1948.522 | 21.803 | 17.4735 | n/a | n/a |
| P2 | cpsat | 0 | PASS | PASS | PASS | PASS | 1724.5025 (1738) | 72.4455 | 1727.006 | 30.084 | 11.3205 | FEASIBLE | false |
| P2 | cpsat | 1 | PASS | PASS | PASS | PASS | 1739.0295 (1738) | 102.753 | 1894.2915 | 34.183 | 9.4545 | OPTIMAL | false |
| P2 | cpsat | 2 | PASS | PASS | PASS | PASS | 1737.46 (1738) | 79.6365 | 1437.7815 | 25.6305 | 12.453 | FEASIBLE | false |

general limits #87 (informational; greedy is not required to meet them, cpsat is):

| persona | planner | day | sodium mg | sodium limit mg | sodium within | sat fat g | sat fat limit g | sat fat within |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 3040.701 | 2000 | FAIL | 11.1495 | 25.7333 | PASS |
| P1 | greedy | 1 | 3040.701 | 2000 | FAIL | 11.1495 | 25.7333 | PASS |
| P1 | greedy | 2 | 3040.701 | 2000 | FAIL | 11.1495 | 25.7333 | PASS |
| P1 | cpsat | 0 | 1983.287 | 2000 | PASS | 15.6115 | 25.7333 | PASS |
| P1 | cpsat | 1 | 1972.3585 | 2000 | PASS | 8.5395 | 25.7333 | PASS |
| P1 | cpsat | 2 | 1983.287 | 2000 | PASS | 15.6115 | 25.7333 | PASS |
| P2 | greedy | 0 | 1948.522 | 2000 | PASS | 17.4735 | 19.3111 | PASS |
| P2 | greedy | 1 | 1948.522 | 2000 | PASS | 17.4735 | 19.3111 | PASS |
| P2 | greedy | 2 | 1948.522 | 2000 | PASS | 17.4735 | 19.3111 | PASS |
| P2 | cpsat | 0 | 1727.006 | 2000 | PASS | 11.3205 | 19.3111 | PASS |
| P2 | cpsat | 1 | 1894.2915 | 2000 | PASS | 9.4545 | 19.3111 | PASS |
| P2 | cpsat | 2 | 1437.7815 | 2000 | PASS | 12.453 | 19.3111 | PASS |

| persona | planner | day | slot | ref_external | multiplier | kcal |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 0 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 0 | SNACK | NG-D17 | 2 | 342 |
| P1 | greedy | 1 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 1 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 1 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 1 | SNACK | NG-D17 | 2 | 342 |
| P1 | greedy | 2 | BREAKFAST | NG-B08 | 1.5 | 582.3075 |
| P1 | greedy | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | greedy | 2 | DINNER | F1-L02 | 1 | 580.44 |
| P1 | greedy | 2 | SNACK | NG-D17 | 2 | 342 |
| P1 | cpsat | 0 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 0 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | cpsat | 0 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 0 | SNACK | NG-S05 | 1 | 167.7 |
| P1 | cpsat | 0 | SNACK | NG-S09 | 1 | 170.4 |
| P1 | cpsat | 1 | BREAKFAST | NG-B16 | 1 | 304.4 |
| P1 | cpsat | 1 | LUNCH | F1-D05 | 1.5 | 702.3195 |
| P1 | cpsat | 1 | DINNER | NG-L28 | 2 | 1052.686 |
| P1 | cpsat | 1 | SNACK | NG-S13 | 0.5 | 123.7 |
| P1 | cpsat | 2 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 2 | LUNCH | F1-L04 | 1.5 | 811.7595 |
| P1 | cpsat | 2 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 2 | SNACK | NG-S05 | 1 | 167.7 |
| P1 | cpsat | 2 | SNACK | NG-S09 | 1 | 170.4 |
| P2 | greedy | 0 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 0 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 0 | DINNER | NG-L25 | 0.5 | 264.2 |
| P2 | greedy | 0 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 1 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 1 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 1 | DINNER | NG-L25 | 0.5 | 264.2 |
| P2 | greedy | 1 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | greedy | 2 | BREAKFAST | NG-B01 | 1.5 | 421.5225 |
| P2 | greedy | 2 | LUNCH | NG-D06 | 1.5 | 581.4795 |
| P2 | greedy | 2 | DINNER | NG-L25 | 0.5 | 264.2 |
| P2 | greedy | 2 | SNACK | NG-S04 | 2 | 394.2 |
| P2 | cpsat | 0 | BREAKFAST | NG-B17 | 0.5 | 252.8275 |
| P2 | cpsat | 0 | LUNCH | NG-D01 | 2 | 444.6 |
| P2 | cpsat | 0 | DINNER | NG-L17 | 1 | 451.855 |
| P2 | cpsat | 0 | SNACK | NG-B05 | 1 | 293.32 |
| P2 | cpsat | 0 | SNACK | NG-S06 | 2 | 281.9 |
| P2 | cpsat | 1 | BREAKFAST | NG-B10 | 1.5 | 420.465 |
| P2 | cpsat | 1 | LUNCH | NG-L16 | 1.5 | 551.6895 |
| P2 | cpsat | 1 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 1 | SNACK | F1-S03 | 0.5 | 72.25 |
| P2 | cpsat | 1 | SNACK | NG-D17 | 1.5 | 256.5 |
| P2 | cpsat | 2 | BREAKFAST | NG-B04 | 1 | 340.9 |
| P2 | cpsat | 2 | LUNCH | NG-L17 | 1 | 451.855 |
| P2 | cpsat | 2 | DINNER | NG-L23 | 1 | 439.96 |
| P2 | cpsat | 2 | SNACK | NG-S06 | 1.5 | 211.425 |
| P2 | cpsat | 2 | SNACK | NG-B05 | 1 | 293.32 |

greedy: criteria 1-4 passed on 1/6 persona-days (0 days C2 N/A, proven infeasible)
cpsat: criteria 1-4 passed on 6/6 persona-days (0 days C2 N/A, proven infeasible)

## 3. Planning time

### F.1 benchmark

greedy: n=6, median=32.917 ms, max=51.184 ms
cpsat: n=6, median=1524.869 ms, max=5816.041 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 51.184 | n/a | n/a |
| P1 | greedy | 1 | 29.981 | n/a | n/a |
| P1 | greedy | 2 | 25.988 | n/a | n/a |
| P1 | cpsat | 0 | 3550.443 | OPTIMAL | false |
| P1 | cpsat | 1 | 5816.041 | OPTIMAL | false |
| P1 | cpsat | 2 | 2505.418 | OPTIMAL | false |
| P2 | greedy | 0 | 34.794 | n/a | n/a |
| P2 | greedy | 1 | 33.772 | n/a | n/a |
| P2 | greedy | 2 | 32.062 | n/a | n/a |
| P2 | cpsat | 0 | 307.016 | OPTIMAL | true |
| P2 | cpsat | 1 | 544.319 | OPTIMAL | true |
| P2 | cpsat | 2 | 142.347 | OPTIMAL | true |

Diagnostic solves (not included in the planner medians):

| persona | planner | day | ms |
| --- | --- | --- | --- |
| P2 | cpsat | 0 | 354.921 |
| P2 | cpsat | 1 | 342.242 |
| P2 | cpsat | 2 | 107.099 |

### Full catalog

greedy: n=6, median=53.975 ms, max=61.093 ms
cpsat: n=6, median=16956.158 ms, max=22924.627 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 61.093 | n/a | n/a |
| P1 | greedy | 1 | 50.327 | n/a | n/a |
| P1 | greedy | 2 | 46.600 | n/a | n/a |
| P1 | cpsat | 0 | 12385.870 | OPTIMAL | false |
| P1 | cpsat | 1 | 18281.508 | FEASIBLE | false |
| P1 | cpsat | 2 | 11146.264 | OPTIMAL | false |
| P2 | greedy | 0 | 56.664 | n/a | n/a |
| P2 | greedy | 1 | 52.308 | n/a | n/a |
| P2 | greedy | 2 | 55.641 | n/a | n/a |
| P2 | cpsat | 0 | 17992.017 | FEASIBLE | false |
| P2 | cpsat | 1 | 22924.627 | OPTIMAL | false |
| P2 | cpsat | 2 | 15920.300 | FEASIBLE | false |

## 4. Verdict

cpsat_v1 meets all #88 criteria on the F.1 benchmark: YES
strict reading (N/A counted as FAIL): NO
cpsat_v1 meets all #88 criteria on the catalog: YES
strict reading (N/A counted as FAIL): YES
