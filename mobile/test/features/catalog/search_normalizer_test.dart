import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/catalog/domain/search_normalizer.dart';

void main() {
  test('shakshuka spellings share one key', () {
    const forms = <String>['شَكشُوكة', 'شكشوكه', 'شكشوكة'];
    final keys = forms.map(normalizeSearch).toSet();
    expect(keys, hasLength(1));
    expect(keys.single, 'شكشوكه');
  });

  test('strips harakat, tatweel, and unifies alef forms', () {
    expect(normalizeSearch('أَكْل'), 'اكل');
    expect(normalizeSearch('إِكْل'), 'اكل');
    expect(normalizeSearch('آكْل'), 'اكل');
    expect(normalizeSearch('ٱكل'), 'اكل');
    expect(normalizeSearch('مـكـتـب'), 'مكتب');
  });

  test('folds teh marbuta, alef maksura, and hamza carriers', () {
    expect(normalizeSearch('مكة'), normalizeSearch('مكه'));
    expect(normalizeSearch('على'), normalizeSearch('علي'));
    expect(normalizeSearch('مؤمن'), 'مومن');
    expect(normalizeSearch('مسئل'), 'مسيل');
  });

  test('maps Arabic-Indic digits and lowercases Latin', () {
    expect(normalizeSearch('وجبة ١٢٣'), 'وجبه 123');
    expect(normalizeSearch('  Salad  BOWL '), 'salad bowl');
  });
}
