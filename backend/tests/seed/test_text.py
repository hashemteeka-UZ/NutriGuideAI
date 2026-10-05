"""normalize_search_text(), rules v1 (§15.9). One test per rule."""

import pytest

from app.core.text import normalize_search_text


def test_lowercases_latin() -> None:
    assert normalize_search_text("Hummus TAHINI") == "hummus tahini"


@pytest.mark.parametrize("code_point", [*range(0x064B, 0x0653), 0x0670])
def test_strips_each_arabic_diacritic(code_point: int) -> None:
    assert normalize_search_text(f"ب{chr(code_point)}ب") == "بب"


def test_strips_tatweel() -> None:
    assert normalize_search_text("عـــدس") == "عدس"


@pytest.mark.parametrize("variant", ["أ", "إ", "آ", "ٱ"])
def test_unifies_alef_variants(variant: str) -> None:
    assert normalize_search_text(f"{variant}رز") == "ارز"


def test_teh_marbuta_becomes_heh() -> None:
    assert normalize_search_text("شوربة") == "شوربه"


def test_alef_maksura_becomes_yeh() -> None:
    assert normalize_search_text("مستشفى") == "مستشفي"


def test_waw_with_hamza_becomes_waw() -> None:
    assert normalize_search_text("لؤلؤ") == "لولو"


def test_yeh_with_hamza_becomes_yeh() -> None:
    assert normalize_search_text("مائدة") == "مايده"


def test_arabic_indic_digits_become_ascii() -> None:
    assert normalize_search_text("٠١٢٣٤٥٦٧٨٩") == "0123456789"


def test_eastern_arabic_indic_digits_become_ascii() -> None:
    assert normalize_search_text("۰۱۲۳۴۵۶۷۸۹") == "0123456789"


def test_collapses_and_strips_whitespace() -> None:
    assert normalize_search_text("  a \t\n  b  ") == "a b"


def test_mixed_arabic_and_english() -> None:
    raw = "  شَكْشُوكَة ليبيّة   مع خبز  Whole-Wheat PITA ١٢٠ غرام "
    assert normalize_search_text(raw) == "شكشوكه ليبيه مع خبز whole-wheat pita 120 غرام"


def test_other_letters_unchanged_and_idempotent() -> None:
    text = "بتث جحخ 90% lean"
    assert normalize_search_text(text) == text
    assert normalize_search_text(normalize_search_text("أَحْمَد")) == normalize_search_text("أَحْمَد")
