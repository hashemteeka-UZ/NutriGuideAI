"""Account credentials. Public until a token exists (I.2)."""

from fastapi import APIRouter

from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.auth import LoginRequest, RefreshRequest, RegisterRequest, TokenPair

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register",
    status_code=201,
    response_model=TokenPair,
    responses=PROBLEM_RESPONSES,
    description=(
        "Create an account and return an access token and a refresh token.\n"
        + error_codes("EMAIL_TAKEN", "VALIDATION_ERROR", "RATE_LIMITED")
    ),
)
def register(body: RegisterRequest) -> TokenPair:
    raise not_implemented()


@router.post(
    "/login",
    response_model=TokenPair,
    responses=PROBLEM_RESPONSES,
    description=(
        "Exchange an email and password for a new token pair.\n"
        + error_codes("INVALID_CREDENTIALS", "RATE_LIMITED")
    ),
)
def login(body: LoginRequest) -> TokenPair:
    raise not_implemented()


@router.post(
    "/refresh",
    response_model=TokenPair,
    responses=PROBLEM_RESPONSES,
    description=(
        "Rotate a refresh token. TOKEN_REUSED means the token was already used; the app logs out.\n"
        + error_codes("TOKEN_INVALID", "TOKEN_REUSED", "RATE_LIMITED")
    ),
)
def refresh_session(body: RefreshRequest) -> TokenPair:
    raise not_implemented()


@router.post(
    "/logout",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Revoke the refresh token. No content on success.\n" + error_codes("VALIDATION_ERROR")
    ),
)
def logout(body: RefreshRequest) -> None:
    raise not_implemented()
