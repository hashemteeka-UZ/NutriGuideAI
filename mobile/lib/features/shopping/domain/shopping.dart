class ShoppingRow {
  const ShoppingRow({
    required this.ingredientId,
    required this.name,
    required this.grams,
    required this.meals,
    required this.checked,
  });

  final int ingredientId;
  final String name;
  final double grams;
  final int meals;
  final bool checked;
}

class ShoppingSnapshot {
  const ShoppingSnapshot({
    required this.rangeKey,
    required this.dateFrom,
    required this.dateTo,
    required this.items,
  });

  final String rangeKey;
  final String dateFrom;
  final String dateTo;
  final List<ShoppingRow> items;

  int get checkedCount => items.where((ShoppingRow row) => row.checked).length;
}

/// Under 1000 g, round to the nearest 10 g. Otherwise kilograms, one decimal.
/// Under 5 g (spices) the nearest 10 g would be 0, so keep whole grams, at
/// least 1.
({double amount, bool kilograms, bool approximate}) shoppingQuantity(
  num grams,
) {
  if (grams > 0 && grams < 5) {
    return (
      amount: grams.round().clamp(1, 4).toDouble(),
      kilograms: false,
      approximate: true,
    );
  }
  if (grams < 1000) {
    return (
      amount: ((grams / 10).round() * 10).toDouble(),
      kilograms: false,
      approximate: true,
    );
  }
  final kilos = grams / 1000;
  return (
    amount: (kilos * 10).roundToDouble() / 10,
    kilograms: true,
    approximate: false,
  );
}

String shoppingShareText({
  required String header,
  required List<ShoppingRow> items,
  required String Function(ShoppingRow row) quantity,
}) {
  final buffer = StringBuffer(header);
  for (final row in items) {
    if (row.checked) {
      continue;
    }
    buffer
      ..writeln()
      ..write('- ${row.name}: ${quantity(row)}');
  }
  return buffer.toString();
}
