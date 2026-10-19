"""The signed-in account (I.2, #170, #174)."""

from fastapi import APIRouter, Depends

from app.api.deps import CurrentUser, DbSession, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.account import Account
from app.services.account import account_info, delete_account

router = APIRouter(tags=["account"], dependencies=[Depends(get_current_user)])


@router.get(
    "/me",
    response_model=Account,
    responses=PROBLEM_RESPONSES,
    description=(
        "Account identity. has_profile is false until the first successful PUT /me/profile.\n"
        + error_codes("UNAUTHORIZED")
    ),
)
def get_me(user_id: CurrentUser, session: DbSession) -> Account:
    user, has_profile = account_info(session, user_id)
    return Account(
        user_id=user.user_id,
        email=user.email,
        created_at=user.created_at,
        has_profile=has_profile,
    )


@router.delete(
    "/me",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Delete the account and every row that belongs to it.\n" + error_codes("UNAUTHORIZED")
    ),
)
def delete_me(user_id: CurrentUser, session: DbSession) -> None:
    delete_account(session, user_id)
    session.commit()
