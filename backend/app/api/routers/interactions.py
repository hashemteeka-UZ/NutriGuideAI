"""Client learning events. ACCEPT, SWAP_OUT, and PREF_* are written only by the server (#169)."""

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.interactions import InteractionCreate, InteractionOut

router = APIRouter(tags=["interactions"], dependencies=[Depends(get_current_user)])


@router.post(
    "/interactions",
    status_code=201,
    response_model=InteractionOut,
    responses={
        **PROBLEM_RESPONSES,
        200: {
            "model": InteractionOut,
            "description": "Same client_uuid and the same content were already stored.",
        },
    },
    description=(
        "Record IMPRESSION, VIEW, SAVE, RATE, COOK, or SKIP. "
        "When plan_item_id is set, the server copies plan_id, slot, and algorithm_version "
        "into context. 201 when created, 200 on a duplicate client_uuid.\n"
        + error_codes(
            "UNAUTHORIZED",
            "MEAL_NOT_FOUND",
            "PLAN_ITEM_NOT_FOUND",
            "CLIENT_UUID_CONFLICT",
            "VALIDATION_ERROR",
        )
    ),
)
def create_interaction(body: InteractionCreate) -> InteractionOut:
    raise not_implemented()
