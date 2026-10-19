"""Offline catalog snapshot (I.7)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header

from app.api.deps import bearer
from app.api.errors import PROBLEM_RESPONSES, error_codes, not_implemented
from app.api.schemas.meals import CatalogSnapshot

router = APIRouter(tags=["catalog"], dependencies=[Depends(bearer)])

_ETAG = {
    "description": "Opaque tag of this snapshot. Send it back as If-None-Match.",
    "schema": {"type": "string"},
}


@router.get(
    "/catalog/snapshot",
    response_model=CatalogSnapshot,
    responses={
        **PROBLEM_RESPONSES,
        200: {"headers": {"ETag": _ETAG}},
        304: {
            "description": "The device already has this snapshot.",
            "headers": {"ETag": _ETAG},
        },
    },
    description=(
        "Every active meal without a personal stance. "
        "Return 304 when If-None-Match equals the ETag.\n" + error_codes("UNAUTHORIZED")
    ),
)
def get_catalog_snapshot(
    if_none_match: Annotated[str | None, Header(alias="If-None-Match")] = None,
) -> CatalogSnapshot:
    raise not_implemented()
