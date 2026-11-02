import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/theme/accent.dart';
import 'package:nutriguide/core/theme/app_colors.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/profile/data/display_name.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_secure.dart';
import '../../support/pump_app.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  testNutriguide('onboarding opens with the optional name page', (
    tester,
  ) async {
    final secure = MemorySecure();
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
      askName: true,
      nameStore: secure,
    );
    expect(find.byKey(const Key('onb-name-page')), findsOneWidget);
    expect(find.text('ماذا نناديك؟'), findsOneWidget);
    // Continue stays off until a name is typed.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('onb-name-continue')))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const Key('onb-name-field')), '  أحمد ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('onb-name-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onb-name-page')), findsNothing);
    expect(find.text('عرّفنا بنفسك'), findsOneWidget);
    expect(await secure.read(displayNameKey), 'أحمد');
  });

  testNutriguide('skipping the name page keeps nothing', (tester) async {
    final secure = MemorySecure();
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
      askName: true,
      nameStore: secure,
    );
    await tester.tap(find.byKey(const Key('onb-name-skip')));
    await tester.pumpAndSettle();
    expect(find.text('عرّفنا بنفسك'), findsOneWidget);
    expect(await secure.read(displayNameKey), isNull);
  });

  testNutriguide('a stored name greets on Today and heads the account', (
    tester,
  ) async {
    final secure = MemorySecure();
    await secure.write(displayNameKey, 'سارة');
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: true)),
      ),
      nameStore: secure,
    );
    expect(find.text('نهارك سعيد، سارة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('account-header')),
        matching: find.text('سارة'),
      ),
      findsOneWidget,
    );
  });

  test('names are trimmed, capped and empty means none', () {
    expect(cleanDisplayName('  أحمد   علي '), 'أحمد علي');
    expect(cleanDisplayName('   '), isNull);
    expect(cleanDisplayName('x' * 40), hasLength(displayNameMaxLength));
  });

  test('the accent follows the goal and white text stays readable', () {
    expect(accentForGoal('LOSE'), AccentPalette.emerald);
    expect(accentForGoal('MAINTAIN'), AccentPalette.teal);
    expect(accentForGoal('GAIN'), AccentPalette.plum);
    expect(AccentPalette.emerald.light.$1, const Color(0xFF08875D));
    for (final palette in <AccentPalette>[
      AccentPalette.emerald,
      AccentPalette.teal,
      AccentPalette.plum,
    ]) {
      final (brand, _, onBrand) = palette.light;
      expect(_contrast(brand, onBrand), greaterThanOrEqualTo(4.5));
      final (darkBrand, _, darkOn) = palette.dark;
      expect(_contrast(darkBrand, darkOn), greaterThanOrEqualTo(4.5));
    }
    // A chosen colour wins over the goal; auto before sign-in keeps the
    // default identity.
    expect(accentFor(AccentChoice.plum, goal: 'LOSE'), AccentPalette.plum);
    expect(accentFor(AccentChoice.auto), isNull);
  });

  test('the accent never touches energy, macro or water colours', () {
    for (final dark in <bool>[false, true]) {
      final base = dark ? AppColors.dark : AppColors.light;
      final themed = AccentPalette.plum.apply(base, dark: dark);
      expect(themed.kcal, base.kcal);
      expect(themed.protein, base.protein);
      expect(themed.carb, base.carb);
      expect(themed.fat, base.fat);
      expect(themed.fiber, base.fiber);
      expect(themed.water, base.water);
      expect(themed.brand, isNot(base.brand));
    }
  });
}
