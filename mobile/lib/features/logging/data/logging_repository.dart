import 'package:drift/drift.dart';

import '../../../core/api/manual/sync_models.dart';
import '../../../core/db/app_database.dart' as db;
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../plan/domain/plan.dart';
import '../domain/logging.dart';

/// Logs and undoes plan meals (Decisions #263, #265). Each action stores its
/// row and its outbox operation in one transaction.
class LoggingRepository {
  LoggingRepository(
    this._database,
    this._outbox, {
    DateTime Function()? now,
    this._onAction,
  }) : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final OutboxStore _outbox;
  final DateTime Function() _now;
  final void Function()? _onAction;

  /// Logs [item] as eaten: [factor] of the planned portion, at
  /// [consumedAt] (now by default). A second tap on an eaten item does
  /// nothing.
  Future<void> logPlanItem(
    PlanItem item, {
    double factor = 1,
    DateTime? consumedAt,
  }) async {
    final servings = item.servingsMultiplier * factor;
    if (servings <= 0 || servings > 10) {
      throw const LoggingException('servings');
    }
    final at = consumedAt ?? _now();
    var queued = false;
    await _database.transaction(() async {
      final logs = await _rowsForItem(item.planItemId);
      if (logs.any((db.ConsumptionLog row) => row.state != logDeleting)) {
        return;
      }
      final clientUuid = _outbox.newId();
      await _database
          .into(_database.consumptionLogs)
          .insert(
            db.ConsumptionLogsCompanion.insert(
              clientUuid: clientUuid,
              kind: 'PLAN_ITEM',
              planItemId: Value(item.planItemId),
              mealId: Value(item.mealId),
              logDate: item.planDate,
              slot: Value(item.slot),
              servingsConsumed: Value(servings),
              consumedAt: at.toUtc(),
              name: Value(item.mealName),
              state: logPending,
            ),
          );
      await _outbox.enqueue(
        PlanItemLogCreateOp(
          opId: _outbox.newId(),
          clientUuid: clientUuid,
          planItemId: item.planItemId,
          servingsConsumed: servings,
          consumedAt: at,
        ),
        clientUuid: clientUuid,
        entityRef: consumptionRef(clientUuid),
      );
      queued = true;
    });
    if (queued) {
      _onAction?.call();
    }
  }

  /// Undoes the log of [planItemId]. A log the server has not confirmed is
  /// dropped together with its queued create; a confirmed log queues a
  /// delete (compaction, Decision #263).
  Future<void> undo(int planItemId) async {
    var queued = false;
    await _database.transaction(() async {
      final rows = await _rowsForItem(planItemId);
      for (final row in rows) {
        if (row.state == logDeleting) {
          continue;
        }
        final serverId = row.serverLogId;
        if (serverId == null) {
          await _dropUnsent(row.clientUuid);
          continue;
        }
        await (_database.update(
          _database.consumptionLogs,
        )..where((t) => t.clientUuid.equals(row.clientUuid))).write(
          const db.ConsumptionLogsCompanion(state: Value(logDeleting)),
        );
        await _outbox.enqueue(
          ConsumptionDeleteOp(opId: _outbox.newId(), logId: serverId),
          clientUuid: row.clientUuid,
          entityRef: consumptionRef(row.clientUuid),
        );
        queued = true;
      }
    });
    if (queued) {
      _onAction?.call();
    }
  }

  /// Drops a log the server refused, with its rejected operation.
  Future<void> discard(String clientUuid) async {
    await _database.transaction(() async {
      await _dropUnsent(clientUuid);
    });
  }

  Future<void> _dropUnsent(String clientUuid) async {
    final ops = await _outbox.forEntity(consumptionRef(clientUuid));
    await _outbox.remove(<String>[for (final op in ops) op.opId]);
    await (_database.delete(
      _database.consumptionLogs,
    )..where((t) => t.clientUuid.equals(clientUuid))).go();
  }

  Future<List<db.ConsumptionLog>> _rowsForItem(int planItemId) {
    return (_database.select(
      _database.consumptionLogs,
    )..where((t) => t.planItemId.equals(planItemId))).get();
  }

  Stream<List<LoggedMeal>> watchDate(String date) {
    final query = _database.select(_database.consumptionLogs)
      ..where((t) => t.logDate.equals(date));
    return query.watch().map(
      (List<db.ConsumptionLog> rows) => <LoggedMeal>[
        for (final row in rows) loggedMealFromRow(row),
      ],
    );
  }

  Future<List<RejectedLog>> rejectedLogs() async {
    final ops = await _outbox.rejected();
    final logs = <RejectedLog>[];
    for (final op in ops) {
      final clientUuid = op.clientUuid;
      if (clientUuid == null) {
        continue;
      }
      final row = await (_database.select(
        _database.consumptionLogs,
      )..where((t) => t.clientUuid.equals(clientUuid))).getSingleOrNull();
      logs.add(
        RejectedLog(
          clientUuid: clientUuid,
          code: op.lastErrorCode ?? 'REJECTED',
          mealName: row?.name,
          slot: row?.slot,
        ),
      );
    }
    return logs;
  }
}

LoggedMeal loggedMealFromRow(db.ConsumptionLog row) {
  return LoggedMeal(
    clientUuid: row.clientUuid,
    serverLogId: row.serverLogId,
    kind: row.kind,
    planItemId: row.planItemId,
    mealId: row.mealId,
    logDate: row.logDate,
    slot: row.slot,
    servingsConsumed: row.servingsConsumed,
    consumedAt: row.consumedAt,
    name: row.name,
    kcal: row.kcal,
    proteinG: row.proteinG,
    carbG: row.carbG,
    fatG: row.fatG,
    state: row.state,
  );
}
