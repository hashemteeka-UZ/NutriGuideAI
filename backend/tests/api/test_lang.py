"""Accept-Language parsing and the localized-name helper."""

from app.api.deps import get_lang, pick_name


def test_accept_language_picks_the_first_known_primary_tag() -> None:
    assert get_lang("en-US,en;q=0.9") == "en"
    assert get_lang("fr, en;q=0.5") == "en"
    assert get_lang("ar") == "ar"
    assert get_lang(None) == "ar"
    assert get_lang() == "ar"
    assert get_lang("garbage") == "ar"
    assert get_lang("en;q=0") == "ar"
    assert get_lang("en;q=0, ar;q=0.2") == "ar"


def test_pick_name_uses_english_only_when_it_was_asked_for_and_present() -> None:
    assert pick_name("en", "عربي", "English") == "English"
    assert pick_name("en", "عربي", "") == "عربي"
    assert pick_name("en", "عربي", None) == "عربي"
    assert pick_name("ar", "عربي", "English") == "عربي"
