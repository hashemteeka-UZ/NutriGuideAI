"""Meal windows scale with the awake span (#193)."""

from datetime import time

from app.services.meal_windows import meal_windows


def test_reference_day_is_the_16_hour_schedule() -> None:
    windows = meal_windows(time(7, 0), time(23, 0))
    assert [(item.slot, item.start, item.end) for item in windows] == [
        ("BREAKFAST", time(7, 30), time(9, 30)),
        ("LUNCH", time(13, 0), time(15, 0)),
        ("SNACK", time(16, 30), time(17, 30)),
        ("DINNER", time(18, 30), time(20, 30)),
    ]


def test_late_sleeper_wraps_past_midnight() -> None:
    windows = meal_windows(time(10, 0), time(2, 0))
    assert [(item.slot, item.start, item.end) for item in windows] == [
        ("BREAKFAST", time(10, 30), time(12, 30)),
        ("LUNCH", time(16, 0), time(18, 0)),
        ("SNACK", time(19, 30), time(20, 30)),
        ("DINNER", time(21, 30), time(23, 30)),
    ]


def test_awake_span_under_10_hours_has_no_windows() -> None:
    assert meal_windows(time(8, 0), time(17, 0)) == []
    assert meal_windows(time(23, 0), time(7, 0)) == []
