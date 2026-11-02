import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/catalog/domain/dish_icon.dart';

/// test/fixtures/catalog_dishes.json is the full catalog as the phone gets it
/// (`GET /catalog/snapshot` in ar and en, catalog_v3, 158 meals): name and
/// non-optional ingredients, heaviest first.
List<Map<String, Object?>> _catalog() {
  final raw = File('test/fixtures/catalog_dishes.json').readAsStringSync();
  return (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>();
}

String _icon(Map<String, Object?> meal, String lang) {
  final side = meal[lang]! as Map<String, Object?>;
  return dishIcon(
    side['name']! as String,
    ingredients: (side['ingredients']! as List<Object?>).cast<String>(),
  );
}

void main() {
  final catalog = _catalog();

  test('the fixture is the full catalog', () {
    expect(catalog, hasLength(158));
  });

  test('no meal gets a time-of-day icon, in either language', () {
    for (final meal in catalog) {
      for (final lang in const <String>['ar', 'en']) {
        expect(
          timeOfDayIcons,
          isNot(contains(_icon(meal, lang))),
          reason: '${meal['id']} $lang',
        );
      }
    }
  });

  test('Arabic and English give every meal the same icon', () {
    final mismatches = <String>[
      for (final meal in catalog)
        if (_icon(meal, 'ar') != _icon(meal, 'en'))
          '${meal['id']}: ar ${_icon(meal, 'ar')} / en ${_icon(meal, 'en')}',
    ];
    expect(mismatches, isEmpty);
  });

  test('every meal is recognised from its own name', () {
    final unknown = <String>[
      for (final meal in catalog)
        if (dishIcon(
              (meal['ar']! as Map<String, Object?>)['name']! as String,
            ) ==
            fallbackDishIcon)
          '${meal['id']}',
    ];
    expect(unknown, isEmpty);
  });

  test('the dish decides: fish, chicken, eggs, legumes, rice and the rest', () {
    String of(int id) =>
        _icon(catalog.firstWhere((meal) => meal['id'] == id), 'ar');
    expect(of(16), 'fish'); // سلمون بالفرن
    expect(of(63), 'fish'); // بلطي مشوي مع رز
    expect(of(22), 'poultry-leg'); // دجاج مشوي
    expect(of(38), 'cooking'); // شكشوكة
    expect(of(8), 'beans'); // فول بالطحينة
    expect(of(21), 'cooked-rice'); // رز بالخضار
    expect(of(106), 'spaghetti'); // معكرونة قمح كامل بالدجاج
    expect(of(129), 'green-salad'); // سلطة خضراء ليبية
    expect(of(68), 'pot-of-food'); // شربة عدس
    expect(of(65), 'sandwich'); // ساندويتش دجاج مشوي
    expect(of(118), 'flatbread'); // مناقيش زعتر
    expect(of(31), 'bowl-with-spoon'); // زبادي بالتمر
    expect(of(152), 'red-apple'); // تفاحة
    expect(of(54), 'cut-of-meat'); // كفتة بالصلصة
    // Peanut butter is not fava beans (فول).
    expect(of(34), 'red-apple'); // تفاح بزبدة الفول السوداني
    expect(of(125), 'flatbread'); // توست أسمر بزبدة الفول السوداني والموز
    expect(of(102), 'shallow-pan-of-food'); // ورق عنب: not grapes
    expect(of(127), 'glass-of-milk'); // حليب قليل الدسم
  });

  test('unknown names fall back to the main ingredient, then a plate', () {
    expect(dishIcon('طبق اليوم', ingredients: <String>['ماء', 'سمك']), 'fish');
    expect(dishIcon('Chef special', ingredients: <String>['Lentils']), 'beans');
    expect(dishIcon('طبق اليوم'), fallbackDishIcon);
  });
}
