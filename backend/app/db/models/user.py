"""USER domain (§11). May reference CATALOG and REFERENCE (§8)."""

from datetime import date, datetime
from enum import StrEnum
from typing import Any
from uuid import UUID

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Index,
    Integer,
    PrimaryKeyConstraint,
    SmallInteger,
    String,
    UniqueConstraint,
    Uuid,
    false,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.types import (
    MEASURE,
    SERVINGS_MULTIPLIER,
    created_at_column,
    enum_check,
    fk_column,
    pk_column,
    updated_at_column,
)


class Sex(StrEnum):
    MALE = "MALE"
    FEMALE = "FEMALE"


class ActivityLevel(StrEnum):
    SEDENTARY = "SEDENTARY"
    LIGHT = "LIGHT"
    MODERATE = "MODERATE"
    HIGH = "HIGH"
    ATHLETE = "ATHLETE"


class GoalType(StrEnum):
    LOSE = "LOSE"
    MAINTAIN = "MAINTAIN"
    GAIN = "GAIN"


class PhysiologicalStatus(StrEnum):
    NONE = "NONE"
    PREGNANT = "PREGNANT"
    LACTATING = "LACTATING"


class ConditionSeverity(StrEnum):
    MILD = "MILD"
    MODERATE = "MODERATE"
    SEVERE = "SEVERE"


class AllergenSeverity(StrEnum):
    AVOID = "AVOID"
    SEVERE = "SEVERE"


class IngredientStance(StrEnum):
    LIKE = "LIKE"
    DISLIKE = "DISLIKE"
    EXCLUDE = "EXCLUDE"


class InteractionEventType(StrEnum):
    IMPRESSION = "IMPRESSION"
    ACCEPT = "ACCEPT"
    VIEW = "VIEW"
    SAVE = "SAVE"
    RATE = "RATE"
    COOK = "COOK"
    SKIP = "SKIP"
    SWAP_OUT = "SWAP_OUT"


class MealSlot(StrEnum):
    BREAKFAST = "BREAKFAST"
    LUNCH = "LUNCH"
    DINNER = "DINNER"
    SNACK = "SNACK"


class WeightSource(StrEnum):
    MANUAL = "MANUAL"


class TargetReason(StrEnum):
    INITIAL = "INITIAL"
    WEIGHT_UPDATE = "WEIGHT_UPDATE"
    GOAL_CHANGE = "GOAL_CHANGE"
    PROFILE_CHANGE = "PROFILE_CHANGE"
    FORMULA_CHANGE = "FORMULA_CHANGE"


SERVINGS_MULTIPLIER_STEPS = (0.5, 1.0, 1.5, 2.0)


# §11.1
class User(Base):
    __tablename__ = "users"
    __table_args__ = (CheckConstraint("email = lower(email)", name="email_lowercase"),)

    user_id: Mapped[int] = pk_column()
    email: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    hashed_password: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.2
class UserProfile(Base):
    __tablename__ = "user_profiles"
    __table_args__ = (
        enum_check("sex", Sex, name="sex_valid"),
        enum_check("activity_level", ActivityLevel, name="activity_level_valid"),
        enum_check("goal_type", GoalType, name="goal_type_valid"),
        enum_check("physiological_status", PhysiologicalStatus, name="physiological_status_valid"),
        CheckConstraint("height_cm BETWEEN 100 AND 250", name="height_range"),
        CheckConstraint("target_weight_kg BETWEEN 30 AND 300", name="target_weight_range"),
        CheckConstraint("weekly_rate_kg > 0 AND weekly_rate_kg <= 1.0", name="weekly_rate_range"),
        CheckConstraint("water_goal_ml BETWEEN 500 AND 5000", name="water_goal_range"),
        CheckConstraint(
            f"sex = '{Sex.FEMALE.value}'"
            f" OR physiological_status = '{PhysiologicalStatus.NONE.value}'",
            name="status_requires_female",
        ),
        CheckConstraint(
            f"goal_type = '{GoalType.MAINTAIN.value}'"
            " OR (target_weight_kg IS NOT NULL AND weekly_rate_kg IS NOT NULL)",
            name="goal_requires_target",
        ),
    )

    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE", primary_key=True)
    sex: Mapped[str] = mapped_column(String, nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    height_cm: Mapped[float] = mapped_column(MEASURE, nullable=False)
    activity_level: Mapped[str] = mapped_column(String, nullable=False)
    goal_type: Mapped[str] = mapped_column(String, nullable=False)
    target_weight_kg: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    weekly_rate_kg: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    physiological_status: Mapped[str] = mapped_column(
        String, nullable=False, server_default=PhysiologicalStatus.NONE.value
    )
    timezone: Mapped[str] = mapped_column(String, nullable=False)
    water_goal_ml: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.3
class UserHealthCondition(Base):
    __tablename__ = "user_health_conditions"
    __table_args__ = (
        UniqueConstraint("user_id", "condition_id"),
        enum_check("severity", ConditionSeverity, name="severity_valid"),
    )

    id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    condition_id: Mapped[int] = fk_column(
        "health_conditions.condition_id", ondelete="RESTRICT", index=True
    )
    severity: Mapped[str | None] = mapped_column(String, nullable=True)
    diagnosed: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.4
class UserAllergenPref(Base):
    __tablename__ = "user_allergen_prefs"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "allergen_id"),
        enum_check("severity", AllergenSeverity, name="severity_valid"),
    )

    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    allergen_id: Mapped[int] = fk_column("allergens.allergen_id", ondelete="RESTRICT", index=True)
    severity: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.5
