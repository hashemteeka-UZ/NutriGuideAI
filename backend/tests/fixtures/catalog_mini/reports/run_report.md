# Catalog run report

## Input files

- `ingredients.yaml`: `e4c0ea5ad3f4229be928e7de3f6cfbbfe206c9266dd213ea343b980782646f20`
- `manual_foods.yaml`: `1a59d472a52a6de17ecd584a9ae1a158f109efc462b2d10b035b3a9a3baebf9c`
- `meals/batch_01.yaml`: `98eef8ee77dc43cc82dad1ff1e18f27bf95eba1e65081843784fef6977f359d0`
- `reference_seed.yaml`: `fa801883387fddb2e9f6c9111939d503380c99dcfab0442cabb3332522cdac9d`
- `sources/fndds_ingredient_subset.csv`: `a6d3f31208f851fd8d508bc8b373bcb877bd9adf43df0fc3cf6a7be3a3b56714`
- `sources/source_manifest.yaml`: `80158014809b5306888797567f705dc060ac31abacb316b790e03214aefedae6`
- `sources/sr_legacy_subset.csv`: `39dfc89caa86a8b62472fadbec85f14f701cff271b0c3c91b42acf8185c810a2`

## foods

- total: 8
- by outcome:
  - accepted: 5
  - excluded: 1
  - quarantine: 2
- by outcome and reason:
  - accepted:accepted: 5
  - excluded:non_permissible_ingredient: 1
  - quarantine:ingredient_status_uncertain: 1
  - quarantine:missing_mandatory_nutrient: 1

## ingredients

- total: 8
- by outcome:
  - accepted: 5
  - excluded: 1
  - quarantine: 2
- by outcome and reason:
  - accepted:accepted: 5
  - excluded:non_permissible_ingredient: 1
  - quarantine:ingredient_status_uncertain: 1
  - quarantine:missing_mandatory_nutrient: 1

## meals

- total: 7
- by outcome:
  - accepted: 2
  - excluded: 1
  - quarantine: 4
- by outcome and reason:
  - accepted:accepted: 2
  - excluded:uses_excluded_ingredient: 1
  - quarantine:G10: 1
  - quarantine:not_reviewed: 1
  - quarantine:uses_quarantined_ingredient: 2

## Nutrient fills (#93)

| ndb | nutrient | value | source |
|---|---|---:|---|
| 99013 | sugars | 0 | FNDDS 2021-2023 Ingredient Nutrient Values |

## Meals by quality tier

  - GOLD: 1
  - SILVER: 1

## Meals per occasion tag

  - breakfast_suitable: 0
  - lunch_suitable: 1
  - dinner_suitable: 1
  - snack_suitable: 0

## Share per cuisine

  - LIBYAN: 2 (100.0%)
