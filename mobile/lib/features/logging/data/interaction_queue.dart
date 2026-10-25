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
