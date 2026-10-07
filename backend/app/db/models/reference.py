"""REFERENCE domain (§9). Must not reference CATALOG or USER tables (§8)."""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Integer,
    PrimaryKeyConstraint,
    String,
    UniqueConstraint,
    false,
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql.elements import conv

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


class TagGroup(StrEnum):
    DIETARY = "DIETARY"
    OCCASION = "OCCASION"
    CONDITION = "CONDITION"


class LimitBasis(StrEnum):
    ABSOLUTE = "ABSOLUTE"
    PERCENT_ENERGY = "PERCENT_ENERGY"


class RestrictionType(StrEnum):
    AVOID = "AVOID"
    LIMIT = "LIMIT"


class FoodExternalSource(StrEnum):
    FNDDS_INGREDIENT = "FNDDS_INGREDIENT"
    FNDDS_FOOD = "FNDDS_FOOD"
    FDC = "FDC"
    TEAM_TEMPLATE = "TEAM_TEMPLATE"
    MANUAL = "MANUAL"


class FoodState(StrEnum):
    RAW = "raw"
    COOKED = "cooked"
    AS_PURCHASED = "as_purchased"


class NutrientUnit(StrEnum):
    G = "g"
    MG = "mg"
    MCG = "mcg"
    KCAL = "kcal"
    IU = "IU"


class ReviewStatus(StrEnum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


# §9.1
class Category(Base):
    __tablename__ = "categories"

    category_id: Mapped[int] = pk_column()
    name_en: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    name_ar: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.2
class Cuisine(Base):
    __tablename__ = "cuisines"

    cuisine_id: Mapped[int] = pk_column()
    code: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    name_en: Mapped[str] = mapped_column(String, nullable=False)
    name_ar: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.3
class Allergen(Base):
    __tablename__ = "allergens"

    allergen_id: Mapped[int] = pk_column()
    code: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    name_en: Mapped[str] = mapped_column(String, nullable=False)
    name_ar: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.4
class DietaryTag(Base):
    __tablename__ = "dietary_tags"
    __table_args__ = (enum_check("tag_group", TagGroup, name="tag_group_valid"),)

    tag_id: Mapped[int] = pk_column()
    code: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    name_en: Mapped[str] = mapped_column(String, nullable=False)
    name_ar: Mapped[str] = mapped_column(String, nullable=False)
    tag_group: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.5
class HealthCondition(Base):
    __tablename__ = "health_conditions"

    condition_id: Mapped[int] = pk_column()
    code: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    name_en: Mapped[str] = mapped_column(String, nullable=False)
    name_ar: Mapped[str] = mapped_column(String, nullable=False)
    is_supported: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())
    fluid_goal_requires_clinician: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=false()
    )
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.5b
class ConditionNutrientLimit(Base):
    __tablename__ = "condition_nutrient_limits"
    __table_args__ = (
        # Convention name would be 66 chars (> 63); shortened manually per §17.
        UniqueConstraint(
            "condition_id",
            "nutrient_id",
            "limit_basis",
            name=conv("uq_condition_nutrient_limits_condition_nutrient_basis"),
        ),
        enum_check("limit_basis", LimitBasis, name="limit_basis_valid"),
        CheckConstraint(
            "max_per_meal IS NOT NULL OR max_per_day IS NOT NULL OR min_per_day IS NOT NULL",
            name="at_least_one_limit",
        ),
        CheckConstraint(
            "min_per_day IS NULL OR max_per_day IS NULL OR min_per_day <= max_per_day",
            name="min_le_max",
        ),
        CheckConstraint(
            "(max_per_meal IS NULL OR max_per_meal >= 0)"
            " AND (max_per_day IS NULL OR max_per_day >= 0)"
            " AND (min_per_day IS NULL OR min_per_day >= 0)",
            name="values_non_negative",
        ),
        CheckConstraint(
            f"limit_basis <> '{LimitBasis.PERCENT_ENERGY.value}'"
            " OR ((max_per_meal IS NULL OR max_per_meal <= 100)"
            " AND (max_per_day IS NULL OR max_per_day <= 100)"
            " AND (min_per_day IS NULL OR min_per_day <= 100))",
            name="percent_max_100",
        ),
    )

    id: Mapped[int] = pk_column()
    condition_id: Mapped[int] = fk_column("health_conditions.condition_id", ondelete="CASCADE")
    nutrient_id: Mapped[int] = fk_column("nutrients.nutrient_id", ondelete="RESTRICT", index=True)
    limit_basis: Mapped[str] = mapped_column(String, nullable=False)
    max_per_meal: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    max_per_day: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    min_per_day: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    severity_note: Mapped[str | None] = mapped_column(String, nullable=True)
    source_reference: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.5c
class ConditionTagRestriction(Base):
    __tablename__ = "condition_tag_restrictions"
    __table_args__ = (
        UniqueConstraint("condition_id", "tag_id"),
        enum_check("restriction_type", RestrictionType, name="restriction_type_valid"),
        CheckConstraint(
            f"restriction_type = '{RestrictionType.LIMIT.value}' OR max_servings_per_week IS NULL",
            name="max_servings_only_for_limit",
        ),
        CheckConstraint(
            "max_servings_per_week IS NULL OR max_servings_per_week > 0",
            name="max_servings_positive",
        ),
    )

    id: Mapped[int] = pk_column()
    condition_id: Mapped[int] = fk_column("health_conditions.condition_id", ondelete="CASCADE")
    tag_id: Mapped[int] = fk_column("dietary_tags.tag_id", ondelete="RESTRICT", index=True)
    restriction_type: Mapped[str] = mapped_column(String, nullable=False)
    max_servings_per_week: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.6
