import 'package:uuid/uuid.dart';

import '../../../core/api/manual/sync_models.dart';
import '../../../core/db/app_database.dart';
import '../../../core/sync/outbox_store.dart';

/// Learning events go through the outbox only (Decision #267).
class InteractionQueue {
  InteractionQueue(this._database, this._outbox, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final OutboxStore _outbox;
  final Uuid _uuid;
  final Set<String> _impressions = <String>{};
  final Set<String> _skips = <String>{};

  /// One IMPRESSION per plan item per day. The id is derived from the item,
  /// its meal and the date, so a repeat after a restart comes back from the
  /// server as DUPLICATE instead of a second event.
  Future<void> impression({
    required int planItemId,
    required int mealId,
    required String date,
  }) async {
    final key = '$planItemId:$mealId:$date';
    if (!_impressions.add(key)) {
      return;
    }
    final clientUuid = _uuid.v5(
      Namespace.url.value,
      'https://nutriguide.app/impression/$key',
    );
    final queued = await _outbox.forEntity('impression:$key');
    if (queued.isNotEmpty) {
      return;
    }
    await _queue(
      InteractionCreateOp(
        opId: _outbox.newId(),
        clientUuid: clientUuid,
        mealId: mealId,
        eventType: 'IMPRESSION',
        planItemId: planItemId,
        screen: 'today',
      ),
      entityRef: 'impression:$key',
    );
  }

  /// A VIEW when catalog or plan details open.
  Future<void> view({required int mealId, int? planItemId}) {
    return _queue(
      InteractionCreateOp(
        opId: _outbox.newId(),
        clientUuid: _outbox.newId(),
        mealId: mealId,
        eventType: 'VIEW',
        planItemId: planItemId,
        screen: 'meal_detail',
      ),
    );
  }

  /// A RATE from 1 to 5 (#301). Every rating is a new event with its own id.
  Future<void> rate({
    required int mealId,
    required int value,
    int? planItemId,
    required String screen,
  }) {
    if (value < 1 || value > 5) {
      throw ArgumentError.value(value, 'value', 'must be 1 to 5');
    }
    return _queue(
      InteractionCreateOp(
        opId: _outbox.newId(),
        clientUuid: _outbox.newId(),
        mealId: mealId,
        eventType: 'RATE',
        planItemId: planItemId,
        screen: screen,
        value: value,
      ),
    );
  }

  /// One SKIP («لم آكلها») per plan item and date (#301). The id is derived
  /// as for IMPRESSION, so a second tap or a restart cannot add a second one.
  Future<void> skip({
    required int planItemId,
    required int mealId,
    required String date,
  }) async {
    final key = '$planItemId:$date';
    if (!_skips.add(key)) {
      return;
    }
    final queued = await _outbox.forEntity('skip:$key');
    if (queued.isNotEmpty) {
      return;
    }
    await _queue(
      InteractionCreateOp(
        opId: _outbox.newId(),
        clientUuid: _uuid.v5(
          Namespace.url.value,
          'https://nutriguide.app/skip/$key',
        ),
        mealId: mealId,
        eventType: 'SKIP',
        planItemId: planItemId,
        screen: 'plan_item',
      ),
      entityRef: 'skip:$key',
    );
  }

  Future<void> _queue(InteractionCreateOp op, {String? entityRef}) {
    return _database.transaction(() {
      return _outbox.enqueue(
        op,
        clientUuid: op.clientUuid,
        entityRef: entityRef,
      );
    });
  }
}
