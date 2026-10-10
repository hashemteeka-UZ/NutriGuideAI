# F.1-e scenario report

Generated from `run_f1_scenario` with `start_date` 2026-10-07 and `start_now` 2026-10-07T05:00:00+00:00.

## 1. Data and versions

| field | value |
| --- | --- |
| dataset_version | f1_slice_v0, f1_slice_v1 |
| computation_version | calc_v1 |
| tag_rules_version | tags_v1 |
| planner_version | greedy_v1 |
| formula_version | targets_v1 |
| meals | 36 |
| active meals | 35 |
| inactive meals | 1 |
| foods | 63 |

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
| BREAKFAST | F1-B02 | فول مدمس بزيت الزيتون والليمون | 2 | 593.426 | 34.262 | 80.11 | 812.13 | 9.77 | 32.802 | 2.458 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-L04 | دجاج بالأرز المبهر والخضار | 1.5 | 811.7595 | 48.156 | 105.21 | 1093.3725 | 6.4725 | 5.895 | 3.906 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-L02 | مبكبكة بلحم الضأن | 1 | 580.44 | 29.128 | 82.713 | 657.655 | 6.445 | 4.842 | 3.178 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | F1-B04 | زبادي يوناني بالخيار وزيت الزيتون مع خبز أسمر | 1 | 333.18 | 23.872 | 42.875 | 705.92 | 8.609 | 4.225 | 1.326 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2318.8055 | 2316 | target |
| protein | 135.418 | 126 | target |
| carbohydrate | 310.908 | 279.3 | target |
| fat | 60.961 | 77.2 | target |
| fiber | 47.764 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

### P1 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | F1-B02 | فول مدمس بزيت الزيتون والليمون | 2 | 593.426 | 34.262 | 80.11 | 812.13 | 9.77 | 32.802 | 2.458 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-D01 | شربة ليبية بلحم الضأن | 1.5 | 431.3925 | 24.7635 | 50.514 | 1047.4575 | 6.7845 | 5.9325 | 3.141 | HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-L02 | مبكبكة بلحم الضأن | 1 | 580.44 | 29.128 | 82.713 | 657.655 | 6.445 | 4.842 | 3.178 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | F1-B04 | زبادي يوناني بالخيار وزيت الزيتون مع خبز أسمر | 1 | 333.18 | 23.872 | 42.875 | 705.92 | 8.609 | 4.225 | 1.326 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1938.4385 | 2316 | target |
| protein | 112.0255 | 126 | target |
| carbohydrate | 256.212 | 279.3 | target |
| fat | 55.3435 | 77.2 | target |
| fiber | 47.8015 | 32 | soft target |

kcal_within_10pct: False

unmet_minimums: none

### P1 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | F1-B02 | فول مدمس بزيت الزيتون والليمون | 2 | 593.426 | 34.262 | 80.11 | 812.13 | 9.77 | 32.802 | 2.458 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| LUNCH | F1-D04 | صدر دجاج مشوي مع سلطة وخبز أسمر | 2 | 807.75 | 71.14 | 80.566 | 1409.16 | 9.362 | 11.27 | 3.842 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| DINNER | F1-D01 | شربة ليبية بلحم الضأن | 2 | 575.19 | 33.018 | 67.352 | 1396.61 | 9.046 | 7.91 | 4.188 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |
| SNACK | F1-B04 | زبادي يوناني بالخيار وزيت الزيتون مع خبز أسمر | 1 | 333.18 | 23.872 | 42.875 | 705.92 | 8.609 | 4.225 | 1.326 | FITS_KCAL_TARGET, HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 2309.546 | 2299 | target |
| protein | 162.292 | 124.5 | target |
| carbohydrate | 270.903 | 277.9 | target |
| fat | 70.201 | 76.6 | target |
| fiber | 56.207 | 32 | soft target |

kcal_within_10pct: True

unmet_minimums: none

## 3. P2 plans

### P2 day 0 (2026-10-07)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | F1-B01 | شكشوكة ليبية مع خبز أسمر | 1 | 447.93 | 21.888 | 51.929 | 993.17 | 10.9 | 8.494 | 4.444 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | F1-D04 | صدر دجاج مشوي مع سلطة وخبز أسمر | 1 | 403.875 | 35.57 | 40.283 | 704.58 | 4.681 | 5.635 | 1.921 | HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | F1-D05 | مجدرة بالبرغل | 0.5 | 234.1065 | 9.7095 | 38.4735 | 252.4675 | 2.2085 | 6.477 | 0.8085 | LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | F1-S01 | تمر مع لوز | 0.5 | 128.4 | 2.7275 | 20.9125 | 0.6 | 16.2725 | 3.25 | 0.388 | HIGH_FIBER, LOW_SATURATED_FAT, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1214.3115 | 1738 | target |
| protein | 69.895 | 70 | target |
| carbohydrate | 151.598 | 234.2 | target |
| fat | 41.958 | 57.9 | target |
| fiber | 23.856 | 24 | soft target |
| max sodium | 1950.8175 | 2000 | max_per_day |
| max sugars | 34.062 | 43.45 | max_per_day |
| min fiber | 23.856 | 25 | min_per_day |

