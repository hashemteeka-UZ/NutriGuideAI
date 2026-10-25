import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/day_plan_out.dart';
import 'package:nutriguide/core/api/generated/models/meal_pref.dart';
import 'package:nutriguide/core/api/generated/models/sync_changes.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/core/sync/sync_api.dart';
import 'package:nutriguide/core/sync/sync_engine.dart';
import 'package:nutriguide/features/logging/data/logging_repository.dart';

import '../../support/plan_samples.dart';

final _now = DateTime.utc(2026, 10, 24, 9);

void main() {
  late AppDatabase database;
  late OutboxStore outbox;
  late LoggingRepository logging;
  late _FakeSyncApi api;
  late _MemoryCursor cursor;
  late _HookLog hooks;

  SyncEngine engine() {
    return SyncEngine(
      database: database,
      outbox: outbox,
      api: api,
      cursor: cursor,
      hooks: hooks.hooks(),
      now: () => _now,
    );
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database, now: () => _now);
    logging = LoggingRepository(database, outbox, now: () => _now);
    api = _FakeSyncApi();
    cursor = _MemoryCursor();
    hooks = _HookLog();
  });

  tearDown(() => database.close());

  Future<List<ConsumptionLog>> logs() {
    return database.select(database.consumptionLogs).get();
  }

  test('uploads in order and stores the server id of a CREATED log', () async {
    await logging.logPlanItem(sampleItem(planItemId: 1));
    await logging.logPlanItem(sampleItem(planItemId: 2));
    api.answer = (List<Map<String, Object?>> ops) => <SyncOpOutcome>[
      for (var i = 0; i < ops.length; i++)
        SyncOpOutcome(
          opId: '${ops[i]['op_id']}',
          status: SyncOpStatus.created,
          entityId: 100 + i,
        ),
    ];

    expect(await engine().syncNow(), SyncOutcome.done);

    final sent = api.batches.single;
    expect(
      <Object?>[for (final op in sent) (op['log']! as Map)['plan_item_id']],
      <int>[1, 2],
    );
    final rows = await logs();
    expect(<int?>{for (final row in rows) row.serverLogId}, <int>{100, 101});
    expect(rows.every((row) => row.state == 'CONFIRMED'), isTrue);
    expect(await outbox.pending(10), isEmpty);
    expect(cursor.value, _serverTime);
    expect(hooks.todayRefreshed, 1);
  });

  test('a network failure resends the same batch with the same ids', () async {
    await logging.logPlanItem(sampleItem(planItemId: 1));
    api.failUploads = 1;

    expect(await engine().syncNow(), SyncOutcome.offline);
    expect(await outbox.pending(10), hasLength(1));

    api.answer = _created;
    expect(await engine().syncNow(), SyncOutcome.done);
    expect(api.batches, hasLength(2));
    expect(api.batches[0].single['op_id'], api.batches[1].single['op_id']);
    expect(
      (api.batches[0].single['log']! as Map)['client_uuid'],
      (api.batches[1].single['log']! as Map)['client_uuid'],
    );
    final attempts = await database.select(database.outbox).get();
    expect(attempts, isEmpty);
  });

  test('DUPLICATE counts as stored', () async {
    await logging.logPlanItem(sampleItem(planItemId: 1));
    api.answer = (ops) => <SyncOpOutcome>[
      SyncOpOutcome(
        opId: '${ops.single['op_id']}',
        status: SyncOpStatus.duplicate,
        entityId: 55,
      ),
    ];
    await engine().syncNow();
    expect((await logs()).single.serverLogId, 55);
    expect(await outbox.pending(10), isEmpty);
  });

  test('REJECTED is kept with its code and never sent again', () async {
    await logging.logPlanItem(sampleItem(planItemId: 1));
    api.answer = (ops) => <SyncOpOutcome>[
      SyncOpOutcome(
        opId: '${ops.single['op_id']}',
        status: SyncOpStatus.rejected,
        code: 'PLAN_ITEM_NOT_FOUND',
      ),
    ];
    await engine().syncNow();
    await engine().syncNow();

    expect(api.batches, hasLength(1));
    expect((await logs()).single.state, 'REJECTED');
    final rejected = await outbox.rejected();
    expect(rejected.single.lastErrorCode, 'PLAN_ITEM_NOT_FOUND');
    expect((await outbox.counts()).rejected, 1);
  });

  test('501 operations go in two batches of 500 and 1', () async {
    await database.transaction(() async {
      for (var i = 0; i < 501; i++) {
        await outbox.enqueue(
          InteractionCreateOp(
            opId: outbox.newId(),
            clientUuid: outbox.newId(),
            mealId: i,
            eventType: 'VIEW',
          ),
        );
      }
    });
    api.answer = _created;
    await engine().syncNow();
    expect(<int>[for (final batch in api.batches) batch.length], <int>[500, 1]);
    expect((api.batches[1].single)['meal_id'], 500);
  });

  test('changes upsert logs by id and drop deleted ids', () async {
    await database
        .into(database.consumptionLogs)
        .insert(
          ConsumptionLogsCompanion.insert(
            clientUuid: 'mine',
            serverLogId: const Value(21),
            kind: 'PLAN_ITEM',
            logDate: '2026-10-24',
            consumedAt: _now,
            state: 'CONFIRMED',
          ),
        );
    await database
        .into(database.consumptionLogs)
        .insert(
          ConsumptionLogsCompanion.insert(
            clientUuid: 'gone',
            serverLogId: const Value(30),
            kind: 'MEAL',
            logDate: '2026-10-24',
            consumedAt: _now,
            state: 'CONFIRMED',
          ),
        );
    api.feed = _changes(
      logs: <Map<String, Object?>>[_log(21, kcal: 310), _log(22, kcal: 120)],
      deleted: <int>[30],
    );
    await engine().syncNow();

    final rows = {for (final row in await logs()) row.clientUuid: row};
    expect(rows.keys.toSet(), <String>{'mine', 'server-22'});
    expect(rows['mine']!.kcal, 310);
    expect(rows['server-22']!.kcal, 120);
    expect(hooks.prefs, 1);
    expect(hooks.todayRefreshed, 1);
  });

  test('the first download asks for 29 days, a day inside the limit', () async {
    await engine().syncNow();
    expect(api.sinces.single, _now.subtract(const Duration(days: 29)));
  });

  test('CLOCK_SKEW retries once two minutes back', () async {
    cursor.value = _now.add(const Duration(hours: 1));
    api.changesFailures.add('CLOCK_SKEW');
    expect(await engine().syncNow(), SyncOutcome.done);
    expect(api.sinces, hasLength(2));
    expect(api.sinces.last, _now.subtract(const Duration(minutes: 2)));
  });

  test('VALIDATION_ERROR resets since and reloads everything', () async {
    cursor.value = _now.subtract(const Duration(days: 40));
    api.changesFailures.add('VALIDATION_ERROR');
    await engine().syncNow();
    expect(cursor.value, isNull);
    expect(hooks.fullRefreshes, 1);
  });

  test('profile_changed refetches the profile', () async {
    api.feed = _changes(profileChanged: true);
    await engine().syncNow();
    expect(hooks.profileChanges, 1);
  });

  test('concurrent syncNow calls share one run', () async {
    await logging.logPlanItem(sampleItem(planItemId: 1));
    final gate = Completer<void>();
    api.gate = gate.future;
    api.answer = _created;
    final sync = engine();
    final first = sync.syncNow();
    final second = sync.syncNow();
    gate.complete();
    await Future.wait(<Future<SyncOutcome>>[first, second]);
    expect(api.batches, hasLength(1));
    expect(api.sinces, hasLength(1));
  });

  test('a delete the server no longer has is done, not rejected', () async {
    await database
        .into(database.consumptionLogs)
        .insert(
          ConsumptionLogsCompanion.insert(
            clientUuid: 'c-1',
            serverLogId: const Value(21),
            kind: 'PLAN_ITEM',
            planItemId: const Value(4),
            logDate: '2026-10-24',
            consumedAt: _now,
            state: 'CONFIRMED',
          ),
        );
    await logging.undo(4);
    api.answer = (ops) => <SyncOpOutcome>[
      SyncOpOutcome(
        opId: '${ops.single['op_id']}',
        status: SyncOpStatus.rejected,
        code: 'LOG_NOT_FOUND',
      ),
    ];
    await engine().syncNow();
    expect(await logs(), isEmpty);
    expect((await outbox.counts()).rejected, 0);
  });
}

