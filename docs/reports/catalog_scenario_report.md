# F.1-e scenario report

Generated from `run_f1_scenario` with `start_date` 2026-10-07 and `start_now` 2026-10-07T05:00:00+00:00.

## 1. Data and versions

| field | value |
| --- | --- |
| dataset_version | team_recipes_v1, team_recipes_v2, team_recipes_v3, team_recipes_v4, team_recipes_v5 |
| computation_version | calc_v1 |
| tag_rules_version | tags_v2 |
| planner_version | greedy_v1 |
| formula_version | targets_v1 |
| meals | 158 |
| active meals | 158 |
| inactive meals | 0 |
| foods | 177 |

## 2. P1 profile, screening, targets, limits

| field | value |
| --- | --- |
| sex | MALE |
| age_years | 30 |
| height_cm | 175 |
| start_weight_kg | 90 |
| activity_level | MODERATE |
| goal_type | LOSE |
| target_weight_kg | 80 |
| weekly_rate_kg | 0.5 |
| conditions | none |
| timezone | Africa/Tripoli |
| screening_eligible | True |
| screening_reasons | — |

| reason | kcal | protein_g | carb_g | fat_g | fiber_g | was_floor_applied |
| --- | --- | --- | --- | --- | --- | --- |
| INITIAL | 2316 | 126 | 279.3 | 77.2 | 32 | False |
| WEIGHT_UPDATE | 2299 | 124.5 | 277.9 | 76.6 | 32 | False |

