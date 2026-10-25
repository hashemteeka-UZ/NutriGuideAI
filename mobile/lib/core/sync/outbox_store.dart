import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/manual/sync_models.dart';
import '../db/app_database.dart';

const outboxPending = 'PENDING';
const outboxRejected = 'REJECTED';

/// One queued operation, read back for sending.
final class QueuedOp {
  const QueuedOp({
    required this.opId,
    required this.seq,
    required this.opType,
    required this.payload,
    required this.state,
    this.clientUuid,
    this.entityRef,
    this.lastErrorCode,
  });

  final String opId;
  final int seq;
  final String opType;
  final Map<String, Object?> payload;
  final String state;
  final String? clientUuid;
  final String? entityRef;
  final String? lastErrorCode;
}

/// Queued operations by state. Learning events are counted apart: they are
/// not the user's records, so the status and the logout question ignore
/// them.
final class OutboxCounts {
  const OutboxCounts({
    required this.pending,
    required this.rejected,
    this.events = 0,
  });

  final int pending;
  final int rejected;
  final int events;

  static const empty = OutboxCounts(pending: 0, rejected: 0);
}

/// The outbox table (Decision #263). Writers call [enqueue] inside the same
/// transaction as their own row so the action and its operation are stored
/// together or not at all.
class OutboxStore {
  OutboxStore(this._database, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final AppDatabase _database;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// A fresh UUID v4 for an `op_id` or a `client_uuid`.
  String newId() => _uuid.v4();

  /// Adds [op] after every queued operation. Call it inside a transaction.
  Future<void> enqueue(
    SyncOperation op, {
    String? clientUuid,
    String? entityRef,
  }) async {
    final last = await _database
        .customSelect('SELECT COALESCE(MAX(seq), 0) AS last FROM outbox')
        .getSingle();
    await _database
        .into(_database.outbox)
        .insert(
          OutboxCompanion.insert(
            opId: op.opId,
            seq: last.read<int>('last') + 1,
            opType: op.op,
            payloadJson: jsonEncode(op.toJson()),
            clientUuid: Value(clientUuid),
            entityRef: Value(entityRef),
            createdAt: _now().toUtc(),
            state: outboxPending,
          ),
        );
  }

  /// Up to [limit] pending operations in send order.
  Future<List<QueuedOp>> pending(int limit) async {
    final rows =
        await (_database.select(_database.outbox)
              ..where((t) => t.state.equals(outboxPending))
              ..orderBy(<OrderClauseGenerator<$OutboxTable>>[
                (t) => OrderingTerm.asc(t.seq),
              ])
              ..limit(limit))
            .get();
    return <QueuedOp>[for (final row in rows) _queued(row)];
  }

  Future<List<QueuedOp>> rejected() async {
    final rows =
        await (_database.select(_database.outbox)
              ..where((t) => t.state.equals(outboxRejected))
              ..orderBy(<OrderClauseGenerator<$OutboxTable>>[
                (t) => OrderingTerm.asc(t.seq),
              ]))
            .get();
    return <QueuedOp>[for (final row in rows) _queued(row)];
  }

  /// Queued operations that concern [entityRef], in send order.
  Future<List<QueuedOp>> forEntity(String entityRef) async {
    final rows =
        await (_database.select(_database.outbox)
              ..where((t) => t.entityRef.equals(entityRef))
              ..orderBy(<OrderClauseGenerator<$OutboxTable>>[
                (t) => OrderingTerm.asc(t.seq),
              ]))
            .get();
    return <QueuedOp>[for (final row in rows) _queued(row)];
  }

  Future<void> remove(Iterable<String> opIds) async {
    final ids = opIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await (_database.delete(
      _database.outbox,
    )..where((t) => t.opId.isIn(ids))).go();
  }

  Future<void> markRejected(String opId, String code) async {
    await (_database.update(
      _database.outbox,
    )..where((t) => t.opId.equals(opId))).write(
      OutboxCompanion(
        state: const Value(outboxRejected),
        lastErrorCode: Value(code),
      ),
    );
  }

  /// Counts one more send attempt for [opIds]; the ids and payloads stay.
  Future<void> markAttempt(Iterable<String> opIds, String? errorCode) async {
    final ids = opIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await _database.customUpdate(
      'UPDATE outbox SET attempts = attempts + 1, last_error_code = ? '
      'WHERE op_id IN (${List<String>.filled(ids.length, '?').join(', ')})',
      variables: <Variable<Object>>[
        Variable<String>(errorCode),
        for (final id in ids) Variable<String>(id),
      ],
      updates: <TableInfo<Table, Object?>>{_database.outbox},
    );
  }

  Future<OutboxCounts> counts() async {
    final rows = await _database.select(_database.outbox).get();
    return _count(rows);
  }

  Stream<OutboxCounts> watchCounts() {
    return _database.select(_database.outbox).watch().map(_count);
  }

  OutboxCounts _count(List<OutboxData> rows) {
    var pending = 0;
    var rejected = 0;
    var events = 0;
    for (final row in rows) {
      if (row.opType == 'INTERACTION_CREATE') {
        events += 1;
      } else if (row.state == outboxRejected) {
        rejected += 1;
      } else {
        pending += 1;
      }
    }
    return OutboxCounts(pending: pending, rejected: rejected, events: events);
  }

  QueuedOp _queued(OutboxData row) {
    final decoded = jsonDecode(row.payloadJson);
    return QueuedOp(
      opId: row.opId,
      seq: row.seq,
      opType: row.opType,
      payload: decoded is Map
          ? Map<String, Object?>.from(decoded)
          : const <String, Object?>{},
      state: row.state,
      clientUuid: row.clientUuid,
      entityRef: row.entityRef,
      lastErrorCode: row.lastErrorCode,
    );
  }
}

/// The outbox key of a consumption log.
String consumptionRef(String clientUuid) => 'consumption:$clientUuid';
