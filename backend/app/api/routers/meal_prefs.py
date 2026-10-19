"""Meal like and dislike. The server writes PREF_LIKE, PREF_DISLIKE, or PREF_CLEAR (#169)."""

from fastapi import APIRouter, Depends

from app.api.deps import CurrentUser, DbSession, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.meal_prefs import MealPref, MealPrefUpdate
from app.db.models.user import MealStance
from app.services.meal_prefs import clear_meal_pref
from app.services.meal_prefs import list_meal_prefs as stored_meal_prefs
from app.services.meal_prefs import set_meal_pref as store_meal_pref

router = APIRouter(
    prefix="/me/meal-prefs", tags=["meal-prefs"], dependencies=[Depends(get_current_user)]
)


@router.get(
    "",
    response_model=list[MealPref],
    responses=PROBLEM_RESPONSES,
    description=(
        "Stances the user has set. Meals with no row are omitted.\n" + error_codes("UNAUTHORIZED")
    ),
)
def list_meal_prefs(user_id: CurrentUser, session: DbSession) -> list[MealPref]:
    rows = stored_meal_prefs(session, user_id)
    return [
        MealPref(
            meal_id=row.meal_id,
            stance=MealStance(row.stance),
            updated_at=row.updated_at,
        )
        for row in rows
    ]


@router.put(
    "/{meal_id}",
    response_model=MealPref,
    responses=PROBLEM_RESPONSES,
    description=(
        "Set LIKE or DISLIKE. Also writes PREF_LIKE or PREF_DISLIKE.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def set_meal_pref(
    meal_id: int, body: MealPrefUpdate, user_id: CurrentUser, session: DbSession, now: Now
) -> MealPref:
    row = store_meal_pref(session, user_id, meal_id, body.stance, now)
    saved = MealPref(meal_id=row.meal_id, stance=MealStance(row.stance), updated_at=row.updated_at)
    session.commit()
    return saved


@router.delete(
    "/{meal_id}",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Clear the stance. Also writes PREF_CLEAR.\n"
        + error_codes("UNAUTHORIZED", "MEAL_NOT_FOUND")
    ),
)
def delete_meal_pref(meal_id: int, user_id: CurrentUser, session: DbSession, now: Now) -> None:
    clear_meal_pref(session, user_id, meal_id, now)
    session.commit()
