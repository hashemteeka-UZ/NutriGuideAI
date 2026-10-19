"""Offline batch and the change feed (I.7, #138)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import AwareDatetime

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.sync import SyncBatch, SyncChanges, SyncResult

router = APIRouter(prefix="/sync", tags=["sync"], dependencies=[Depends(bearer)])


@router.post(
    "/batch",
    response_model=SyncResult,
    responses=PROBLEM_RESPONSES,
    description=(
        "Apply 1 to 500 operations. Each op_id is chosen by the client. "
        "A rejected operation sets status REJECTED and code.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR", "RATE_LIMITED")
    ),
)
def sync_batch(body: SyncBatch) -> SyncResult:
    raise not_implemented()


@router.get(
    "/changes",
    response_model=SyncChanges,
    responses=PROBLEM_RESPONSES,
    description=(
        "Rows changed after `since`, plus ids deleted since then.\n"
        + error_codes("UNAUTHORIZED", "VALIDATION_ERROR")
    ),
)
def get_sync_changes(since: Annotated[AwareDatetime, Query()]) -> SyncChanges:
    raise not_implemented()
