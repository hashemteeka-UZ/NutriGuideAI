import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/plan/presentation/showcase_motion.dart';
import 'package:nutriguide/features/plan/presentation/showcase_screen.dart';

import '../../support/plan_samples.dart';

void main() {
  group('dishEmojiOf', () {
    test('uses the dish name when the catalog icon is missing', () {
      expect(
        dishEmojiOf(sampleItem(mealName: 'صدر دجاج مشوي مع برغل')),
        'poultry-leg',
      );
    });

    test('never shows a time-of-day emoji for a meal', () {
      final item = sampleItem(mealName: 'سلطة خضراء')
          .copyWith(iconName: 'crescent-moon');
      expect(dishEmojiOf(item), 'green-salad');
    });
  });

  Widget host(Widget child, {required bool reduceMotion}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('a reel spins while searching and stops on the chosen dish', (
    tester,
  ) async {
    Widget reel(String? settled) => Reel(
      pool: const <String>['a', 'b', 'c'],
      settled: settled,
      build: (String e) => Text(e),
    );
    await tester.pumpWidget(host(reel(null), reduceMotion: false));
    final first = (tester.widget(find.byType(Text)) as Text).data;
    await tester.pump(const Duration(milliseconds: 120));
    final next = (tester.widget(find.byType(Text)) as Text).data;
    expect(next, isNot(first));

    await tester.pumpWidget(host(reel('fish'), reduceMotion: false));
    await tester.pumpAndSettle();
    expect(find.text('fish'), findsOneWidget);
  });

  testWidgets('with reduced motion nothing repeats and the screen settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: <Widget>[
            Pulse(color: Colors.blue, child: SizedBox.square(dimension: 10)),
            SpinRing(color: Colors.blue, size: 20),
            SizedBox(
              width: 100,
              child: SearchingBar(
                color: Colors.blue,
                track: Colors.grey,
                height: 4,
              ),
            ),
            ConfettiBurst(),
          ],
        ),
        reduceMotion: true,
      ),
    );
    // Repeating animations would make this time out.
    await tester.pumpAndSettle();
    expect(find.byType(SpinRing), findsOneWidget);
  });
}
