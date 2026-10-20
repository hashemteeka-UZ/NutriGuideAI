"""Local meal windows from wake and sleep (#193).

The reference awake span is 16 hours (07:00 to 23:00). Lunch and the snack scale with
the user's awake span. Dinner is anchored to sleep. Times wrap past midnight and are
rounded to five minutes. An awake span under 10 hours has no sensible schedule.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import time
from decimal import ROUND_HALF_UP, Decimal

_DAY_MINUTES = Decimal(24 * 60)
_FIVE = Decimal(5)
_REFERENCE_HOURS = Decimal(16)
_SHORT_DAY = Decimal(10)
_SLOT_ORDER = ("BREAKFAST", "LUNCH", "SNACK", "DINNER")


@dataclass(frozen=True)
class MealWindow:
    slot: str
    start: time
    end: time


def _minutes(value: time) -> Decimal:
    return Decimal(value.hour * 60 + value.minute) + (Decimal(value.second) / Decimal(60))


def _clock(minutes: Decimal) -> time:
    rounded = int((_minutes_mod(minutes) / _FIVE).quantize(Decimal(1), rounding=ROUND_HALF_UP)) * 5
    rounded %= 24 * 60
    hour, minute = divmod(rounded, 60)
    return time(hour, minute)


def _minutes_mod(minutes: Decimal) -> Decimal:
    return minutes % _DAY_MINUTES


def _awake_hours(wake: time, sleep: time) -> Decimal:
    wake_m = _minutes(wake)
    sleep_m = _minutes(sleep)
    span = sleep_m + _DAY_MINUTES - wake_m if sleep_m <= wake_m else sleep_m - wake_m
    return span / Decimal(60)


def meal_windows(wake_time: time, sleep_time: time) -> list[MealWindow]:
    """BREAKFAST, LUNCH, SNACK, DINNER, or an empty list when the day is too short."""
    awake = _awake_hours(wake_time, sleep_time)
    if awake < _SHORT_DAY:
        return []
    scale = awake / _REFERENCE_HOURS
    wake = _minutes(wake_time)
    sleep = _minutes(sleep_time)
    spans = {
        "BREAKFAST": (wake + Decimal("30"), wake + Decimal("150")),
        "LUNCH": (wake + Decimal(6) * scale * Decimal(60), wake + Decimal(8) * scale * Decimal(60)),
        "SNACK": (
            wake + Decimal("9.5") * scale * Decimal(60),
            wake + Decimal("10.5") * scale * Decimal(60),
        ),
        "DINNER": (sleep - Decimal("270"), sleep - Decimal("150")),
    }
    return [
        MealWindow(slot=slot, start=_clock(spans[slot][0]), end=_clock(spans[slot][1]))
        for slot in _SLOT_ORDER
    ]