final _serverTime = DateTime.utc(2026, 10, 24, 9, 0, 5);

List<SyncOpOutcome> _created(List<Map<String, Object?>> ops) {
  return <SyncOpOutcome>[
    for (final op in ops)
      SyncOpOutcome(opId: '${op['op_id']}', status: SyncOpStatus.created),
  ];
}

Map<String, Object?> _log(int id, {required double kcal}) {
  return <String, Object?>{
    'log_id': id,
    'kind': 'PLAN_ITEM',
    'log_date': '2026-10-24',
    'consumed_at': '2026-10-24T08:15:00Z',
    'name': 'meal $id',
    'nutrients': <String, Object?>{'kcal': kcal},
    'status': 'CREATED',
    'plan_item_id': id,
    'servings_consumed': 1,
    'slot': 'BREAKFAST',
  };
}

SyncChanges _changes({
  List<Map<String, Object?>> logs = const <Map<String, Object?>>[],
  List<int> deleted = const <int>[],
  bool profileChanged = false,
}) {
  return SyncChanges.fromJson(<String, Object?>{
    'server_time': _serverTime.toIso8601String(),
    'consumption_logs': logs,
    'deleted_consumption_log_ids': deleted,
    'water_logs': const <Object?>[],
    'deleted_water_log_ids': const <Object?>[],
    'weights': const <Object?>[],
    'plans': const <Object?>[],
    'meal_prefs': const <Object?>[],
    'profile_changed': profileChanged,
  });
}

