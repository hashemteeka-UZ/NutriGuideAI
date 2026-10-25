# L.3 slot tag classifier

Features tf_v1: 158 meals, 110 features (91 ingredient codes used by >= 2 meals). scikit-learn 1.9.1. Nested CV: 25 outer folds (KFold 5 shuffled x 5 repeats), inner 3-fold grid for C, threshold 0.5, random_state 42. Runtime 37.4 s.

Mean ± std over the outer folds.

| model | F1 breakfast | F1 lunch | F1 dinner | F1 snack | micro-F1 | macro-F1 | Hamming loss | subset accuracy |
|---|---|---|---|---|---|---|---|---|
| prior (frequency >= 0.5) | 0.000 ± 0.000 | 0.000 ± 0.000 | 0.000 ± 0.000 | 0.000 ± 0.000 | 0.000 ± 0.000 | 0.000 ± 0.000 | 0.399 ± 0.019 | 0.000 ± 0.000 |
| kcal-only logistic regression | 0.360 ± 0.085 | 0.730 ± 0.101 | 0.521 ± 0.097 | 0.790 ± 0.080 | 0.604 ± 0.043 | 0.601 ± 0.045 | 0.361 ± 0.036 | 0.155 ± 0.041 |
| logistic regression (one-vs-rest) | 0.783 ± 0.101 | 0.888 ± 0.071 | 0.691 ± 0.069 | 0.902 ± 0.064 | 0.819 ± 0.037 | 0.816 ± 0.039 | 0.145 ± 0.028 | 0.562 ± 0.059 |
| random forest **best** | 0.825 ± 0.074 | 0.923 ± 0.061 | 0.851 ± 0.061 | 0.900 ± 0.058 | 0.880 ± 0.031 | 0.875 ± 0.032 | 0.096 ± 0.025 | 0.689 ± 0.072 |

Best model by mean macro-F1: random forest (0.875), above the prior baseline (0.000).

Top positive features of the logistic model fit on all meals:

- breakfast_suitable: tag:vegetarian (+5.49), ingredient:WHOLE_WHEAT_BREAD (+4.39), ingredient:WHOLE_WHEAT_FLOUR (+4.39), ingredient:EGG (+3.21), kcal_per_serving (+3.10)
- lunch_suitable: ingredient:WATER (+5.46), per_serving:sodium (+3.93), ingredient:POTATO (+3.73), ingredient:WHITE_RICE (+2.71), kcal_per_serving (+2.27)
- dinner_suitable: ingredient:CANNED_TUNA_IN_WATER_DRAINED (+3.36), ingredient:ZUCCHINI (+3.04), ingredient:CANNED_FAVA_BEANS (+2.68), ingredient:TOMATO (+2.55), ingredient:CHICKEN_BREAST_SKINLESS (+2.50)
- snack_suitable: tag:vegan (+3.28), tag:vegetarian (+3.10), ingredient:WHITE_WHEAT_FLOUR (+2.54), cuisine:LEVANTINE (+2.15), ingredient:CUCUMBER (+2.14)

Review candidates (out-of-fold, random forest): 1, in review_candidates.md.
