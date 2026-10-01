"""initial schema

All 34 tables of the REFERENCE, CATALOG and USER domains plus the pg_trgm extension (§15.9).

Revision ID: 0001
Revises:
Create Date: 2026-10-01 03:27:05.509945
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Must precede the gin_trgm_ops indexes (§17 migration note).
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.create_table(
        "allergens",
        sa.Column("allergen_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("name_en", sa.String(), nullable=False),
        sa.Column("name_ar", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("allergen_id", name=op.f("pk_allergens")),
    )
    op.create_table(
        "categories",
        sa.Column("category_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("name_en", sa.String(), nullable=False),
        sa.Column("name_ar", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("category_id", name=op.f("pk_categories")),
    )
    op.create_table(
        "cuisines",
        sa.Column("cuisine_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("name_en", sa.String(), nullable=False),
        sa.Column("name_ar", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("cuisine_id", name=op.f("pk_cuisines")),
    )
    op.create_table(
        "dietary_tags",
        sa.Column("tag_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("code", sa.String(), nullable=False),
        sa.Column("name_en", sa.String(), nullable=False),
        sa.Column("name_ar", sa.String(), nullable=False),
        sa.Column("tag_group", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "tag_group IN ('DIETARY', 'OCCASION', 'CONDITION')",
            name=op.f("ck_dietary_tags_tag_group_valid"),
        ),
        sa.PrimaryKeyConstraint("tag_id", name=op.f("pk_dietary_tags")),
        sa.UniqueConstraint("code", name=op.f("uq_dietary_tags_code")),
    )
    op.create_table(
        "health_conditions",
        sa.Column("condition_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("code", sa.String(), nullable=False),
        sa.Column("name_en", sa.String(), nullable=False),
        sa.Column("name_ar", sa.String(), nullable=False),
        sa.Column("is_supported", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "fluid_goal_requires_clinician",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("condition_id", name=op.f("pk_health_conditions")),
        sa.UniqueConstraint("code", name=op.f("uq_health_conditions_code")),
    )
    op.create_table(
        "nutrients",
        sa.Column("nutrient_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("code", sa.String(), nullable=False),
        sa.Column("source_code", sa.String(), nullable=True),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("unit", sa.String(), nullable=False),
        sa.Column("is_mandatory", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "unit IN ('g', 'mg', 'mcg', 'kcal', 'IU')", name=op.f("ck_nutrients_unit_valid")
        ),
        sa.PrimaryKeyConstraint("nutrient_id", name=op.f("pk_nutrients")),
        sa.UniqueConstraint("code", name=op.f("uq_nutrients_code")),
    )
    op.create_table(
        "users",
        sa.Column("user_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("hashed_password", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint("email = lower(email)", name=op.f("ck_users_email_lowercase")),
        sa.PrimaryKeyConstraint("user_id", name=op.f("pk_users")),
        sa.UniqueConstraint("email", name=op.f("uq_users_email")),
    )
    op.create_table(
        "condition_nutrient_limits",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("condition_id", sa.BigInteger(), nullable=False),
        sa.Column("nutrient_id", sa.BigInteger(), nullable=False),
        sa.Column("limit_basis", sa.String(), nullable=False),
        sa.Column(
            "max_per_meal", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True
        ),
        sa.Column("max_per_day", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True),
        sa.Column("min_per_day", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True),
        sa.Column("severity_note", sa.String(), nullable=True),
        sa.Column("source_reference", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "limit_basis <> 'PERCENT_ENERGY' OR ((max_per_meal IS NULL OR max_per_meal <= 100) AND (max_per_day IS NULL OR max_per_day <= 100) AND (min_per_day IS NULL OR min_per_day <= 100))",
            name=op.f("ck_condition_nutrient_limits_percent_max_100"),
        ),
        sa.CheckConstraint(
            "limit_basis IN ('ABSOLUTE', 'PERCENT_ENERGY')",
            name=op.f("ck_condition_nutrient_limits_limit_basis_valid"),
        ),
        sa.CheckConstraint(
            "(max_per_meal IS NULL OR max_per_meal >= 0) AND (max_per_day IS NULL OR max_per_day >= 0) AND (min_per_day IS NULL OR min_per_day >= 0)",
            name=op.f("ck_condition_nutrient_limits_values_non_negative"),
        ),
        sa.CheckConstraint(
            "max_per_meal IS NOT NULL OR max_per_day IS NOT NULL OR min_per_day IS NOT NULL",
            name=op.f("ck_condition_nutrient_limits_at_least_one_limit"),
        ),
        sa.CheckConstraint(
            "min_per_day IS NULL OR max_per_day IS NULL OR min_per_day <= max_per_day",
            name=op.f("ck_condition_nutrient_limits_min_le_max"),
        ),
        sa.ForeignKeyConstraint(
            ["condition_id"],
            ["health_conditions.condition_id"],
            name=op.f("fk_condition_nutrient_limits_condition_id_health_conditions"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["nutrient_id"],
            ["nutrients.nutrient_id"],
            name=op.f("fk_condition_nutrient_limits_nutrient_id_nutrients"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_condition_nutrient_limits")),
        sa.UniqueConstraint(
            "condition_id",
            "nutrient_id",
            "limit_basis",
            name=op.f("uq_condition_nutrient_limits_condition_nutrient_basis"),
        ),
    )
    op.create_index(
        op.f("ix_condition_nutrient_limits_nutrient_id"),
        "condition_nutrient_limits",
        ["nutrient_id"],
        unique=False,
    )
    op.create_table(
        "condition_tag_restrictions",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("condition_id", sa.BigInteger(), nullable=False),
        sa.Column("tag_id", sa.BigInteger(), nullable=False),
        sa.Column("restriction_type", sa.String(), nullable=False),
        sa.Column("max_servings_per_week", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "restriction_type = 'LIMIT' OR max_servings_per_week IS NULL",
            name=op.f("ck_condition_tag_restrictions_max_servings_only_for_limit"),
        ),
        sa.CheckConstraint(
            "restriction_type IN ('AVOID', 'LIMIT')",
            name=op.f("ck_condition_tag_restrictions_restriction_type_valid"),
        ),
        sa.CheckConstraint(
            "max_servings_per_week IS NULL OR max_servings_per_week > 0",
            name=op.f("ck_condition_tag_restrictions_max_servings_positive"),
        ),
        sa.ForeignKeyConstraint(
            ["condition_id"],
            ["health_conditions.condition_id"],
            name=op.f("fk_condition_tag_restrictions_condition_id_health_conditions"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["tag_id"],
            ["dietary_tags.tag_id"],
            name=op.f("fk_condition_tag_restrictions_tag_id_dietary_tags"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_condition_tag_restrictions")),
        sa.UniqueConstraint(
            "condition_id", "tag_id", name=op.f("uq_condition_tag_restrictions_condition_id_tag_id")
        ),
    )
    op.create_index(
        op.f("ix_condition_tag_restrictions_tag_id"),
        "condition_tag_restrictions",
        ["tag_id"],
        unique=False,
    )
    op.create_table(
        "foods",
        sa.Column("food_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("fdc_id", sa.Integer(), nullable=True),
        sa.Column("description", sa.String(), nullable=False),
        sa.Column("data_type", sa.String(), nullable=True),
        sa.Column("category_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "basis_grams", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column("external_source", sa.String(), nullable=False),
        sa.Column("external_code", sa.String(), nullable=False),
        sa.Column("state", sa.String(), nullable=False),
        sa.Column("source_reference", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "external_source IN ('FNDDS_INGREDIENT', 'FNDDS_FOOD', 'FDC', 'TEAM_TEMPLATE', 'MANUAL')",
            name=op.f("ck_foods_external_source_valid"),
        ),
        sa.CheckConstraint(
            "state IN ('raw', 'cooked', 'as_purchased')", name=op.f("ck_foods_state_valid")
        ),
        sa.CheckConstraint("basis_grams = 100", name=op.f("ck_foods_basis_grams_100")),
        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.category_id"],
            name=op.f("fk_foods_category_id_categories"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("food_id", name=op.f("pk_foods")),
        sa.UniqueConstraint(
            "external_source", "external_code", name=op.f("uq_foods_external_source_external_code")
        ),
        sa.UniqueConstraint("fdc_id", name=op.f("uq_foods_fdc_id")),
    )
    op.create_index(op.f("ix_foods_category_id"), "foods", ["category_id"], unique=False)
    op.create_table(
        "meals",
        sa.Column("meal_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("ref_external", sa.String(), nullable=True),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("default_lang", sa.String(length=2), nullable=False),
        sa.Column("name_normalized", sa.String(), nullable=False),
        sa.Column("servings", sa.Integer(), nullable=False),
        sa.Column(
            "total_grams", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column("weight_method", sa.String(), nullable=False),
        sa.Column("cuisine_id", sa.BigInteger(), nullable=True),
        sa.Column("source", sa.String(), nullable=False),
        sa.Column("source_license", sa.String(), nullable=False),
        sa.Column("quality_tier", sa.String(), nullable=False),
        sa.Column("is_verified", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "ingested_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("dataset_version", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "default_lang ~ '^[a-z]{2}$'", name=op.f("ck_meals_default_lang_iso639_1")
        ),
        sa.CheckConstraint(
            "quality_tier IN ('GOLD', 'SILVER')", name=op.f("ck_meals_quality_tier_valid")
        ),
        sa.CheckConstraint(
            "weight_method IN ('WEIGHED', 'YIELD_FACTOR', 'SUM_OF_INGREDIENTS')",
            name=op.f("ck_meals_weight_method_valid"),
        ),
        sa.CheckConstraint("servings > 0", name=op.f("ck_meals_servings_positive")),
        sa.CheckConstraint("total_grams > 0", name=op.f("ck_meals_total_grams_positive")),
        sa.ForeignKeyConstraint(
            ["cuisine_id"],
            ["cuisines.cuisine_id"],
            name=op.f("fk_meals_cuisine_id_cuisines"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("meal_id", name=op.f("pk_meals")),
        sa.UniqueConstraint("source", "ref_external", name=op.f("uq_meals_source_ref_external")),
    )
    op.create_index(op.f("ix_meals_cuisine_id"), "meals", ["cuisine_id"], unique=False)
    op.create_index(
        op.f("ix_meals_name_normalized"),
        "meals",
        ["name_normalized"],
        unique=False,
        postgresql_using="gin",
        postgresql_ops={"name_normalized": "gin_trgm_ops"},
    )
    op.create_table(
        "refresh_tokens",
        sa.Column("token_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("token_hash", sa.String(), nullable=False),
        sa.Column("family_id", sa.Uuid(), nullable=False),
        sa.Column(
            "issued_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("replaced_by_token_id", sa.BigInteger(), nullable=True),
        sa.CheckConstraint(
            "expires_at > issued_at", name=op.f("ck_refresh_tokens_expires_after_issued")
        ),
        sa.ForeignKeyConstraint(
            ["replaced_by_token_id"],
            ["refresh_tokens.token_id"],
            name=op.f("fk_refresh_tokens_replaced_by_token_id_refresh_tokens"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_refresh_tokens_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("token_id", name=op.f("pk_refresh_tokens")),
        sa.UniqueConstraint("token_hash", name=op.f("uq_refresh_tokens_token_hash")),
    )
    op.create_index(
        op.f("ix_refresh_tokens_family_id"), "refresh_tokens", ["family_id"], unique=False
    )
    op.create_index(
        op.f("ix_refresh_tokens_replaced_by_token_id"),
        "refresh_tokens",
        ["replaced_by_token_id"],
        unique=False,
    )
    op.create_index(op.f("ix_refresh_tokens_user_id"), "refresh_tokens", ["user_id"], unique=False)
    op.create_table(
        "user_allergen_prefs",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("allergen_id", sa.BigInteger(), nullable=False),
        sa.Column("severity", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "severity IN ('AVOID', 'SEVERE')", name=op.f("ck_user_allergen_prefs_severity_valid")
        ),
        sa.ForeignKeyConstraint(
            ["allergen_id"],
            ["allergens.allergen_id"],
            name=op.f("fk_user_allergen_prefs_allergen_id_allergens"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_allergen_prefs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id", "allergen_id", name=op.f("pk_user_allergen_prefs")),
    )
    op.create_index(
        op.f("ix_user_allergen_prefs_allergen_id"),
        "user_allergen_prefs",
        ["allergen_id"],
        unique=False,
    )
    op.create_table(
        "user_health_conditions",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("condition_id", sa.BigInteger(), nullable=False),
        sa.Column("severity", sa.String(), nullable=True),
        sa.Column("diagnosed", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "severity IN ('MILD', 'MODERATE', 'SEVERE')",
            name=op.f("ck_user_health_conditions_severity_valid"),
        ),
        sa.ForeignKeyConstraint(
            ["condition_id"],
            ["health_conditions.condition_id"],
            name=op.f("fk_user_health_conditions_condition_id_health_conditions"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_health_conditions_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_user_health_conditions")),
        sa.UniqueConstraint(
            "user_id", "condition_id", name=op.f("uq_user_health_conditions_user_id_condition_id")
        ),
    )
    op.create_index(
        op.f("ix_user_health_conditions_condition_id"),
        "user_health_conditions",
        ["condition_id"],
        unique=False,
    )
    op.create_table(
        "user_profiles",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("sex", sa.String(), nullable=False),
        sa.Column("birth_date", sa.Date(), nullable=False),
        sa.Column("height_cm", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column("activity_level", sa.String(), nullable=False),
        sa.Column("goal_type", sa.String(), nullable=False),
        sa.Column(
            "target_weight_kg", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True
        ),
        sa.Column(
            "weekly_rate_kg", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True
        ),
        sa.Column("physiological_status", sa.String(), server_default="NONE", nullable=False),
        sa.Column("timezone", sa.String(), nullable=False),
        sa.Column("water_goal_ml", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "activity_level IN ('SEDENTARY', 'LIGHT', 'MODERATE', 'HIGH', 'ATHLETE')",
            name=op.f("ck_user_profiles_activity_level_valid"),
        ),
        sa.CheckConstraint(
            "goal_type = 'MAINTAIN' OR (target_weight_kg IS NOT NULL AND weekly_rate_kg IS NOT NULL)",
            name=op.f("ck_user_profiles_goal_requires_target"),
        ),
        sa.CheckConstraint(
            "goal_type IN ('LOSE', 'MAINTAIN', 'GAIN')",
            name=op.f("ck_user_profiles_goal_type_valid"),
        ),
        sa.CheckConstraint(
            "physiological_status IN ('NONE', 'PREGNANT', 'LACTATING')",
            name=op.f("ck_user_profiles_physiological_status_valid"),
        ),
        sa.CheckConstraint(
            "sex = 'FEMALE' OR physiological_status = 'NONE'",
            name=op.f("ck_user_profiles_status_requires_female"),
        ),
        sa.CheckConstraint("sex IN ('MALE', 'FEMALE')", name=op.f("ck_user_profiles_sex_valid")),
        sa.CheckConstraint(
            "height_cm BETWEEN 100 AND 250", name=op.f("ck_user_profiles_height_range")
        ),
        sa.CheckConstraint(
            "target_weight_kg BETWEEN 30 AND 300", name=op.f("ck_user_profiles_target_weight_range")
        ),
        sa.CheckConstraint(
            "water_goal_ml BETWEEN 500 AND 5000", name=op.f("ck_user_profiles_water_goal_range")
        ),
        sa.CheckConstraint(
            "weekly_rate_kg > 0 AND weekly_rate_kg <= 1.0",
            name=op.f("ck_user_profiles_weekly_rate_range"),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_profiles_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id", name=op.f("pk_user_profiles")),
    )
    op.create_table(
        "user_targets",
        sa.Column("target_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("valid_from", sa.DateTime(timezone=True), nullable=False),
        sa.Column("valid_to", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "based_on_weight_kg", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column("bmr_kcal", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column("tdee_kcal", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column(
            "target_kcal", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column(
            "target_protein_g", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column(
            "target_carb_g", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column(
            "target_fat_g", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column("formula_version", sa.String(), nullable=False),
        sa.Column("reason", sa.String(), nullable=False),
        sa.Column("was_floor_applied", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "reason IN ('INITIAL', 'WEIGHT_UPDATE', 'GOAL_CHANGE', 'PROFILE_CHANGE', 'FORMULA_CHANGE')",
            name=op.f("ck_user_targets_reason_valid"),
        ),
        sa.CheckConstraint(
            "bmr_kcal > 0 AND tdee_kcal > 0 AND target_kcal > 0 AND target_protein_g > 0 AND target_carb_g > 0 AND target_fat_g > 0",
            name=op.f("ck_user_targets_values_positive"),
        ),
        sa.CheckConstraint(
            "valid_to IS NULL OR valid_to > valid_from",
            name=op.f("ck_user_targets_valid_to_after_from"),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_targets_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("target_id", name=op.f("pk_user_targets")),
    )
    op.create_index(
        op.f("ix_user_targets_user_id"),
        "user_targets",
        ["user_id"],
        unique=True,
        postgresql_where=sa.text("valid_to IS NULL"),
    )
    op.create_index(
        op.f("ix_user_targets_user_id_valid_from"),
        "user_targets",
        ["user_id", "valid_from"],
        unique=False,
    )
    op.create_table(
        "water_logs",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("amount_ml", sa.Integer(), nullable=False),
        sa.Column("client_uuid", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("amount_ml BETWEEN 1 AND 2000", name=op.f("ck_water_logs_amount_range")),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_water_logs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_water_logs")),
        sa.UniqueConstraint("client_uuid", name=op.f("uq_water_logs_client_uuid")),
    )
    op.create_index(op.f("ix_water_logs_user_id"), "water_logs", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_water_logs_user_id_log_date"),
        "water_logs",
        ["user_id", "log_date"],
        unique=False,
        postgresql_where=sa.text("deleted_at IS NULL"),
    )
    op.create_table(
        "weight_logs",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("measured_on", sa.Date(), nullable=False),
        sa.Column("weight_kg", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column("source", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("source IN ('MANUAL')", name=op.f("ck_weight_logs_source_valid")),
        sa.CheckConstraint(
            "weight_kg BETWEEN 20 AND 400", name=op.f("ck_weight_logs_weight_range")
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_weight_logs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_weight_logs")),
        sa.UniqueConstraint(
            "user_id", "measured_on", name=op.f("uq_weight_logs_user_id_measured_on")
        ),
    )
    op.create_table(
        "food_nutrients",
        sa.Column("food_id", sa.BigInteger(), nullable=False),
        sa.Column("nutrient_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "amount_per_100g", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.CheckConstraint(
            "amount_per_100g >= 0", name=op.f("ck_food_nutrients_amount_non_negative")
        ),
        sa.ForeignKeyConstraint(
            ["food_id"],
            ["foods.food_id"],
            name=op.f("fk_food_nutrients_food_id_foods"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["nutrient_id"],
            ["nutrients.nutrient_id"],
            name=op.f("fk_food_nutrients_nutrient_id_nutrients"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("food_id", "nutrient_id", name=op.f("pk_food_nutrients")),
    )
    op.create_index(
        op.f("ix_food_nutrients_nutrient_id"), "food_nutrients", ["nutrient_id"], unique=False
    )
    op.create_table(
        "ingredients",
        sa.Column("ingredient_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("canonical_name", sa.String(), nullable=False),
        sa.Column("canonical_name_ar", sa.String(), nullable=False),
        sa.Column("default_food_id", sa.BigInteger(), nullable=True),
        sa.Column("review_status", sa.String(), server_default="PENDING", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "review_status IN ('PENDING', 'APPROVED', 'REJECTED')",
            name=op.f("ck_ingredients_review_status_valid"),
        ),
        sa.ForeignKeyConstraint(
            ["default_food_id"],
            ["foods.food_id"],
            name=op.f("fk_ingredients_default_food_id_foods"),
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("ingredient_id", name=op.f("pk_ingredients")),
    )
    op.create_index(
        op.f("ix_ingredients_default_food_id"), "ingredients", ["default_food_id"], unique=False
    )
    op.create_table(
        "meal_allergens",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("allergen_id", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["allergen_id"],
            ["allergens.allergen_id"],
            name=op.f("fk_meal_allergens_allergen_id_allergens"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_allergens_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("meal_id", "allergen_id", name=op.f("pk_meal_allergens")),
    )
    op.create_index(
        op.f("ix_meal_allergens_allergen_id"), "meal_allergens", ["allergen_id"], unique=False
    )
    op.create_table(
        "meal_nutrients",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("nutrient_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "amount_per_serving", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column(
            "amount_per_100g", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.Column("computed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("computation_version", sa.String(), nullable=False),
        sa.CheckConstraint(
            "amount_per_100g >= 0", name=op.f("ck_meal_nutrients_amount_per_100g_non_negative")
        ),
        sa.CheckConstraint(
            "amount_per_serving >= 0",
            name=op.f("ck_meal_nutrients_amount_per_serving_non_negative"),
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_nutrients_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["nutrient_id"],
            ["nutrients.nutrient_id"],
            name=op.f("fk_meal_nutrients_nutrient_id_nutrients"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("meal_id", "nutrient_id", name=op.f("pk_meal_nutrients")),
    )
    op.create_index(
        op.f("ix_meal_nutrients_nutrient_id"), "meal_nutrients", ["nutrient_id"], unique=False
    )
    op.create_table(
        "meal_plans",
        sa.Column("plan_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("date_from", sa.Date(), nullable=False),
        sa.Column("date_to", sa.Date(), nullable=False),
        sa.Column("generated_by", sa.String(), nullable=False),
        sa.Column("algorithm_version", sa.String(), nullable=False),
        sa.Column("target_id", sa.BigInteger(), nullable=True),
        sa.Column("target_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint("date_to >= date_from", name=op.f("ck_meal_plans_date_range")),
        sa.ForeignKeyConstraint(
            ["target_id"],
            ["user_targets.target_id"],
            name=op.f("fk_meal_plans_target_id_user_targets"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_meal_plans_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("plan_id", name=op.f("pk_meal_plans")),
    )
    op.create_index(op.f("ix_meal_plans_target_id"), "meal_plans", ["target_id"], unique=False)
    op.create_index(
        op.f("ix_meal_plans_user_id_date_from"),
        "meal_plans",
        ["user_id", "date_from"],
        unique=False,
    )
    op.create_table(
        "meal_tags",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("tag_id", sa.BigInteger(), nullable=False),
        sa.Column("source", sa.String(), nullable=False),
        sa.CheckConstraint(
            "source IN ('MANUAL', 'DERIVED')", name=op.f("ck_meal_tags_source_valid")
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_tags_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["tag_id"],
            ["dietary_tags.tag_id"],
            name=op.f("fk_meal_tags_tag_id_dietary_tags"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("meal_id", "tag_id", name=op.f("pk_meal_tags")),
    )
    op.create_index(op.f("ix_meal_tags_tag_id"), "meal_tags", ["tag_id"], unique=False)
    op.create_table(
        "meal_translations",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("lang", sa.String(length=2), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("name_normalized", sa.String(), nullable=False),
        sa.CheckConstraint("lang ~ '^[a-z]{2}$'", name=op.f("ck_meal_translations_lang_iso639_1")),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_translations_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("meal_id", "lang", name=op.f("pk_meal_translations")),
    )
    op.create_index(
        op.f("ix_meal_translations_name_normalized"),
        "meal_translations",
        ["name_normalized"],
        unique=False,
        postgresql_using="gin",
        postgresql_ops={"name_normalized": "gin_trgm_ops"},
    )
    op.create_table(
        "portions_food",
        sa.Column("portion_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("food_id", sa.BigInteger(), nullable=False),
        sa.Column("unit_text", sa.String(), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column(
            "gram_weight", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False
        ),
        sa.CheckConstraint("gram_weight > 0", name=op.f("ck_portions_food_gram_weight_positive")),
        sa.ForeignKeyConstraint(
            ["food_id"],
            ["foods.food_id"],
            name=op.f("fk_portions_food_food_id_foods"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("portion_id", name=op.f("pk_portions_food")),
    )
    op.create_index(op.f("ix_portions_food_food_id"), "portions_food", ["food_id"], unique=False)
    op.create_table(
        "user_interactions",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("value", sa.SmallInteger(), nullable=True),
        sa.Column(
            "context", postgresql.JSONB(astext_type=sa.Text()), server_default="{}", nullable=False
        ),
        sa.Column("client_uuid", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "event_type <> 'RATE' OR value IS NOT NULL",
            name=op.f("ck_user_interactions_rate_requires_value"),
        ),
        sa.CheckConstraint(
            "event_type IN ('IMPRESSION', 'ACCEPT', 'VIEW', 'SAVE', 'RATE', 'COOK', 'SKIP', 'SWAP_OUT')",
            name=op.f("ck_user_interactions_event_type_valid"),
        ),
        sa.CheckConstraint(
            "value IS NULL OR value BETWEEN 1 AND 5", name=op.f("ck_user_interactions_value_range")
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_user_interactions_meal_id_meals"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_interactions_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_user_interactions")),
        sa.UniqueConstraint("client_uuid", name=op.f("uq_user_interactions_client_uuid")),
    )
    op.create_index(
        op.f("ix_user_interactions_meal_id"), "user_interactions", ["meal_id"], unique=False
    )
    op.create_index(
        op.f("ix_user_interactions_user_id_created_at"),
        "user_interactions",
        ["user_id", "created_at"],
        unique=False,
    )
    op.create_table(
        "ingredient_aliases",
        sa.Column("alias_id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("ingredient_id", sa.BigInteger(), nullable=False),
        sa.Column("alias_text", sa.String(), nullable=False),
        sa.Column("lang", sa.String(length=2), nullable=False),
        sa.Column("confidence", sa.Numeric(precision=4, scale=3, asdecimal=False), nullable=True),
        sa.Column("source", sa.String(), nullable=True),
        sa.Column("alias_normalized", sa.String(), nullable=False),
        sa.CheckConstraint("lang ~ '^[a-z]{2}$'", name=op.f("ck_ingredient_aliases_lang_iso639_1")),
        sa.CheckConstraint(
            "confidence BETWEEN 0 AND 1", name=op.f("ck_ingredient_aliases_confidence_range")
        ),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.ingredient_id"],
            name=op.f("fk_ingredient_aliases_ingredient_id_ingredients"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("alias_id", name=op.f("pk_ingredient_aliases")),
        sa.UniqueConstraint(
            "alias_text", "lang", name=op.f("uq_ingredient_aliases_alias_text_lang")
        ),
    )
    op.create_index(
        op.f("ix_ingredient_aliases_alias_normalized"),
        "ingredient_aliases",
        ["alias_normalized"],
        unique=False,
        postgresql_using="gin",
        postgresql_ops={"alias_normalized": "gin_trgm_ops"},
    )
    op.create_index(
        op.f("ix_ingredient_aliases_ingredient_id"),
        "ingredient_aliases",
        ["ingredient_id"],
        unique=False,
    )
    op.create_table(
        "ingredient_allergens",
        sa.Column("ingredient_id", sa.BigInteger(), nullable=False),
        sa.Column("allergen_id", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["allergen_id"],
            ["allergens.allergen_id"],
            name=op.f("fk_ingredient_allergens_allergen_id_allergens"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.ingredient_id"],
            name=op.f("fk_ingredient_allergens_ingredient_id_ingredients"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint(
            "ingredient_id", "allergen_id", name=op.f("pk_ingredient_allergens")
        ),
    )
    op.create_index(
        op.f("ix_ingredient_allergens_allergen_id"),
        "ingredient_allergens",
        ["allergen_id"],
        unique=False,
    )
    op.create_table(
        "ingredient_tags",
        sa.Column("ingredient_id", sa.BigInteger(), nullable=False),
        sa.Column("tag_id", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.ingredient_id"],
            name=op.f("fk_ingredient_tags_ingredient_id_ingredients"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["tag_id"],
            ["dietary_tags.tag_id"],
            name=op.f("fk_ingredient_tags_tag_id_dietary_tags"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("ingredient_id", "tag_id", name=op.f("pk_ingredient_tags")),
    )
    op.create_index(op.f("ix_ingredient_tags_tag_id"), "ingredient_tags", ["tag_id"], unique=False)
    op.create_table(
        "meal_ingredients",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("ingredient_id", sa.BigInteger(), nullable=False),
        sa.Column("food_id", sa.BigInteger(), nullable=True),
        sa.Column("grams", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=False),
        sa.Column("text_original", sa.String(), nullable=True),
        sa.Column(
            "mapping_confidence", sa.Numeric(precision=4, scale=3, asdecimal=False), nullable=True
        ),
        sa.CheckConstraint("grams > 0", name=op.f("ck_meal_ingredients_grams_positive")),
        sa.CheckConstraint(
            "mapping_confidence BETWEEN 0 AND 1",
            name=op.f("ck_meal_ingredients_mapping_confidence_range"),
        ),
        sa.CheckConstraint("position >= 1", name=op.f("ck_meal_ingredients_position_min_1")),
        sa.ForeignKeyConstraint(
            ["food_id"],
            ["foods.food_id"],
            name=op.f("fk_meal_ingredients_food_id_foods"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.ingredient_id"],
            name=op.f("fk_meal_ingredients_ingredient_id_ingredients"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_ingredients_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("meal_id", "position", name=op.f("pk_meal_ingredients")),
    )
    op.create_index(
        op.f("ix_meal_ingredients_food_id"), "meal_ingredients", ["food_id"], unique=False
    )
    op.create_index(
        op.f("ix_meal_ingredients_ingredient_id"),
        "meal_ingredients",
        ["ingredient_id"],
        unique=False,
    )
    op.create_table(
        "meal_plan_items",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("plan_id", sa.BigInteger(), nullable=False),
        sa.Column("day_index", sa.Integer(), nullable=False),
        sa.Column("slot", sa.String(), nullable=False),
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "servings_multiplier", sa.Numeric(precision=3, scale=2, asdecimal=False), nullable=False
        ),
        sa.Column("was_swapped", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "reason_codes",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default="[]",
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "slot IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')",
            name=op.f("ck_meal_plan_items_slot_valid"),
        ),
        sa.CheckConstraint(
            "day_index >= 0", name=op.f("ck_meal_plan_items_day_index_non_negative")
        ),
        sa.CheckConstraint(
            "servings_multiplier IN (0.5, 1.0, 1.5, 2.0)",
            name=op.f("ck_meal_plan_items_servings_multiplier_step"),
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_plan_items_meal_id_meals"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["plan_id"],
            ["meal_plans.plan_id"],
            name=op.f("fk_meal_plan_items_plan_id_meal_plans"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_meal_plan_items")),
    )
    op.create_index(
        op.f("ix_meal_plan_items_meal_id"), "meal_plan_items", ["meal_id"], unique=False
    )
    op.create_index(
        op.f("ix_meal_plan_items_plan_id"), "meal_plan_items", ["plan_id"], unique=False
    )
    op.create_table(
        "user_ingredient_prefs",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("ingredient_id", sa.BigInteger(), nullable=False),
        sa.Column("stance", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "stance IN ('LIKE', 'DISLIKE', 'EXCLUDE')",
            name=op.f("ck_user_ingredient_prefs_stance_valid"),
        ),
        sa.ForeignKeyConstraint(
            ["ingredient_id"],
            ["ingredients.ingredient_id"],
            name=op.f("fk_user_ingredient_prefs_ingredient_id_ingredients"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_ingredient_prefs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id", "ingredient_id", name=op.f("pk_user_ingredient_prefs")),
    )
    op.create_index(
        op.f("ix_user_ingredient_prefs_ingredient_id"),
        "user_ingredient_prefs",
        ["ingredient_id"],
        unique=False,
    )
    op.create_table(
        "consumption_logs",
        sa.Column("id", sa.BigInteger(), sa.Identity(always=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("slot", sa.String(), nullable=True),
        sa.Column("plan_item_id", sa.BigInteger(), nullable=True),
        sa.Column("meal_id", sa.BigInteger(), nullable=True),
        sa.Column("food_id", sa.BigInteger(), nullable=True),
        sa.Column(
            "servings_consumed", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True
        ),
        sa.Column(
            "grams_consumed", sa.Numeric(precision=12, scale=3, asdecimal=False), nullable=True
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("client_uuid", sa.Uuid(), nullable=True),
        sa.Column("nutrients_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.CheckConstraint(
            "slot IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')",
            name=op.f("ck_consumption_logs_slot_valid"),
        ),
        sa.CheckConstraint(
            "(meal_id IS NOT NULL) <> (food_id IS NOT NULL)",
            name=op.f("ck_consumption_logs_one_target"),
        ),
        sa.CheckConstraint(
            "food_id IS NULL OR (grams_consumed > 0 AND servings_consumed IS NULL)",
            name=op.f("ck_consumption_logs_food_requires_grams"),
        ),
        sa.CheckConstraint(
            "meal_id IS NULL OR (servings_consumed > 0 AND grams_consumed IS NULL)",
            name=op.f("ck_consumption_logs_meal_requires_servings"),
        ),
        sa.CheckConstraint(
            "plan_item_id IS NULL OR meal_id IS NOT NULL",
            name=op.f("ck_consumption_logs_plan_item_needs_meal"),
        ),
        sa.ForeignKeyConstraint(
            ["food_id"],
            ["foods.food_id"],
            name=op.f("fk_consumption_logs_food_id_foods"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_consumption_logs_meal_id_meals"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["plan_item_id"],
            ["meal_plan_items.id"],
            name=op.f("fk_consumption_logs_plan_item_id_meal_plan_items"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_consumption_logs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_consumption_logs")),
        sa.UniqueConstraint("client_uuid", name=op.f("uq_consumption_logs_client_uuid")),
    )
    op.create_index(
        op.f("ix_consumption_logs_food_id"), "consumption_logs", ["food_id"], unique=False
    )
    op.create_index(
        op.f("ix_consumption_logs_meal_id"), "consumption_logs", ["meal_id"], unique=False
    )
    op.create_index(
        op.f("ix_consumption_logs_plan_item_id"), "consumption_logs", ["plan_item_id"], unique=False
    )
    op.create_index(
        op.f("ix_consumption_logs_user_id"), "consumption_logs", ["user_id"], unique=False
    )
    op.create_index(
        op.f("ix_consumption_logs_user_id_log_date"),
        "consumption_logs",
        ["user_id", "log_date"],
        unique=False,
        postgresql_where=sa.text("deleted_at IS NULL"),
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_consumption_logs_user_id_log_date"),
        table_name="consumption_logs",
        postgresql_where=sa.text("deleted_at IS NULL"),
    )
    op.drop_index(op.f("ix_consumption_logs_user_id"), table_name="consumption_logs")
    op.drop_index(op.f("ix_consumption_logs_plan_item_id"), table_name="consumption_logs")
    op.drop_index(op.f("ix_consumption_logs_meal_id"), table_name="consumption_logs")
    op.drop_index(op.f("ix_consumption_logs_food_id"), table_name="consumption_logs")
    op.drop_table("consumption_logs")
    op.drop_index(
        op.f("ix_user_ingredient_prefs_ingredient_id"), table_name="user_ingredient_prefs"
    )
    op.drop_table("user_ingredient_prefs")
    op.drop_index(op.f("ix_meal_plan_items_plan_id"), table_name="meal_plan_items")
    op.drop_index(op.f("ix_meal_plan_items_meal_id"), table_name="meal_plan_items")
    op.drop_table("meal_plan_items")
    op.drop_index(op.f("ix_meal_ingredients_ingredient_id"), table_name="meal_ingredients")
    op.drop_index(op.f("ix_meal_ingredients_food_id"), table_name="meal_ingredients")
    op.drop_table("meal_ingredients")
    op.drop_index(op.f("ix_ingredient_tags_tag_id"), table_name="ingredient_tags")
    op.drop_table("ingredient_tags")
    op.drop_index(op.f("ix_ingredient_allergens_allergen_id"), table_name="ingredient_allergens")
    op.drop_table("ingredient_allergens")
    op.drop_index(op.f("ix_ingredient_aliases_ingredient_id"), table_name="ingredient_aliases")
    op.drop_index(
        op.f("ix_ingredient_aliases_alias_normalized"),
        table_name="ingredient_aliases",
        postgresql_using="gin",
        postgresql_ops={"alias_normalized": "gin_trgm_ops"},
    )
    op.drop_table("ingredient_aliases")
    op.drop_index(op.f("ix_user_interactions_user_id_created_at"), table_name="user_interactions")
    op.drop_index(op.f("ix_user_interactions_meal_id"), table_name="user_interactions")
    op.drop_table("user_interactions")
    op.drop_index(op.f("ix_portions_food_food_id"), table_name="portions_food")
    op.drop_table("portions_food")
    op.drop_index(
        op.f("ix_meal_translations_name_normalized"),
        table_name="meal_translations",
        postgresql_using="gin",
        postgresql_ops={"name_normalized": "gin_trgm_ops"},
    )
    op.drop_table("meal_translations")
    op.drop_index(op.f("ix_meal_tags_tag_id"), table_name="meal_tags")
    op.drop_table("meal_tags")
    op.drop_index(op.f("ix_meal_plans_user_id_date_from"), table_name="meal_plans")
    op.drop_index(op.f("ix_meal_plans_target_id"), table_name="meal_plans")
    op.drop_table("meal_plans")
    op.drop_index(op.f("ix_meal_nutrients_nutrient_id"), table_name="meal_nutrients")
    op.drop_table("meal_nutrients")
    op.drop_index(op.f("ix_meal_allergens_allergen_id"), table_name="meal_allergens")
    op.drop_table("meal_allergens")
    op.drop_index(op.f("ix_ingredients_default_food_id"), table_name="ingredients")
    op.drop_table("ingredients")
    op.drop_index(op.f("ix_food_nutrients_nutrient_id"), table_name="food_nutrients")
    op.drop_table("food_nutrients")
    op.drop_table("weight_logs")
    op.drop_index(
        op.f("ix_water_logs_user_id_log_date"),
        table_name="water_logs",
        postgresql_where=sa.text("deleted_at IS NULL"),
    )
    op.drop_index(op.f("ix_water_logs_user_id"), table_name="water_logs")
    op.drop_table("water_logs")
    op.drop_index(op.f("ix_user_targets_user_id_valid_from"), table_name="user_targets")
    op.drop_index(
        op.f("ix_user_targets_user_id"),
        table_name="user_targets",
        postgresql_where=sa.text("valid_to IS NULL"),
    )
    op.drop_table("user_targets")
    op.drop_table("user_profiles")
    op.drop_index(
        op.f("ix_user_health_conditions_condition_id"), table_name="user_health_conditions"
    )
    op.drop_table("user_health_conditions")
    op.drop_index(op.f("ix_user_allergen_prefs_allergen_id"), table_name="user_allergen_prefs")
    op.drop_table("user_allergen_prefs")
    op.drop_index(op.f("ix_refresh_tokens_user_id"), table_name="refresh_tokens")
    op.drop_index(op.f("ix_refresh_tokens_replaced_by_token_id"), table_name="refresh_tokens")
    op.drop_index(op.f("ix_refresh_tokens_family_id"), table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_index(
        op.f("ix_meals_name_normalized"),
        table_name="meals",
        postgresql_using="gin",
        postgresql_ops={"name_normalized": "gin_trgm_ops"},
    )
    op.drop_index(op.f("ix_meals_cuisine_id"), table_name="meals")
    op.drop_table("meals")
    op.drop_index(op.f("ix_foods_category_id"), table_name="foods")
    op.drop_table("foods")
    op.drop_index(
        op.f("ix_condition_tag_restrictions_tag_id"), table_name="condition_tag_restrictions"
    )
    op.drop_table("condition_tag_restrictions")
    op.drop_index(
        op.f("ix_condition_nutrient_limits_nutrient_id"), table_name="condition_nutrient_limits"
    )
    op.drop_table("condition_nutrient_limits")
    op.drop_table("users")
    op.drop_table("nutrients")
    op.drop_table("health_conditions")
    op.drop_table("dietary_tags")
    op.drop_table("cuisines")
    op.drop_table("categories")
    op.drop_table("allergens")
    op.execute("DROP EXTENSION IF EXISTS pg_trgm")
