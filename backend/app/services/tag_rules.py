"""Meal-level threshold tags (rule R1, finding F-02).

Threshold tags are derived from the meal's own meal_nutrients.amount_per_100g, never from
ingredient_tags: a pinch of salt would otherwise tag every savoury meal high_sodium.
A meal gets the tag when amount_per_100g > threshold (nutrient's own unit: sodium mg, sugars g).
"""

from __future__ import annotations

from typing import Final

TAG_RULES_VERSION: Final = "tags_v1"
# UK Food Standards Agency front-of-pack "high" thresholds per 100 g.
THRESHOLD_TAGS: Final[dict[str, tuple[str, float]]] = {
    "high_sodium": ("sodium", 600),
    "high_sugar": ("sugars", 22.5),
}
