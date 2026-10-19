"""Reference lists come from the database, supported conditions first (#180)."""

from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from app.services.reference import UNKNOWN_DATASET_VERSION, reference_lists
from tests.builders import make_cuisine, make_health_condition, make_meal


def test_conditions_are_supported_first_then_by_code_and_names_follow_language(
    session: Session, integrity_conn: Connection
) -> None:
    make_health_condition(
        integrity_conn,
        code="ZZZ_SUPPORTED",
        name_ar="\u0645\u062f\u0639\u0648\u0645",
        name_en="Supported",
        is_supported=True,
    )
    make_health_condition(
        integrity_conn,
        code="AAA_UNSUPPORTED",
        name_ar="\u063a\u064a\u0631",
        name_en="Unsupported",
        is_supported=False,
    )
    make_cuisine(
        integrity_conn,
        code="LIBYAN",
        name_ar="\u0644\u064a\u0628\u064a",
        name_en="Libyan",
    )
    arabic = reference_lists(session, "ar")
    english = reference_lists(session, "en")
    codes = [item.code for item in arabic.health_conditions]
    assert codes.index("ZZZ_SUPPORTED") < codes.index("AAA_UNSUPPORTED")
    by_code = {item.code: item for item in arabic.health_conditions}
    assert by_code["ZZZ_SUPPORTED"].name == "\u0645\u062f\u0639\u0648\u0645"
    assert by_code["AAA_UNSUPPORTED"].is_supported is False
    english_names = {item.code: item.name for item in english.health_conditions}
    assert english_names["ZZZ_SUPPORTED"] == "Supported"
    assert arabic.cuisines[0].code == "LIBYAN"
    assert arabic.cuisines[0].name == "\u0644\u064a\u0628\u064a"
    assert [level.value for level in arabic.activity_levels] == [
        "SEDENTARY",
        "LIGHT",
        "MODERATE",
        "HIGH",
        "ATHLETE",
    ]
    assert [goal.value for goal in arabic.goal_types] == ["LOSE", "MAINTAIN", "GAIN"]
    assert arabic.dataset_version == UNKNOWN_DATASET_VERSION


def test_dataset_version_matches_the_single_active_meal(
    session: Session, integrity_conn: Connection
) -> None:
    make_meal(integrity_conn, dataset_version="catalog-2026.10", is_active=True)
    assert reference_lists(session, "ar").dataset_version == "catalog-2026.10"