Resolved limits: none (#69).

## 2. P2 profile, screening, targets, limits

| field | value |
| --- | --- |
| sex | FEMALE |
| age_years | 55 |
| height_cm | 160 |
| start_weight_kg | 70 |
| activity_level | LIGHT |
| goal_type | MAINTAIN |
| target_weight_kg | — |
| weekly_rate_kg | — |
| conditions | HYPERTENSION, DIABETES_T2 |
| timezone | Africa/Tripoli |
| screening_eligible | True |
| screening_reasons | — |

| reason | kcal | protein_g | carb_g | fat_g | fiber_g | was_floor_applied |
| --- | --- | --- | --- | --- | --- | --- |
| INITIAL | 1738 | 70 | 234.2 | 57.9 | 24 | False |

| kind | nutrient_or_tag | value | sources |
| --- | --- | --- | --- |
| max_per_day | sodium | 2000 | HYPERTENSION ABSOLUTE WHO (2012). Guideline: Sodium intake for adults and children. < 2 g sodium/day |
| max_per_day | sugars | 43.45 | DIABETES_T2 PERCENT_ENERGY WHO (2015). Guideline: Sugars intake for adults and children. < 10% of energy (free sugars; applied here to total sugars, which is stricter - see Decision #69) |
| min_per_day | fiber | 25 | DIABETES_T2 ABSOLUTE ADA Standards of Care in Diabetes (2024), section 5: at least 14 g fiber per 1000 kcal (about 25 g/day) |
| max_per_meal | carbohydrate | 60 | DIABETES_T2 ABSOLUTE ADA carbohydrate-counting education: 45-60 g carbohydrate per meal for most adults |
| avoid_tag | added_sugar | AVOID | — |
| limit_tag | high_sodium | 3 | — |
| limit_tag | high_sugar | 3 | — |

## 2. P3 profile, screening, targets, limits

| field | value |
| --- | --- |
| sex | MALE |
| age_years | 60 |
| height_cm | 170 |
| start_weight_kg | 80 |
| activity_level | LIGHT |
| goal_type | MAINTAIN |
| target_weight_kg | — |
| weekly_rate_kg | — |
| conditions | DIABETES_INSULIN |
| timezone | Africa/Tripoli |
| screening_eligible | False |
| screening_reasons | UNSUPPORTED_CONDITION:DIABETES_INSULIN |

No `user_targets` rows.

Resolved limits: none (no target).

## 3. P1 plans

### P1 day 0 (2026-10-07)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B32 | حمص بالطحينة مع خبز وخضار | 1 | 576.4 | 20.921 | 77.41 | 650.065 | 10.399 | 16.12 | 3.036 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | NG-L47 | مبطن بطاطا مع سلطة | 1.5 | 811.83 | 36.684 | 74.034 | 737.9895 | 7.353 | 9.048 | 8.472 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR |
| DINNER | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR |
| SNACK | NG-S08 | تين مجفف مع جوز | 2 | 345.6 | 6.55 | 42.436 | 6.6 | 29.536 | 7.89 | 1.924 | FITS_KCAL_TARGET, HIGH_FIBER, LOW_SODIUM |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2315.3095 | 2316 | target |
| protein | 110.4015 | 126 | target |
| carbohydrate | 215.2565 | 279.3 | target |
| fat | 120.8935 | 77.2 | target |
| fiber | 39.967 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

### P1 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B32 | حمص بالطحينة مع خبز وخضار | 1 | 576.4 | 20.921 | 77.41 | 650.065 | 10.399 | 16.12 | 3.036 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | NG-D01 | سلطة بطاطا بالبيض | 1.5 | 333.45 | 11.1645 | 39.441 | 672.9495 | 3.2445 | 5.0895 | 3.0375 | LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR |
| SNACK | NG-S08 | تين مجفف مع جوز | 2 | 345.6 | 6.55 | 42.436 | 6.6 | 29.536 | 7.89 | 1.924 | FITS_KCAL_TARGET, HIGH_FIBER, LOW_SODIUM |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1836.9295 | 2316 | target |
| protein | 84.882 | 126 | target |
| carbohydrate | 180.6635 | 279.3 | target |
| fat | 94.3435 | 77.2 | target |
| fiber | 36.0085 | 32 | soft target |

kcal_within_10pct: False

unmet_minimums: none

### P1 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B32 | حمص بالطحينة مع خبز وخضار | 1 | 576.4 | 20.921 | 77.41 | 650.065 | 10.399 | 16.12 | 3.036 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | NG-L60 | يخنة بازلاء باللحم مع رز | 1.5 | 801.6375 | 54.222 | 116.0175 | 735.33 | 17.325 | 15.2445 | 3.0795 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR |
| DINNER | NG-D23 | سلطة فول | 2 | 575.82 | 25.738 | 74.226 | 426.17 | 12.504 | 19.768 | 3.08 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR |
| SNACK | NG-S08 | تين مجفف مع جوز | 2 | 345.6 | 6.55 | 42.436 | 6.6 | 29.536 | 7.89 | 1.924 | FITS_KCAL_TARGET, HIGH_FIBER, LOW_SODIUM |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2299.4575 | 2299 | target |
| protein | 107.431 | 124.5 | target |
| carbohydrate | 310.0895 | 277.9 | target |
| fat | 79.46 | 76.6 | target |
| fiber | 59.0225 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

## 3. P2 plans

### P2 day 0 (2026-10-07)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-D22 | بوريك لحم بالفرن | 1 | 327.37 | 20.128 | 25.996 | 266.04 | 1.237 | 1.596 | 4.267 | HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1724.572 | 1738 | target |
| protein | 102.4305 | 70 | target |
| carbohydrate | 106.586 | 234.2 | target |
| fat | 102.1975 | 57.9 | target |
| fiber | 19.385 | 24 | soft target |
| max sodium | 1961.5645 | 2000 | max_per_day |
| max sugars | 34.508 | 43.45 | max_per_day |
| min fiber | 19.385 | 25 | min_per_day |

kcal_within_10pct: True

unmet_minimums: fiber min 25 total 19.385

### P2 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | NG-D01 | سلطة بطاطا بالبيض | 1.5 | 333.45 | 11.1645 | 39.441 | 672.9495 | 3.2445 | 5.0895 | 3.0375 | LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-D22 | بوريك لحم بالفرن | 1 | 327.37 | 20.128 | 25.996 | 266.04 | 1.237 | 1.596 | 4.267 | HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1476.5425 | 1738 | target |
| protein | 67.3485 | 70 | target |
| carbohydrate | 124.6505 | 234.2 | target |
| fat | 82.294 | 57.9 | target |
| fiber | 17.5655 | 24 | soft target |
| max sodium | 1815.8695 | 2000 | max_per_day |
| max sugars | 30.182 | 43.45 | max_per_day |
| min fiber | 17.5655 | 25 | min_per_day |

kcal_within_10pct: False

unmet_minimums: fiber min 25 total 17.5655

### P2 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-D22 | بوريك لحم بالفرن | 1 | 327.37 | 20.128 | 25.996 | 266.04 | 1.237 | 1.596 | 4.267 | HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1724.572 | 1738 | target |
| protein | 102.4305 | 70 | target |
| carbohydrate | 106.586 | 234.2 | target |
| fat | 102.1975 | 57.9 | target |
| fiber | 19.385 | 24 | soft target |
| max sodium | 1961.5645 | 2000 | max_per_day |
| max sugars | 34.508 | 43.45 | max_per_day |
| min fiber | 19.385 | 25 | min_per_day |

kcal_within_10pct: True

unmet_minimums: fiber min 25 total 19.385

## 3. P3 plans

### P3 day 0 (2026-10-07)

No plan.

## 4. P1 logs and adherence

### P1 day 0 (2026-10-07)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B32 | 1 | ACTIVE |
| PLAN_ITEM | NG-L47 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D06 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-S08 | 2 | ACTIVE |

| field | value |
| --- | --- |
| status | ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

### P1 day 1 (2026-10-08)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B32 | 0.5 | TOMBSTONE |
| PLAN_ITEM | NG-B32 | 1 | ACTIVE |
| PLAN_ITEM | NG-D01 | 1.5 | ACTIVE |
| FOOD | 09087 | 30 | ACTIVE |

| field | value |
| --- | --- |
| status | NOT_ACHIEVED |
| reason | — |
| completion | 0.500 |
| exceeded_limits | none |
| log_count | 3 |

### P1 day 2 (2026-10-09)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B32 | 1 | ACTIVE |
| PLAN_ITEM | NG-L60 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D23 | 2 | ACTIVE |
| PLAN_ITEM | NG-S08 | 2 | ACTIVE |

| field | value |
| --- | --- |
| status | ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

Streak at last day: 1

## 4. P2 logs and adherence

### P2 day 0 (2026-10-07)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B01 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D06 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D22 | 1 | ACTIVE |
| PLAN_ITEM | NG-S04 | 2 | ACTIVE |

| field | value |
| --- | --- |
| status | ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

### P2 day 1 (2026-10-08)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B01 | 0.75 | TOMBSTONE |
| PLAN_ITEM | NG-B01 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D01 | 1.5 | ACTIVE |
| FOOD | 11215 | 20 | ACTIVE |

| field | value |
| --- | --- |
| status | NOT_ACHIEVED |
| reason | — |
| completion | 0.500 |
| exceeded_limits | none |
| log_count | 3 |

### P2 day 2 (2026-10-09)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B01 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D06 | 1.5 | ACTIVE |
| PLAN_ITEM | NG-D22 | 1 | ACTIVE |
| PLAN_ITEM | NG-S04 | 2 | ACTIVE |

| field | value |
| --- | --- |
| status | ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

Streak at last day: 1

## 4. P3 logs and adherence

### P3 day 0 (2026-10-07)

| kind | item | amount | status |
| --- | --- | --- | --- |
| MEAL | NG-B01 | 1 | ACTIVE |

| field | value |
| --- | --- |
| status | — |
| reason | NO_TARGET |
| completion | — |
| exceeded_limits | none |
| log_count | 1 |

Streak at last day: 0

## 5. Layer 1 survivors and variety

| persona | slot | survivors | evaluated | removing_codes |
| --- | --- | --- | --- | --- |
| P1 | BREAKFAST | 50 | 158 | NO_OCCASION:BREAKFAST 108 |
| P1 | LUNCH | 68 | 158 | NO_OCCASION:LUNCH 90 |
| P1 | DINNER | 72 | 158 | NO_OCCASION:DINNER 86 |
| P1 | SNACK | 62 | 158 | NO_OCCASION:SNACK 96 |
| P2 | BREAKFAST | 36 | 158 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 7, MAX_PER_MEAL:carbohydrate 46, NO_OCCASION:BREAKFAST 108 |
| P2 | LUNCH | 33 | 158 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 7, MAX_PER_MEAL:carbohydrate 46, NO_OCCASION:LUNCH 90 |
| P2 | DINNER | 52 | 158 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 7, MAX_PER_MEAL:carbohydrate 46, NO_OCCASION:DINNER 86 |
| P2 | SNACK | 52 | 158 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 7, MAX_PER_MEAL:carbohydrate 46, NO_OCCASION:SNACK 96 |

P1 variety across three days: 7 distinct meals / 12 items.

## 6. Planner timing

| statistic | ms |
| --- | --- |
| n | 6 |
| min | 65.675 |
| median | 82.971 |
| max | 138.163 |

## 7. Observations

- P1 day 0 sodium total: 2213.299 mg; no limit applies (#69).
- P1 day 1 sodium total: 2148.259 mg; no limit applies (#69).
- P1 day 2 sodium total: 1818.165 mg; no limit applies (#69).
- The three P1 day plans share 2 of 7 meals.
- P1 used 7 distinct meals across 12 planned items.
- P1 day-2 plan uses reason WEIGHT_UPDATE; INITIAL target closed=True.
- P2 day-2 weight 70.4 kg target_status=NOT_TRIGGERED.
- P2 day 0 plan vs max_per_day: sodium 1961.5645/2000; sugars 34.508/43.45.
- P2 day 0 kcal_within_10pct=True; unmet_minimums=1.
- P2 day 1 plan vs max_per_day: sodium 1815.8695/2000; sugars 30.182/43.45.
- P2 day 1 kcal_within_10pct=False; unmet_minimums=1.
- P2 day 2 plan vs max_per_day: sodium 1961.5645/2000; sugars 34.508/43.45.
- P2 day 2 kcal_within_10pct=True; unmet_minimums=1.
- P1 day 0 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 kcal_within_10pct=False; adherence=NOT_ACHIEVED; completion=0.500.
- P1 day 2 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 lunch swapped NG-L47 → NG-D01.
- P2 day 1 lunch swapped NG-D06 → NG-D01.
- P3 screening eligible=False reasons=UNSUPPORTED_CONDITION:DIABETES_INSULIN; user_targets=0; adherence status=None reason=NO_TARGET.
- Mandatory nutrients in the loaded catalog: 9.
