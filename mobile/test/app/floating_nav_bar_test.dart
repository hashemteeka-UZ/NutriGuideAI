import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/shell.dart';
import 'package:nutriguide/core/theme/app_theme.dart';

const _tabs = <NavTab>[
  NavTab('اليوم', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'tab-a'),
  NavTab('الخطة', Icons.calendar_month_outlined, Icons.calendar_month, 'tab-b'),
  NavTab('الماء', Icons.water_drop_outlined, Icons.water_drop, 'tab-c'),
  NavTab('تقدمي', Icons.insights_outlined, Icons.insights, 'tab-d'),
  NavTab('حسابي', Icons.person_outline, Icons.person, 'tab-e'),
];

Widget _host({
  required int index,
  required ValueChanged<int> onSelect,
  bool reduce = false,
  TextDirection direction = TextDirection.rtl,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: reduce,
      ),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: const SizedBox.expand(key: Key('body')),
          bottomNavigationBar: FloatingNavBar(
            tabs: _tabs,
            index: index,
            onSelect: onSelect,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the pill sits behind the selected tab and slides in RTL', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(_host(index: 0, onSelect: (i) => selected = i));
    final bar = tester.getRect(find.byKey(const Key('floating-nav')));
    final first = tester.getRect(find.byKey(const Key('nav-pill')));
    // RTL: the first tab is on the right.
    expect(first.right, closeTo(bar.right - 6 - 1, 1.5));
    expect(
      tester.getCenter(find.byKey(const Key('tab-a'))).dx,
      closeTo(first.center.dx, 1),
    );

    await tester.tap(find.byKey(const Key('tab-c')));
    expect(selected, 2);
    await tester.pumpWidget(_host(index: 2, onSelect: (i) => selected = i));
    await tester.pump(const Duration(milliseconds: 100));
    final moving = tester.getRect(find.byKey(const Key('nav-pill')));
    expect(moving.center.dx, lessThan(first.center.dx));
    await tester.pumpAndSettle();
    final third = tester.getRect(find.byKey(const Key('nav-pill')));
    expect(
      third.center.dx,
      closeTo(tester.getCenter(find.byKey(const Key('tab-c'))).dx, 1),
    );
    expect(moving.center.dx, greaterThan(third.center.dx));
  });

  testWidgets('reduced motion moves the pill at once', (tester) async {
    await tester.pumpWidget(_host(index: 0, onSelect: (_) {}, reduce: true));
    await tester.pumpWidget(_host(index: 4, onSelect: (_) {}, reduce: true));
    // One frame later the pill is already under the new tab.
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const Key('nav-pill'))).dx,
      closeTo(tester.getCenter(find.byKey(const Key('tab-e'))).dx, 1),
    );
  });

  testWidgets('labels always show; the selected tab is marked and bold', (
    tester,
  ) async {
    await tester.pumpWidget(_host(index: 1, onSelect: (_) {}));
    await tester.pumpAndSettle();
    for (final tab in _tabs) {
      expect(find.text(tab.label), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.byKey(const Key('tab-b'))),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: 'الخطة',
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('tab-a'))),
      matchesSemantics(
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: 'اليوم',
      ),
    );
    final bold = tester.widget<Text>(find.text('الخطة'));
    final style = DefaultTextStyle.of(tester.element(find.text('الخطة'))).style;
    expect(bold.style?.fontWeight ?? style.fontWeight, FontWeight.w700);
    // Filled icon for the selected tab, outlined for the others.
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
  });

  testWidgets('the bar floats below the content, never over it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(index: 0, onSelect: (_) {}));
    final body = tester.getRect(find.byKey(const Key('body')));
    final bar = tester.getRect(find.byKey(const Key('floating-nav')));
    expect(body.bottom, lessThanOrEqualTo(bar.top));
    // 12 px from the screen sides.
    expect(bar.left, 12);
    expect(bar.right, 390 - 12);
  });
}
