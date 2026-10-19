"""Public reference lists and ingredient search hits (I.3)."""

from pydantic import BaseModel, ConfigDict, Field

from app.api.schemas.common import Page, with_example
from app.db.models.user import ActivityLevel, GoalType, MealSlot, Sex

_CONDITIONS = [
    {
        "code": "DIABETES_T2",
        "name": "السكري من النوع الثاني (بدون إنسولين)",
        "is_supported": True,
        "fluid_goal_requires_clinician": False,
    },
    {
        "code": "HYPERTENSION",
        "name": "ارتفاع ضغط الدم",
        "is_supported": True,
        "fluid_goal_requires_clinician": False,
    },
    {
        "code": "HEART_DISEASE",
        "name": "أمراض القلب",
        "is_supported": True,
        "fluid_goal_requires_clinician": True,
    },
    {
        "code": "DIABETES_INSULIN",
        "name": "السكري المعالج بالإنسولين",
        "is_supported": False,
        "fluid_goal_requires_clinician": False,
    },
]

_ALLERGENS = [
    {"code": "GLUTEN", "name": "الغلوتين"},
    {"code": "MILK", "name": "الحليب"},
    {"code": "EGG", "name": "البيض"},
    {"code": "FISH", "name": "السمك"},
    {"code": "SHELLFISH", "name": "المحار والقشريات"},
    {"code": "PEANUT", "name": "الفول السوداني"},
    {"code": "TREE_NUTS", "name": "المكسرات الشجرية"},
    {"code": "SESAME", "name": "السمسم"},
    {"code": "SOY", "name": "الصويا"},
]

_CUISINES = [
    {"code": "LIBYAN", "name": "ليبي"},
    {"code": "LEVANTINE", "name": "شامي"},
    {"code": "GENERAL", "name": "عام"},
    {"code": "EGYPTIAN", "name": "مصري"},
    {"code": "MAGHREBI", "name": "مغاربي"},
]

INGREDIENT_HIT_EXAMPLE = {
    "ingredient_id": 18,
    "code": "FOUL_MEDAMES",
    "name": "فول مدمس",
    "food_id": 18,
}


class ConditionRef(BaseModel):
    code: str
    name: str
    is_supported: bool
    fluid_goal_requires_clinician: bool

    model_config = with_example(_CONDITIONS[1])


class CodeName(BaseModel):
    code: str
    name: str

    model_config = with_example(_ALLERGENS[0])


class Reference(BaseModel):
    health_conditions: list[ConditionRef]
    allergens: list[CodeName]
    cuisines: list[CodeName]
    activity_levels: list[ActivityLevel]
    goal_types: list[GoalType]
    sexes: list[Sex]
    slots: list[MealSlot]
    dataset_version: str = Field(
        description=(
            'Active catalog dataset_version shared with GET /health, or "unknown" when active '
            "meals do not share exactly one version."
        )
    )

    model_config = with_example(
        {
            "health_conditions": _CONDITIONS,
            "allergens": _ALLERGENS,
            "cuisines": _CUISINES,
            "activity_levels": [level.value for level in ActivityLevel],
            "goal_types": [goal.value for goal in GoalType],
            "sexes": [sex.value for sex in Sex],
            "slots": [slot.value for slot in MealSlot],
            "dataset_version": "catalog_v3",
        }
    )


class IngredientHit(BaseModel):
    ingredient_id: int
    code: str
    name: str
    food_id: int | None = None

    model_config = with_example(INGREDIENT_HIT_EXAMPLE)


class IngredientPage(Page[IngredientHit]):
    model_config = with_example({"items": [INGREDIENT_HIT_EXAMPLE], "total": 1})


class IngredientQuery(BaseModel):
    model_config = ConfigDict(extra="forbid")

    q: str = Field(min_length=1, max_length=60)
    limit: int = Field(default=20, ge=1, le=50)
    offset: int = Field(default=0, ge=0)
