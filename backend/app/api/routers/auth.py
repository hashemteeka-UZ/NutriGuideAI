"""Account credentials. Public until a token exists."""

from fastapi import APIRouter, Request

from app.api.deps import DbSession, Now
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import AUTH_RATE_LIMIT, limiter
from app.api.schemas.auth import LoginRequest, RefreshRequest, RegisterRequest, TokenPair
from app.services.auth import (
    IssuedTokens,
    TokenReusedError,
    authenticate,
    register_user,
    rotate_refresh,
)
from app.services.auth import logout as revoke_refresh_family

router = APIRouter(prefix="/auth", tags=["auth"])


def _pair(issued: IssuedTokens) -> TokenPair:
    return TokenPair(
        access_token=issued.access_token,
        refresh_token=issued.refresh_token,
        token_type="bearer",
        expires_in=issued.expires_in,
    )


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
@limiter.limit(AUTH_RATE_LIMIT)
def register(request: Request, body: RegisterRequest, session: DbSession, now: Now) -> TokenPair:
    del request
    issued = register_user(session, body.email, body.password, now)
    session.commit()
    return _pair(issued)


@router.post(
    "/login",
    response_model=TokenPair,
    responses=PROBLEM_RESPONSES,
    description=(
        "Exchange an email and password for a new token pair.\n"
        + error_codes("INVALID_CREDENTIALS", "RATE_LIMITED")
    ),
)
@limiter.limit(AUTH_RATE_LIMIT)
def login(request: Request, body: LoginRequest, session: DbSession, now: Now) -> TokenPair:
    del request
    issued = authenticate(session, body.email, body.password, now)
    session.commit()
    return _pair(issued)


@router.post(
    "/refresh",
    response_model=TokenPair,
    responses=PROBLEM_RESPONSES,
    description=(
        "Rotate a refresh token. TOKEN_REUSED means the token was already used; the app logs out.\n"
        + error_codes("TOKEN_INVALID", "TOKEN_REUSED", "RATE_LIMITED")
    ),
)
@limiter.limit(AUTH_RATE_LIMIT)
def refresh_session(
    request: Request, body: RefreshRequest, session: DbSession, now: Now
) -> TokenPair:
    del request
    try:
        issued = rotate_refresh(session, body.refresh_token, now)
    except TokenReusedError:
        # Reuse revokes the rest of the family and flushes. get_db rolls the
        # session back when this exception leaves the request, which would undo
        # that revocation, so commit it before re-raising.
        session.commit()
        raise
    session.commit()
    return _pair(issued)


@router.post(
    "/logout",
    status_code=204,
    response_model=None,
    responses=PROBLEM_RESPONSES,
    description=(
        "Revoke the refresh token. No content on success.\n" + error_codes("VALIDATION_ERROR")
    ),
)
@limiter.limit(AUTH_RATE_LIMIT)
def logout(request: Request, body: RefreshRequest, session: DbSession, now: Now) -> None:
    del request
    revoke_refresh_family(session, body.refresh_token, now)
    session.commit()
