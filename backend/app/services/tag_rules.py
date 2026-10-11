"""Meal-level threshold tags (rule R1, finding F-02; drink thresholds Decision #97).

Threshold tags are derived from the meal's own meal_nutrients.amount_per_100g, never from
ingredient_tags: a pinch of salt would otherwise tag every savoury meal high_sodium.
A meal gets the tag when amount_per_100g > threshold (nutrient's own unit: sodium mg, sugars g).
An absent per-100 g value derives no tag (missing != zero, §9.8).

Foods use the UK Food Standards Agency front-of-pack "high" thresholds per 100 g
(`THRESHOLD_TAGS`). A meal that carries the manual occasion tag `beverage` uses the FSA
drinks "high" thresholds per 100 ml (`BEVERAGE_THRESHOLD_TAGS`): sugars > 11.25 g and
sodium > 300 mg (salt > 0.75 g). Source: UK Food Standards Agency, *Guide to creating a
front of pack (FoP) nutrition label for pre-packed products sold through retail outlets*
(2016). 100 ml is assumed equal to 100 g for water- and milk-based drinks, so the stored
per-100 g amount is compared directly with the per-100 ml figure (Decision #97).
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Final

TAG_RULES_VERSION: Final = "tags_v2"
BEVERAGE_TAG: Final = "beverage"
# UK Food Standards Agency front-of-pack "high" thresholds per 100 g.
THRESHOLD_TAGS: Final[dict[str, tuple[str, float]]] = {
    "high_sodium": ("sodium", 600),
    "high_sugar": ("sugars", 22.5),
}
# UK FSA drinks "high" per 100 ml. 100 ml ≈ 100 g for water/milk-based drinks (#97).
BEVERAGE_THRESHOLD_TAGS: Final[dict[str, tuple[str, float]]] = {
    "high_sodium": ("sodium", 300),
    "high_sugar": ("sugars", 11.25),
}
# Both tables are checked at start-up (tags exist, nutrients exist).
THRESHOLD_TABLES: Final[tuple[Mapping[str, tuple[str, float]], ...]] = (
    THRESHOLD_TAGS,
    BEVERAGE_THRESHOLD_TAGS,
)


def threshold_tags_for(tag_codes: Iterable[str]) -> Mapping[str, tuple[str, float]]:
    """Drink thresholds when the meal carries the occasion tag `beverage`; otherwise foods."""
    if BEVERAGE_TAG in tag_codes:
        return BEVERAGE_THRESHOLD_TAGS
    return THRESHOLD_TAGS
