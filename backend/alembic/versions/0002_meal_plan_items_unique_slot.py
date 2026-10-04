"""meal plan items unique slot

One BREAKFAST, LUNCH and DINNER per plan day; several SNACK items stay allowed (§11.8, #71).

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-03 16:32:39.427967
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | Sequence[str] | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index(
        op.f("ix_meal_plan_items_plan_id_day_index_slot"),
        "meal_plan_items",
        ["plan_id", "day_index", "slot"],
        unique=True,
        postgresql_where=sa.text("slot <> 'SNACK'"),
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_meal_plan_items_plan_id_day_index_slot"),
        table_name="meal_plan_items",
        postgresql_where=sa.text("slot <> 'SNACK'"),
    )
