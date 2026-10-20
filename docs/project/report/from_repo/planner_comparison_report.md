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

Solver parameters from optimizer._configure: num_workers=1, random_seed=0, max_deterministic_time=2.0, retry max_deterministic_time=10.0, linearization_level=2, log_search_progress=False.
Objective weights: W_KCAL=3, W_KCAL_RELAXED=50, W_MACRO=1, W_FIBER=1, W_SLOT=1, LIKED_BONUS=10.
C1 re-resolves limits the way the plan was built: resolve_condition_limits at the frozen target kcal, then apply_general_limits when algorithm_version is cpsat_v1. Day totals are recomputed from stored items with exact Decimal amounts.

## 1. F.1 benchmark

| persona | planner | day | C1 | C2 | C3 | C4 | kcal (target) | protein g | sodium mg | fiber g | sat fat g | solver status | kcal_relaxed | slot_band_pass |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2318.8055 (2316) | 135.418 | 3269.0775 | 47.764 | 10.868 | n/a | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2310.64 (2316) | 130.3425 | 1886.185 | 20.913 | 19.632 | OPTIMAL | false | true |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2324.9145 (2316) | 98.793 | 1987.3075 | 46.4445 | 11.2735 | OPTIMAL | false | true |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2310.64 (2316) | 130.3425 | 1886.185 | 20.913 | 19.632 | OPTIMAL | false | true |
| P2 | greedy | 0 | PASS | FAIL | FAIL | PASS | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a | n/a |
| P2 | greedy | 1 | PASS | FAIL | FAIL | FAIL | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a | n/a |
| P2 | greedy | 2 | PASS | FAIL | FAIL | FAIL | 1214.3115 (1738) | 69.895 | 1950.8175 | 23.856 | 7.5615 | n/a | n/a | n/a |
| P2 | cpsat | 0 | PASS | N/A* | PASS | PASS | 1474.4025 (1738) | 66.981 | 1997.0195 | 40.3185 | 8.9355 | OPTIMAL | true | false |
| P2 | cpsat | 1 | PASS | N/A* | PASS | PASS | 1302.1815 (1738) | 89.4585 | 1771.174 | 25.2 | 6.941 | OPTIMAL | true | false |
| P2 | cpsat | 2 | PASS | N/A* | PASS | PASS | 1474.4025 (1738) | 66.981 | 1997.0195 | 40.3185 | 8.9355 | OPTIMAL | true | false |

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
| P2 | cpsat | 1 | SNACK | F1-S06 | 0.5 | 93.79 |
| P2 | cpsat | 1 | SNACK | F1-S03 | 0.5 | 72.25 |
| P2 | cpsat | 2 | BREAKFAST | F1-B02 | 1 | 296.713 |
| P2 | cpsat | 2 | LUNCH | F1-L03 | 0.5 | 354.425 |
| P2 | cpsat | 2 | DINNER | F1-L02 | 0.5 | 290.22 |
| P2 | cpsat | 2 | SNACK | F1-S04 | 1.5 | 404.6445 |
| P2 | cpsat | 2 | SNACK | F1-S01 | 0.5 | 128.4 |

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

| persona | planner | day | C1 | C2 | C3 | C4 | kcal (target) | protein g | sodium mg | fiber g | sat fat g | solver status | kcal_relaxed | slot_band_pass |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | PASS | PASS | PASS | PASS | 2315.3095 (2316) | 110.4015 | 2213.299 | 39.967 | 20.7835 | n/a | n/a | n/a |
| P1 | greedy | 1 | PASS | PASS | PASS | FAIL | 2315.3095 (2316) | 110.4015 | 2213.299 | 39.967 | 20.7835 | n/a | n/a | n/a |
| P1 | greedy | 2 | PASS | PASS | PASS | FAIL | 2315.3095 (2316) | 110.4015 | 2213.299 | 39.967 | 20.7835 | n/a | n/a | n/a |
| P1 | cpsat | 0 | PASS | PASS | PASS | PASS | 2314.3555 (2316) | 127.5 | 1964.1615 | 33.757 | 15.802 | FEASIBLE | false | true |
| P1 | cpsat | 1 | PASS | PASS | PASS | PASS | 2317.847 (2316) | 124.9905 | 1632.702 | 23.866 | 9.547 | FEASIBLE | false | true |
| P1 | cpsat | 2 | PASS | PASS | PASS | PASS | 2314.3555 (2316) | 127.5 | 1964.1615 | 33.757 | 15.802 | FEASIBLE | false | true |
| P2 | greedy | 0 | PASS | PASS | FAIL | PASS | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a | n/a |
| P2 | greedy | 1 | PASS | PASS | FAIL | FAIL | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a | n/a |
| P2 | greedy | 2 | PASS | PASS | FAIL | FAIL | 1724.572 (1738) | 102.4305 | 1961.5645 | 19.385 | 20.131 | n/a | n/a | n/a |
| P2 | cpsat | 0 | PASS | PASS | PASS | PASS | 1741.21 (1738) | 83.304 | 1345.357 | 27.426 | 12.676 | OPTIMAL | false | true |
| P2 | cpsat | 1 | PASS | PASS | PASS | PASS | 1736.7325 (1738) | 80.507 | 1783.927 | 37.0775 | 8.9875 | OPTIMAL | false | true |
| P2 | cpsat | 2 | PASS | PASS | PASS | PASS | 1741.21 (1738) | 83.304 | 1345.357 | 27.426 | 12.676 | OPTIMAL | false | true |

