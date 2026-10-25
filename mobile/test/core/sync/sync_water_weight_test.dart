import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/sync_changes.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/core/sync/sync_api.dart';
import 'package:nutriguide/core/sync/sync_engine.dart';
import 'package:nutriguide/features/water/data/water_repository.dart';
import 'package:nutriguide/features/weight/data/weight_repository.dart';

import '../../support/pump_app.dart';

final _now = DateTime(2026, 10, 25, 9);

void main() {
  late AppDatabase database;
  late OutboxStore outbox;
  late _Api api;
  var weightHooks = 0;

  SyncEngine engine() {
    return SyncEngine(
      database: database,
      outbox: outbox,
      api: api,
      cursor: _Cursor(),
      hooks: SyncHooks(
        storePlans: (_) async {},
        replacePrefs: (_) async {},
        profileChanged: () async {},
        fullRefresh: () async {},
        todayChanged: () async {},
        weightConfirmed: () async => weightHooks += 1,
      ),
      now: () => _now,
    );
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database, now: () => _now);
    api = _Api();
    weightHooks = 0;
  });

  tearDown(() => database.close());

  test('a CREATED glass keeps its server id and is confirmed', () async {
    final water = WaterRepository(
      database,
      outbox,
      OfflineWaterApi(),
      now: () => _now,
    );
    await water.add(250);
    api.answer = (ops) => <SyncOpOutcome>[
      SyncOpOutcome(
        opId: '${ops.single['op_id']}',
        status: SyncOpStatus.created,
        entityId: 40,
      ),
    ];
    await engine().syncNow();
    final row = await database.select(database.waterLogs).getSingle();
    expect(row.serverLogId, 40);
    expect(row.state, 'CONFIRMED');
    expect(await outbox.pending(10), isEmpty);
  });

  test('the feed upserts glasses by id and drops deleted ids', () async {
    await database
        .into(database.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            clientUuid: 'mine',
            serverLogId: const Value(3),
            amountMl: 250,
            consumedAt: _now.toUtc(),
            logDate: '2026-10-25',
            state: 'CONFIRMED',
          ),
        );
    await database
        .into(database.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            clientUuid: 'gone',
            serverLogId: const Value(9),
            amountMl: 150,
            consumedAt: _now.toUtc(),
            logDate: '2026-10-25',
            state: 'CONFIRMED',
          ),
        );
    api.feed = _feed(
      water: <Map<String, Object?>>[
        <String, Object?>{
          'log_id': 3,
          'amount_ml': 300,
          'consumed_at': '2026-10-25T06:00:00Z',
        },
        <String, Object?>{
          'log_id': 4,
          'amount_ml': 500,
          'consumed_at': '2026-10-25T07:00:00Z',
        },
      ],
      deletedWater: <int>[9],
    );
    await engine().syncNow();
    final rows = {
      for (final row in await database.select(database.waterLogs).get())
        row.clientUuid: row,
    };
    expect(rows.keys.toSet(), <String>{'mine', 'server-4'});
    expect(rows['mine']!.amountMl, 300);
    expect(rows['server-4']!.amountMl, 500);
  });

  test('feed weights are stored by date; a pending local one stays', () async {
    final weights = WeightRepository(
      database,
      outbox,
      OfflineWeightApi(),
      now: () => _now,
    );
    await weights.save(79.4);
    api.failUploads = true;
    api.feed = _feed(
      weights: <Map<String, Object?>>[
        <String, Object?>{'measured_on': '2026-10-25', 'weight_kg': 80.0},
        <String, Object?>{'measured_on': '2026-10-20', 'weight_kg': 81.0},
      ],
    );
    // The upload fails, so the run stops before the feed: send the feed
    // through a second engine run without uploads.
    await engine().syncNow();
    api.failUploads = false;
    await database.delete(database.outbox).go();
    await engine().syncNow();
    final rows = {
      for (final row in await database.select(database.weights).get())
        row.measuredOn: row,
    };
    expect(rows['2026-10-25']!.weightKg, 79.4);
    expect(rows['2026-10-25']!.state, 'PENDING');
    expect(rows['2026-10-20']!.weightKg, 81.0);
    expect(rows['2026-10-20']!.state, 'CONFIRMED');
  });

  test('a stored WEIGHT_PUT confirms the row and asks for targets', () async {
    final weights = WeightRepository(
      database,
      outbox,
      OfflineWeightApi(),
      now: () => _now,
    );
    await weights.save(78.2);
    api.answer = (ops) => <SyncOpOutcome>[
      SyncOpOutcome(
        opId: '${ops.single['op_id']}',
        status: SyncOpStatus.updated,
      ),
    ];
    await engine().syncNow();
    final row = await database.select(database.weights).getSingle();
    expect(row.state, 'CONFIRMED');
    expect(weightHooks, 1);
  });
}

SyncChanges _feed({
  List<Map<String, Object?>> water = const <Map<String, Object?>>[],
  List<int> deletedWater = const <int>[],
  List<Map<String, Object?>> weights = const <Map<String, Object?>>[],
}) {
  return SyncChanges.fromJson(<String, Object?>{
    'server_time': '2026-10-25T07:00:05Z',
    'consumption_logs': const <Object?>[],
    'deleted_consumption_log_ids': const <Object?>[],
    'water_logs': water,
    'deleted_water_log_ids': deletedWater,
    'weights': weights,
    'plans': const <Object?>[],
    'meal_prefs': const <Object?>[],
    'profile_changed': false,
  });
}

class _Api implements SyncApi {
  List<SyncOpOutcome> Function(List<Map<String, Object?>> ops) answer = (ops) =>
      <SyncOpOutcome>[
        for (final op in ops)
          SyncOpOutcome(opId: '${op['op_id']}', status: SyncOpStatus.created),
      ];
  SyncChanges? feed;
  bool failUploads = false;

  @override
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations) async {
    if (failUploads) {
      throw const SyncFailure(SyncFailureKind.transient);
    }
    return SyncBatchResult(
      results: answer(operations),
      serverTime: DateTime.utc(2026, 10, 25, 7),
    );
  }

  @override
  Future<SyncChanges> changes(DateTime since) async => feed ?? _feed();
}

class _Cursor implements SyncCursor {
  DateTime? value;

  @override
  Future<DateTime?> read() async => value;

  @override
  Future<void> write(DateTime serverTime) async => value = serverTime;

  @override
  Future<void> clear() async => value = null;
}
