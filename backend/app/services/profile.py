"""Profile replace: children by difference, one weight, at most one target (#136, #176-#178)."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, time
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import (
    Allergen,
    Cuisine,
    HealthCondition,
    Ingredient,
    UserAllergenPref,
    UserCuisinePref,
    UserHealthCondition,
    UserIngredientPref,
    UserProfile,
    UserTarget,
    WeightLog,
)
from app.db.models.user import GoalType, TargetReason
from app.services.common import to_decimal, zone
from app.services.screening import ProfileNotFoundError, ScreeningResult, screen_user
from app.services.targets import MissingWeightError, TargetError, create_user_target, validate_goal
from app.services.water import WaterGoalResult, water_goal
from app.services.weight import WEIGHT_RECOMPUTE_DELTA_KG, upsert_weight


class UnknownCodeError(ValueError):
    def __init__(self, kind: str, values: Sequence[str]) -> None:
        self.kind = kind
        self.values = tuple(values)
        super().__init__(f"unknown {kind}: {', '.join(self.values)}")


@dataclass(frozen=True)
class ConditionInput:
    code: str
    severity: str | None


@dataclass(frozen=True)
class AllergenInput:
    code: str
    severity: str


@dataclass(frozen=True)
class IngredientInput:
    ingredient_id: int
    stance: str


@dataclass(frozen=True)
class ProfileInput:
    sex: str
    birth_date: date
    height_cm: float
    activity_level: str
    goal_type: str
    target_weight_kg: float | None
    weekly_rate_kg: float | None
    timezone: str
    wake_time: time
    sleep_time: time
    water_goal_ml: int | None
    current_weight_kg: float | None
    conditions: tuple[ConditionInput, ...]
    allergens: tuple[AllergenInput, ...]
    ingredient_prefs: tuple[IngredientInput, ...]
    cuisines: tuple[str, ...]


@dataclass(frozen=True)
class ConditionSet:
    code: str
    severity: str | None


@dataclass(frozen=True)
class AllergenSet:
    code: str
    severity: str


@dataclass(frozen=True)
class IngredientSet:
    ingredient_id: int
    stance: str


@dataclass(frozen=True)
class ProfileOutcome:
    profile: UserProfile
    conditions: tuple[ConditionSet, ...]
    allergens: tuple[AllergenSet, ...]
    ingredient_prefs: tuple[IngredientSet, ...]
    cuisines: tuple[str, ...]
    latest_weight: tuple[date, Decimal] | None
    screening: ScreeningResult
    target: UserTarget | None


@dataclass(frozen=True)
class TargetsOutcome:
    screening: ScreeningResult
    target: UserTarget | None
    water: WaterGoalResult


@dataclass(frozen=True)
class _Previous:
    sex: str
    birth_date: date
    height_cm: float
    activity_level: str
    goal_type: str
    target_weight_kg: float | None
    weekly_rate_kg: float | None


def _optional(value: float | None) -> Decimal | None:
    return None if value is None else to_decimal(value)


def _measure_changed(old: float | None, new: float | None) -> bool:
    if old is None and new is None:
        return False
    if old is None or new is None:
        return True
    return to_decimal(old) != to_decimal(new)


def _resolve_codes(
    session: Session,
    model: type[HealthCondition] | type[Allergen] | type[Cuisine],
    kind: str,
    codes: Sequence[str],
) -> dict[str, int]:
    if not codes:
        return {}
    id_column = {
        HealthCondition: HealthCondition.condition_id,
        Allergen: Allergen.allergen_id,
        Cuisine: Cuisine.cuisine_id,
    }[model]
    found: dict[str, int] = {}
    for code, row_id in session.execute(
        select(model.code, id_column).where(model.code.in_(codes))
    ).all():
        found[str(code)] = int(row_id)
    missing = [code for code in codes if code not in found]
    if missing:
        raise UnknownCodeError(kind, missing)
    return found


def _resolve_ingredients(session: Session, prefs: Sequence[IngredientInput]) -> None:
    if not prefs:
        return
    ids = [pref.ingredient_id for pref in prefs]
    found = set(
        session.scalars(
            select(Ingredient.ingredient_id).where(Ingredient.ingredient_id.in_(ids))
        ).all()
    )
    missing = [str(ingredient_id) for ingredient_id in ids if ingredient_id not in found]
    if missing:
        raise UnknownCodeError("ingredient", missing)


def _latest_weight(session: Session, user_id: int) -> tuple[date, Decimal] | None:
    row = session.execute(
        select(WeightLog.measured_on, WeightLog.weight_kg)
        .where(WeightLog.user_id == user_id)
        .order_by(WeightLog.measured_on.desc())
        .limit(1)
    ).one_or_none()
    if row is None:
        return None
    measured_on, weight_kg = row
    return measured_on, to_decimal(weight_kg)


def _replace_conditions(
    session: Session, user_id: int, chosen: dict[int, str | None], now: datetime
) -> None:
    existing = {
        row.condition_id: row
        for row in session.scalars(
            select(UserHealthCondition).where(UserHealthCondition.user_id == user_id)
        ).all()
    }
    for condition_id, row in existing.items():
        if condition_id not in chosen:
            session.delete(row)
        elif row.severity != chosen[condition_id]:
            row.severity = chosen[condition_id]
    for condition_id, severity in chosen.items():
        if condition_id not in existing:
            session.add(
                UserHealthCondition(
                    user_id=user_id,
                    condition_id=condition_id,
                    severity=severity,
                    diagnosed=False,
                    created_at=now,
                    updated_at=now,
                )
            )


def _replace_allergens(
    session: Session, user_id: int, chosen: dict[int, str], now: datetime
) -> None:
    existing = {
        row.allergen_id: row
        for row in session.scalars(
            select(UserAllergenPref).where(UserAllergenPref.user_id == user_id)
        ).all()
    }
    for allergen_id, row in existing.items():
        if allergen_id not in chosen:
            session.delete(row)
        elif row.severity != chosen[allergen_id]:
            row.severity = chosen[allergen_id]
    for allergen_id, severity in chosen.items():
        if allergen_id not in existing:
            session.add(
                UserAllergenPref(
                    user_id=user_id,
                    allergen_id=allergen_id,
                    severity=severity,
                    created_at=now,
                    updated_at=now,
                )
            )


def _replace_ingredients(
    session: Session, user_id: int, chosen: dict[int, str], now: datetime
) -> None:
    existing = {
        row.ingredient_id: row
        for row in session.scalars(
            select(UserIngredientPref).where(UserIngredientPref.user_id == user_id)
        ).all()
    }
    for ingredient_id, row in existing.items():
        if ingredient_id not in chosen:
            session.delete(row)
        elif row.stance != chosen[ingredient_id]:
            row.stance = chosen[ingredient_id]
    for ingredient_id, stance in chosen.items():
        if ingredient_id not in existing:
            session.add(
                UserIngredientPref(
                    user_id=user_id,
                    ingredient_id=ingredient_id,
                    stance=stance,
                    created_at=now,
                    updated_at=now,
                )
            )


def _replace_cuisines(session: Session, user_id: int, chosen: set[int], now: datetime) -> None:
    existing = {
        row.cuisine_id: row
        for row in session.scalars(
            select(UserCuisinePref).where(UserCuisinePref.user_id == user_id)
        ).all()
    }
    for cuisine_id, row in existing.items():
        if cuisine_id not in chosen:
            session.delete(row)
    for cuisine_id in chosen:
        if cuisine_id not in existing:
            session.add(UserCuisinePref(user_id=user_id, cuisine_id=cuisine_id, created_at=now))


def _write_profile(
    session: Session, user_id: int, data: ProfileInput, now: datetime
) -> tuple[UserProfile, _Previous | None]:
    profile = session.get(UserProfile, user_id)
    previous = None
    if profile is None:
        profile = UserProfile(
            user_id=user_id,
            sex=data.sex,
            birth_date=data.birth_date,
            height_cm=data.height_cm,
            activity_level=data.activity_level,
            goal_type=data.goal_type,
            target_weight_kg=data.target_weight_kg,
            weekly_rate_kg=data.weekly_rate_kg,
            timezone=data.timezone,
            wake_time=data.wake_time,
            sleep_time=data.sleep_time,
            water_goal_ml=data.water_goal_ml,
            created_at=now,
            updated_at=now,
        )
        session.add(profile)
    else:
        previous = _Previous(
            sex=profile.sex,
            birth_date=profile.birth_date,
            height_cm=profile.height_cm,
            activity_level=profile.activity_level,
            goal_type=profile.goal_type,
            target_weight_kg=profile.target_weight_kg,
            weekly_rate_kg=profile.weekly_rate_kg,
        )
        profile.sex = data.sex
        profile.birth_date = data.birth_date
        profile.height_cm = data.height_cm
        profile.activity_level = data.activity_level
        profile.goal_type = data.goal_type
        profile.target_weight_kg = data.target_weight_kg
        profile.weekly_rate_kg = data.weekly_rate_kg
        profile.timezone = data.timezone
        profile.wake_time = data.wake_time
        profile.sleep_time = data.sleep_time
        profile.water_goal_ml = data.water_goal_ml
        profile.updated_at = now
    return profile, previous


def _current_target(session: Session, user_id: int, *, lock: bool) -> UserTarget | None:
    statement = select(UserTarget).where(
        UserTarget.user_id == user_id, UserTarget.valid_to.is_(None)
    )
    if lock:
        statement = statement.with_for_update()
    return session.execute(statement).scalar_one_or_none()


def _close_target(current: UserTarget, now: datetime) -> None:
    if now <= current.valid_from:
        raise TargetError(
            f"user {current.user_id}: now ({now.isoformat()}) must be after the current target's "
            f"valid_from ({current.valid_from.isoformat()})"
        )
    current.valid_to = now


def _target_reason(
    previous: _Previous, data: ProfileInput, current: UserTarget, latest_kg: Decimal
) -> TargetReason | None:
    if (
        previous.goal_type != data.goal_type
        or _measure_changed(previous.target_weight_kg, data.target_weight_kg)
        or _measure_changed(previous.weekly_rate_kg, data.weekly_rate_kg)
    ):
        return TargetReason.GOAL_CHANGE
    if (
        previous.sex != data.sex
        or previous.birth_date != data.birth_date
        or _measure_changed(previous.height_cm, data.height_cm)
        or previous.activity_level != data.activity_level
    ):
        return TargetReason.PROFILE_CHANGE
    if abs(latest_kg - to_decimal(current.based_on_weight_kg)) >= WEIGHT_RECOMPUTE_DELTA_KG:
        return TargetReason.WEIGHT_UPDATE
    return None


def _apply_target(
    session: Session,
    user_id: int,
    previous: _Previous | None,
    data: ProfileInput,
    latest_kg: Decimal,
    screening: ScreeningResult,
    now: datetime,
) -> UserTarget | None:
    current = _current_target(session, user_id, lock=True)
    if not screening.eligible:
        if current is not None:
            _close_target(current, now)
            session.flush()
        return None
    if current is None:
        had_any = session.scalar(
            select(func.count()).select_from(UserTarget).where(UserTarget.user_id == user_id)
        )
        reason = TargetReason.INITIAL if not had_any else TargetReason.PROFILE_CHANGE
        return create_user_target(session, user_id, reason, now)
    if previous is None:
        return create_user_target(session, user_id, TargetReason.INITIAL, now)
    change = _target_reason(previous, data, current, latest_kg)
    if change is None:
        return current
    return create_user_target(session, user_id, change, now)


def _outcome(
    session: Session,
    profile: UserProfile,
    screening: ScreeningResult,
    target: UserTarget | None,
) -> ProfileOutcome:
    user_id = profile.user_id
    conditions = tuple(
        ConditionSet(code=code, severity=severity)
        for code, severity in session.execute(
            select(HealthCondition.code, UserHealthCondition.severity)
            .join(
                UserHealthCondition,
                UserHealthCondition.condition_id == HealthCondition.condition_id,
            )
            .where(UserHealthCondition.user_id == user_id)
            .order_by(HealthCondition.code)
        ).all()
    )
    allergens = tuple(
        AllergenSet(code=code, severity=severity)
        for code, severity in session.execute(
            select(Allergen.code, UserAllergenPref.severity)
            .join(UserAllergenPref, UserAllergenPref.allergen_id == Allergen.allergen_id)
            .where(UserAllergenPref.user_id == user_id)
            .order_by(Allergen.code)
        ).all()
    )
    ingredient_prefs = tuple(
        IngredientSet(ingredient_id=ingredient_id, stance=stance)
        for ingredient_id, stance in session.execute(
            select(UserIngredientPref.ingredient_id, UserIngredientPref.stance)
            .where(UserIngredientPref.user_id == user_id)
            .order_by(UserIngredientPref.ingredient_id)
        ).all()
    )
    cuisines = tuple(
        session.scalars(
            select(Cuisine.code)
            .join(UserCuisinePref, UserCuisinePref.cuisine_id == Cuisine.cuisine_id)
            .where(UserCuisinePref.user_id == user_id)
            .order_by(Cuisine.code)
        ).all()
    )
    return ProfileOutcome(
        profile=profile,
        conditions=conditions,
        allergens=allergens,
        ingredient_prefs=ingredient_prefs,
        cuisines=cuisines,
        latest_weight=_latest_weight(session, user_id),
        screening=screening,
        target=target,
    )


def save_profile(
    session: Session, user_id: int, data: ProfileInput, now: datetime
) -> ProfileOutcome:
    """Replace the profile in the caller's transaction. At most one new target."""
    today = now.astimezone(zone(data.timezone)).date()
    condition_ids = _resolve_codes(
        session, HealthCondition, "condition", [item.code for item in data.conditions]
    )
    allergen_ids = _resolve_codes(
        session, Allergen, "allergen", [item.code for item in data.allergens]
    )
    cuisine_ids = _resolve_codes(session, Cuisine, "cuisine", list(data.cuisines))
    _resolve_ingredients(session, data.ingredient_prefs)

    existing = session.get(UserProfile, user_id)
    if existing is None and data.current_weight_kg is None:
        raise MissingWeightError(
            f"user {user_id} has no profile yet and current_weight_kg was not sent"
        )

    profile, previous = _write_profile(session, user_id, data, now)
    session.flush()
    _replace_conditions(
        session,
        user_id,
        {condition_ids[item.code]: item.severity for item in data.conditions},
        now,
    )
    _replace_allergens(
        session,
        user_id,
        {allergen_ids[item.code]: item.severity for item in data.allergens},
        now,
    )
    _replace_ingredients(
        session,
        user_id,
        {item.ingredient_id: item.stance for item in data.ingredient_prefs},
        now,
    )
    _replace_cuisines(session, user_id, set(cuisine_ids.values()), now)
    session.flush()

    if data.current_weight_kg is not None:
        upsert_weight(session, user_id, today, data.current_weight_kg, now, now)
    latest = _latest_weight(session, user_id)
    if latest is None:
        raise MissingWeightError(f"user {user_id} has no weight_logs row")
    validate_goal(
        GoalType(data.goal_type),
        _optional(data.target_weight_kg),
        _optional(data.weekly_rate_kg),
        latest[1],
    )
    screening = screen_user(session, user_id, today)
    target = _apply_target(session, user_id, previous, data, latest[1], screening, now)
    return _outcome(session, profile, screening, target)


def load_profile(session: Session, user_id: int, now: datetime) -> ProfileOutcome:
    profile = session.get(UserProfile, user_id)
    if profile is None:
        raise ProfileNotFoundError(f"user {user_id} has no user_profiles row")
    today = now.astimezone(zone(profile.timezone)).date()
    screening = screen_user(session, user_id, today)
    return _outcome(session, profile, screening, _current_target(session, user_id, lock=False))


def load_targets(session: Session, user_id: int, now: datetime) -> TargetsOutcome:
    outcome = load_profile(session, user_id, now)
    return TargetsOutcome(
        screening=outcome.screening,
        target=outcome.target,
        water=water_goal(
            session,
            user_id,
            outcome.screening,
            outcome.profile.sex,
            outcome.profile.water_goal_ml,
        ),
    )