general limits #87 (informational; greedy is not required to meet them, cpsat is):

| persona | planner | day | sodium mg | sodium limit mg | sodium within | sat fat g | sat fat limit g | sat fat within |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 2213.299 | 2000 | FAIL | 20.7835 | 25.7333 | PASS |
| P1 | greedy | 1 | 2213.299 | 2000 | FAIL | 20.7835 | 25.7333 | PASS |
| P1 | greedy | 2 | 2213.299 | 2000 | FAIL | 20.7835 | 25.7333 | PASS |
| P1 | cpsat | 0 | 1964.1615 | 2000 | PASS | 15.802 | 25.7333 | PASS |
| P1 | cpsat | 1 | 1632.702 | 2000 | PASS | 9.547 | 25.7333 | PASS |
| P1 | cpsat | 2 | 1964.1615 | 2000 | PASS | 15.802 | 25.7333 | PASS |
| P2 | greedy | 0 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | greedy | 1 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | greedy | 2 | 1961.5645 | 2000 | PASS | 20.131 | 19.3111 | FAIL |
| P2 | cpsat | 0 | 1345.357 | 2000 | PASS | 12.676 | 19.3111 | PASS |
| P2 | cpsat | 1 | 1783.927 | 2000 | PASS | 8.9875 | 19.3111 | PASS |
| P2 | cpsat | 2 | 1345.357 | 2000 | PASS | 12.676 | 19.3111 | PASS |

| persona | planner | day | slot | ref_external | multiplier | kcal |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 0 | LUNCH | NG-L47 | 1.5 | 811.83 |
| P1 | greedy | 0 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | greedy | 0 | SNACK | NG-S08 | 2 | 345.6 |
| P1 | greedy | 1 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 1 | LUNCH | NG-L47 | 1.5 | 811.83 |
| P1 | greedy | 1 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | greedy | 1 | SNACK | NG-S08 | 2 | 345.6 |
| P1 | greedy | 2 | BREAKFAST | NG-B32 | 1 | 576.4 |
| P1 | greedy | 2 | LUNCH | NG-L47 | 1.5 | 811.83 |
| P1 | greedy | 2 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | greedy | 2 | SNACK | NG-S08 | 2 | 345.6 |
| P1 | cpsat | 0 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 0 | LUNCH | NG-L45 | 1.5 | 817.026 |
| P1 | cpsat | 0 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 0 | SNACK | NG-D20 | 0.5 | 74.975 |
| P1 | cpsat | 0 | SNACK | NG-S10 | 1 | 254.235 |
| P1 | cpsat | 1 | BREAKFAST | NG-B16 | 2 | 608.8 |
| P1 | cpsat | 1 | LUNCH | NG-L28 | 1.5 | 789.5145 |
| P1 | cpsat | 1 | DINNER | NG-L05 | 1.5 | 582.2775 |
| P1 | cpsat | 1 | SNACK | NG-S04 | 1 | 197.1 |
| P1 | cpsat | 1 | SNACK | NG-B10 | 0.5 | 140.155 |
| P1 | cpsat | 2 | BREAKFAST | NG-B05 | 2 | 586.64 |
| P1 | cpsat | 2 | LUNCH | NG-L45 | 1.5 | 817.026 |
| P1 | cpsat | 2 | DINNER | NG-D06 | 1.5 | 581.4795 |
| P1 | cpsat | 2 | SNACK | NG-S10 | 1 | 254.235 |
| P1 | cpsat | 2 | SNACK | NG-D20 | 0.5 | 74.975 |
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
| P2 | cpsat | 0 | BREAKFAST | NG-B33 | 1 | 368.333 |
| P2 | cpsat | 0 | LUNCH | NG-L52 | 1 | 580.202 |
| P2 | cpsat | 0 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 0 | SNACK | NG-S06 | 1 | 140.95 |
| P2 | cpsat | 0 | SNACK | NG-S32 | 2 | 213.6 |
| P2 | cpsat | 1 | BREAKFAST | NG-B26 | 1 | 459.063 |
| P2 | cpsat | 1 | LUNCH | NG-D11 | 2 | 506.556 |
| P2 | cpsat | 1 | DINNER | NG-D23 | 1.5 | 431.865 |
| P2 | cpsat | 1 | SNACK | NG-B05 | 1 | 293.32 |
| P2 | cpsat | 1 | SNACK | NG-D03 | 0.5 | 45.9285 |
| P2 | cpsat | 2 | BREAKFAST | NG-B33 | 1 | 368.333 |
| P2 | cpsat | 2 | LUNCH | NG-L52 | 1 | 580.202 |
| P2 | cpsat | 2 | DINNER | NG-L11 | 1 | 438.125 |
| P2 | cpsat | 2 | SNACK | NG-S06 | 1 | 140.95 |
| P2 | cpsat | 2 | SNACK | NG-S32 | 2 | 213.6 |

