"""ingredient natural key and restriction provenance

Second post-freeze change (v4.16, §20.1, Decision #91): ingredients.code as the
ingredient natural key (F-01, #77) and condition_tag_restrictions.source_reference
(provenance gap, #89, §14). Existing rows are backfilled, then NOT NULL.

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-11 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | Sequence[str] | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

CODE_BACKFILL = (
    "UPDATE ingredients SET code = upper(btrim(regexp_replace("
    "btrim(canonical_name), '[^A-Za-z0-9]+', '_', 'g'), '_'))"
)
SOURCE_BACKFILL = (
    "UPDATE condition_tag_restrictions SET source_reference = "
    "'backfilled by migration 0004; reloaded from the reference seed'"
)


def upgrade() -> None:
    # §9.10: add nullable, backfill from canonical_name (same rule as slice_foods.yaml),
    # then enforce NOT NULL, UNIQUE and the format CHECK.
    op.add_column("ingredients", sa.Column("code", sa.String(), nullable=True))
    op.execute(CODE_BACKFILL)
    op.alter_column("ingredients", "code", existing_type=sa.String(), nullable=False)
    op.create_unique_constraint(op.f("uq_ingredients_code"), "ingredients", ["code"])
    op.create_check_constraint(
        op.f("ck_ingredients_code_format"),
        "ingredients",
        "code ~ '^[A-Z][A-Z0-9_]*$'",
    )

    # §9.5c: add nullable, backfill existing rows, then enforce NOT NULL.
    op.add_column(
        "condition_tag_restrictions", sa.Column("source_reference", sa.String(), nullable=True)
    )
    op.execute(SOURCE_BACKFILL)
    op.alter_column(
        "condition_tag_restrictions",
        "source_reference",
        existing_type=sa.String(),
        nullable=False,
    )


def downgrade() -> None:
    op.drop_column("condition_tag_restrictions", "source_reference")

    op.drop_constraint(op.f("ck_ingredients_code_format"), "ingredients", type_="check")
    op.drop_constraint(op.f("uq_ingredients_code"), "ingredients", type_="unique")
    op.drop_column("ingredients", "code")