kcal_within_10pct: False

unmet_minimums: fiber min 25 total 23.856

### P2 day 1 (2026-10-08)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | F1-B01 | شكشوكة ليبية مع خبز أسمر | 1 | 447.93 | 21.888 | 51.929 | 993.17 | 10.9 | 8.494 | 4.444 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | F1-D01 | شربة ليبية بلحم الضأن | 1 | 287.595 | 16.509 | 33.676 | 698.305 | 4.523 | 3.955 | 2.094 | HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR, MATCHES_LIKED_INGREDIENT, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | F1-D05 | مجدرة بالبرغل | 0.5 | 234.1065 | 9.7095 | 38.4735 | 252.4675 | 2.2085 | 6.477 | 0.8085 | LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | F1-S01 | تمر مع لوز | 0.5 | 128.4 | 2.7275 | 20.9125 | 0.6 | 16.2725 | 3.25 | 0.388 | HIGH_FIBER, LOW_SATURATED_FAT, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1098.0315 | 1738 | target |
| protein | 50.834 | 70 | target |
| carbohydrate | 144.991 | 234.2 | target |
| fat | 39.602 | 57.9 | target |
| fiber | 22.176 | 24 | soft target |
| max sodium | 1944.5425 | 2000 | max_per_day |
| max sugars | 33.904 | 43.45 | max_per_day |
| min fiber | 22.176 | 25 | min_per_day |

kcal_within_10pct: False

unmet_minimums: fiber min 25 total 22.176

### P2 day 2 (2026-10-09)

| slot | meal | name_ar | multiplier | kcal | protein | carbohydrate | sodium | sugars | fiber | saturated_fat | reason_codes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BREAKFAST | F1-B01 | شكشوكة ليبية مع خبز أسمر | 1 | 447.93 | 21.888 | 51.929 | 993.17 | 10.9 | 8.494 | 4.444 | FITS_KCAL_TARGET, LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| LUNCH | F1-D04 | صدر دجاج مشوي مع سلطة وخبز أسمر | 1 | 403.875 | 35.57 | 40.283 | 704.58 | 4.681 | 5.635 | 1.921 | HIGH_PROTEIN, LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| DINNER | F1-D05 | مجدرة بالبرغل | 0.5 | 234.1065 | 9.7095 | 38.4735 | 252.4675 | 2.2085 | 6.477 | 0.8085 | LOW_SATURATED_FAT, LOW_SUGAR, SUITS_CONDITION_DIABETES_T2, SUITS_CONDITION_HYPERTENSION |
| SNACK | F1-S01 | تمر مع لوز | 0.5 | 128.4 | 2.7275 | 20.9125 | 0.6 | 16.2725 | 3.25 | 0.388 | HIGH_FIBER, LOW_SATURATED_FAT, LOW_SODIUM, SUITS_CONDITION_HYPERTENSION |

| quantity | plan_total | target_or_limit | basis |
| --- | --- | --- | --- |
| energy_kcal | 1214.3115 | 1738 | target |
| protein | 69.895 | 70 | target |
| carbohydrate | 151.598 | 234.2 | target |
| fat | 41.958 | 57.9 | target |
| fiber | 23.856 | 24 | soft target |
| max sodium | 1950.8175 | 2000 | max_per_day |
| max sugars | 34.062 | 43.45 | max_per_day |
| min fiber | 23.856 | 25 | min_per_day |

kcal_within_10pct: False

unmet_minimums: fiber min 25 total 23.856

## 3. P3 plans

### P3 day 0 (2026-10-07)

No plan.

## 4. P1 logs and adherence

### P1 day 0 (2026-10-07)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | F1-B02 | 2 | ACTIVE |
| PLAN_ITEM | F1-L04 | 1.5 | ACTIVE |
| PLAN_ITEM | F1-L02 | 1 | ACTIVE |
| PLAN_ITEM | F1-B04 | 1 | ACTIVE |

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
| PLAN_ITEM | F1-B02 | 1 | TOMBSTONE |
| PLAN_ITEM | F1-B02 | 2 | ACTIVE |
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
| PLAN_ITEM | F1-B02 | 2 | ACTIVE |
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
| PLAN_ITEM | F1-B01 | 1 | ACTIVE |
| PLAN_ITEM | F1-D04 | 1 | ACTIVE |
| PLAN_ITEM | F1-D05 | 0.5 | ACTIVE |
| PLAN_ITEM | F1-S01 | 0.5 | ACTIVE |