class _FakeSyncApi implements SyncApi {
  final List<List<Map<String, Object?>>> batches = [];
  final List<DateTime> sinces = [];
  final List<String> changesFailures = [];
  List<SyncOpOutcome> Function(List<Map<String, Object?>> ops) answer =
      _created;
  int failUploads = 0;
  SyncChanges? feed;
  Future<void>? gate;

  @override
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations) async {
    await gate;
    batches.add(<Map<String, Object?>>[...operations]);
    if (failUploads > 0) {
      failUploads -= 1;
      throw const SyncFailure(SyncFailureKind.transient);
    }
    return SyncBatchResult(
      results: answer(operations),
      serverTime: _serverTime,
    );
  }

  @override
  Future<SyncChanges> changes(DateTime since) async {
    sinces.add(since);
    if (changesFailures.isNotEmpty) {
      throw SyncFailure(
        SyncFailureKind.refused,
        code: changesFailures.removeAt(0),
      );
    }
    return feed ?? _changes();
  }
}

class _MemoryCursor implements SyncCursor {
  DateTime? value;

  @override
  Future<DateTime?> read() async => value;

  @override
  Future<void> write(DateTime serverTime) async => value = serverTime;

  @override
  Future<void> clear() async => value = null;
}

class _HookLog {
  int plans = 0;
  int prefs = 0;
  int profileChanges = 0;
  int fullRefreshes = 0;
  int todayRefreshed = 0;

  SyncHooks hooks() {
    return SyncHooks(
      storePlans: (List<DayPlanOut> _) async => plans += 1,
      replacePrefs: (List<MealPref> _) async => prefs += 1,
      profileChanged: () async => profileChanges += 1,
      fullRefresh: () async => fullRefreshes += 1,
      todayChanged: () async => todayRefreshed += 1,
    );
  }
}
