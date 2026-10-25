import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/generated/models/consumption_log_out.dart';
import '../api/generated/models/day_plan_out.dart';
import '../api/generated/models/meal_pref.dart';
import '../api/generated/models/sync_changes.dart';
import '../api/manual/sync_models.dart';
import '../db/app_database.dart';
import '../db/personal_data.dart';
import 'outbox_store.dart';
import 'sync_api.dart';

/// Where the next `since` of `GET /sync/changes` is kept.
abstract interface class SyncCursor {
  Future<DateTime?> read();

  Future<void> write(DateTime serverTime);

  Future<void> clear();
}

final class PreferencesSyncCursor implements SyncCursor {
  PreferencesSyncCursor({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<DateTime?> read() async {
    final value = (await _preferences()).getString(syncSincePreferenceKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> write(DateTime serverTime) async {
    await (await _preferences()).setString(
      syncSincePreferenceKey,
      wireInstant(serverTime),
    );
  }

  @override
  Future<void> clear() async {
    await (await _preferences()).remove(syncSincePreferenceKey);
  }
}

/// What the rest of the app does with the parts of the change feed that
/// belong to other features.
final class SyncHooks {
  const SyncHooks({
    required this.storePlans,
    required this.replacePrefs,
    required this.profileChanged,
    required this.fullRefresh,
    required this.todayChanged,
  });

  final Future<void> Function(List<DayPlanOut> plans) storePlans;
  final Future<void> Function(List<MealPref> prefs) replacePrefs;
  final Future<void> Function() profileChanged;

  /// The feed refused `since` as too old: reload plans and today.
  final Future<void> Function() fullRefresh;

  /// Logs changed on the server: reload today's totals.
  final Future<void> Function() todayChanged;

  static SyncHooks none = SyncHooks(
    storePlans: (_) async {},
    replacePrefs: (_) async {},
    profileChanged: () async {},
    fullRefresh: () async {},
    todayChanged: () async {},
  );
}

enum SyncOutcome { done, offline, failed }

/// Uploads the outbox, then pulls the change feed (Decision #264).
final class SyncEngine {
  SyncEngine({
    required this._database,
    required this._outbox,
    required this._api,
    required this._cursor,
    required this._hooks,
    int Function()? generation,
    DateTime Function()? now,
  }) : _generation = generation ?? (() => 0),
       _now = now ?? DateTime.now;

  static const batchLimit = 500;

  final AppDatabase _database;
  final OutboxStore _outbox;
  final SyncApi _api;
  final SyncCursor _cursor;
  final SyncHooks _hooks;
  final int Function() _generation;
  final DateTime Function() _now;

  /// True while operations are being sent.
  final ValueNotifier<bool> uploading = ValueNotifier<bool>(false);

  /// The outcome of the last run; [SyncOutcome.offline] keeps the
  /// "waiting for a connection" status on screen.
  final ValueNotifier<SyncOutcome?> lastOutcome = ValueNotifier<SyncOutcome?>(
    null,
  );

  Future<SyncOutcome>? _running;

  /// One run at a time; a second caller shares the run in flight.
  Future<SyncOutcome> syncNow() {
    final current = _running;
    if (current != null) {
      return current;
    }
    final future = _run();
    _running = future;
    return future.whenComplete(() {
      if (identical(_running, future)) {
        _running = null;
      }
    });
  }

  Future<SyncOutcome> _run() async {
    final seen = _generation();
    final upload = await _upload(seen);
    if (upload.outcome != SyncOutcome.done || seen != _generation()) {
      lastOutcome.value = upload.outcome;
      return upload.outcome;
    }
    final download = await _download(seen);
    if (seen != _generation()) {
      return download.outcome;
    }
    if (upload.logsChanged || download.logsChanged) {
      try {
        await _hooks.todayChanged();
      } on Object {
        // The cached totals stay until the next run.
      }
    }
    lastOutcome.value = download.outcome;
    return download.outcome;
  }

  Future<({SyncOutcome outcome, bool logsChanged})> _upload(int seen) async {
    var logsChanged = false;
    try {
      while (seen == _generation()) {
        final batch = await _outbox.pending(batchLimit);
        if (batch.isEmpty) {
          break;
        }
        uploading.value = true;
        final SyncBatchResult result;
        try {
          result = await _api.upload(<Map<String, Object?>>[
            for (final op in batch) op.payload,
          ]);
        } on SyncFailure catch (failure) {
          if (failure.kind == SyncFailureKind.transient) {
            await _outbox.markAttempt(<String>[
              for (final op in batch) op.opId,
            ], failure.code);
            return (outcome: SyncOutcome.offline, logsChanged: logsChanged);
          }
          if (failure.code == 'VALIDATION_ERROR') {
            // The body itself was refused. Send one operation at a time so
            // only the bad one is set aside.
            final isolated = await _uploadOneByOne(batch, seen);
            logsChanged = logsChanged || isolated.logsChanged;
            if (isolated.outcome != SyncOutcome.done) {
              return (outcome: isolated.outcome, logsChanged: logsChanged);
            }
            continue;
          }
          await _outbox.markAttempt(<String>[
            for (final op in batch) op.opId,
          ], failure.code);
          return (outcome: SyncOutcome.failed, logsChanged: logsChanged);
        }
        if (seen != _generation()) {
          break;
        }
        final applied = await _apply(batch, result.results);
        logsChanged = logsChanged || applied.logsChanged;
        if (applied.settled == 0) {
          // Nothing in the answer matched; do not resend in a loop.
          return (outcome: SyncOutcome.failed, logsChanged: logsChanged);
        }
      }
      return (outcome: SyncOutcome.done, logsChanged: logsChanged);
    } finally {
      uploading.value = false;
    }
  }

  Future<({SyncOutcome outcome, bool logsChanged})> _uploadOneByOne(
    List<QueuedOp> batch,
    int seen,
  ) async {
    var logsChanged = false;
    for (final op in batch) {
      if (seen != _generation()) {
        break;
      }
      try {
        final result = await _api.upload(<Map<String, Object?>>[op.payload]);
        final applied = await _apply(<QueuedOp>[op], result.results);
        logsChanged = logsChanged || applied.logsChanged;
      } on SyncFailure catch (failure) {
        if (failure.kind == SyncFailureKind.transient) {
          await _outbox.markAttempt(<String>[op.opId], failure.code);
          return (outcome: SyncOutcome.offline, logsChanged: logsChanged);
        }
        await _database.transaction(() async {
          await _reject(op, failure.code ?? 'VALIDATION_ERROR');
        });
      }
    }
    return (outcome: SyncOutcome.done, logsChanged: logsChanged);
  }

  /// Applies each result to its operation and the row it concerns.
  Future<({int settled, bool logsChanged})> _apply(
    List<QueuedOp> batch,
    List<SyncOpOutcome> results,
  ) async {
    final byId = <String, SyncOpOutcome>{
      for (final result in results) result.opId: result,
    };
    var settled = 0;
    var logsChanged = false;
    await _database.transaction(() async {
      for (final op in batch) {
        final result = byId[op.opId];
        if (result == null) {
          continue;
        }
        settled += 1;
        if (op.opType == 'CONSUMPTION_CREATE' ||
            op.opType == 'CONSUMPTION_DELETE') {
          logsChanged = true;
        }
        if (result.stored) {
          await _stored(op, result);
          await _outbox.remove(<String>[op.opId]);
        } else if (op.opType == 'CONSUMPTION_DELETE' &&
            result.code == 'LOG_NOT_FOUND') {
          // The server no longer has the log: the delete is done.
          await _deleteLogRow(op);
          await _outbox.remove(<String>[op.opId]);
        } else {
          await _reject(op, result.code ?? 'REJECTED');
        }
      }
    });
    return (settled: settled, logsChanged: logsChanged);
  }

  Future<void> _stored(QueuedOp op, SyncOpOutcome result) async {
    final clientUuid = op.clientUuid;
    switch (op.opType) {
      case 'CONSUMPTION_CREATE':
        if (clientUuid == null) {
          return;
        }
        final entityId = result.entityId;
        if (entityId != null) {
          // A row from the change feed may already hold this server id.
          await (_database.delete(_database.consumptionLogs)..where(
                (t) =>
                    t.serverLogId.equals(entityId) &
                    t.clientUuid.equals(clientUuid).not(),
              ))
              .go();
        }
        await (_database.update(
          _database.consumptionLogs,
        )..where((t) => t.clientUuid.equals(clientUuid))).write(
          ConsumptionLogsCompanion(
            serverLogId: Value(entityId),
            state: const Value(logConfirmed),
          ),
        );
      case 'CONSUMPTION_DELETE':
        await _deleteLogRow(op);
    }
  }

  Future<void> _deleteLogRow(QueuedOp op) async {
    final clientUuid = op.clientUuid;
    if (clientUuid == null) {
      return;
    }
    await (_database.delete(
      _database.consumptionLogs,
    )..where((t) => t.clientUuid.equals(clientUuid))).go();
  }

  Future<void> _reject(QueuedOp op, String code) async {
    if (op.opType == 'INTERACTION_CREATE') {
      // A refused learning event has nothing to show the user.
      await _outbox.remove(<String>[op.opId]);
      return;
    }
    await _outbox.markRejected(op.opId, code);
    final clientUuid = op.clientUuid;
    if (clientUuid == null) {
      return;
    }
    final state = switch (op.opType) {
      'CONSUMPTION_CREATE' => logRejected,
      // The delete failed: the log is still on the server.
      'CONSUMPTION_DELETE' => logConfirmed,
      _ => null,
    };
    if (state == null) {
      return;
    }
    await (_database.update(_database.consumptionLogs)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .write(ConsumptionLogsCompanion(state: Value(state)));
  }

  Future<({SyncOutcome outcome, bool logsChanged})> _download(int seen) async {
    final stored = await _cursor.read();
    final since =
        stored ??
        _now()
            .toUtc()
            .subtract(const Duration(days: 30))
            .add(const Duration(minutes: 5));
    try {
      final changes = await _changes(since);
      if (seen != _generation()) {
        return (outcome: SyncOutcome.done, logsChanged: false);
      }
      final logsChanged =
          changes.consumptionLogs.isNotEmpty ||
          changes.deletedConsumptionLogIds.isNotEmpty;
      await _database.transaction(() async {
        for (final log in changes.consumptionLogs) {
          await _upsertLog(log);
        }
        final deleted = changes.deletedConsumptionLogIds;
        if (deleted.isNotEmpty) {
          await (_database.delete(
            _database.consumptionLogs,
          )..where((t) => t.serverLogId.isIn(deleted))).go();
        }
      });
      await _hooks.replacePrefs(changes.mealPrefs);
      if (changes.plans.isNotEmpty) {
        await _hooks.storePlans(changes.plans);
      }
      if (changes.profileChanged) {
        await _hooks.profileChanged();
      }
      if (seen != _generation()) {
        return (outcome: SyncOutcome.done, logsChanged: false);
      }
      await _cursor.write(changes.serverTime);
      return (outcome: SyncOutcome.done, logsChanged: logsChanged);
    } on SyncFailure catch (failure) {
      if (failure.kind == SyncFailureKind.transient) {
        return (outcome: SyncOutcome.offline, logsChanged: false);
      }
      if (failure.code == 'VALIDATION_ERROR') {
        await _cursor.clear();
        try {
          await _hooks.fullRefresh();
        } on Object {
          return (outcome: SyncOutcome.offline, logsChanged: false);
        }
        return (outcome: SyncOutcome.done, logsChanged: true);
      }
      return (outcome: SyncOutcome.failed, logsChanged: false);
    }
  }

  Future<SyncChanges> _changes(DateTime since) async {
    try {
      return await _api.changes(since);
    } on SyncFailure catch (failure) {
      if (failure.code != 'CLOCK_SKEW') {
        rethrow;
      }
      return _api.changes(_now().toUtc().subtract(const Duration(minutes: 2)));
    }
  }

  Future<void> _upsertLog(ConsumptionLogOut log) async {
    final values = ConsumptionLogsCompanion(
      serverLogId: Value(log.logId),
      kind: Value(log.kind.json ?? 'MEAL'),
      planItemId: Value(log.planItemId),
      mealId: Value(log.mealId),
      logDate: Value(_isoDate(log.logDate)),
      slot: Value(log.slot?.json),
      servingsConsumed: Value(log.servingsConsumed?.toDouble()),
      consumedAt: Value(log.consumedAt.toUtc()),
      name: Value(log.name),
      kcal: Value(log.nutrients.kcal?.toDouble()),
      proteinG: Value(log.nutrients.proteinG?.toDouble()),
      carbG: Value(log.nutrients.carbG?.toDouble()),
      fatG: Value(log.nutrients.fatG?.toDouble()),
    );
    final existing = await (_database.select(
      _database.consumptionLogs,
    )..where((t) => t.serverLogId.equals(log.logId))).getSingleOrNull();
    if (existing != null) {
      // A log the user is deleting stays hidden until the delete is sent.
      await (_database.update(
        _database.consumptionLogs,
      )..where((t) => t.clientUuid.equals(existing.clientUuid))).write(
        values.copyWith(
          state: Value(
            existing.state == logDeleting ? logDeleting : logConfirmed,
          ),
        ),
      );
      return;
    }
    // The feed has no client id. A log stored from another device gets a
    // local key from its server id.
    await _database
        .into(_database.consumptionLogs)
        .insert(
          values.copyWith(
            clientUuid: Value('server-${log.logId}'),
            state: const Value(logConfirmed),
          ),
        );
  }
}

const logPending = 'PENDING';
const logConfirmed = 'CONFIRMED';
const logRejected = 'REJECTED';
const logDeleting = 'DELETING';

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
