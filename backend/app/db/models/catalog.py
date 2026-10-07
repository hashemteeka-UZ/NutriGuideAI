"""CATALOG domain (§10). May reference REFERENCE only, never USER (§8)."""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Integer,
    PrimaryKeyConstraint,
    String,
    UniqueConstraint,
    false,
    func,
    true,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.types import (
    CONFIDENCE,
    LANG_CODE,
    MEASURE,
    created_at_column,
    enum_check,
    fk_column,
    lang_check,
    pk_column,
    trigram_index,
    updated_at_column,
)


class WeightMethod(StrEnum):
    WEIGHED = "WEIGHED"
    YIELD_FACTOR = "YIELD_FACTOR"
    SUM_OF_INGREDIENTS = "SUM_OF_INGREDIENTS"


class QualityTier(StrEnum):
    GOLD = "GOLD"
    SILVER = "SILVER"


class MealTagSource(StrEnum):
    MANUAL = "MANUAL"
    DERIVED = "DERIVED"


# §10.1
class Meal(Base):
    __tablename__ = "meals"
    __table_args__ = (
        UniqueConstraint("source", "ref_external"),
        CheckConstraint("servings > 0", name="servings_positive"),
        CheckConstraint("total_grams > 0", name="total_grams_positive"),
        enum_check("weight_method", WeightMethod, name="weight_method_valid"),
        enum_check("quality_tier", QualityTier, name="quality_tier_valid"),
        lang_check("default_lang", name="default_lang_iso639_1"),
        CheckConstraint(
            "yield_factor IS NULL OR (yield_factor > 0 AND yield_factor <= 3)",
            name="yield_factor_range",
        ),
        CheckConstraint(
            f"weight_method = '{WeightMethod.YIELD_FACTOR.value}' OR yield_factor IS NULL",
            name="yield_factor_only_for_yield_method",
        ),
        trigram_index("name_normalized"),
    )

    meal_id: Mapped[int] = pk_column()
    ref_external: Mapped[str | None] = mapped_column(String, nullable=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    default_lang: Mapped[str] = mapped_column(LANG_CODE, nullable=False)
    name_normalized: Mapped[str] = mapped_column(String, nullable=False)
    servings: Mapped[int] = mapped_column(Integer, nullable=False)
    total_grams: Mapped[float] = mapped_column(MEASURE, nullable=False)
    weight_method: Mapped[str] = mapped_column(String, nullable=False)
    cuisine_id: Mapped[int | None] = fk_column(
        "cuisines.cuisine_id", ondelete="RESTRICT", nullable=True, index=True
    )
    source: Mapped[str] = mapped_column(String, nullable=False)
    source_license: Mapped[str] = mapped_column(String, nullable=False)
    quality_tier: Mapped[str] = mapped_column(String, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=true())
    ingested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    dataset_version: Mapped[str] = mapped_column(String, nullable=False)
    variant_group: Mapped[str | None] = mapped_column(String, nullable=True, index=True)
    yield_factor: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    yield_factor_source: Mapped[str | None] = mapped_column(String, nullable=True)
    reviewed_by: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §10.2
class MealIngredient(Base):
    __tablename__ = "meal_ingredients"
    __table_args__ = (
        PrimaryKeyConstraint("meal_id", "position"),
        CheckConstraint("grams > 0", name="grams_positive"),
        CheckConstraint("position >= 1", name="position_min_1"),
        CheckConstraint("mapping_confidence BETWEEN 0 AND 1", name="mapping_confidence_range"),
    )

    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="CASCADE")
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    ingredient_id: Mapped[int] = fk_column(
        "ingredients.ingredient_id", ondelete="RESTRICT", index=True
    )
    food_id: Mapped[int | None] = fk_column(
        "foods.food_id", ondelete="SET NULL", nullable=True, index=True
    )
    grams: Mapped[float] = mapped_column(MEASURE, nullable=False)
    text_original: Mapped[str | None] = mapped_column(String, nullable=True)
    mapping_confidence: Mapped[float | None] = mapped_column(CONFIDENCE, nullable=True)
    is_optional: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())


# §10.3
class MealNutrient(Base):
    __tablename__ = "meal_nutrients"
    __table_args__ = (
        PrimaryKeyConstraint("meal_id", "nutrient_id"),
        CheckConstraint("amount_per_serving >= 0", name="amount_per_serving_non_negative"),
        CheckConstraint("amount_per_100g >= 0", name="amount_per_100g_non_negative"),
    )

    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="CASCADE")
    nutrient_id: Mapped[int] = fk_column("nutrients.nutrient_id", ondelete="RESTRICT", index=True)
    amount_per_serving: Mapped[float] = mapped_column(MEASURE, nullable=False)
    amount_per_100g: Mapped[float] = mapped_column(MEASURE, nullable=False)
    computed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    computation_version: Mapped[str] = mapped_column(String, nullable=False)


# §10.4
class MealAllergen(Base):
    __tablename__ = "meal_allergens"
    __table_args__ = (PrimaryKeyConstraint("meal_id", "allergen_id"),)

    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="CASCADE")
    allergen_id: Mapped[int] = fk_column("allergens.allergen_id", ondelete="RESTRICT", index=True)


# §10.5
class MealTag(Base):
    __tablename__ = "meal_tags"
    __table_args__ = (
        PrimaryKeyConstraint("meal_id", "tag_id"),
        enum_check("source", MealTagSource, name="source_valid"),
        CheckConstraint(
            f"source = '{MealTagSource.DERIVED.value}' OR rule_version IS NULL",
            name="rule_version_only_derived",
        ),
    )

    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="CASCADE")
    tag_id: Mapped[int] = fk_column("dietary_tags.tag_id", ondelete="RESTRICT", index=True)
    source: Mapped[str] = mapped_column(String, nullable=False)
    rule_version: Mapped[str | None] = mapped_column(String, nullable=True)


# §10.6
class MealTranslation(Base):
    __tablename__ = "meal_translations"
    __table_args__ = (
        PrimaryKeyConstraint("meal_id", "lang"),
        lang_check("lang", name="lang_iso639_1"),
        trigram_index("name_normalized"),
    )

    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="CASCADE")
    lang: Mapped[str] = mapped_column(LANG_CODE, nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    name_normalized: Mapped[str] = mapped_column(String, nullable=False)
