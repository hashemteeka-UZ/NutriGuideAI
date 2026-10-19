"""Password hashing and refresh-token rotation, without HTTP."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import RefreshToken, User
from app.services.auth import (
    EmailTakenError,
    InvalidCredentialsError,
    TokenInvalidError,
    TokenReusedError,
    authenticate,
    decode_access,
    hash_password,
    logout,
    register_user,
    rotate_refresh,
    verify_password,
)

NOW = datetime(2026, 10, 12, 9, 0, tzinfo=UTC)
PASSWORD = "password1"


def test_hash_round_trip() -> None:
    hashed = hash_password(PASSWORD)
    assert hashed != PASSWORD
    matches, updated = verify_password(PASSWORD, hashed)
    assert matches is True
    assert updated is None
    matches, _updated = verify_password("wrong-password", hashed)
    assert matches is False


def test_login_rehashes_a_stale_password(session: Session) -> None:
    stale = PasswordHash((Argon2Hasher(time_cost=1, memory_cost=8192, parallelism=1),))
    user = User(email="rehash@example.com", hashed_password=stale.hash(PASSWORD))
    session.add(user)
    session.flush()
    before = user.hashed_password
    authenticate(session, "rehash@example.com", PASSWORD, NOW)
    assert user.hashed_password != before
    matches, updated = verify_password(PASSWORD, user.hashed_password)
    assert matches is True
    assert updated is None


def test_register_stores_a_lower_case_email_and_rejects_a_duplicate(session: Session) -> None:
    issued = register_user(session, "  User@Example.com  ", PASSWORD, NOW)
    stored = session.execute(select(User).where(User.email == "user@example.com")).scalar_one()
    assert stored.hashed_password != PASSWORD
    assert issued.expires_in == 900
    with pytest.raises(EmailTakenError):
        register_user(session, "user@example.com", PASSWORD, NOW)


def test_unknown_email_and_wrong_password_are_the_same_error(session: Session) -> None:
    register_user(session, "known@example.com", PASSWORD, NOW)
    with pytest.raises(InvalidCredentialsError) as unknown:
        authenticate(session, "missing@example.com", PASSWORD, NOW)
    with pytest.raises(InvalidCredentialsError) as wrong:
        authenticate(session, "known@example.com", "password2", NOW)
    assert str(unknown.value) == str(wrong.value)
    missing = session.execute(
        select(User).where(User.email == "missing@example.com")
    ).scalar_one_or_none()
    assert missing is None


def test_decode_uses_the_injected_clock(session: Session) -> None:
    issued = register_user(session, "clock@example.com", PASSWORD, NOW)
    user_id = session.execute(
        select(User.user_id).where(User.email == "clock@example.com")
    ).scalar_one()
    still_valid = NOW + timedelta(minutes=15) - timedelta(seconds=1)
    assert decode_access(issued.access_token, still_valid) == user_id
    with pytest.raises(TokenInvalidError):
        decode_access(issued.access_token, NOW + timedelta(minutes=16))


def test_refresh_reuse_revokes_the_family(session: Session) -> None:
    issued = register_user(session, "rotate@example.com", PASSWORD, NOW)
    rotated = rotate_refresh(session, issued.refresh_token, NOW)
    with pytest.raises(TokenReusedError):
        rotate_refresh(session, issued.refresh_token, NOW)
    with pytest.raises(TokenReusedError):
        rotate_refresh(session, rotated.refresh_token, NOW)
    rows = session.scalars(select(RefreshToken)).all()
    assert rows
    assert all(row.revoked_at is not None for row in rows)


def test_expired_and_unknown_refresh_tokens_are_invalid(session: Session) -> None:
    issued = register_user(session, "expire@example.com", PASSWORD, NOW)
    with pytest.raises(TokenInvalidError):
        rotate_refresh(session, issued.refresh_token, NOW + timedelta(days=30))
    with pytest.raises(TokenInvalidError):
        rotate_refresh(session, "not-a-token", NOW)


def test_logout_revokes_a_known_family_and_ignores_an_unknown_token(session: Session) -> None:
    issued = register_user(session, "logout@example.com", PASSWORD, NOW)
    logout(session, "not-a-token", NOW)
    logout(session, issued.refresh_token, NOW)
    row = session.execute(select(RefreshToken)).scalar_one()
    assert row.revoked_at == NOW
    with pytest.raises(TokenReusedError):
        rotate_refresh(session, issued.refresh_token, NOW)
