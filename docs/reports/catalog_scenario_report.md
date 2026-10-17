# F.1-e scenario report

Generated from `run_f1_scenario` with `start_date` 2026-10-07 and `start_now` 2026-10-07T05:00:00+00:00.

## 1. Data and versions

| field | value |
| --- | --- |
| dataset_version | f1_slice_v0, f1_slice_v1, team_recipes_v1, team_recipes_v2 |
| computation_version | calc_v1 |
| tag_rules_version | tags_v2 |
| planner_version | greedy_v1 |
| formula_version | targets_v1 |
| meals | 121 |
| active meals | 110 |
| inactive meals | 11 |
| foods | 178 |

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
| conditions | CKD |
| timezone | Africa/Tripoli |
| screening_eligible | False |
| screening_reasons | UNSUPPORTED_CONDITION:CKD |

No `user_targets` rows.

Resolved limits: none (no target).

## 3. P1 plans

### P1 day 0 (2026-10-07)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B08 | فول بالطحينة | 1.5 | 582.3075 | 28.8345 | 99.792 | 699.9675 | 7.0815 | 19.2105 | 1.4835 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-L04 | دجاج بالأرز المبهر والخضار | 1.5 | 811.7595 | 48.156 | 105.21 | 1093.3725 | 6.4725 | 5.895 | 3.906 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-L02 | مبكبكة بلحم الضأن | 1 | 580.44 | 29.128 | 82.713 | 657.655 | 6.445 | 4.842 | 3.178 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | NG-D17 | تبولة | 2 | 342 | 9.046 | 41.83 | 589.706 | 6.49 | 10.326 | 2.582 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2316.507 | 2316 | target |
| protein | 115.1645 | 126 | target |
| carbohydrate | 329.545 | 279.3 | target |
| fat | 63.6775 | 77.2 | target |
| fiber | 40.2735 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

### P1 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B08 | فول بالطحينة | 1.5 | 582.3075 | 28.8345 | 99.792 | 699.9675 | 7.0815 | 19.2105 | 1.4835 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-D01 | شربة ليبية بلحم الضأن | 1.5 | 431.3925 | 24.7635 | 50.514 | 1047.4575 | 6.7845 | 5.9325 | 3.141 | HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-L02 | مبكبكة بلحم الضأن | 1 | 580.44 | 29.128 | 82.713 | 657.655 | 6.445 | 4.842 | 3.178 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | NG-D17 | تبولة | 2 | 342 | 9.046 | 41.83 | 589.706 | 6.49 | 10.326 | 2.582 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1936.14 | 2316 | target |
| protein | 91.772 | 126 | target |
| carbohydrate | 274.849 | 279.3 | target |
| fat | 58.06 | 77.2 | target |
| fiber | 40.311 | 32 | soft target |

kcal_within_10pct: False

unmet_minimums: none

### P1 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B08 | فول بالطحينة | 1.5 | 582.3075 | 28.8345 | 99.792 | 699.9675 | 7.0815 | 19.2105 | 1.4835 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-D04 | صدر دجاج مشوي مع سلطة وخبز أسمر | 2 | 807.75 | 71.14 | 80.566 | 1409.16 | 9.362 | 11.27 | 3.842 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-D01 | شربة ليبية بلحم الضأن | 2 | 575.19 | 33.018 | 67.352 | 1396.61 | 9.046 | 7.91 | 4.188 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | F1-B04 | زبادي يوناني بالخيار وزيت الزيتون مع خبز أسمر | 1 | 333.18 | 23.872 | 42.875 | 705.92 | 8.609 | 4.225 | 1.326 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2298.4275 | 2299 | target |
| protein | 156.8645 | 124.5 | target |
| carbohydrate | 290.585 | 277.9 | target |
| fat | 63.3645 | 76.6 | target |
| fiber | 42.6155 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

## 3. P2 plans

### P2 day 0 (2026-10-07)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-L25 | مجدرة مع زبادي | 0.5 | 264.2 | 11.966 | 39.0275 | 252.9975 | 7.507 | 4.014 | 1.6095 | LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1661.402 | 1738 | target |
| protein | 94.2685 | 70 | target |
| carbohydrate | 119.6175 | 234.2 | target |
| fat | 94.009 | 57.9 | target |
| fiber | 21.803 | 24 | soft target |
| max sodium | 1948.522 | 2000 | max_per_day |
| max sugars | 40.778 | 43.45 | max_per_day |
| min fiber | 21.803 | 25 | min_per_day |

kcal_within_10pct: True

unmet_minimums: fiber min 25 total 21.803

### P2 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | F1-D07 | تبولة | 1.5 | 366.45 | 8.64 | 43.9515 | 639.495 | 6.5235 | 9.3375 | 2.853 | LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-L25 | مجدرة مع زبادي | 0.5 | 264.2 | 11.966 | 39.0275 | 252.9975 | 7.507 | 4.014 | 1.6095 | LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1446.3725 | 1738 | target |
| protein | 56.662 | 70 | target |
| carbohydrate | 142.1925 | 234.2 | target |
| fat | 79.0465 | 57.9 | target |
| fiber | 24.2315 | 24 | soft target |
| max sodium | 1769.3725 | 2000 | max_per_day |
| max sugars | 39.731 | 43.45 | max_per_day |
| min fiber | 24.2315 | 25 | min_per_day |

kcal_within_10pct: False

unmet_minimums: fiber min 25 total 24.2315

