"""FastAPI application factory."""

from typing import Any, Final

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRoute
from slowapi.errors import RateLimitExceeded

from app.api.errors import ServiceErrorMiddleware, register_exception_handlers
from app.api.limiting import limiter, rate_limit_handler
from app.api.observability import RequestIdMiddleware, configure_logging
from app.api.routers import (
    account,
    adherence,
    auth,
    catalog,
    consumption,
    health,
    ingredients,
    interactions,
    meal_prefs,
    meals,
    plans,
    profile,
    reference,
    sync,
    water,
    weights,
)
from app.core.config import get_settings

API_PREFIX: Final = "/api/v1"
API_VERSION: Final = "0.3.0"

_CORS_METHODS: Final = ["GET", "POST", "PUT", "PATCH", "DELETE"]
_CORS_HEADERS: Final = ["Authorization", "Content-Type", "Accept-Language", "X-Request-ID"]


def _operation_id(route: APIRoute) -> str:
    """operationId is the endpoint function name, which becomes the Dart method name."""
    return route.name


def create_app() -> FastAPI:
    configure_logging()
    application = FastAPI(
        title="NutriGuideAI API",
        version=API_VERSION,
        openapi_url="/api/openapi.json",
        docs_url="/api/docs",
        redoc_url=None,
        generate_unique_id_function=_operation_id,
    )
    # Starlette inserts each middleware at the front, so the first add is the inner one.
    # Service errors stay inside the request-id middleware, and CORS stays outside both.
    application.add_middleware(ServiceErrorMiddleware)
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
    application.state.limiter = limiter
    application.add_exception_handler(RateLimitExceeded, rate_limit_handler)
    register_exception_handlers(application)
    for module in (
        health,
        auth,
        account,
        reference,
        ingredients,
        profile,
        meal_prefs,
        meals,
        catalog,
        plans,
        consumption,
        weights,
        water,
        adherence,
        interactions,
        sync,
    ):
        application.include_router(module.router, prefix=API_PREFIX)
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
