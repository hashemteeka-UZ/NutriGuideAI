"""RFC 9457 problem details shared by every error response."""

from pydantic import BaseModel


class ValidationIssue(BaseModel):
    loc: list[str | int]
    msg: str
    type: str


class ProblemDetail(BaseModel):
    type: str = "about:blank"
    title: str
    status: int
    detail: str | None = None
    code: str
    request_id: str | None = None
    errors: list[ValidationIssue] | None = None
    reasons: list[str] | None = None
