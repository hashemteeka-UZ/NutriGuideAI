"""Learning events the app may send. ACCEPT, SWAP_OUT, and PREF_* are server-written."""

from typing import Literal, Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.api.schemas.common import with_example

ClientEventType = Literal["IMPRESSION", "VIEW", "SAVE", "RATE", "COOK", "SKIP"]

INTERACTION_EXAMPLE = {"interaction_id": 9, "status": "CREATED"}


class InteractionCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    client_uuid: UUID
    meal_id: int
    event_type: ClientEventType
    value: int | None = Field(default=None, ge=1, le=5)
    plan_item_id: int | None = None
    screen: str | None = Field(default=None, max_length=40)

    @model_validator(mode="after")
    def rate_needs_value(self) -> Self:
        if self.event_type == "RATE" and self.value is None:
            raise ValueError("value is required when event_type is RATE")
        return self


class InteractionOut(BaseModel):
    interaction_id: int
    status: Literal["CREATED", "DUPLICATE"]

    model_config = with_example(INTERACTION_EXAMPLE)