| field | value |
| --- | --- |
| status | NOT_ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

### P2 day 1 (2026-10-08)

| kind | item | amount | status |
| --- | --- | --- | --- |
| PLAN_ITEM | F1-B01 | 0.5 | TOMBSTONE |
| PLAN_ITEM | F1-B01 | 1 | ACTIVE |
| PLAN_ITEM | F1-D01 | 1 | ACTIVE |
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
| PLAN_ITEM | F1-B01 | 1 | ACTIVE |
| PLAN_ITEM | F1-D04 | 1 | ACTIVE |
| PLAN_ITEM | F1-D05 | 0.5 | ACTIVE |
| PLAN_ITEM | F1-S01 | 0.5 | ACTIVE |

| field | value |
| --- | --- |
| status | NOT_ACHIEVED |
| reason | — |
| completion | 1.000 |
| exceeded_limits | none |
| log_count | 4 |

Streak at last day: 0

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
| P1 | BREAKFAST | 10 | 36 | INACTIVE 1, NO_OCCASION:BREAKFAST 26 |
| P1 | LUNCH | 21 | 36 | INACTIVE 1, NO_OCCASION:LUNCH 15 |
| P1 | DINNER | 18 | 36 | INACTIVE 1, NO_OCCASION:DINNER 18 |
| P1 | SNACK | 8 | 36 | INACTIVE 1, NO_OCCASION:SNACK 27 |
| P2 | BREAKFAST | 6 | 36 | ALLERGEN:Peanut 1, AVOID_TAG:added_sugar 2, INACTIVE 1, MAX_PER_MEAL:carbohydrate 10, NO_OCCASION:BREAKFAST 26 |
| P2 | LUNCH | 12 | 36 | ALLERGEN:Peanut 1, AVOID_TAG:added_sugar 2, INACTIVE 1, MAX_PER_MEAL:carbohydrate 10, NO_OCCASION:LUNCH 15 |
| P2 | DINNER | 14 | 36 | ALLERGEN:Peanut 1, AVOID_TAG:added_sugar 2, INACTIVE 1, MAX_PER_MEAL:carbohydrate 10, NO_OCCASION:DINNER 18 |
| P2 | SNACK | 6 | 36 | ALLERGEN:Peanut 1, AVOID_TAG:added_sugar 2, INACTIVE 1, MAX_PER_MEAL:carbohydrate 10, NO_OCCASION:SNACK 27 |

P1 variety across three days: 6 distinct meals / 12 items.

## 6. Planner timing

| statistic | ms |
| --- | --- |
| n | 6 |
| min | 18.635 |
| median | 21.637 |
| max | 32.160 |

## 7. Observations

- P1 day 0 sodium total: 3269.0775 mg; no limit applies (#69).
- P1 day 1 sodium total: 3223.1625 mg; no limit applies (#69).
- P1 day 2 sodium total: 4323.82 mg; no limit applies (#69).
- The three P1 day plans share 2 of 6 meals.
- P1 used 6 distinct meals across 12 planned items.
- P1 day-2 plan uses reason WEIGHT_UPDATE; INITIAL target closed=True.
- P2 day-2 weight 70.4 kg target_status=NOT_TRIGGERED.
- P2 day 0 plan vs max_per_day: sodium 1950.8175/2000; sugars 34.062/43.45.
- P2 day 0 kcal_within_10pct=False; unmet_minimums=1.
- P2 day 1 plan vs max_per_day: sodium 1944.5425/2000; sugars 33.904/43.45.
- P2 day 1 kcal_within_10pct=False; unmet_minimums=1.
- P2 day 2 plan vs max_per_day: sodium 1950.8175/2000; sugars 34.062/43.45.
- P2 day 2 kcal_within_10pct=False; unmet_minimums=1.
- P1 day 0 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 kcal_within_10pct=False; adherence=NOT_ACHIEVED; completion=0.500.
- P1 day 2 kcal_within_10pct=True; adherence=ACHIEVED; completion=1.000.
- P1 day 1 lunch swapped F1-L04 → F1-D01.
- P2 day 1 lunch swapped F1-D04 → F1-D01.
- P3 screening eligible=False reasons=UNSUPPORTED_CONDITION:CKD; user_targets=0; adherence status=None reason=NO_TARGET.
- Mandatory nutrients in the loaded catalog: 9.
