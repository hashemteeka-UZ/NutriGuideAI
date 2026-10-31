import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/plan/data/user_context.dart';
import 'package:nutriguide/features/water/domain/water.dart';

void main() {
  test('07:00 to 23:00 with 2,000 ml: eight sessions of 250 ml', () {
    final sessions = waterSessions(
      goalMl: 2000,
      totalMl: 750,
      wakeMinutes: 7 * 60,
      sleepMinutes: 23 * 60,
    );
    expect(sessions.map((WaterSession s) => s.minutes).toList(), <int>[
      450,
      570,
      705,
      825,
      945,
      1065,
      1200,
      1320,
    ]);
    expect(sessions.every((WaterSession s) => s.amountMl == 250), isTrue);
    expect(sessions.map((WaterSession s) => s.done).toList(), <bool>[
      true,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
    ]);
  });

  test('sleep after midnight wraps and the amount rounds to 50 ml', () {
    final sessions = waterSessions(
      goalMl: 1500,
      totalMl: 0,
      wakeMinutes: 9 * 60,
      sleepMinutes: 60,
    );
    expect(sessions, hasLength(8));
    expect(sessions.first.minutes, 570);
    expect(sessions.last.minutes, 0);
    expect(sessions.first.amountMl, 200);
    expect(sessions.any((WaterSession s) => s.done), isFalse);
  });

  test('no profile times: 07:00 to 23:00, and never fewer than four', () {
    expect(waterSessions(goalMl: 2000, totalMl: 0), hasLength(8));
    expect(
      waterSessions(
        goalMl: 1000,
        totalMl: 0,
        wakeMinutes: 8 * 60,
        sleepMinutes: 12 * 60,
      ),
      hasLength(4),
    );
  });

  test('clock strings parse with or without seconds', () {
    expect(clockToMinutes('07:30'), 450);
    expect(clockToMinutes('23:00:00'), 1380);
    expect(clockToMinutes('bad'), isNull);
  });
}
