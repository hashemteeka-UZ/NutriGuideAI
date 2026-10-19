# Protein coverage of the meal catalog (athlete / muscle-building path)

> Update 2026-10-19 (decision #175): the muscle-building path is cancelled permanently. This check is kept as history only.

Scope: `backend/data/catalog/meals/team_recipes_batch_01.yaml`, the only meal batch (40 meals, catalog_v1 / team_recipes_v1). The older `backend/data/f1_slice/slice_meals.yaml` is the F.1 seed and is not included. Values are per **one serving** at the default multiplier of 1.0.

## How the numbers are produced in the code

- **Meal nutrients (calc_v1)**: `backend/app/services/meal_nutrition.py:52` `_meal_total` adds `grams/100 * amount_per_100g` over the ingredients. Then `:113` sets `per_serving = total / servings`. A missing value counts as unknown, not as zero.
- **Food values**: ingredients map to SR Legacy NDB codes (`ingredients.yaml`, all 196 use `source: SR_LEGACY`). The FNDDS ingredient values fill a mandatory nutrient only when SR has no value (`backend/app/pipeline/classify.py:103` `fill_foods`). Energy is `energy_kcal` = SR nutrient 208 and protein is SR 203 (`reference_seed.yaml:113-122`). The script reads the same subsets: `sources/sr_legacy_subset.csv` and `sources/fndds_ingredient_subset.csv`.
- **Slots**: a meal can go in a slot only if it has the manual occasion tag `<slot>_suitable` (`backend/app/services/meal_filter.py:39-44`, check at `:242`). One meal can carry several slot tags, so the per-slot counts overlap.
- **Portion scaling**: the code supports it. Both planners choose a meal **and** a servings multiplier from `MULTIPLIERS = (0.5, 1.0, 1.5, 2.0)` (`backend/app/services/planner.py:68`). In cpsat_v1, `backend/app/services/optimizer.py:231` loops `for step in MULTIPLIERS`. Absolute protein scales linearly with the multiplier. Protein density (%E, g/100 kcal) does not change.
- **Day structure**: there is one meal per main slot (`planner.py:61`) and up to 2 snacks (`planner.py:70`). The energy shares are breakfast 0.25, lunch 0.35, dinner 0.25 and snacks 0.15 (`planner.py:62-67`). For a 2800 kcal day the slot targets are **B 700 / L 980 / D 700 / snack ≈210 each**.
- **Protein in cpsat_v1** is only a *daily* absolute deviation term in the objective (`optimizer.py:508`). There is **no per-meal protein minimum**. The `HIGH_PROTEIN` reason code means at least 20 % of energy from protein (`planner.py:76`), and it is only a label. The athlete protein target is 1.8 g/kg (`targets.py:56`).

## 1. Per-slot coverage (servings multiplier 1.0, plus scaling)

| slot | meals | P>=25g | P>=20g | P%E>=20 | P%E>=25 | reach 25g @x<=2.0 | 25g @ x<=1.5 | P>=25g at kcal-matched mult | median g/100kcal |
|---|---|---|---|---|---|---|---|---|---|
| breakfast | 16 | 2 | 2 | 9 | 7 | 8 | 6 | 8 | 5.73 |
| lunch | 18 | 10 | 12 | 13 | 11 | 14 | 12 | 14 | 7.09 |
| dinner | 23 | 9 | 11 | 14 | 12 | 16 | 14 | 15 | 6.50 |
| snack | 16 | 0 | 0 | 5 | 4 | 3 | 1 | 0 | 3.36 |


Column notes:
- "reach 25g @x<=2.0" and "25g @ x<=1.5" count the meals that reach 25 g within the planner's multiplier range.
- "kcal-matched mult" means the multiplier whose kcal is closest to the slot target for a 2800 kcal day. Almost every meal lands on 2.0 there, because the meals are small (median ≈300 kcal).

## 2. Portion scaling

Scaling is allowed in steps of 0.5–2.0×. With it, the number of meals that can reach 25 g rises as follows:
- breakfast: 2 → 8 (6 of them at ≤1.5×)
- lunch: 10 → 14
- dinner: 9 → 16
- snack: 0 → 3

But scaling needs large plates. Several meals only get there at 2.0×, for example oats with yogurt (609 kcal), toast with mozzarella (502 kcal) and vegetable couscous (831 kcal). 18 of the 40 meals cannot reach 25 g at any multiplier because their protein is below 12.5 g per serving. This covers every snack except Greek yogurt and all the drinks.

## 3. Top 10 / bottom 10 by protein density (g protein per 100 kcal)

Top 10:

| # | meal | slots | kcal | protein g |
|---|---|---|---|---|
| 1 | Greek yogurt with strawberries and banana (NG-S09) | snack,breakfast | 170 | 18.4 (10.80 g/100kcal, 43.2 %E) |
| 2 | Grilled chicken with garlic and lemon and potatoes (NG-L06) | lunch,dinner | 317 | 32.1 (10.14 g/100kcal, 40.5 %E) |
| 3 | Lamb liver with garlic and cumin (NG-B03) | breakfast,dinner | 307 | 29.4 (9.59 g/100kcal, 38.4 %E) |
| 4 | Green beans with beef (NG-L15) | lunch,dinner | 230 | 21.9 (9.53 g/100kcal, 38.1 %E) |
| 5 | Grilled chicken breast with quinoa and vegetables (NG-L16) | lunch,dinner | 372 | 35.0 (9.39 g/100kcal, 37.6 %E) |
| 6 | Chicken tagine with vegetables and olives (NG-L12) | lunch,dinner | 395 | 34.3 (8.70 g/100kcal, 34.8 %E) |
| 7 | Coffee with milk, no sugar (NG-S03) | snack,breakfast | 35 | 2.8 (8.16 g/100kcal, 32.6 %E) |
| 8 | Chicken soup with vegetables and barley (NG-D11) | lunch,dinner | 253 | 20.6 (8.12 g/100kcal, 32.5 %E) |
| 9 | Baked salmon with broccoli and carrots (NG-D06) | lunch,dinner | 388 | 30.8 (7.95 g/100kcal, 31.8 %E) |
| 10 | Tea with milk, no sugar (NG-S02) | snack,breakfast | 44 | 3.4 (7.75 g/100kcal, 31.0 %E) |

Bottom 10 (lowest density last):

| # | meal | slots | kcal | protein g |
|---|---|---|---|---|
| 31 | Vegetable couscous (NG-L02) | lunch,dinner | 416 | 12.9 (3.11 g/100kcal, 12.5 %E) |
| 32 | Mutabbal (eggplant with tahini) with wholewheat pita (NG-D07) | dinner,snack | 195 | 6.0 (3.06 g/100kcal, 12.3 %E) |
| 33 | Almonds, walnuts and raisins (NG-S04) | snack | 197 | 5.2 (2.63 g/100kcal, 10.5 %E) |
| 34 | Vegetable soup with barley (NG-D04) | lunch,dinner | 200 | 4.7 (2.36 g/100kcal, 9.4 %E) |
| 35 | Air-popped popcorn with olive oil (NG-S06) | snack | 141 | 3.2 (2.30 g/100kcal, 9.2 %E) |
| 36 | Apple with peanut butter (NG-S05) | snack | 168 | 3.7 (2.22 g/100kcal, 8.9 %E) |
| 37 | Rice with vegetables (NG-L05) | lunch,dinner | 388 | 8.1 (2.10 g/100kcal, 8.4 %E) |
| 38 | Dried figs with walnuts (NG-S08) | snack | 173 | 3.3 (1.89 g/100kcal, 7.6 %E) |
| 39 | Bsisa with dates (NG-B05) | breakfast,snack | 293 | 4.9 (1.68 g/100kcal, 6.7 %E) |
| 40 | Carrot salad with cumin (NG-D03) | dinner,snack | 92 | 1.2 (1.34 g/100kcal, 5.4 %E) |

## 4. Verdict

**The catalog is not yet enough for a per-main-meal minimum of about 25 g protein on a 2800 kcal athlete day.**

- **Breakfast is the main gap.** Only 2 of 16 breakfast-tagged meals reach 25 g at 1.0×, and both are savoury dinner-style dishes (lamb liver, tuna sandwich). With scaling, 8 of 16 reach it. Two of those are drinks or dinner-style dishes, so in practice about 5–6 real breakfast options pass, and most need 1.5–2.0×. The median breakfast density is 5.7 g/100 kcal. At the 700 kcal slot target that is about 40 g, so it works only if every breakfast is a double portion. The low-protein traditional breakfasts (bsisa, zummita, bread with oil and thyme, dates with buttermilk) stay below 25 g at any multiplier.
- **Lunch and dinner are adequate but thin for a weekly rotation.** 12 distinct meals tagged lunch or dinner have ≥25 g at 1.0×, and 19 have it at ≤2.0×. That is enough to fill one week without repeating. It is still few once allergens, dislikes and the previous-day exclusion are applied, and nearly every option is chicken, beef, lamb or fish. No vegetarian lunch or dinner reaches 25 g at 1.0×.
- **Snacks are weak for an athlete.** None reaches 20 g. Only Greek yogurt with fruit (18.4 g) comes close to a 15–20 g protein snack. Snacks are 0.15 of energy (about 420 kcal), and the current snacks average about 3–10 g protein.
- **Planner side, outside the data**: cpsat_v1 only balances *daily* protein. Even with better recipes, a per-meal floor would need a new constraint, for example `protein(position) >= 25 g` per main position. That would make the infeasibility risk in the breakfast slot visible right away.

**Rough number of new high-protein recipes needed.** Target: ≥25 g at 1.0× and ≥25 %E, about 450–650 kcal per serving, so that the 2800 kcal slot targets are met at 1.0–1.5× instead of 2.0×.

| slot | new recipes | what kind |
|---|---|---|
| Breakfast | **6–8** | eggs plus labneh or feta, shakshuka with eggs, ful with eggs, Greek-yogurt bowls, cottage/white-cheese plates, chicken or tuna wraps |
| Lunch | **3–5** | include 2 legume-based or vegetarian ones with ≥25 g (lentils with eggs or yogurt, chickpeas plus dairy) |
| Dinner | **3–5** | lighter dinners at ≥25 g: fish, chicken, egg-white or cottage based |
| Snack | **4–6** | ≥15 g each: Greek yogurt/labneh, milk or yogurt shakes, boiled eggs, tuna, roasted chickpeas with yogurt |

That is about **16–24 new recipes** in total. Breakfast is the priority.

## Appendix A: full per-meal results
### All meals (sorted by protein density)

| ref | name | slots | kcal | protein g | P %E | g/100kcal | mult to 25g | kcal at that mult |
|---|---|---|---|---|---|---|---|---|
| NG-S09 | Greek yogurt with strawberries and banana | snack,breakfast | 170 | 18.4 | 43.2 | 10.80 | 1.5 | 256 |
| NG-L06 | Grilled chicken with garlic and lemon and potatoes | lunch,dinner | 317 | 32.1 | 40.5 | 10.14 | 1.0 | 317 |
| NG-B03 | Lamb liver with garlic and cumin | breakfast,dinner | 307 | 29.4 | 38.4 | 9.59 | 1.0 | 307 |
| NG-L15 | Green beans with beef | lunch,dinner | 230 | 21.9 | 38.1 | 9.53 | 1.5 | 345 |
| NG-L16 | Grilled chicken breast with quinoa and vegetables | lunch,dinner | 372 | 35.0 | 37.6 | 9.39 | 1.0 | 372 |
| NG-L12 | Chicken tagine with vegetables and olives | lunch,dinner | 395 | 34.3 | 34.8 | 8.70 | 1.0 | 395 |
| NG-S03 | Coffee with milk, no sugar | snack,breakfast | 35 | 2.8 | 32.6 | 8.16 | - | - |
| NG-D11 | Chicken soup with vegetables and barley | lunch,dinner | 253 | 20.6 | 32.5 | 8.12 | 1.5 | 380 |
| NG-D06 | Baked salmon with broccoli and carrots | lunch,dinner | 388 | 30.8 | 31.8 | 7.95 | 1.0 | 388 |
| NG-S02 | Tea with milk, no sugar | snack,breakfast | 44 | 3.4 | 31.0 | 7.75 | - | - |
| NG-L13 | Black-eyed peas with lamb | lunch,dinner | 357 | 26.8 | 30.0 | 7.51 | 1.0 | 357 |
| NG-L01 | Couscous with fish | lunch | 491 | 36.2 | 29.5 | 7.37 | 1.0 | 491 |
| NG-L08 | Molokhia with chicken and rice | lunch | 447 | 32.0 | 28.6 | 7.15 | 1.0 | 447 |
| NG-D02 | Libyan tuna sandwich with harissa and olives | dinner,breakfast | 461 | 32.8 | 28.4 | 7.11 | 1.0 | 461 |
| NG-L17 | Beef with sauteed vegetables and brown rice | lunch,dinner | 452 | 31.8 | 28.1 | 7.03 | 1.0 | 452 |
| NG-L11 | Grilled sea bass with brown rice and salad | lunch,dinner | 438 | 29.4 | 26.8 | 6.71 | 1.0 | 438 |
| NG-B07 | Soft white cheese (low-fat cottage cheese) with tomato, cucumber and wholewheat pita | breakfast,dinner | 300 | 19.5 | 26.0 | 6.50 | 1.5 | 450 |
| NG-B11 | Wholewheat toast with mozzarella and vegetables | breakfast,snack | 251 | 15.8 | 25.3 | 6.32 | 2.0 | 502 |
| NG-B01 | Omelette with parsley | breakfast,dinner | 281 | 17.1 | 24.4 | 6.09 | 1.5 | 422 |
| NG-L10 | Maqluba with chicken and eggplant | lunch | 424 | 25.0 | 23.6 | 5.91 | 1.0 | 424 |
| NG-S01 | Yogurt with dates | snack,breakfast | 178 | 9.5 | 21.5 | 5.37 | - | - |
| NG-D09 | Lentil salad with vegetables | lunch,dinner | 203 | 10.5 | 20.7 | 5.17 | - | - |
| NG-B08 | Fava beans with tahini | breakfast,dinner | 388 | 19.2 | 19.8 | 4.95 | 1.5 | 582 |
| NG-L14 | Zucchini stuffed with rice and beef | lunch,dinner | 315 | 15.6 | 19.8 | 4.95 | 2.0 | 630 |
| NG-B09 | Oats with yogurt and blueberries | breakfast,snack | 305 | 14.4 | 18.9 | 4.73 | 2.0 | 609 |
| NG-B02 | Potato omelette | breakfast,dinner | 262 | 11.8 | 18.0 | 4.51 | - | - |
| NG-B06 | Dates with buttermilk | breakfast,snack | 213 | 9.3 | 17.4 | 4.35 | - | - |
| NG-B04 | Zummita (roasted barley flour) with olive oil and buttermilk | breakfast,snack | 341 | 11.9 | 13.9 | 3.48 | - | - |
| NG-D01 | Potato salad with egg | dinner,lunch | 222 | 7.4 | 13.4 | 3.35 | - | - |
| NG-B10 | Wholewheat bread with olive oil, thyme and tomato | breakfast,snack | 280 | 9.1 | 12.9 | 3.23 | - | - |
| NG-L02 | Vegetable couscous | lunch,dinner | 416 | 12.9 | 12.5 | 3.11 | 2.0 | 831 |
| NG-D07 | Mutabbal (eggplant with tahini) with wholewheat pita | dinner,snack | 195 | 6.0 | 12.3 | 3.06 | - | - |
| NG-S04 | Almonds, walnuts and raisins | snack | 197 | 5.2 | 10.5 | 2.63 | - | - |
| NG-D04 | Vegetable soup with barley | lunch,dinner | 200 | 4.7 | 9.4 | 2.36 | - | - |
| NG-S06 | Air-popped popcorn with olive oil | snack | 141 | 3.2 | 9.2 | 2.30 | - | - |
| NG-S05 | Apple with peanut butter | snack | 168 | 3.7 | 8.9 | 2.22 | - | - |
| NG-L05 | Rice with vegetables | lunch,dinner | 388 | 8.1 | 8.4 | 2.10 | - | - |
| NG-S08 | Dried figs with walnuts | snack | 173 | 3.3 | 7.6 | 1.89 | - | - |
| NG-B05 | Bsisa with dates | breakfast,snack | 293 | 4.9 | 6.7 | 1.68 | - | - |
| NG-D03 | Carrot salad with cumin | dinner,snack | 92 | 1.2 | 5.4 | 1.34 | - | - |

### Kcal-matched view (2800 kcal day; slot targets B 700 / L 980 / D 700 / snack 210)

| ref | name | slot | mult | kcal | protein g |
|---|---|---|---|---|---|
| NG-B03 | Lamb liver with garlic and cumin | breakfast | 2.0 | 613 | 58.8 |
| NG-D02 | Libyan tuna sandwich with harissa and olives | breakfast | 1.5 | 692 | 49.2 |
| NG-B07 | Soft white cheese (low-fat cottage cheese) with tomato, cucumber and wholewheat pita | breakfast | 2.0 | 600 | 39.0 |
| NG-B08 | Fava beans with tahini | breakfast | 2.0 | 776 | 38.4 |
| NG-S09 | Greek yogurt with strawberries and banana | breakfast | 2.0 | 341 | 36.8 |
| NG-B01 | Omelette with parsley | breakfast | 2.0 | 562 | 34.2 |
| NG-B11 | Wholewheat toast with mozzarella and vegetables | breakfast | 2.0 | 502 | 31.7 |
| NG-B09 | Oats with yogurt and blueberries | breakfast | 2.0 | 609 | 28.8 |
| NG-B04 | Zummita (roasted barley flour) with olive oil and buttermilk | breakfast | 2.0 | 682 | 23.7 |
| NG-B02 | Potato omelette | breakfast | 2.0 | 524 | 23.6 |
| NG-S01 | Yogurt with dates | breakfast | 2.0 | 355 | 19.1 |
| NG-B06 | Dates with buttermilk | breakfast | 2.0 | 426 | 18.5 |
| NG-B10 | Wholewheat bread with olive oil, thyme and tomato | breakfast | 2.0 | 561 | 18.1 |
| NG-B05 | Bsisa with dates | breakfast | 2.0 | 587 | 9.9 |
| NG-S02 | Tea with milk, no sugar | breakfast | 2.0 | 87 | 6.7 |
| NG-S03 | Coffee with milk, no sugar | breakfast | 2.0 | 70 | 5.7 |
| NG-L01 | Couscous with fish | lunch | 2.0 | 982 | 72.4 |
| NG-L16 | Grilled chicken breast with quinoa and vegetables | lunch | 2.0 | 745 | 70.0 |
| NG-L12 | Chicken tagine with vegetables and olives | lunch | 2.0 | 789 | 68.6 |
| NG-L06 | Grilled chicken with garlic and lemon and potatoes | lunch | 2.0 | 634 | 64.3 |
| NG-L08 | Molokhia with chicken and rice | lunch | 2.0 | 894 | 64.0 |
| NG-L17 | Beef with sauteed vegetables and brown rice | lunch | 2.0 | 904 | 63.5 |
| NG-D06 | Baked salmon with broccoli and carrots | lunch | 2.0 | 775 | 61.7 |
| NG-L11 | Grilled sea bass with brown rice and salad | lunch | 2.0 | 876 | 58.8 |
| NG-L13 | Black-eyed peas with lamb | lunch | 2.0 | 714 | 53.6 |
| NG-L10 | Maqluba with chicken and eggplant | lunch | 2.0 | 848 | 50.1 |
| NG-L15 | Green beans with beef | lunch | 2.0 | 460 | 43.9 |
| NG-D11 | Chicken soup with vegetables and barley | lunch | 2.0 | 507 | 41.1 |
| NG-L14 | Zucchini stuffed with rice and beef | lunch | 2.0 | 630 | 31.2 |
| NG-L02 | Vegetable couscous | lunch | 2.0 | 831 | 25.9 |
| NG-D09 | Lentil salad with vegetables | lunch | 2.0 | 406 | 21.0 |
| NG-L05 | Rice with vegetables | lunch | 2.0 | 776 | 16.3 |
| NG-D01 | Potato salad with egg | lunch | 2.0 | 445 | 14.9 |
| NG-D04 | Vegetable soup with barley | lunch | 2.0 | 401 | 9.5 |
| NG-L16 | Grilled chicken breast with quinoa and vegetables | dinner | 2.0 | 745 | 70.0 |
| NG-L12 | Chicken tagine with vegetables and olives | dinner | 2.0 | 789 | 68.6 |
| NG-L06 | Grilled chicken with garlic and lemon and potatoes | dinner | 2.0 | 634 | 64.3 |
| NG-D06 | Baked salmon with broccoli and carrots | dinner | 2.0 | 775 | 61.7 |
| NG-B03 | Lamb liver with garlic and cumin | dinner | 2.0 | 613 | 58.8 |
| NG-L13 | Black-eyed peas with lamb | dinner | 2.0 | 714 | 53.6 |
| NG-D02 | Libyan tuna sandwich with harissa and olives | dinner | 1.5 | 692 | 49.2 |
| NG-L17 | Beef with sauteed vegetables and brown rice | dinner | 1.5 | 678 | 47.6 |
| NG-L11 | Grilled sea bass with brown rice and salad | dinner | 1.5 | 657 | 44.1 |
| NG-L15 | Green beans with beef | dinner | 2.0 | 460 | 43.9 |
| NG-D11 | Chicken soup with vegetables and barley | dinner | 2.0 | 507 | 41.1 |
| NG-B07 | Soft white cheese (low-fat cottage cheese) with tomato, cucumber and wholewheat pita | dinner | 2.0 | 600 | 39.0 |
| NG-B08 | Fava beans with tahini | dinner | 2.0 | 776 | 38.4 |
| NG-B01 | Omelette with parsley | dinner | 2.0 | 562 | 34.2 |
| NG-L14 | Zucchini stuffed with rice and beef | dinner | 2.0 | 630 | 31.2 |
| NG-B02 | Potato omelette | dinner | 2.0 | 524 | 23.6 |
| NG-D09 | Lentil salad with vegetables | dinner | 2.0 | 406 | 21.0 |
| NG-L02 | Vegetable couscous | dinner | 1.5 | 623 | 19.4 |
| NG-L05 | Rice with vegetables | dinner | 2.0 | 776 | 16.3 |
| NG-D01 | Potato salad with egg | dinner | 2.0 | 445 | 14.9 |
| NG-D07 | Mutabbal (eggplant with tahini) with wholewheat pita | dinner | 2.0 | 390 | 11.9 |
| NG-D04 | Vegetable soup with barley | dinner | 2.0 | 401 | 9.5 |
| NG-D03 | Carrot salad with cumin | dinner | 2.0 | 184 | 2.5 |

## Appendix B: script used (run as `python3 -I protein_coverage.py repo/backend/data/catalog`)

```python
"""Protein coverage of the catalog meals (replicates calc_v1 for energy_kcal=208 and protein=203).

per_serving = sum(grams/100 * amount_per_100g) / servings  (app/services/meal_nutrition.py)
Food values: SR Legacy subset; FNDDS ingredient fill only when the SR value is missing (#93).
Multipliers: 0.5, 1.0, 1.5, 2.0 (app/services/planner.py MULTIPLIERS).
Slot kcal shares: breakfast .25, lunch .35, dinner .25, snacks .15 split over <=2 snacks.
"""
import csv
import sys
from collections import defaultdict
from pathlib import Path

import yaml

CAT = Path(sys.argv[1])  # backend/data/catalog
DAY_KCAL = 2800
MULTS = (0.5, 1.0, 1.5, 2.0)
SLOT_KCAL = {"breakfast": .25 * DAY_KCAL, "lunch": .35 * DAY_KCAL, "dinner": .25 * DAY_KCAL,
             "snack": .15 * DAY_KCAL / 2}  # per snack if 2 snacks
NUTS = {"208": "kcal", "203": "protein"}

sr = defaultdict(dict)
with open(CAT / "sources/sr_legacy_subset.csv") as f:
    for r in csv.DictReader(f):
        if r["nutrient_nbr"] in NUTS:
            sr[r["ndb_number"]][NUTS[r["nutrient_nbr"]]] = float(r["amount_per_100g"])
fn = defaultdict(dict)
with open(CAT / "sources/fndds_ingredient_subset.csv") as f:
    for r in csv.DictReader(f):
        if r["nutrient_nbr"] in NUTS:
            fn[r["ndb_number"]][NUTS[r["nutrient_nbr"]]] = float(r["amount_per_100g"])

ing = {i["code"]: i for i in yaml.safe_load(open(CAT / "ingredients.yaml"))["ingredients"]}


def per100(code, nut):
    ndb = ing[code]["food"]["code"]
    v = sr[ndb].get(nut)
    return v if v is not None else fn[ndb].get(nut)


rows = []
for path in sorted((CAT / "meals").glob("*.yaml")):
    for m in yaml.safe_load(open(path))["meals"]:
        tot = {"kcal": 0.0, "protein": 0.0}
        for it in m["ingredients"]:
            assert ing[it["code"]]["review_status"] == "APPROVED", it["code"]
            for n in tot:
                v = per100(it["code"], n)
                assert v is not None, (m["ref_external"], it["code"], n)
                tot[n] += it["grams"] / 100 * v
        kcal, prot = tot["kcal"] / m["servings"], tot["protein"] / m["servings"]
        slots = [t.removesuffix("_suitable") for t in m["occasion_tags"] if t.endswith("_suitable")]
        rows.append(dict(ref=m["ref_external"], name=m["name_en"], slots=slots, kcal=kcal, prot=prot,
                         pct=prot * 4 / kcal * 100, per100=prot / kcal * 100))


def at_slot_kcal(r, slot):
    """Multiplier the planner would lean to (closest kcal to slot target) and its protein."""
    m = min(MULTS, key=lambda x: abs(r["kcal"] * x - SLOT_KCAL[slot]))
    return m, r["prot"] * m


out = []
p = out.append
p(f"Meals: {len(rows)}\n")
p("| slot | meals | P>=25g | P>=20g | P%E>=20 | P%E>=25 | reach 25g @x<=2.0 | 25g @ x<=1.5 | P>=25g at kcal-matched mult | median g/100kcal |")
p("|---|---|---|---|---|---|---|---|---|---|")
for s in ("breakfast", "lunch", "dinner", "snack"):
    rs = [r for r in rows if s in r["slots"]]
    d = sorted(r["per100"] for r in rs)
    med = (d[len(d) // 2] + d[(len(d) - 1) // 2]) / 2
    p(f"| {s} | {len(rs)} | {sum(r['prot'] >= 25 for r in rs)} | {sum(r['prot'] >= 20 for r in rs)} | "
      f"{sum(r['pct'] >= 20 for r in rs)} | {sum(r['pct'] >= 25 for r in rs)} | "
      f"{sum(r['prot'] * 2 >= 25 for r in rs)} | {sum(r['prot'] * 1.5 >= 25 for r in rs)} | "
      f"{sum(at_slot_kcal(r, s)[1] >= 25 for r in rs)} | {med:.2f} |")

p("\n### All meals (sorted by protein density)\n")
p("| ref | name | slots | kcal | protein g | P %E | g/100kcal | mult to 25g | kcal at that mult |")
p("|---|---|---|---|---|---|---|---|---|")
for r in sorted(rows, key=lambda r: -r["per100"]):
    need = next((m for m in MULTS if r["prot"] * m >= 25), None)
    p(f"| {r['ref']} | {r['name']} | {','.join(r['slots'])} | {r['kcal']:.0f} | {r['prot']:.1f} | "
      f"{r['pct']:.1f} | {r['per100']:.2f} | {need or '-'} | {r['kcal'] * need:.0f} |" if need else
      f"| {r['ref']} | {r['name']} | {','.join(r['slots'])} | {r['kcal']:.0f} | {r['prot']:.1f} | "
      f"{r['pct']:.1f} | {r['per100']:.2f} | - | - |")

p("\n### Kcal-matched view (2800 kcal day; slot targets B 700 / L 980 / D 700 / snack 210)\n")
p("| ref | name | slot | mult | kcal | protein g |")
p("|---|---|---|---|---|---|")
for s in ("breakfast", "lunch", "dinner"):
    for r in sorted((r for r in rows if s in r["slots"]), key=lambda r: -at_slot_kcal(r, s)[1]):
        m, pr = at_slot_kcal(r, s)
        p(f"| {r['ref']} | {r['name']} | {s} | {m} | {r['kcal'] * m:.0f} | {pr:.1f} |")
print("\n".join(out))
```
