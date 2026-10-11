# Raw table profile

## food.csv
- rows: 7793
- columns: 5
- null counts of key columns:
  - fdc_id: 0
  - description: 0
  - food_category_id: 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## food_nutrient.csv
- rows: 644125
- columns: 11
- null counts of key columns:
  - fdc_id: 0
  - nutrient_id: 0
  - amount: 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## nutrient.csv
- rows: 474
- columns: 5
- null counts of key columns:
  - id: 0
  - nutrient_nbr: 12
- schema errors: 0 (expected: none)
- duplicate keys: 0

## Ingredient Nutrient Values
- rows: 112320
- columns: 10
- null counts of key columns:
  - Ingredient code: 0
  - Nutrient code: 0
  - Nutrient value: 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## FNDDS Nutrient Values
- rows: 5431
- columns: 69
- null counts of key columns:
  - Food code: 0
  - Main food description: 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## Portions and Weights
- rows: 22046
- columns: 7
- null counts of key columns:
  - Food code: 0
  - Portion weight (g): 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## Foods and Beverages
- rows: 5432
- columns: 5
- null counts of key columns:
  - Food code: 0
  - Main food description: 0
- schema errors: 0 (expected: none)
- duplicate keys: 0

## #93 Feasibility: SR mandatory-nutrient gaps vs FNDDS ingredient fill

- SR Legacy foods: 7793
- foods missing at least one mandatory nutrient: 2083
- missing (food, nutrient) gaps: 3174
- of those gaps, FNDDS Ingredient Nutrient Values fills: 17

### Per-nutrient

| nutrient | source_code | SR foods missing | of which FNDDS fills |
|---|---|---:|---:|
| energy_kcal | 208 | 0 | 0 |
| protein | 203 | 0 | 0 |
| total_fat | 204 | 0 | 0 |
| carbohydrate | 205 | 0 | 0 |
| fiber | 291 | 562 | 1 |
| sugars | 269 | 1786 | 1 |
| saturated_fat | 606 | 343 | 7 |
| cholesterol | 601 | 399 | 8 |
| sodium | 307 | 84 | 0 |

### F-03 cases

#### NDB 17013 (lamb)
- SR lacks: sugars
- FNDDS values: (none for the nutrients SR lacks)

#### NDB 20028 (dry couscous)
- SR lacks: sugars
- FNDDS values: (none for the nutrients SR lacks)

### Agreement

FNDDS values for nutrients SR also publishes that differ by more than 5%: 485 of 15049
