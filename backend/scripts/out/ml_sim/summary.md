# L.1 simulation summary

Features mf_v1: 158 meals, d = 25. 50 users per seed, T = 200, 20 candidates a round, seeds [1, 2, 3, 4, 5].

Mean cumulative expected regret (std over seeds); regret/round over the first 20 rounds (cold start); acceptance = mean reward in the last 50 rounds. independent: every user's taste is drawn alone. shared_taste: 0.7 of a population taste + 0.3 of the user's own.

## independent

| scenario | policy | regret T=50 | regret T=100 | regret T=200 | regret/round t≤20 | acceptance |
|---|---|---|---|---|---|---|
| independent | random | 19.31 (0.55) | 38.59 (1.01) | 77.41 (2.14) | 0.381 | 0.392 |
| independent | popularity | 19.02 (0.84) | 37.93 (1.72) | 75.90 (3.62) | 0.382 | 0.400 |
| independent | content_only | 13.05 (1.60) | 25.68 (3.05) | 51.05 (5.99) | 0.273 | 0.532 |
| independent | linucb_disjoint (alpha 0.1) | 8.07 (0.57) | 12.31 (1.02) | 17.82 (1.23) | 0.214 | 0.736 |
| independent | linucb_disjoint (alpha 0.25) | 8.11 (0.72) | 12.01 (1.03) | 17.18 (1.90) | 0.216 | 0.741 |
| independent | linucb_disjoint (alpha 0.5) | 8.23 (0.64) | 12.21 (0.89) | 17.74 (1.30) | 0.224 | 0.737 |
| independent | linucb_disjoint (alpha 1) | 9.41 (0.29) | 14.23 (0.42) | 20.58 (0.65) | 0.249 | 0.728 |
| independent | linucb_hybrid (alpha 0.1) | 9.79 (1.38) | 14.18 (2.36) | 19.56 (3.11) | 0.271 | 0.740 |
| independent | linucb_hybrid (alpha 0.25) | 8.97 (0.46) | 13.28 (0.94) | 18.50 (1.69) | 0.258 | 0.738 |
| independent | linucb_hybrid (alpha 0.5) **chosen** | 8.27 (0.22) | 12.17 (0.41) | 17.39 (0.60) | 0.238 | 0.742 |
| independent | linucb_hybrid (alpha 1) | 9.57 (0.21) | 14.19 (0.32) | 20.67 (0.76) | 0.259 | 0.726 |

Lowest hybrid regret at T=200 in independent: alpha 0.5.

## shared_taste

| scenario | policy | regret T=50 | regret T=100 | regret T=200 | regret/round t≤20 | acceptance |
|---|---|---|---|---|---|---|
| shared_taste | random | 17.67 (2.06) | 35.17 (4.12) | 70.42 (8.40) | 0.352 | 0.391 |
| shared_taste | popularity | 10.72 (2.23) | 20.20 (4.08) | 38.15 (7.85) | 0.230 | 0.569 |
| shared_taste | content_only | 13.36 (1.28) | 26.36 (2.63) | 52.33 (5.47) | 0.275 | 0.481 |
| shared_taste | linucb_disjoint (alpha 0.1) | 9.17 (0.70) | 14.25 (1.16) | 21.08 (2.24) | 0.230 | 0.684 |
| shared_taste | linucb_disjoint (alpha 0.25) | 8.80 (0.85) | 13.37 (1.80) | 19.68 (3.08) | 0.227 | 0.689 |
| shared_taste | linucb_disjoint (alpha 0.5) | 8.67 (0.82) | 13.33 (1.61) | 19.64 (2.43) | 0.224 | 0.690 |
| shared_taste | linucb_disjoint (alpha 1) | 9.19 (0.51) | 14.50 (1.10) | 21.54 (2.08) | 0.237 | 0.683 |
| shared_taste | linucb_hybrid (alpha 0.1) | 3.48 (0.87) | 5.89 (1.41) | 9.56 (2.11) | 0.084 | 0.710 |
| shared_taste | linucb_hybrid (alpha 0.25) | 3.72 (0.73) | 6.22 (1.17) | 10.11 (1.82) | 0.090 | 0.711 |
| shared_taste | linucb_hybrid (alpha 0.5) **chosen** | 4.12 (0.78) | 6.87 (1.22) | 10.96 (1.95) | 0.099 | 0.708 |
| shared_taste | linucb_hybrid (alpha 1) | 5.60 (0.26) | 9.33 (0.57) | 14.70 (1.01) | 0.133 | 0.695 |

Lowest hybrid regret at T=200 in shared_taste: alpha 0.1.

Configured alpha: 0.5.
Runtime: 148.2 s.