greedy: criteria 1-4 passed on 1/6 persona-days (0 days C2 N/A, proven infeasible)
cpsat: criteria 1-4 passed on 6/6 persona-days (0 days C2 N/A, proven infeasible)

## 3. Planning time

### F.1 benchmark

greedy: n=6, median=30.058 ms, max=39.208 ms
cpsat: n=6, median=268.519 ms, max=410.775 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 39.208 | n/a | n/a |
| P1 | greedy | 1 | 24.452 | n/a | n/a |
| P1 | greedy | 2 | 26.765 | n/a | n/a |
| P1 | cpsat | 0 | 410.775 | OPTIMAL | false |
| P1 | cpsat | 1 | 125.490 | OPTIMAL | false |
| P1 | cpsat | 2 | 243.242 | OPTIMAL | false |
| P2 | greedy | 0 | 30.137 | n/a | n/a |
| P2 | greedy | 1 | 32.238 | n/a | n/a |
| P2 | greedy | 2 | 29.979 | n/a | n/a |
| P2 | cpsat | 0 | 293.795 | OPTIMAL | true |
| P2 | cpsat | 1 | 301.411 | OPTIMAL | true |
| P2 | cpsat | 2 | 178.842 | OPTIMAL | true |

Diagnostic solves (not included in the planner medians):

| persona | planner | day | ms |
| --- | --- | --- | --- |
| P2 | cpsat | 0 | 300.267 |
| P2 | cpsat | 1 | 189.001 |
| P2 | cpsat | 2 | 100.219 |

### Full catalog

greedy: n=6, median=61.829 ms, max=112.621 ms
cpsat: n=6, median=3088.838 ms, max=3974.746 ms

| persona | planner | day | ms | solver status | kcal_relaxed |
| --- | --- | --- | --- | --- | --- |
| P1 | greedy | 0 | 61.870 | n/a | n/a |
| P1 | greedy | 1 | 49.356 | n/a | n/a |
| P1 | greedy | 2 | 61.789 | n/a | n/a |
| P1 | cpsat | 0 | 3530.382 | FEASIBLE | false |
| P1 | cpsat | 1 | 3974.746 | FEASIBLE | false |
| P1 | cpsat | 2 | 3496.666 | FEASIBLE | false |
| P2 | greedy | 0 | 58.607 | n/a | n/a |
| P2 | greedy | 1 | 112.621 | n/a | n/a |
| P2 | greedy | 2 | 62.939 | n/a | n/a |
| P2 | cpsat | 0 | 2681.009 | OPTIMAL | false |
| P2 | cpsat | 1 | 1813.291 | OPTIMAL | false |
| P2 | cpsat | 2 | 1146.466 | OPTIMAL | false |

## 4. Verdict

cpsat_v1 meets all #88 criteria on the F.1 benchmark: YES
strict reading (N/A counted as FAIL): NO
cpsat_v1 meets all #88 criteria on the catalog: YES
strict reading (N/A counted as FAIL): YES
