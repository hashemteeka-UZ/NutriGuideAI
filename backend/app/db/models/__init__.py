"""Import every model so that Base.metadata is complete (Alembic relies on this)."""

from app.db.models.reference import (
    Allergen,
    Category,
    ConditionNutrientLimit,
    ConditionTagRestriction,
    Cuisine,
    DietaryTag,
    Food,
    FoodNutrient,
    HealthCondition,
    Ingredient,
    IngredientAlias,
    IngredientAllergen,
    IngredientTag,
    Nutrient,
    PortionFood,
)

__all__ = [
    "Allergen",
    "Category",
    "ConditionNutrientLimit",
    "ConditionTagRestriction",
    "Cuisine",
    "DietaryTag",
    "Food",
    "FoodNutrient",
    "HealthCondition",
    "Ingredient",
    "IngredientAlias",
    "IngredientAllergen",
    "IngredientTag",
    "Nutrient",
    "PortionFood",
]
