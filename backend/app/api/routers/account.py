"""The signed-in account (I.2, #170, #174)."""

from fastapi import APIRouter, Depends

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.account import Account

router = APIRouter(tags=["account"], dependencies=[Depends(bearer)])


@router.get(
    "/me",
    response_model=Account,
    responses=PROBLEM_RESPONSES,
    description=(
        "Account identity. has_profile is false until the first successful PUT /me/profile.\n"
        + error_codes("UNAUTHORIZED")
    ),
)
def get_me() -> Account:
    raise not_implemented()


@router.delete(
    "/me",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Delete the account and every row that belongs to it.\n" + error_codes("UNAUTHORIZED")
    ),
)
def delete_me() -> None:
    raise not_implemented()
