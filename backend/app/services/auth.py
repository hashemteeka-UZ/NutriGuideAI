"""Passwords, access tokens, and refresh-token rotation. No FastAPI imports.

Do not log passwords, tokens, or token hashes (#133).
"""

from __future__ import annotations

import hashlib
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta
from uuid import UUID, uuid4

import jwt
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.models import RefreshToken, User

# Recommended Argon2id defaults. One hasher for the process.
_HASHER = PasswordHash((Argon2Hasher(),))
# Unknown emails still pay for one verification so the response time does not
# reveal whether the account exists (OWASP).
_DUMMY_HASH = _HASHER.hash("not-a-real-password")

_EMAIL_UNIQUE = "uq_users_email"


class AuthError(Exception):
    pass


class EmailTakenError(AuthError):
    pass


class InvalidCredentialsError(AuthError):
    pass


class TokenInvalidError(AuthError):
    pass


class TokenReusedError(AuthError):
    pass


@dataclass(frozen=True)
class IssuedTokens:
    access_token: str
    refresh_token: str
    expires_in: int


def hash_password(password: str) -> str:
    return _HASHER.hash(password)


def verify_password(password: str, hashed: str) -> tuple[bool, str | None]:
    """Return whether the password matches, and a new hash when the stored one is stale."""
    return _HASHER.verify_and_update(password, hashed)


def normalize_email(email: str) -> str:
    """`users.email_lowercase` already rejects any value that is not lower case."""
    return email.strip().lower()


def register_user(session: Session, email: str, password: str, now: datetime) -> IssuedTokens:
    user = User(email=normalize_email(email), hashed_password=hash_password(password))
    session.add(user)
    try:
        with session.begin_nested():
            session.flush()
    except IntegrityError as exc:
        if not _is_email_unique(exc):
            raise
        raise EmailTakenError("Email already registered") from None
    return issue_tokens(session, user.user_id, now)


def authenticate(session: Session, email: str, password: str, now: datetime) -> IssuedTokens:
    user = session.execute(
        select(User).where(User.email == normalize_email(email))
    ).scalar_one_or_none()
    if user is None:
        verify_password(password, _DUMMY_HASH)
        raise InvalidCredentialsError("Invalid email or password")
    matches, updated = verify_password(password, user.hashed_password)
    if not matches:
        raise InvalidCredentialsError("Invalid email or password")
    if updated is not None:
        user.hashed_password = updated
    return issue_tokens(session, user.user_id, now)


def issue_tokens(
    session: Session, user_id: int, now: datetime, family_id: UUID | None = None
) -> IssuedTokens:
    settings = get_settings()
    raw_refresh = secrets.token_urlsafe(32)
    session.add(
        RefreshToken(
            user_id=user_id,
            token_hash=_token_hash(raw_refresh),
            family_id=family_id if family_id is not None else uuid4(),
            issued_at=now,
            expires_at=now + timedelta(days=settings.REFRESH_TOKEN_DAYS),
        )
    )
    session.flush()
    return IssuedTokens(
        access_token=_encode_access(user_id, now),
        refresh_token=raw_refresh,
        expires_in=settings.ACCESS_TOKEN_MINUTES * 60,
    )


def rotate_refresh(session: Session, raw_token: str, now: datetime) -> IssuedTokens:
    row = _lock_token(session, raw_token)
    if row is None or row.expires_at <= now:
        raise TokenInvalidError("Invalid token")
    if row.revoked_at is not None:
        # Reuse of a revoked token (#45): the rest of the family is no longer trusted.
        _revoke_family(session, row.family_id, now)
        session.flush()
        raise TokenReusedError("Refresh token reuse")
    row.revoked_at = now
    issued = issue_tokens(session, row.user_id, now, family_id=row.family_id)
    new_hash = _token_hash(issued.refresh_token)
    row.replaced_by_token_id = session.execute(
        select(RefreshToken.token_id).where(RefreshToken.token_hash == new_hash)
    ).scalar_one()
    session.flush()
    return issued


def logout(session: Session, raw_token: str, now: datetime) -> None:
    """Revoke the family when the token is known. An unknown token is a no-op."""
    row = session.execute(
        select(RefreshToken).where(RefreshToken.token_hash == _token_hash(raw_token))
    ).scalar_one_or_none()
    if row is None:
        return
    _revoke_family(session, row.family_id, now)


def decode_access(token: str, now: datetime) -> int:
    """User id from an access token. `exp` is compared to `now`, not the wall clock."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET.get_secret_value(),
            algorithms=["HS256"],
            options={"verify_exp": False, "require": ["exp", "sub", "typ"]},
        )
    except jwt.PyJWTError:
        raise TokenInvalidError("Invalid token") from None
    if not isinstance(payload, dict) or payload.get("typ") != "access":
        raise TokenInvalidError("Invalid token")
    sub = payload.get("sub")
    exp = payload.get("exp")
    if not isinstance(sub, str) or not sub.isdigit():
        raise TokenInvalidError("Invalid token")
    if isinstance(exp, bool) or not isinstance(exp, int):
        raise TokenInvalidError("Invalid token")
    if now.timestamp() >= exp:
        raise TokenInvalidError("Invalid token")
    return int(sub)


def _encode_access(user_id: int, now: datetime) -> str:
    settings = get_settings()
    exp = now + timedelta(minutes=settings.ACCESS_TOKEN_MINUTES)
    claims = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
        "typ": "access",
    }
    token = jwt.encode(claims, settings.JWT_SECRET.get_secret_value(), algorithm="HS256")
    if not isinstance(token, str):
        raise TokenInvalidError("Invalid token")
    return token


def _token_hash(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode()).hexdigest()


def _lock_token(session: Session, raw_token: str) -> RefreshToken | None:
    statement = select(RefreshToken).where(RefreshToken.token_hash == _token_hash(raw_token))
    return session.execute(statement.with_for_update()).scalar_one_or_none()


def _revoke_family(session: Session, family_id: UUID, now: datetime) -> None:
    session.execute(
        update(RefreshToken)
        .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )


def _is_email_unique(exc: IntegrityError) -> bool:
    orig = exc.orig
    constraint = getattr(getattr(orig, "diag", None), "constraint_name", None)
    return constraint == _EMAIL_UNIQUE
