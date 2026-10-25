"""Learning layer settings (#285, #288). DEFAULT_ALPHA is written by scripts/ml_simulate.py."""

from __future__ import annotations

from typing import Final

# Exploration width of the upper confidence bound, chosen by the simulation (#289).
DEFAULT_ALPHA: Final = 0.5
# Ridge penalty: A0 and every A_u start as RIDGE_LAMBDA * I (Li et al. 2010 use 1).
RIDGE_LAMBDA: Final = 1.0
# Upper end of the integer bonus L.2 adds to the optimizer objective.
MAX_LEARNED_BONUS: Final = 100
# Cold start (#288): pseudo-observations before a user's first event.
COLD_START_WEIGHT: Final = 0.3
COLD_START_CAP: Final = 20
COLD_START_LIKE_REWARD: Final = 1.0
COLD_START_CUISINE_REWARD: Final = 0.5
