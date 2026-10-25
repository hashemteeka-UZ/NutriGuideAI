import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart' as db;
import '../../../core/db/database_provider.dart';
import '../../../core/sync/sync_engine.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/badges.dart';

/// One badge as the grid shows it.
class BadgeItem {
  const BadgeItem({required this.progress, this.earnedOn, this.seen = true});

  final BadgeProgress progress;

  /// YYYY-MM-DD the phone first saw it earned; null while locked.
  final String? earnedOn;

  /// False for a badge earned since the user last opened the grid.
  final bool seen;

  BadgeCode get code => progress.code;
  bool get earned => earnedOn != null;
}

/// Evaluates the rules on local tables and stores newly earned badges (#308).
class BadgeService {
  BadgeService(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final DateTime Function() _now;

  Future<BadgeInputs> _inputs() async {
    final logs = await (_database.select(
      _database.consumptionLogs,
    )..where((t) => t.state.isIn(<String>[logPending, logConfirmed]))).get();
    final days = await _database.select(_database.adherenceDays).get();
    final water = await (_database.select(
      _database.waterLogs,
    )..where((t) => t.state.equals(logConfirmed))).get();
    final summaries = await _database.select(_database.daySummaries).get();
    final weights = await _database.select(_database.weights).get();

    final waterByDate = <String, int>{};
    for (final row in water) {
      waterByDate[row.logDate] = (waterByDate[row.logDate] ?? 0) + row.amountMl;
    }
    final goals = <String, int?>{
      for (final row in summaries) row.summaryDate: row.goalMl,
    };
    final dated = summaries.where((s) => s.goalMl != null).toList()
      ..sort((a, b) => a.summaryDate.compareTo(b.summaryDate));
    return BadgeInputs(
      loggedMealIds: <int?>[for (final log in logs) log.mealId],
      dayStatuses: <String, String?>{
        for (final day in days) day.date: day.status,
      },
      waterByDate: waterByDate,
      waterGoalByDate: goals,
      latestWaterGoal: dated.isEmpty ? null : dated.last.goalMl,
      weightDates: <String>[for (final weight in weights) weight.measuredOn],
    );
  }

  /// Every badge, after storing the ones earned now. Running it twice gives
  /// the same rows: an earned badge keeps its first date and is never removed.
  Future<List<BadgeItem>> evaluate() async {
    final progress = evaluateBadges(await _inputs());
    final today = isoDate(dateOnly(_now()));
    await _database.batch((batch) {
      batch.insertAll(_database.earnedBadges, <db.EarnedBadgesCompanion>[
        for (final item in progress)
          if (item.earned)
            db.EarnedBadgesCompanion.insert(
              code: item.code.code,
              earnedOn: today,
            ),
      ], mode: InsertMode.insertOrIgnore);
    });
    final stored = {
      for (final row in await _database.select(_database.earnedBadges).get())
        row.code: row,
    };
    return <BadgeItem>[
      for (final item in progress)
        BadgeItem(
          // A stored badge stays earned even if its days left the cache.
          progress: stored.containsKey(item.code.code)
              ? BadgeProgress(
                  code: item.code,
                  current: item.target,
                  target: item.target,
                )
              : item,
          earnedOn: stored[item.code.code]?.earnedOn,
          seen: stored[item.code.code]?.seen ?? true,
        ),
    ];
  }

  Future<void> markSeen(Iterable<BadgeCode> codes) async {
    final list = <String>[for (final code in codes) code.code];
    if (list.isEmpty) {
      return;
    }
    await (_database.update(_database.earnedBadges)
          ..where((t) => t.code.isIn(list)))
        .write(const db.EarnedBadgesCompanion(seen: Value(true)));
  }
}

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService(
    ref.watch(appDatabaseProvider),
    now: ref.watch(planClockProvider),
  );
});

/// The grid's data; invalidated after each evaluation outside the grid.
final badgeBoardProvider = FutureProvider<List<BadgeItem>>((ref) {
  return ref.watch(badgeServiceProvider).evaluate();
});
