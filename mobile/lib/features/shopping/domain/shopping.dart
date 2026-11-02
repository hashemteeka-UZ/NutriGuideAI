class ShoppingRow {
  const ShoppingRow({
    required this.ingredientId,
    required this.name,
    required this.grams,
    required this.meals,
    required this.checked,
    this.categoryCode = '',
    this.category = '',
  });

  final int ingredientId;
  final String name;
  final double grams;
  final int meals;
  final bool checked;

  /// USDA food group code (API 1.2.0); empty in an older cache.
  final String categoryCode;
  final String category;

  ShoppingRow withChecked(bool value) {
    return ShoppingRow(
      ingredientId: ingredientId,
      name: name,
      grams: grams,
      meals: meals,
      checked: value,
      categoryCode: categoryCode,
      category: category,
    );
  }
}

/// The three lists on the shopping screen (P2b).
enum ShoppingScope { plan, today, meal }

/// One header and its rows. [code] is empty for the single fallback group.
class ShoppingGroup {
  const ShoppingGroup({
    required this.code,
    required this.name,
    required this.rows,
  });

  final String code;
  final String name;
  final List<ShoppingRow> rows;
}

/// Groups rows by food group in code order, names inside a group in the order
/// given. Rows without a code (an older cache) form one last group; when no
/// row has a code there is exactly one group.
List<ShoppingGroup> groupShopping(List<ShoppingRow> rows) {
  final byCode = <String, List<ShoppingRow>>{};
  final names = <String, String>{};
  for (final row in rows) {
    byCode.putIfAbsent(row.categoryCode, () => <ShoppingRow>[]).add(row);
    if (row.category.isNotEmpty) {
      names[row.categoryCode] = row.category;
    }
  }
  final codes = byCode.keys.toList()
    ..sort((String a, String b) {
      if (a.isEmpty != b.isEmpty) {
        return a.isEmpty ? 1 : -1;
      }
      return a.compareTo(b);
    });
  return <ShoppingGroup>[
    for (final code in codes)
      ShoppingGroup(code: code, name: names[code] ?? '', rows: byCode[code]!),
  ];
}

/// Emoji (assets/emoji) for a USDA food group header.
String categoryEmoji(String code) {
  return switch (code) {
    '0100' => 'glass-of-milk',
    '0200' => 'herb',
    '0400' => 'olive',
    '0500' => 'poultry-leg',
    '0800' || '1800' || '2000' => 'bread',
    '0900' => 'red-apple',
    '1000' || '1300' || '1700' || '0700' => 'cut-of-meat',
    '1100' => 'leafy-green',
    '1200' => 'peanuts',
    '1400' => 'teacup-without-handle',
    '1500' => 'fish',
    '1600' => 'beans',
    '1900' => 'honey-pot',
    '2500' => 'jar',
    _ => 'shopping-cart',
  };
}

/// The plan item to shop for now: the one whose window contains [nowMinutes],
/// else the next one to start today. Items without a window are skipped.
T? pickCurrentMeal<T>({
  required List<T> items,
  required ({String start, String end})? Function(T item) window,
  required int nowMinutes,
  required int Function(String hhmm) minutes,
}) {
  T? next;
  var nextStart = 1 << 30;
  for (final item in items) {
    final span = window(item);
    if (span == null) {
      continue;
    }
    final start = minutes(span.start);
    final end = minutes(span.end);
    if (start <= nowMinutes && nowMinutes <= end) {
      return item;
    }
    if (start > nowMinutes && start < nextStart) {
      next = item;
      nextStart = start;
    }
  }
  return next;
}

/// Ingredient grams for one plan item from the local catalog: grams per
/// serving x (item grams / serving grams). Optional ingredients and tap water
/// are left out; repeated ingredients are summed.
List<ShoppingRow> mealShoppingRows({
  required List<
    ({int ingredientId, String name, double gramsPerServing, bool isOptional})
  >
  ingredients,
  required double itemGrams,
  required double servingGrams,
  required Map<int, ({String code, String name})> categories,
  required Set<int> checked,
}) {
  final factor = servingGrams <= 0 ? 1.0 : itemGrams / servingGrams;
  final grams = <int, double>{};
  final names = <int, String>{};
  for (final line in ingredients) {
    if (line.isOptional || isTapWater(line.name)) {
      continue;
    }
    grams[line.ingredientId] =
        (grams[line.ingredientId] ?? 0) + line.gramsPerServing * factor;
    names[line.ingredientId] = line.name;
  }
  final rows = <ShoppingRow>[
    for (final id in grams.keys)
      ShoppingRow(
        ingredientId: id,
        name: names[id]!,
        grams: (grams[id]! * 10).roundToDouble() / 10,
        meals: 1,
        checked: checked.contains(id),
        categoryCode: categories[id]?.code ?? '',
        category: categories[id]?.name ?? '',
      ),
  ];
  return rows;
}

/// Tap water is an ingredient for cooking but nothing to buy (#315). The
/// list has names only, so the WATER ingredient is matched by its name.
bool isTapWater(String name) {
  final trimmed = name.trim().toLowerCase();
  return trimmed == 'ماء' || trimmed == 'water';
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

/// Unchecked items only, under one line per food group when the list has
/// groups ([groupName] gives the header, e.g. the localized fallback).
String shoppingShareText({
  required String header,
  required List<ShoppingRow> items,
  required String Function(ShoppingRow row) quantity,
  String Function(ShoppingGroup group)? groupName,
}) {
  final buffer = StringBuffer(header);
  final groups = groupShopping(<ShoppingRow>[
    for (final row in items)
      if (!row.checked) row,
  ]);
  final titled = groupName != null && groups.length > 1;
  for (final group in groups) {
    if (titled) {
      buffer
        ..writeln()
        ..writeln()
        ..write(groupName(group));
    }
    for (final row in group.rows) {
      buffer
        ..writeln()
        ..write('- ${row.name}: ${quantity(row)}');
    }
  }
  return buffer.toString();
}
