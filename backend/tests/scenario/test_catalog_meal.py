"""Catalog mode logs the lowest meal the breakfast filter accepts (#187)."""

from sqlalchemy.engine import Connection
from sqlalchemy.orm import Session

from tests.builders import make_dietary_tag, make_meal, make_meal_tag, make_user
from tests.scenario.f1_scenario import catalog_slot_meal_id


def test_catalog_mode_picks_the_lowest_breakfast_meal(integrity_conn: Connection) -> None:
    user = make_user(integrity_conn)
    breakfast = make_dietary_tag(integrity_conn, code="breakfast_suitable", tag_group="OCCASION")
    lunch = make_dietary_tag(integrity_conn, code="lunch_suitable", tag_group="OCCASION")
    earliest_lunch = make_meal(integrity_conn, is_active=True)
    make_meal_tag(integrity_conn, meal_id=earliest_lunch, tag_id=lunch)
    inactive = make_meal(integrity_conn, is_active=False)
    make_meal_tag(integrity_conn, meal_id=inactive, tag_id=breakfast)
    first = make_meal(integrity_conn, is_active=True)
    make_meal_tag(integrity_conn, meal_id=first, tag_id=breakfast)
    second = make_meal(integrity_conn, is_active=True)
    make_meal_tag(integrity_conn, meal_id=second, tag_id=breakfast)
    with Session(bind=integrity_conn, join_transaction_mode="create_savepoint") as session:
        assert catalog_slot_meal_id(session, user, "BREAKFAST") == first
        assert first < second
        assert earliest_lunch < first
