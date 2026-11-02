import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/l10n/app_localizations.dart';

void main() {
  test('Arabic meal counts use the right number forms', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(ar.shopInMeals(1), 'في وجبة واحدة');
    expect(ar.shopInMeals(2), 'في وجبتين');
    expect(ar.shopInMeals(3), 'في 3 وجبات');
    expect(ar.shopInMeals(11), 'في 11 وجبة');
    expect(ar.favouritesCount(0), 'لا وجبات');
    expect(ar.favouritesCount(2), 'وجبتان');
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.shopInMeals(1), 'In 1 meal');
    expect(en.shopInMeals(4), 'In 4 meals');
  });

  test('the water tips are the approved texts', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(
      ar.waterSessionTip,
      'كوب واحد (نحو 250 مل) في كل مرة يكفي. وزّع الباقي على يومك، '
      'ولا حاجة لشرب كمية كبيرة دفعة واحدة.',
    );
    expect(
      ar.waterLargeTip,
      'هذه كمية كبيرة دفعة واحدة. الأريح أن تقسمها على مرتين.',
    );
  });
}
