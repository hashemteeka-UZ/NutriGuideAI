"""Learning layer settings (#285, #288). DEFAULT_ALPHA is written by scripts/ml_simulate.py."""

from __future__ import annotations

from typing import Final

# Exploration width of the upper confidence bound, chosen by the simulation (#289).
DEFAULT_ALPHA: Final = 0.5
# Ridge penalty: A0 and every A_u start as RIDGE_LAMBDA * I (Li et al. 2010 use 1).
RIDGE_LAMBDA: Final = 1.0
# Upper end of the learned objective bonus (#291), in optimizer units (0.1 kcal-equivalent):
# UCB clipped to [-1, 1], then linear to [0, 60]. 60 units = 2 kcal of day deviation at
# W_KCAL = 3 (see app/services/optimizer.py).
MAX_LEARNED_BONUS: Final = 60
# #291: the planning score is mean + PLANNING_EXPLORATION_WEIGHT * width. Damped optimism for
# a committed weekly plan: it keeps the UCB principle while a meal with consistent positive
# feedback outranks untried meals. Swaps use the mean only, and diversity also comes from the
# weekly variety penalty. Measured: liked > untried holds for a weight below 0.137 with 5
# COOK/SAVE events on the F.1 slice, so 0.1.
PLANNING_EXPLORATION_WEIGHT: Final = 0.1
# #294: LEARNED_PREFERENCE needs this learned mean and this many real events of the user.
LEARNED_REASON_MIN_MEAN: Final = 0.35
LEARNED_REASON_MIN_EVENTS: Final = 5
# Cold start (#288): pseudo-observations before a user's first event.
COLD_START_WEIGHT: Final = 0.3
COLD_START_CAP: Final = 20
COLD_START_LIKE_REWARD: Final = 1.0
COLD_START_CUISINE_REWARD: Final = 0.5
