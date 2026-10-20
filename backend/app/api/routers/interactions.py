"""Client learning events. ACCEPT, SWAP_OUT, and PREF_* are written only by the server (#169)."""

from fastapi import APIRouter, Depends, Request, Response

from app.api.deps import CurrentUser, DbSession, Now, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.limiting import DEFAULT_RATE_LIMIT, limiter, plan_generation_key
from app.api.schemas.interactions import InteractionCreate, InteractionOut
from app.services.consumption import LogStatus
from app.services.interactions import record_interaction

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
@limiter.limit(DEFAULT_RATE_LIMIT, key_func=plan_generation_key)
def create_interaction(
    request: Request,
    response: Response,
    body: InteractionCreate,
    session: DbSession,
    user_id: CurrentUser,
    now: Now,
) -> InteractionOut:
    del request
    row, status = record_interaction(
        session,
        user_id,
        body.client_uuid,
        body.meal_id,
        body.event_type,
        body.value,
        body.plan_item_id,
        body.screen,
        now,
    )
    session.commit()
    if status is LogStatus.DUPLICATE:
        response.status_code = 200
    return InteractionOut(interaction_id=row.id, status=status.value)
