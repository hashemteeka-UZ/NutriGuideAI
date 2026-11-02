"""USDA SR Legacy food group codes by their English description (P2a).

The categories table keeps the USDA food group description (`name_en`) but not its code, so
the shopping list maps the description back to the four-digit code here. The codes come from
the SR Legacy `food_category.csv` (USDA FoodData Central, SR Legacy release April 2018).
"""

from __future__ import annotations

from typing import Final

USDA_FOOD_GROUP_CODES: Final[dict[str, str]] = {
    "Dairy and Egg Products": "0100",
    "Spices and Herbs": "0200",
    "Baby Foods": "0300",
    "Fats and Oils": "0400",
    "Poultry Products": "0500",
    "Soups, Sauces, and Gravies": "0600",
    "Sausages and Luncheon Meats": "0700",
    "Breakfast Cereals": "0800",
    "Fruits and Fruit Juices": "0900",
    "Pork Products": "1000",
    "Vegetables and Vegetable Products": "1100",
    "Nut and Seed Products": "1200",
    "Beef Products": "1300",
    "Beverages": "1400",
    "Finfish and Shellfish Products": "1500",
    "Legumes and Legume Products": "1600",
    "Lamb, Veal, and Game Products": "1700",
    "Baked Products": "1800",
    "Sweets": "1900",
    "Cereal Grains and Pasta": "2000",
    "Fast Foods": "2100",
    "Meals, Entrees, and Side Dishes": "2200",
    "Snacks": "2500",
    "American Indian/Alaska Native Foods": "3500",
    "Restaurant Foods": "3600",
}


def food_group_code(name_en: str) -> str:
    """The USDA code for a category description, or "" for a group outside SR Legacy."""
    return USDA_FOOD_GROUP_CODES.get(name_en, "")
