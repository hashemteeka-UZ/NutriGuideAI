"""Auth request and token models (I.2)."""

import re
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, WithJsonSchema

from app.api.schemas.common import with_example

# email-validator is not a project dependency, so this is a string with OpenAPI format email.
_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
EmailAddress = Annotated[
    str,
    Field(pattern=_EMAIL.pattern),
    WithJsonSchema({"type": "string", "format": "email", "pattern": _EMAIL.pattern}),
]

TOKEN_PAIR_EXAMPLE = {
    "access_token": "access-token-example",
    "refresh_token": "refresh-token-example",
    "token_type": "bearer",
    "expires_in": 900,
}


class RegisterRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailAddress
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailAddress
    password: str = Field(max_length=128)


class RefreshRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"]
    expires_in: int

    model_config = with_example(TOKEN_PAIR_EXAMPLE)
