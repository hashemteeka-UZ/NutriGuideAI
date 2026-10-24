abstract interface class TimezoneSource {
  Future<String> ianaName();
}

String normalizeIana(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'UTC';
  }
  return trimmed;
}
