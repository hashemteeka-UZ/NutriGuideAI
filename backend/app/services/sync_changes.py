"""Change feed for one user since a client cursor (#211)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Final

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import (
    ConsumptionLog,
    MealPlan,
    MealPlanItem,
    UserAllergenPref,
    UserHealthCondition,
    UserIngredientPref,
    UserMealPref,
    UserProfile,
    UserTarget,
    WaterLog,
    WeightLog,
)
from app.services.common import InputRejectedError, require_aware
from app.services.consumption import local_date
from app.services.logging_requests import LoggedConsumption, consumption_views
from app.services.meal_prefs import list_meal_prefs
from app.services.plan_requests import current_plans
from app.services.plan_view import PlanViewData, plan_view
from app.services.weight import CLOCK_SKEW_TOLERANCE, ClockSkewError, weights_between

SYNC_MAX_AGE_DAYS: Final = 30
SYNC_OVERLAP: Final = timedelta(minutes=2)
WEIGHT_HISTORY_DAYS: Final = 30


@dataclass(frozen=True)
class SyncFeed:
    consumption_logs: list[LoggedConsumption]
    deleted_consumption_log_ids: list[int]
    water_logs: list[WaterLog]
    deleted_water_log_ids: list[int]
    weights: list[WeightLog]
    plans: list[PlanViewData]
    meal_prefs: list[UserMealPref]
    profile_changed: bool


def _profile_changed(session: Session, user_id: int, cutoff: datetime) -> bool:
    checks = (
        select(UserProfile.user_id).where(
            UserProfile.user_id == user_id, UserProfile.updated_at > cutoff
        ),
        select(UserHealthCondition.id).where(
            UserHealthCondition.user_id == user_id, UserHealthCondition.updated_at > cutoff
        ),
        select(UserAllergenPref.allergen_id).where(
            UserAllergenPref.user_id == user_id, UserAllergenPref.updated_at > cutoff
        ),
        select(UserIngredientPref.ingredient_id).where(
            UserIngredientPref.user_id == user_id, UserIngredientPref.updated_at > cutoff
        ),
        select(UserTarget.target_id).where(
            UserTarget.user_id == user_id, UserTarget.created_at > cutoff
        ),
    )
    return any(session.scalar(check.limit(1)) is not None for check in checks)


def _plans_since(
    session: Session, user_id: int, yesterday: date, cutoff: datetime, lang: str
) -> list[PlanViewData]:
    latest = session.scalar(
        select(MealPlan.date_to)
        .where(MealPlan.user_id == user_id)
        .order_by(MealPlan.date_to.desc())
        .limit(1)
    )
    if latest is None or latest < yesterday:
        return []
    changed = set(
        session.scalars(
            select(MealPlanItem.plan_id)
            .join(MealPlan, MealPlan.plan_id == MealPlanItem.plan_id)
            .where(MealPlan.user_id == user_id, MealPlanItem.updated_at > cutoff)
        ).all()
    )
    views: list[PlanViewData] = []
    for _day, plan in current_plans(session, user_id, yesterday, latest):
        if plan.created_at > cutoff or plan.plan_id in changed:
            views.append(plan_view(session, user_id, plan, lang))
    return views


def changes_since(
    session: Session, user_id: int, since: datetime, now: datetime, lang: str
) -> SyncFeed:
    """Rows the phone should merge. `since` is the previous response's server_time."""
    require_aware(since, "since")
    require_aware(now, "now")
    if since > now + CLOCK_SKEW_TOLERANCE:
        raise ClockSkewError(
            f"since {since.isoformat()} is more than {CLOCK_SKEW_TOLERANCE} after "
            f"the server time {now.isoformat()}"
        )
    earliest = now - timedelta(days=SYNC_MAX_AGE_DAYS)
    if since < earliest:
        raise InputRejectedError(
            f"since {since.isoformat()} is more than {SYNC_MAX_AGE_DAYS} days before "
            f"the server time {now.isoformat()}; reload the full state"
        )
    cutoff = since - SYNC_OVERLAP
    today = local_date(session, user_id, now)
    logs = list(
        session.scalars(
            select(ConsumptionLog)
            .where(
                ConsumptionLog.user_id == user_id,
                ConsumptionLog.deleted_at.is_(None),
                ConsumptionLog.created_at > cutoff,
            )
            .order_by(ConsumptionLog.created_at, ConsumptionLog.id)
        ).all()
    )
    deleted_logs = list(
        session.scalars(
            select(ConsumptionLog.id)
            .where(
                ConsumptionLog.user_id == user_id,
                ConsumptionLog.deleted_at.is_not(None),
                ConsumptionLog.deleted_at > cutoff,
            )
            .order_by(ConsumptionLog.id)
        ).all()
    )
    water = list(
        session.scalars(
            select(WaterLog)
            .where(
                WaterLog.user_id == user_id,
                WaterLog.deleted_at.is_(None),
                WaterLog.created_at > cutoff,
            )
            .order_by(WaterLog.created_at, WaterLog.id)
        ).all()
    )
    deleted_water = list(
        session.scalars(
            select(WaterLog.id)
            .where(
                WaterLog.user_id == user_id,
                WaterLog.deleted_at.is_not(None),
                WaterLog.deleted_at > cutoff,
            )
            .order_by(WaterLog.id)
        ).all()
    )
    return SyncFeed(
        consumption_logs=consumption_views(session, logs, lang),
        deleted_consumption_log_ids=deleted_logs,
        water_logs=water,
        deleted_water_log_ids=deleted_water,
        weights=weights_between(
            session, user_id, today - timedelta(days=WEIGHT_HISTORY_DAYS), today
        ),
        plans=_plans_since(session, user_id, today - timedelta(days=1), cutoff, lang),
        meal_prefs=list_meal_prefs(session, user_id),
        profile_changed=_profile_changed(session, user_id, cutoff),
    )
