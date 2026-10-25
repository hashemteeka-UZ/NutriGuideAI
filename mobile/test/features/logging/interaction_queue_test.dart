import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/features/logging/data/interaction_queue.dart';

void main() {
  late AppDatabase database;
  late OutboxStore outbox;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database);
  });

  tearDown(() => database.close());

  test('one IMPRESSION per plan item per day, with a stable id', () async {
    final queue = InteractionQueue(database, outbox);
    await queue.impression(planItemId: 5, mealId: 42, date: '2026-10-24');
    await queue.impression(planItemId: 5, mealId: 42, date: '2026-10-24');
    await queue.impression(planItemId: 5, mealId: 42, date: '2026-10-25');

    final ops = await outbox.pending(10);
    expect(ops, hasLength(2));
    expect(ops.first.payload['event_type'], 'IMPRESSION');
    expect(ops.first.payload['screen'], 'today');
    expect(ops.first.payload['plan_item_id'], 5);

    // A new run of the app derives the same id for the same day.
    final restarted = InteractionQueue(database, outbox);
    await outbox.remove(<String>[for (final op in ops) op.opId]);
    await restarted.impression(planItemId: 5, mealId: 42, date: '2026-10-24');
    final again = await outbox.pending(10);
    expect(again.single.clientUuid, ops.first.clientUuid);
  });

  test('RATE carries its value; 0 and 6 are refused (#301)', () async {
    final queue = InteractionQueue(database, outbox);
    await queue.rate(mealId: 42, value: 4, planItemId: 5, screen: 'today');
    await queue.rate(mealId: 42, value: 5, screen: 'plan_item');
    expect(
      () => queue.rate(mealId: 42, value: 0, screen: 'today'),
      throwsArgumentError,
    );
    expect(
      () => queue.rate(mealId: 42, value: 6, screen: 'today'),
      throwsArgumentError,
    );
    final ops = await outbox.pending(10);
    expect(ops, hasLength(2));
    expect(ops.first.opType, 'INTERACTION_CREATE');
    expect(ops.first.payload['event_type'], 'RATE');
    expect(ops.first.payload['value'], 4);
    expect(ops.first.payload['plan_item_id'], 5);
    expect(ops.first.payload['screen'], 'today');
    expect(ops.first.payload['meal_id'], 42);
    expect(ops.last.payload.containsKey('plan_item_id'), isFalse);
    // Each rating is a new event.
    expect(ops.first.clientUuid, isNot(ops.last.clientUuid));
  });

  test(
    'one SKIP per plan item and date, in memory and after a restart',
    () async {
      final queue = InteractionQueue(database, outbox);
      await queue.skip(planItemId: 5, mealId: 42, date: '2026-10-24');
      await queue.skip(planItemId: 5, mealId: 42, date: '2026-10-24');
      var ops = await outbox.pending(10);
      expect(ops, hasLength(1));
      expect(ops.single.payload['event_type'], 'SKIP');
      expect(ops.single.payload['plan_item_id'], 5);
      expect(ops.single.entityRef, 'skip:5:2026-10-24');

      // A new run while it is still queued: the outbox entity stops it.
      await InteractionQueue(
        database,
        outbox,
      ).skip(planItemId: 5, mealId: 42, date: '2026-10-24');
      ops = await outbox.pending(10);
      expect(ops, hasLength(1));

      // After it was sent, a new run derives the same id (the server says DUPLICATE).
      final sentId = ops.single.clientUuid;
      await outbox.remove(<String>[ops.single.opId]);
      await InteractionQueue(
        database,
        outbox,
      ).skip(planItemId: 5, mealId: 42, date: '2026-10-24');
      expect((await outbox.pending(10)).single.clientUuid, sentId);
    },
  );

  test('VIEW goes through the outbox, never ACCEPT', () async {
    final queue = InteractionQueue(database, outbox);
    await queue.view(mealId: 42, planItemId: 5);
    await queue.view(mealId: 43);
    final ops = await outbox.pending(10);
    expect(
      <Object?>[for (final op in ops) op.payload['event_type']],
      <String>['VIEW', 'VIEW'],
    );
    expect(ops.first.payload['screen'], 'meal_detail');
    expect(ops.last.payload.containsKey('plan_item_id'), isFalse);
    expect(ops.first.clientUuid, isNot(ops.last.clientUuid));
    expect((await outbox.counts()).pending, 0);
    expect((await outbox.counts()).events, 2);
  });
}