### P2 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | NG-B01 | عجة بالبقدونس | 1.5 | 421.5225 | 25.674 | 26.2095 | 868.38 | 4.3185 | 4.44 | 6.1185 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | NG-D06 | سلمون بالفرن مع بروكلي وجزر | 1.5 | 581.4795 | 46.2465 | 21.3765 | 818.6445 | 7.5705 | 6.909 | 7.3515 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | NG-L25 | مجدرة مع زبادي | 0.5 | 264.2 | 11.966 | 39.0275 | 252.9975 | 7.507 | 4.014 | 1.6095 | LOW_SATURATED_FAT, LOW_SODIUM, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | NG-S04 | لوز وجوز وزبيب | 2 | 394.2 | 10.382 | 33.004 | 8.5 | 21.382 | 6.44 | 2.394 | HIGH_FIBER, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1661.402 | 1738 | target |
| protein | 94.2685 | 70 | target |
| carbohydrate | 119.6175 | 234.2 | target |
| fat | 94.009 | 57.9 | target |
| fiber | 21.803 | 24 | soft target |
| max sodium | 1948.522 | 2000 | max_per_day |
| max sugars | 40.778 | 43.45 | max_per_day |
| min fiber | 21.803 | 25 | min_per_day |

kcal_within_10pct: True

unmet_minimums: fiber min 25 total 21.803

## 3. P3 plans

### P3 day 0 (2026-10-07)

No plan.

## 4. P1 logs and adherence

### P1 day 0 (2026-10-07)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | NG-B08 | 1.5 | ACTIVE |
| PLAN_ITEM | F1-L04 | 1.5 | ACTIVE |
| PLAN_ITEM | F1-L02 | 1 | ACTIVE |
| PLAN_ITEM | NG-D17 | 2 | ACTIVE |

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
| PLAN_ITEM | NG-B08 | 0.75 | TOMBSTONE |
| PLAN_ITEM | NG-B08 | 1.5 | ACTIVE |
| PLAN_ITEM | F1-D01 | 1.5 | ACTIVE |
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
| PLAN_ITEM | NG-B08 | 1.5 | ACTIVE |
| PLAN_ITEM | F1-D04 | 2 | ACTIVE |
| PLAN_ITEM | F1-D01 | 2 | ACTIVE |
| PLAN_ITEM | F1-B04 | 1 | ACTIVE |

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
| PLAN_ITEM | NG-L25 | 0.5 | ACTIVE |
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
| PLAN_ITEM | F1-D07 | 1.5 | ACTIVE |
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
| PLAN_ITEM | NG-L25 | 0.5 | ACTIVE |
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
| MEAL | F1-B01 | 1 | ACTIVE |

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
| P1 | BREAKFAST | 39 | 121 | INACTIVE 11, NO_OCCASION:BREAKFAST 81 |
| P1 | LUNCH | 57 | 121 | INACTIVE 11, NO_OCCASION:LUNCH 56 |
| P1 | DINNER | 62 | 121 | INACTIVE 11, NO_OCCASION:DINNER 53 |
| P1 | SNACK | 31 | 121 | INACTIVE 11, NO_OCCASION:SNACK 87 |
| P2 | BREAKFAST | 29 | 121 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 3, INACTIVE 11, MAX_PER_MEAL:carbohydrate 33, NO_OCCASION:BREAKFAST 81 |
| P2 | LUNCH | 32 | 121 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 3, INACTIVE 11, MAX_PER_MEAL:carbohydrate 33, NO_OCCASION:LUNCH 56 |
| P2 | DINNER | 49 | 121 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 3, INACTIVE 11, MAX_PER_MEAL:carbohydrate 33, NO_OCCASION:DINNER 53 |
| P2 | SNACK | 27 | 121 | ALLERGEN:Peanut 2, AVOID_TAG:added_sugar 3, INACTIVE 11, MAX_PER_MEAL:carbohydrate 33, NO_OCCASION:SNACK 87 |

P1 variety across three days: 7 distinct meals / 12 items.

## 6. Planner timing

| statistic | ms |
| --- | --- |
| n | 6 |
| min | 31.733 |
| median | 47.897 |
| max | 74.039 |

## 7. Observations

- P1 day 0 sodium total: 3040.701 mg; no limit applies (#69).
- P1 day 1 sodium total: 2994.786 mg; no limit applies (#69).
- P1 day 2 sodium total: 4211.6575 mg; no limit applies (#69).
- The three P1 day plans share 1 of 7 meals.
- P1 used 7 distinct meals across 12 planned items.
- P1 day-2 plan uses reason WEIGHT_UPDATE; INITIAL target closed=True.
- P2 day-2 weight 70.4 kg target_status=NOT_TRIGGERED.
- P2 day 0 plan vs max_per_day: sodium 1948.522/2000; sugars 40.778/43.45.
- P2 day 0 kcal_within_10pct=True; unmet_minimums=1.
- P2 day 1 plan vs max_per_day: sodium 1769.3725/2000; sugars 39.731/43.45.
- P2 day 1 kcal_within_10pct=False; unmet_minimums=1.
- P2 day 2 plan vs max_per_day: sodium 1948.522/2000; sugars 40.778/43.45.
- P2 day 2 kcal_within_10pct=True; unmet_minimums=1.
- P1 day 0 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 kcal_within_10pct=False; adherence=NOT_ACHIEVED; completion=0.500.
- P1 day 2 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 lunch swapped F1-L04 → F1-D01.
- P2 day 1 lunch swapped NG-D06 → F1-D07.
- P3 screening eligible=False reasons=UNSUPPORTED_CONDITION:CKD; user_targets=0; adherence status=None reason=NO_TARGET.
- Mandatory nutrients in the loaded catalog: 9.
