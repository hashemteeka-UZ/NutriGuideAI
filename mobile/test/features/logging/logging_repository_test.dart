import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/features/logging/data/logging_repository.dart';

import '../../support/plan_samples.dart';

void main() {
  late AppDatabase database;
  late OutboxStore outbox;
  late LoggingRepository repository;
  var actions = 0;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database, now: () => DateTime.utc(2026, 10, 24, 8));
    actions = 0;
    repository = LoggingRepository(
      database,
      outbox,
      now: () => DateTime(2026, 10, 24, 8, 30),
      onAction: () => actions += 1,
    );
  });

  tearDown(() => database.close());

  Future<List<ConsumptionLog>> logs() {
    return database.select(database.consumptionLogs).get();
  }

  test('logging stores the row and its operation together', () async {
    final item = sampleItem(planItemId: 7);
    await repository.logPlanItem(item);

    final rows = await logs();
    expect(rows.single.state, 'PENDING');
    expect(rows.single.planItemId, 7);
    expect(rows.single.servingsConsumed, 1);
    final queued = await outbox.pending(10);
    expect(queued.single.opType, 'CONSUMPTION_CREATE');
    expect(queued.single.clientUuid, rows.single.clientUuid);
    final log = queued.single.payload['log']! as Map<String, Object?>;
    expect(log['client_uuid'], rows.single.clientUuid);
    expect(log['plan_item_id'], 7);
    expect(
      log['consumed_at'],
      DateTime(2026, 10, 24, 8, 30).toUtc().toIso8601String(),
    );
    expect(log['consumed_at'], endsWith('Z'));
    expect(actions, 1);

    // A second tap on an eaten item queues nothing.
    await repository.logPlanItem(item);
    expect(await logs(), hasLength(1));
    expect(await outbox.pending(10), hasLength(1));
  });

  test('a failing outbox write leaves no log behind', () async {
    final failing = LoggingRepository(database, _FailingOutbox(database));
    await expectLater(
      failing.logPlanItem(sampleItem(planItemId: 3)),
      throwsA(isA<StateError>()),
    );
    expect(await logs(), isEmpty);
    expect(await outbox.pending(10), isEmpty);
  });

  test('half a portion logs half the planned servings', () async {
    await repository.logPlanItem(sampleItem(planItemId: 8), factor: 0.5);
    expect((await logs()).single.servingsConsumed, 0.5);
  });

  test('undo of a pending log drops the queued create, no delete', () async {
    await repository.logPlanItem(sampleItem(planItemId: 9));
    await repository.undo(9);
    expect(await logs(), isEmpty);
    expect(await outbox.pending(10), isEmpty);
    expect((await outbox.counts()).pending, 0);
  });

  test('undo of a confirmed log queues a delete with the server id', () async {
    await database
        .into(database.consumptionLogs)
        .insert(
          ConsumptionLogsCompanion.insert(
            clientUuid: 'c-1',
            serverLogId: const Value(21),
            kind: 'PLAN_ITEM',
            planItemId: const Value(4),
            logDate: '2026-10-24',
            consumedAt: DateTime.utc(2026, 10, 24, 6),
            state: 'CONFIRMED',
          ),
        );
    await repository.undo(4);

    expect((await logs()).single.state, 'DELETING');
    final queued = await outbox.pending(10);
    expect(queued.single.opType, 'CONSUMPTION_DELETE');
    expect(queued.single.payload['log_id'], 21);
    expect(queued.single.entityRef, consumptionRef('c-1'));
  });

  test('operations keep their send order', () async {
    await repository.logPlanItem(sampleItem(planItemId: 1));
    await repository.logPlanItem(sampleItem(planItemId: 2));
    await repository.logPlanItem(sampleItem(planItemId: 3));
    final queued = await outbox.pending(10);
    expect(<int>[for (final op in queued) op.seq], <int>[1, 2, 3]);
    expect(
      <Object?>[
        for (final op in queued)
          (op.payload['log']! as Map<String, Object?>)['plan_item_id'],
      ],
      <int>[1, 2, 3],
    );
  });
}

class _FailingOutbox extends OutboxStore {
  _FailingOutbox(super.database);

  @override
  Future<void> enqueue(
    SyncOperation op, {
    String? clientUuid,
    String? entityRef,
  }) async {
    throw StateError('disk full');
  }
}
