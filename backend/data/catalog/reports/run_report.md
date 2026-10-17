# Catalog run report

## Input files

- `ingredients.yaml`: `9dfea1d0a769d038f9b448c5e734860c85fb52ae3b186a1310074cf85ce1e1d5`
- `meals/team_recipes_batch_01.yaml`: `d8248ec09a928f5ebee3372a703c9642d42bd8256d6d9affdc3b354cd72a9aa0`
- `meals/team_recipes_batch_02.yaml`: `571fe29549a9f1a3640b95166a8e6614fe2eb81cd20f5b65eed4fde02408501d`
- `reference_seed.yaml`: `e6401e0387f6ae1c57b92e7e25e22d8e6a994726819a4f1b53d4ae180f873572`
- `sources/fndds_ingredient_subset.csv`: `733f0c8a17d26ed6ecd820e6c716b67919d17a9b117d36aa4546b2d25185cf6e`
- `sources/source_manifest.yaml`: `107f09d6c8f7975b7cb50643144dbf1f3305ac4f6ae9cfafec78e5c51725798f`
- `sources/sr_legacy_subset.csv`: `9b8a1c09d0f79b8b99a4a8e4e2538c2e2b8a35fa83da3bec1b4e3f29d629c856`

## foods

- total: 196
- by outcome:
  - accepted: 177
  - quarantine: 19
- by outcome and reason:
  - accepted:accepted: 177
  - quarantine:energy_inconsistent: 4
  - quarantine:missing_mandatory_nutrient: 15

## ingredients

- total: 196
- by outcome:
  - accepted: 177
  - quarantine: 19
- by outcome and reason:
  - accepted:accepted: 177
  - quarantine:energy_inconsistent: 4
  - quarantine:missing_mandatory_nutrient: 15

## meals

- total: 75
- by outcome:
  - accepted: 75
- by outcome and reason:
  - accepted:accepted: 75

## Nutrient fills (#93)

| ndb | nutrient | value | source |
|---|---|---:|---|
| 12006 | sugars | 1.55 | FNDDS 2021-2023 Ingredient Nutrient Values |

## Meals by quality tier

  - GOLD: 68
  - SILVER: 7

## Meals per occasion tag

  - breakfast_suitable: 29
  - lunch_suitable: 36
  - dinner_suitable: 44
  - snack_suitable: 23

## Share per cuisine

  - EGYPTIAN: 5 (6.7%)
  - GENERAL: 37 (49.3%)
  - LEVANTINE: 7 (9.3%)
  - LIBYAN: 26 (34.7%)

## Load counts (inserted / updated / unchanged / deactivated)

  categories                     0 /    0 /   17 /    0
  cuisines                       0 /    0 /    5 /    0
  allergens                      0 /    0 /    9 /    0
  dietary_tags                   0 /    0 /   11 /    0
  health_conditions              0 /    0 /    5 /    0
  nutrients                      0 /    0 /   10 /    0
  condition_nutrient_limits      0 /    0 /    7 /    0
  condition_tag_restrictions     0 /    0 /    4 /    0
  foods                          0 /    0 /  177 /    0
  food_nutrients                 0 /    0 / 1770 /    0
  ingredients                    0 /    0 /  177 /    0
  ingredient_aliases             0 /    0 /  389 /    0
  ingredient_allergens           0 /    0 /   45 /    0
  ingredient_tags                0 /    0 /    4 /    0
  meals                          0 /    0 /   75 /    0
  meal_translations              0 /    0 /   75 /    0
  meal_ingredients               0 /    0 /  586 /    0
  meal_tags                      0 /    0 /  199 /    0

- deactivated meals: []
- reactivated meals: []
