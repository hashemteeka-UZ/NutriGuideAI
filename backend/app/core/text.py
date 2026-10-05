"""Search-text normalization (§15.9, rules v1). The single implementation; every *_normalized
column is filled through normalize_search_text()."""

import re

# Tashkeel U+064B-U+0652 and superscript alef U+0670.
_ARABIC_DIACRITICS = "".join(chr(cp) for cp in range(0x064B, 0x0653)) + "\u0670"
_TATWEEL = "\u0640"
_ALEF = "\u0627"
_HEH = "\u0647"
_YEH = "\u064a"
_WAW = "\u0648"

_TRANSLATION = str.maketrans(
    {
        **dict.fromkeys(_ARABIC_DIACRITICS + _TATWEEL),
        "\u0623": _ALEF,  # alef with hamza above
        "\u0625": _ALEF,  # alef with hamza below
        "\u0622": _ALEF,  # alef with madda
        "\u0671": _ALEF,  # alef wasla
        "\u0629": _HEH,  # teh marbuta
        "\u0649": _YEH,  # alef maksura
        "\u0624": _WAW,  # waw with hamza
        "\u0626": _YEH,  # yeh with hamza
        **{chr(0x0660 + d): str(d) for d in range(10)},
        **{chr(0x06F0 + d): str(d) for d in range(10)},
    }
)

_WHITESPACE = re.compile(r"\s+")


def normalize_search_text(text: str) -> str:
    """Lowercase Latin, strip tashkeel/tatweel, unify Arabic letter variants, ASCII digits,
    collapse whitespace."""
    normalized = text.translate(_TRANSLATION).lower()
    return _WHITESPACE.sub(" ", normalized).strip()
