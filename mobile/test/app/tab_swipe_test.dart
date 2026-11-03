import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/tab_swipe.dart';

void main() {
  Future<List<int>> pump(
    WidgetTester tester, {
    required int index,
    TextDirection direction = TextDirection.rtl,
    Widget? content,
  }) async {
    final swiped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: TabSwipe(
              index: index,
              count: 5,
              onSwipe: swiped.add,
              child: content ?? const SizedBox.expand(key: Key('page')),
            ),
          ),
        ),
      ),
    );
    return swiped;
  }

  testWidgets('in Arabic a swipe to the right opens the next tab', (
    tester,
  ) async {
    final swiped = await pump(tester, index: 1);
    await tester.fling(find.byType(TabSwipe), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(swiped, <int>[2]);
  });

  testWidgets('in Arabic a swipe to the left goes back', (tester) async {
    final swiped = await pump(tester, index: 1);
    await tester.fling(find.byType(TabSwipe), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(swiped, <int>[0]);
  });

  testWidgets('in English the directions are mirrored', (tester) async {
    final swiped = await pump(tester, index: 1, direction: TextDirection.ltr);
    await tester.fling(find.byType(TabSwipe), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(swiped, <int>[2]);
  });

  testWidgets('no tab before the first or after the last', (tester) async {
    var swiped = await pump(tester, index: 0);
    await tester.fling(find.byType(TabSwipe), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);

    swiped = await pump(tester, index: 4);
    await tester.fling(find.byType(TabSwipe), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);
  });

  testWidgets('a short slow drag does not switch', (tester) async {
    final swiped = await pump(tester, index: 1);
    await tester.drag(find.byType(TabSwipe), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);
  });

  testWidgets('vertical scrolling stays with the page', (tester) async {
    final swiped = await pump(
      tester,
      index: 1,
      content: ListView(
        children: <Widget>[
          for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i')),
        ],
      ),
    );
    await tester.fling(find.byType(ListView), const Offset(0, -400), 1500);
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a sideways list inside a tab keeps its own swipe', (
    tester,
  ) async {
    final swiped = await pump(
      tester,
      index: 1,
      content: Column(
        children: <Widget>[
          SizedBox(
            height: 80,
            child: ListView(
              key: const Key('strip'),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (var i = 0; i < 30; i++)
                  SizedBox(width: 80, child: Text('d$i')),
              ],
            ),
          ),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
    await tester.fling(
      find.byKey(const Key('strip')),
      const Offset(300, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);
  });
}
