"""The signed-in account. Deleting the user row cascades to every user-owned table (§11)."""

from __future__ import annotations

from sqlalchemy.orm import Session

from app.db.models import User, UserProfile


def account_info(session: Session, user_id: int) -> tuple[User, bool]:
    user = session.get(User, user_id)
    if user is None:
        raise LookupError(user_id)
    has_profile = session.get(UserProfile, user_id) is not None
    return user, has_profile


def delete_account(session: Session, user_id: int) -> None:
    user = session.get(User, user_id)
    if user is None:
        return
    session.delete(user)
    session.flush()
