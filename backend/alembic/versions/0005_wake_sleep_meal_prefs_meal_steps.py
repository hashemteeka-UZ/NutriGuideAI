"""wake and sleep times, meal preferences, preparation steps

Third post-freeze change (v4.19, §20.1, Decision #165): user_profiles.wake_time
and sleep_time (#145), user_meal_prefs (#149), meal_steps and meals.dish_form
(#161), preference event types, user_cuisine_prefs, and consumption_logs
entry_group / entry_label.

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-18 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | Sequence[str] | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# 0004 list. Downgrade restores it and fails if PREF_* rows exist, which is acceptable:
# those events are only written after this revision.
EVENT_TYPE_0004 = (
    "event_type IN ('IMPRESSION', 'ACCEPT', 'VIEW', 'SAVE', 'RATE', 'COOK', 'SKIP', 'SWAP_OUT')"
)
EVENT_TYPE_0005 = (
    "event_type IN ('IMPRESSION', 'ACCEPT', 'VIEW', 'SAVE', 'RATE', 'COOK', 'SKIP', 'SWAP_OUT', "
    "'PREF_LIKE', 'PREF_DISLIKE', 'PREF_CLEAR')"
)


def upgrade() -> None:
    # §11.2: existing rows take the server defaults; no separate backfill.
    op.add_column(
        "user_profiles",
        sa.Column("wake_time", sa.Time(), server_default="07:00:00", nullable=False),
    )
    op.add_column(
        "user_profiles",
        sa.Column("sleep_time", sa.Time(), server_default="23:00:00", nullable=False),
    )
    op.create_check_constraint(
        op.f("ck_user_profiles_wake_sleep_differ"),
        "user_profiles",
        "wake_time <> sleep_time",
    )

    # §10.1: nullable; NULL means not yet documented.
    op.add_column("meals", sa.Column("dish_form", sa.String(), nullable=True))
    op.create_check_constraint(
        op.f("ck_meals_dish_form_valid"),
        "meals",
        "dish_form IN ('ONE_DISH', 'PLATE')",
    )

    # §11.6: widen the existing CHECK. Downgrade restores the 0004 list.
    op.drop_constraint(
        op.f("ck_user_interactions_event_type_valid"),
        "user_interactions",
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_user_interactions_event_type_valid"),
        "user_interactions",
        EVENT_TYPE_0005,
    )

    # §10.7
    op.create_table(
        "meal_steps",
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
        sa.Column("lang", sa.String(length=2), nullable=False),
        sa.Column("position", sa.SmallInteger(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
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
        sa.CheckConstraint("position >= 1", name=op.f("ck_meal_steps_position_positive")),
        sa.CheckConstraint("length(btrim(text)) > 0", name=op.f("ck_meal_steps_text_not_blank")),
        sa.CheckConstraint("lang ~ '^[a-z]{2}$'", name=op.f("ck_meal_steps_lang_iso639_1")),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_meal_steps_meal_id_meals"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("meal_id", "lang", "position", name=op.f("pk_meal_steps")),
    )

    # §11.14
    op.create_table(
        "user_meal_prefs",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("meal_id", sa.BigInteger(), nullable=False),
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
            "stance IN ('LIKE', 'DISLIKE')",
            name=op.f("ck_user_meal_prefs_stance_valid"),
        ),
        sa.ForeignKeyConstraint(
            ["meal_id"],
            ["meals.meal_id"],
            name=op.f("fk_user_meal_prefs_meal_id_meals"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_meal_prefs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id", "meal_id", name=op.f("pk_user_meal_prefs")),
    )
    op.create_index(
        op.f("ix_user_meal_prefs_meal_id"), "user_meal_prefs", ["meal_id"], unique=False
    )

    # §11.15: created_at only; rows are inserted or deleted, never updated.
    op.create_table(
        "user_cuisine_prefs",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("cuisine_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["cuisine_id"],
            ["cuisines.cuisine_id"],
            name=op.f("fk_user_cuisine_prefs_cuisine_id_cuisines"),
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.user_id"],
            name=op.f("fk_user_cuisine_prefs_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id", "cuisine_id", name=op.f("pk_user_cuisine_prefs")),
    )
    op.create_index(
        op.f("ix_user_cuisine_prefs_cuisine_id"),
        "user_cuisine_prefs",
        ["cuisine_id"],
        unique=False,
    )

    # §11.9
    op.add_column("consumption_logs", sa.Column("entry_group", sa.Uuid(), nullable=True))
    op.add_column("consumption_logs", sa.Column("entry_label", sa.Text(), nullable=True))
    op.create_index(
        op.f("ix_consumption_logs_entry_group"),
        "consumption_logs",
        ["entry_group"],
        unique=False,
    )
    op.create_check_constraint(
        op.f("ck_consumption_logs_entry_group_food_only"),
        "consumption_logs",
        "entry_group IS NULL OR food_id IS NOT NULL",
    )
    op.create_check_constraint(
        op.f("ck_consumption_logs_entry_label_needs_group"),
        "consumption_logs",
        "entry_label IS NULL OR (entry_group IS NOT NULL AND length(btrim(entry_label)) > 0)",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("ck_consumption_logs_entry_label_needs_group"),
        "consumption_logs",
        type_="check",
    )
    op.drop_constraint(
        op.f("ck_consumption_logs_entry_group_food_only"),
        "consumption_logs",
        type_="check",
    )
    op.drop_index(op.f("ix_consumption_logs_entry_group"), table_name="consumption_logs")
    op.drop_column("consumption_logs", "entry_label")
    op.drop_column("consumption_logs", "entry_group")

    op.drop_index(op.f("ix_user_cuisine_prefs_cuisine_id"), table_name="user_cuisine_prefs")
    op.drop_table("user_cuisine_prefs")
    op.drop_index(op.f("ix_user_meal_prefs_meal_id"), table_name="user_meal_prefs")
    op.drop_table("user_meal_prefs")
    op.drop_table("meal_steps")

    op.drop_constraint(
        op.f("ck_user_interactions_event_type_valid"),
        "user_interactions",
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_user_interactions_event_type_valid"),
        "user_interactions",
        EVENT_TYPE_0004,
    )

    op.drop_constraint(op.f("ck_meals_dish_form_valid"), "meals", type_="check")
    op.drop_column("meals", "dish_form")

    op.drop_constraint(op.f("ck_user_profiles_wake_sleep_differ"), "user_profiles", type_="check")
    op.drop_column("user_profiles", "sleep_time")
    op.drop_column("user_profiles", "wake_time")
