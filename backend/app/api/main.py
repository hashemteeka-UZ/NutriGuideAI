"""FastAPI application factory. Business routes arrive in later Step I passes."""

from typing import Any, Final

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.errors import register_exception_handlers
from app.api.observability import RequestIdMiddleware, configure_logging
from app.api.routers import health
from app.core.config import get_settings

API_PREFIX: Final = "/api/v1"
API_VERSION: Final = "0.1.0"

_CORS_METHODS: Final = ["GET", "POST", "PUT", "PATCH", "DELETE"]
_CORS_HEADERS: Final = ["Authorization", "Content-Type", "Accept-Language", "X-Request-ID"]


def create_app() -> FastAPI:
    configure_logging()
    application = FastAPI(
        title="NutriGuideAI API",
        version=API_VERSION,
        openapi_url="/api/openapi.json",
        docs_url="/api/docs",
        redoc_url=None,
    )
    application.add_middleware(RequestIdMiddleware)
    settings = get_settings()
    if settings.CORS_ORIGINS:
        application.add_middleware(
            CORSMiddleware,
            allow_origins=settings.CORS_ORIGINS,
            allow_methods=_CORS_METHODS,
            allow_headers=_CORS_HEADERS,
            expose_headers=["X-Request-ID"],
        )
    register_exception_handlers(application)
    application.include_router(health.router, prefix=API_PREFIX)
    _prefer_problem_json(application)
    return application


def _prefer_problem_json(application: FastAPI) -> None:
    """FastAPI also emits application/json for a response model; problems are problem+json."""
    generate = application.openapi

    def openapi() -> dict[str, Any]:
        schema = generate()
        paths = schema.get("paths")
        if isinstance(paths, dict):
            for path_item in paths.values():
                _drop_json_alongside_problem(path_item)
        return schema

    application.openapi = openapi  # type: ignore[method-assign]


def _drop_json_alongside_problem(path_item: object) -> None:
    if not isinstance(path_item, dict):
        return
    for operation in path_item.values():
        if not isinstance(operation, dict):
            continue
        responses = operation.get("responses")
        if not isinstance(responses, dict):
            continue
        for key in ("422", "default"):
            response = responses.get(key)
            if not isinstance(response, dict):
                continue
            content = response.get("content")
            if isinstance(content, dict) and "application/problem+json" in content:
                content.pop("application/json", None)


app = create_app()
