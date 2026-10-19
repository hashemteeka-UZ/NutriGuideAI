"""Vocabularies the app needs before sign-in (I.3)."""

from fastapi import APIRouter, Response

from app.api.deps import DbSession, Lang
from app.api.errors import PROBLEM_RESPONSES, error_codes
from app.api.schemas.reference import CodeName, ConditionRef, Reference
from app.services.reference import reference_lists

router = APIRouter(tags=["reference"])


@router.get(
    "/reference",
    response_model=Reference,
    responses=PROBLEM_RESPONSES,
    description=(
        "Conditions, allergens, cuisines, and the closed lists for sex, activity, goal, and slot. "
        "Names follow Accept-Language (ar default, en). DIABETES_INSULIN is included with "
        "is_supported false. The response sets Cache-Control: public, max-age=3600. "
        'dataset_version is "unknown" when active meals do not share one version.\n' + error_codes()
    ),
)
def get_reference(session: DbSession, lang: Lang, response: Response) -> Reference:
    # No rate limit yet (the general limits of #132 come in the closure pass).
    response.headers["Cache-Control"] = "public, max-age=3600"
    lists = reference_lists(session, lang)
    return Reference(
        health_conditions=[
            ConditionRef(
                code=item.code,
                name=item.name,
                is_supported=item.is_supported,
                fluid_goal_requires_clinician=item.fluid_goal_requires_clinician,
            )
            for item in lists.health_conditions
        ],
        allergens=[CodeName(code=item.code, name=item.name) for item in lists.allergens],
        cuisines=[CodeName(code=item.code, name=item.name) for item in lists.cuisines],
        activity_levels=list(lists.activity_levels),
        goal_types=list(lists.goal_types),
        sexes=list(lists.sexes),
        slots=list(lists.slots),
        dataset_version=lists.dataset_version,
    )
