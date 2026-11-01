import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/ui/motion.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.label);

  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => taps++),
      child: Text('${widget.label} $taps'),
    );
  }
}

Widget _host(int index, {bool reduce = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: FadeThroughBranches(
        currentIndex: index,
        children: const <Widget>[_Counter('a'), _Counter('b')],
      ),
    ),
  );
}

void main() {
  testWidgets('switching tabs fades through and keeps branch state', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0));
    await tester.tap(find.text('a 0'));
    await tester.pump();
    expect(find.text('a 1'), findsOneWidget);
    expect(find.text('b 0'), findsNothing);

    await tester.pumpWidget(_host(1));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-way both branches are on stage, each in a fade-through.
    expect(find.text('a 1'), findsOneWidget);
    expect(find.text('b 0'), findsOneWidget);
    expect(find.byType(FadeThroughTransition), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('a 1'), findsNothing);
    expect(find.text('b 0'), findsOneWidget);

    await tester.pumpWidget(_host(0));
    await tester.pumpAndSettle();
    // The first branch kept its state.
    expect(find.text('a 1'), findsOneWidget);
  });

  testWidgets('reduced motion switches tabs at once', (tester) async {
    await tester.pumpWidget(_host(0, reduce: true));
    await tester.pumpWidget(_host(1, reduce: true));
    await tester.pump();
    expect(find.text('a 0'), findsNothing);
    expect(find.text('b 0'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('shared axis enters from the reading end in RTL and LTR', (
    tester,
  ) async {
    Future<double> startDx(TextDirection direction) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0001,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: SharedAxisX(
            animation: controller,
            secondaryAnimation: kAlwaysDismissedAnimation,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(SharedAxisX),
          matching: find.byType(Transform),
        ),
      );
      return transform.transform.getTranslation().x;
    }

    expect(await startDx(TextDirection.ltr), greaterThan(20));
    expect(await startDx(TextDirection.rtl), lessThan(-20));
  });

  testWidgets('sheets fade with their route and skip motion when reduced', (
    tester,
  ) async {
    late BuildContext host;
    Future<void> open({required bool reduce}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Builder(
              builder: (BuildContext context) {
                host = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      unawaited(
        showAppSheet<void>(context: host, builder: (_) => const Text('sheet')),
      );
      await tester.pump();
    }

    await open(reduce: false);
    expect(find.byType(SheetFade), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('sheet'),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    Navigator.of(host).pop();
    await tester.pumpAndSettle();

    await open(reduce: true);
    // No animation: the sheet is fully up after a single frame.
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('sheet'), findsOneWidget);
  });

  test('hero tags are per plan item and per catalog meal', () {
    expect(mealHeroTag(7), 'meal-item-7');
    expect(mealHeroTag(7), isNot(mealHeroTag(8)));
    expect(catalogMealHeroTag(7), isNot(mealHeroTag(7)));
  });
}