class UserIngredientPref(Base):
    __tablename__ = "user_ingredient_prefs"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "ingredient_id"),
        enum_check("stance", IngredientStance, name="stance_valid"),
    )

    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    ingredient_id: Mapped[int] = fk_column(
        "ingredients.ingredient_id", ondelete="RESTRICT", index=True
    )
    stance: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.6
class UserInteraction(Base):
    __tablename__ = "user_interactions"
    __table_args__ = (
        enum_check("event_type", InteractionEventType, name="event_type_valid"),
        CheckConstraint("value IS NULL OR value BETWEEN 1 AND 5", name="value_range"),
        CheckConstraint(
            f"event_type <> '{InteractionEventType.RATE.value}' OR value IS NOT NULL",
            name="rate_requires_value",
        ),
        Index(None, "user_id", "created_at"),
    )

    id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="RESTRICT", index=True)
    event_type: Mapped[str] = mapped_column(String, nullable=False)
    value: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    context: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, server_default="{}")
    client_uuid: Mapped[UUID | None] = mapped_column(Uuid, nullable=True, unique=True)
    created_at: Mapped[datetime] = created_at_column()


# §11.7
class MealPlan(Base):
    __tablename__ = "meal_plans"
    __table_args__ = (
        CheckConstraint("date_to >= date_from", name="date_range"),
        Index(None, "user_id", "date_from"),
    )

    plan_id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    date_from: Mapped[date] = mapped_column(Date, nullable=False)
    date_to: Mapped[date] = mapped_column(Date, nullable=False)
    generated_by: Mapped[str] = mapped_column(String, nullable=False)
    algorithm_version: Mapped[str] = mapped_column(String, nullable=False)
    target_id: Mapped[int | None] = fk_column(
        "user_targets.target_id", ondelete="SET NULL", nullable=True, index=True
    )
    target_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.8
class MealPlanItem(Base):
    __tablename__ = "meal_plan_items"
    __table_args__ = (
        CheckConstraint("day_index >= 0", name="day_index_non_negative"),
        enum_check("slot", MealSlot, name="slot_valid"),
        CheckConstraint(
            f"servings_multiplier IN ({', '.join(map(str, SERVINGS_MULTIPLIER_STEPS))})",
            name="servings_multiplier_step",
        ),
    )

    id: Mapped[int] = pk_column()
    plan_id: Mapped[int] = fk_column("meal_plans.plan_id", ondelete="CASCADE", index=True)
    day_index: Mapped[int] = mapped_column(Integer, nullable=False)
    slot: Mapped[str] = mapped_column(String, nullable=False)
    meal_id: Mapped[int] = fk_column("meals.meal_id", ondelete="RESTRICT", index=True)
    servings_multiplier: Mapped[float] = mapped_column(SERVINGS_MULTIPLIER, nullable=False)
    was_swapped: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=false())
    reason_codes: Mapped[list[str]] = mapped_column(JSONB, nullable=False, server_default="[]")
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


