/// Offline search key.
///
/// Unicode NFC, then Arabic folding. Dart's SDK has no general NFC API, so
/// this composes the canonical Arabic pairs (alef, waw, and yeh with hamza or
/// madda) before folding. Those are the pairs that would otherwise survive as
/// a base letter plus a mark outside the harakat range.
///
/// Local ranking does not use trigram similarity. That is the only difference
/// from the server's meal search.
String normalizeSearch(String input) {
  final buffer = StringBuffer();
  var space = false;
  var started = false;
  for (final original in _nfc(input).runes) {
    final folded = _fold(original);
    if (folded == null) {
      continue;
    }
    if (folded == 0x20) {
      if (!started) {
        continue;
      }
      space = true;
      continue;
    }
    if (space) {
      buffer.writeCharCode(0x20);
      space = false;
    }
    started = true;
    buffer.writeCharCode(folded);
  }
  return buffer.toString();
}

/// Canonical compositions used by Arabic meal names.
const _composed = <int, int>{
  // alef + madda above -> آ
  (0x0627 << 16) | 0x0653: 0x0622,
  // alef + hamza above -> أ
  (0x0627 << 16) | 0x0654: 0x0623,
  // waw + hamza above -> ؤ
  (0x0648 << 16) | 0x0654: 0x0624,
  // alef + hamza below -> إ
  (0x0627 << 16) | 0x0655: 0x0625,
  // yeh + hamza above -> ئ
  (0x064A << 16) | 0x0654: 0x0626,
};

String _nfc(String input) {
  final out = <int>[];
  for (final code in input.runes) {
    if (out.isNotEmpty) {
      final composed = _composed[(out.last << 16) | code];
      if (composed != null) {
        out[out.length - 1] = composed;
        continue;
      }
    }
    out.add(code);
  }
  return String.fromCharCodes(out);
}

/// Returns a replacement code, space (0x20) for whitespace, or null to drop.
int? _fold(int code) {
  if (_isHarakah(code) || code == 0x0640) {
    return null;
  }
  if (code == 0x0623 || code == 0x0625 || code == 0x0622 || code == 0x0671) {
    return 0x0627;
  }
  if (code == 0x0649 || code == 0x0626) {
    return 0x064A;
  }
  if (code == 0x0629) {
    return 0x0647;
  }
  if (code == 0x0624) {
    return 0x0648;
  }
  if (code >= 0x0660 && code <= 0x0669) {
    return 0x30 + (code - 0x0660);
  }
  if (code >= 0x41 && code <= 0x5A) {
    return code + 0x20;
  }
  if (code == 0x09 ||
      code == 0x0A ||
      code == 0x0D ||
      code == 0x20 ||
      code == 0xA0) {
    return 0x20;
  }
  return code;
}

bool _isHarakah(int code) {
  return (code >= 0x064B && code <= 0x0652) || code == 0x0670;
}
