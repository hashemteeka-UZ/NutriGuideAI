import 'package:drift/drift.dart';

import '../../../core/api/manual/sync_models.dart';
import '../../../core/db/app_database.dart' as db;
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/water.dart';
import 'water_api.dart';

/// The outbox key of a glass of water.
String waterRef(String clientUuid) => 'water:$clientUuid';

/// Glasses of water through the outbox (Decision #269), with the same
/// compaction rule as meals.
class WaterRepository {
  WaterRepository(
    this._database,
    this._outbox,
    this._api, {
    DateTime Function()? now,
    this._onAction,
  }) : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final OutboxStore _outbox;
  final WaterApi _api;
  final DateTime Function() _now;
  final void Function()? _onAction;

  /// Adds [amountMl] now: the row and its WATER_CREATE in one transaction.
  Future<void> add(int amountMl) async {
    if (amountMl < waterMinMl || amountMl > waterMaxMl) {
      throw const WaterException('VALIDATION_ERROR');
    }
    final at = _now();
    await _database.transaction(() async {
      final clientUuid = _outbox.newId();
      await _database
          .into(_database.waterLogs)
          .insert(
            db.WaterLogsCompanion.insert(
              clientUuid: clientUuid,
              amountMl: amountMl,
              consumedAt: at.toUtc(),
              logDate: isoDate(dateOnly(at)),
              state: logPending,
            ),
          );
      await _outbox.enqueue(
        WaterCreateOp(
          opId: _outbox.newId(),
          clientUuid: clientUuid,
          amountMl: amountMl,
          consumedAt: at,
        ),
        clientUuid: clientUuid,
        entityRef: waterRef(clientUuid),
      );
    });
    _onAction?.call();
  }

  /// Removes a glass. One the server has not confirmed leaves the outbox
  /// with its row; a confirmed one queues WATER_DELETE.
  Future<void> remove(String clientUuid) async {
    var queued = false;
    await _database.transaction(() async {
      final row = await (_database.select(
        _database.waterLogs,
      )..where((t) => t.clientUuid.equals(clientUuid))).getSingleOrNull();
      if (row == null || row.state == logDeleting) {
        return;
      }
      final serverId = row.serverLogId;
      if (serverId == null) {
        final ops = await _outbox.forEntity(waterRef(clientUuid));
        await _outbox.remove(<String>[for (final op in ops) op.opId]);
        await (_database.delete(
          _database.waterLogs,
        )..where((t) => t.clientUuid.equals(clientUuid))).go();
        return;
      }
      await (_database.update(_database.waterLogs)
            ..where((t) => t.clientUuid.equals(clientUuid)))
          .write(const db.WaterLogsCompanion(state: Value(logDeleting)));
      await _outbox.enqueue(
        WaterDeleteOp(opId: _outbox.newId(), logId: serverId),
        clientUuid: clientUuid,
        entityRef: waterRef(clientUuid),
      );
      queued = true;
    });
    if (queued) {
      _onAction?.call();
    }
  }

  /// `GET /water` for [date]: the server total and goal go to the day
  /// summary, and the server's glasses replace the confirmed rows.
  Future<void> refresh(DateTime date) async {
    final day = await _api.day(date);
    final iso = isoDate(dateOnly(date));
    final fetchedAt = _now().toUtc();
    await _database.transaction(() async {
      final water = db.DaySummariesCompanion(
        totalMl: Value(day.totalMl),
        goalMl: Value(day.goal.goalMl),
        requiresClinician: Value(day.goal.requiresClinician),
        waterSource: Value(day.goal.source.json),
      );
      final updated = await (_database.update(
        _database.daySummaries,
      )..where((t) => t.summaryDate.equals(iso))).write(water);
      if (updated == 0) {
        await _database
            .into(_database.daySummaries)
            .insert(
              water.copyWith(
                summaryDate: Value(iso),
                planItemsTotal: const Value(0),
                planItemsConsumed: const Value(0),
                fetchedAt: Value(fetchedAt),
              ),
            );
      }
      final serverIds = <int>{for (final log in day.logs) log.logId};
      for (final log in day.logs) {
        await upsertServerWater(
          _database,
          logId: log.logId,
          amountMl: log.amountMl,
          consumedAt: log.consumedAt,
        );
      }
      // Confirmed glasses of that day the server no longer lists.
      await (_database.delete(_database.waterLogs)..where(
            (t) =>
                t.logDate.equals(iso) &
                t.state.equals(logConfirmed) &
                t.serverLogId.isNotIn(serverIds),
          ))
          .go();
    });
  }

  /// The amount the doctor set, online only (Decision #270).
  Future<void> setGoal(int goalMl) async {
    if (goalMl < waterGoalMinMl || goalMl > waterGoalMaxMl) {
      throw const WaterException('VALIDATION_ERROR');
    }
    await _api.setGoal(goalMl);
    await refresh(_now());
  }

  Stream<List<WaterEntry>> watchDate(String date) {
    final query = _database.select(_database.waterLogs)
      ..where((t) => t.logDate.equals(date));
    return query.watch().map(
      (List<db.WaterLog> rows) => <WaterEntry>[
        for (final row in rows)
          WaterEntry(
            clientUuid: row.clientUuid,
            serverLogId: row.serverLogId,
            amountMl: row.amountMl,
            consumedAt: row.consumedAt,
            state: row.state,
          ),
      ],
    );
  }
}
