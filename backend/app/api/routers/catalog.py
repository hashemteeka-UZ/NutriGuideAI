"""Offline catalog snapshot (I.4)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response

from app.api.deps import DbSession, Lang, get_current_user
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.meals import CatalogSnapshot
from app.services.meal_catalog import catalog_snapshot

router = APIRouter(tags=["catalog"], dependencies=[Depends(get_current_user)])

_ETAG = {
    "description": "Opaque tag of this snapshot. Send it back as If-None-Match.",
    "schema": {"type": "string"},
}


def _etag_matches(header: str | None, etag: str) -> bool:
    """True for the same strong tag, a list that contains it, or *."""
    if header is None:
        return False
    for part in header.split(","):
        candidate = part.strip()
        if candidate == "*" or candidate == etag:
            return True
    return False


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
        "Every active meal, without a personal stance, ordered by meal_id. "
        "dataset_version is the catalog version. "
        "ETag is a strong tag: the SHA-256 of the canonical JSON of the snapshot without "
        "generated_at (sorted keys, no spaces), plus the language. "
        "If-None-Match equal to that tag, a comma-separated list containing it, or * "
        "returns 304 with an empty body and the ETag. "
        "Otherwise 200 with ETag and Cache-Control: private, no-cache. "
        "Vary is Accept-Language, Authorization, and Accept-Encoding when the body "
        "is large enough to gzip. "
        "A response of at least 1024 bytes is gzip-encoded when the client accepts gzip.\n"
        + error_codes("UNAUTHORIZED")
    ),
)
def get_catalog_snapshot(
    session: DbSession,
    lang: Lang,
    response: Response,
    if_none_match: Annotated[str | None, Header(alias="If-None-Match")] = None,
) -> CatalogSnapshot | Response:
    payload, etag = catalog_snapshot(session, lang)
    if _etag_matches(if_none_match, etag):
        return Response(status_code=304, headers={"ETag": etag})
    response.headers["ETag"] = etag
    response.headers["Vary"] = "Accept-Language, Authorization"
    response.headers["Cache-Control"] = "private, no-cache"
    return CatalogSnapshot.model_validate(payload)