class Food(Base):
    __tablename__ = "foods"
    __table_args__ = (
        UniqueConstraint("external_source", "external_code"),
        enum_check("external_source", FoodExternalSource, name="external_source_valid"),
        enum_check("state", FoodState, name="state_valid"),
        CheckConstraint("basis_grams = 100", name="basis_grams_100"),
    )

    food_id: Mapped[int] = pk_column()
    fdc_id: Mapped[int | None] = mapped_column(Integer, nullable=True, unique=True)
    description: Mapped[str] = mapped_column(String, nullable=False)
    data_type: Mapped[str | None] = mapped_column(String, nullable=True)
    category_id: Mapped[int] = fk_column("categories.category_id", ondelete="RESTRICT", index=True)
    basis_grams: Mapped[float] = mapped_column(MEASURE, nullable=False)
    external_source: Mapped[str] = mapped_column(String, nullable=False)
    external_code: Mapped[str] = mapped_column(String, nullable=False)
    state: Mapped[str] = mapped_column(String, nullable=False)
    source_reference: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.7
class Nutrient(Base):
    __tablename__ = "nutrients"
    __table_args__ = (enum_check("unit", NutrientUnit, name="unit_valid"),)

    nutrient_id: Mapped[int] = pk_column()
    code: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    source_code: Mapped[str | None] = mapped_column(String, nullable=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    unit: Mapped[str] = mapped_column(String, nullable=False)
    is_mandatory: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.8
class FoodNutrient(Base):
    __tablename__ = "food_nutrients"
    __table_args__ = (
        PrimaryKeyConstraint("food_id", "nutrient_id"),
        CheckConstraint("amount_per_100g >= 0", name="amount_non_negative"),
    )

    food_id: Mapped[int] = fk_column("foods.food_id", ondelete="CASCADE")
    nutrient_id: Mapped[int] = fk_column("nutrients.nutrient_id", ondelete="RESTRICT", index=True)
    amount_per_100g: Mapped[float] = mapped_column(MEASURE, nullable=False)


# §9.9
class PortionFood(Base):
    __tablename__ = "portions_food"
    __table_args__ = (CheckConstraint("gram_weight > 0", name="gram_weight_positive"),)

    portion_id: Mapped[int] = pk_column()
    food_id: Mapped[int] = fk_column("foods.food_id", ondelete="CASCADE", index=True)
    unit_text: Mapped[str] = mapped_column(String, nullable=False)
    amount: Mapped[float] = mapped_column(MEASURE, nullable=False)
    gram_weight: Mapped[float] = mapped_column(MEASURE, nullable=False)


# §9.10
class Ingredient(Base):
    __tablename__ = "ingredients"
    __table_args__ = (enum_check("review_status", ReviewStatus, name="review_status_valid"),)

    ingredient_id: Mapped[int] = pk_column()
    canonical_name: Mapped[str] = mapped_column(String, nullable=False)
    canonical_name_ar: Mapped[str] = mapped_column(String, nullable=False)
    default_food_id: Mapped[int | None] = fk_column(
        "foods.food_id", ondelete="SET NULL", nullable=True, index=True
    )
    review_status: Mapped[str] = mapped_column(
        String, nullable=False, server_default=ReviewStatus.PENDING.value
    )
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §9.11
class IngredientAlias(Base):
    __tablename__ = "ingredient_aliases"
    __table_args__ = (
        UniqueConstraint("alias_text", "lang"),
        lang_check("lang", name="lang_iso639_1"),
        CheckConstraint("confidence BETWEEN 0 AND 1", name="confidence_range"),
        trigram_index("alias_normalized"),
    )

    alias_id: Mapped[int] = pk_column()
    ingredient_id: Mapped[int] = fk_column(
        "ingredients.ingredient_id", ondelete="CASCADE", index=True
    )
    alias_text: Mapped[str] = mapped_column(String, nullable=False)
    lang: Mapped[str] = mapped_column(LANG_CODE, nullable=False)
    confidence: Mapped[float | None] = mapped_column(CONFIDENCE, nullable=True)
    source: Mapped[str | None] = mapped_column(String, nullable=True)
    alias_normalized: Mapped[str] = mapped_column(String, nullable=False)


# §9.12
class IngredientAllergen(Base):
    __tablename__ = "ingredient_allergens"
    __table_args__ = (PrimaryKeyConstraint("ingredient_id", "allergen_id"),)

    ingredient_id: Mapped[int] = fk_column("ingredients.ingredient_id", ondelete="CASCADE")
    allergen_id: Mapped[int] = fk_column("allergens.allergen_id", ondelete="RESTRICT", index=True)


# §9.13
class IngredientTag(Base):
    __tablename__ = "ingredient_tags"
    __table_args__ = (PrimaryKeyConstraint("ingredient_id", "tag_id"),)

    ingredient_id: Mapped[int] = fk_column("ingredients.ingredient_id", ondelete="CASCADE")
    tag_id: Mapped[int] = fk_column("dietary_tags.tag_id", ondelete="RESTRICT", index=True)
