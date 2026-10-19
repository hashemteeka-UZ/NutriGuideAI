"""Account state used to choose onboarding or Home (#174)."""

from datetime import datetime

from pydantic import BaseModel

from app.api.schemas.common import with_example

ACCOUNT_EXAMPLE = {
    "user_id": 1,
    "email": "user@example.com",
    "created_at": "2026-10-01T09:00:00Z",
    "has_profile": True,
}


class Account(BaseModel):
    user_id: int
    email: str
    created_at: datetime
    has_profile: bool

    model_config = with_example(ACCOUNT_EXAMPLE)
