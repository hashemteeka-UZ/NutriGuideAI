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