# §11.9
class ConsumptionLog(Base):
    __tablename__ = "consumption_logs"
    __table_args__ = (
        enum_check("slot", MealSlot, name="slot_valid"),
        CheckConstraint("(meal_id IS NOT NULL) <> (food_id IS NOT NULL)", name="one_target"),
        CheckConstraint(
            "meal_id IS NULL OR (servings_consumed > 0 AND grams_consumed IS NULL)",
            name="meal_requires_servings",
        ),
        CheckConstraint(
            "food_id IS NULL OR (grams_consumed > 0 AND servings_consumed IS NULL)",
            name="food_requires_grams",
        ),
        CheckConstraint("plan_item_id IS NULL OR meal_id IS NOT NULL", name="plan_item_needs_meal"),
        Index(None, "user_id", "log_date", postgresql_where=text("deleted_at IS NULL")),
    )

    id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE", index=True)
    consumed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    slot: Mapped[str | None] = mapped_column(String, nullable=True)
    plan_item_id: Mapped[int | None] = fk_column(
        "meal_plan_items.id", ondelete="SET NULL", nullable=True, index=True
    )
    meal_id: Mapped[int | None] = fk_column(
        "meals.meal_id", ondelete="RESTRICT", nullable=True, index=True
    )
    food_id: Mapped[int | None] = fk_column(
        "foods.food_id", ondelete="RESTRICT", nullable=True, index=True
    )
    servings_consumed: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    grams_consumed: Mapped[float | None] = mapped_column(MEASURE, nullable=True)
    created_at: Mapped[datetime] = created_at_column()
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    client_uuid: Mapped[UUID | None] = mapped_column(Uuid, nullable=True, unique=True)
    nutrients_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)


# §11.10
class WeightLog(Base):
    __tablename__ = "weight_logs"
    __table_args__ = (
        UniqueConstraint("user_id", "measured_on"),
        CheckConstraint("weight_kg BETWEEN 20 AND 400", name="weight_range"),
        enum_check("source", WeightSource, name="source_valid"),
    )

    id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    measured_on: Mapped[date] = mapped_column(Date, nullable=False)
    weight_kg: Mapped[float] = mapped_column(MEASURE, nullable=False)
    source: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    # Device time of the last edit; drives last-write-wins sync (§33.4), so never server-set.
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


# §11.11
class UserTarget(Base):
    __tablename__ = "user_targets"
    __table_args__ = (
        CheckConstraint("valid_to IS NULL OR valid_to > valid_from", name="valid_to_after_from"),
        CheckConstraint(
            "bmr_kcal > 0 AND tdee_kcal > 0 AND target_kcal > 0"
            " AND target_protein_g > 0 AND target_carb_g > 0 AND target_fat_g > 0",
            name="values_positive",
        ),
        enum_check("reason", TargetReason, name="reason_valid"),
        Index(None, "user_id", unique=True, postgresql_where=text("valid_to IS NULL")),
        Index(None, "user_id", "valid_from"),
    )

    target_id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE")
    valid_from: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    valid_to: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    based_on_weight_kg: Mapped[float] = mapped_column(MEASURE, nullable=False)
    bmr_kcal: Mapped[float] = mapped_column(MEASURE, nullable=False)
    tdee_kcal: Mapped[float] = mapped_column(MEASURE, nullable=False)
    target_kcal: Mapped[float] = mapped_column(MEASURE, nullable=False)
    target_protein_g: Mapped[float] = mapped_column(MEASURE, nullable=False)
    target_carb_g: Mapped[float] = mapped_column(MEASURE, nullable=False)
    target_fat_g: Mapped[float] = mapped_column(MEASURE, nullable=False)
    formula_version: Mapped[str] = mapped_column(String, nullable=False)
    reason: Mapped[str] = mapped_column(String, nullable=False)
    was_floor_applied: Mapped[bool] = mapped_column(Boolean, nullable=False)
    created_at: Mapped[datetime] = created_at_column()


# §11.12
class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __table_args__ = (CheckConstraint("expires_at > issued_at", name="expires_after_issued"),)

    token_id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE", index=True)
    token_hash: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    family_id: Mapped[UUID] = mapped_column(Uuid, nullable=False, index=True)
    issued_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    replaced_by_token_id: Mapped[int | None] = fk_column(
        "refresh_tokens.token_id", ondelete="SET NULL", nullable=True, index=True
    )


# §11.13
class WaterLog(Base):
    __tablename__ = "water_logs"
    __table_args__ = (
        CheckConstraint("amount_ml BETWEEN 1 AND 2000", name="amount_range"),
        Index(None, "user_id", "log_date", postgresql_where=text("deleted_at IS NULL")),
    )

    id: Mapped[int] = pk_column()
    user_id: Mapped[int] = fk_column("users.user_id", ondelete="CASCADE", index=True)
    consumed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    amount_ml: Mapped[int] = mapped_column(Integer, nullable=False)
    client_uuid: Mapped[UUID | None] = mapped_column(Uuid, nullable=True, unique=True)
    created_at: Mapped[datetime] = created_at_column()
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
