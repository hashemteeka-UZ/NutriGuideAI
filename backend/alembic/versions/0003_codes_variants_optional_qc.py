"""codes, variants, optional ingredients, QC columns

First post-freeze change (v4.14, §20.1): stable codes for cuisines and allergens and UNIQUE
categories.name_en (#77); meals.variant_group (#76); meal_ingredients.is_optional (#75);
meals.yield_factor / yield_factor_source / reviewed_by and meal_tags.rule_version (#78).

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-07 18:45:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: str | Sequence[str] | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

CODE_TABLES = ("cuisines", "allergens")


def upgrade() -> None:
    # §9.2, §9.3: add nullable, backfill existing rows from name_en, then enforce.
    for table in CODE_TABLES:
        op.add_column(table, sa.Column("code", sa.String(), nullable=True))
        op.execute(f"UPDATE {table} SET code = upper(replace(name_en, ' ', '_'))")
        op.alter_column(table, "code", existing_type=sa.String(), nullable=False)
        op.create_unique_constraint(op.f(f"uq_{table}_code"), table, ["code"])

    # §9.1
    op.create_unique_constraint(op.f("uq_categories_name_en"), "categories", ["name_en"])

    # §10.1
    op.add_column("meals", sa.Column("variant_group", sa.String(), nullable=True))
    op.create_index(op.f("ix_meals_variant_group"), "meals", ["variant_group"], unique=False)
    op.add_column(
        "meals", sa.Column("yield_factor", sa.Numeric(precision=12, scale=3), nullable=True)
    )
    op.add_column("meals", sa.Column("yield_factor_source", sa.String(), nullable=True))
    op.add_column("meals", sa.Column("reviewed_by", sa.String(), nullable=True))
    op.create_check_constraint(
        op.f("ck_meals_yield_factor_range"),
        "meals",
        "yield_factor IS NULL OR (yield_factor > 0 AND yield_factor <= 3)",
    )
    op.create_check_constraint(
        op.f("ck_meals_yield_factor_only_for_yield_method"),
        "meals",
        "weight_method = 'YIELD_FACTOR' OR yield_factor IS NULL",
    )

    # §10.2
    op.add_column(
        "meal_ingredients",
        sa.Column("is_optional", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )

    # §10.5
    op.add_column("meal_tags", sa.Column("rule_version", sa.String(), nullable=True))
    op.create_check_constraint(
        op.f("ck_meal_tags_rule_version_only_derived"),
        "meal_tags",
        "source = 'DERIVED' OR rule_version IS NULL",
    )


def downgrade() -> None:
    op.drop_constraint(op.f("ck_meal_tags_rule_version_only_derived"), "meal_tags", type_="check")
    op.drop_column("meal_tags", "rule_version")

    op.drop_column("meal_ingredients", "is_optional")

    op.drop_constraint(op.f("ck_meals_yield_factor_only_for_yield_method"), "meals", type_="check")
    op.drop_constraint(op.f("ck_meals_yield_factor_range"), "meals", type_="check")
    op.drop_column("meals", "reviewed_by")
    op.drop_column("meals", "yield_factor_source")
    op.drop_column("meals", "yield_factor")
    op.drop_index(op.f("ix_meals_variant_group"), table_name="meals")
    op.drop_column("meals", "variant_group")

    op.drop_constraint(op.f("uq_categories_name_en"), "categories", type_="unique")

    for table in reversed(CODE_TABLES):
        op.drop_constraint(op.f(f"uq_{table}_code"), table, type_="unique")
        op.drop_column(table, "code")
