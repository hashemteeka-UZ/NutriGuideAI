"""API contract version. Schemas and the app import it from here so neither imports the other."""

from typing import Final

# 1.1.0 (Step L.2, #294): additive, the LEARNED_PREFERENCE reason code and cpsat_v2_learned.
# 1.2.0 (P2a): additive, ShoppingItem.category_code and ShoppingItem.category.
API_VERSION: Final = "1.2.0"
