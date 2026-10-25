/// Hand-written wire models for `POST /api/v1/sync/batch` (Decision #262).
///
/// The generator skipped the operation union, so these classes write the
/// schemas from docs/api/openapi.json by hand. The contract test in
/// test/core/api/sync_models_contract_test.dart checks every operation
/// against that file.
library;

/// One operation of a `SyncBatch`. [opId] is a UUID v4 generated on the
/// phone and reused for every retry.
sealed class SyncOperation {
  const SyncOperation({required this.opId});

  final String opId;

  /// The `op` discriminator.
  String get op;

  Map<String, Object?> toJson();
}

/// `CONSUMPTION_CREATE` with a `PLAN_ITEM` log.
final class PlanItemLogCreateOp extends SyncOperation {
  const PlanItemLogCreateOp({
    required super.opId,
    required this.clientUuid,
    required this.planItemId,
    required this.servingsConsumed,
    required this.consumedAt,
  });

  final String clientUuid;
  final int planItemId;
  final double servingsConsumed;
  final DateTime consumedAt;

  @override
  String get op => 'CONSUMPTION_CREATE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'log': <String, Object?>{
      'kind': 'PLAN_ITEM',
      'client_uuid': clientUuid,
      'plan_item_id': planItemId,
      'servings_consumed': servingsConsumed,
      'consumed_at': wireInstant(consumedAt),
    },
  };
}

/// `CONSUMPTION_CREATE` with a `MEAL` log (used from K.5b).
final class MealLogCreateOp extends SyncOperation {
  const MealLogCreateOp({
    required super.opId,
    required this.clientUuid,
    required this.mealId,
    required this.servingsConsumed,
    required this.consumedAt,
    this.slot,
  });

  final String clientUuid;
  final int mealId;
  final double servingsConsumed;
  final DateTime consumedAt;

  /// BREAKFAST, LUNCH, DINNER or SNACK.
  final String? slot;

  @override
  String get op => 'CONSUMPTION_CREATE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'log': <String, Object?>{
      'kind': 'MEAL',
      'client_uuid': clientUuid,
      'meal_id': mealId,
      'servings_consumed': servingsConsumed,
      'consumed_at': wireInstant(consumedAt),
      'slot': ?slot,
    },
  };
}

/// `CONSUMPTION_DELETE` of a log the server confirmed.
final class ConsumptionDeleteOp extends SyncOperation {
  const ConsumptionDeleteOp({required super.opId, required this.logId});

  final int logId;

  @override
  String get op => 'CONSUMPTION_DELETE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'log_id': logId,
  };
}

final class WaterCreateOp extends SyncOperation {
  const WaterCreateOp({
    required super.opId,
    required this.clientUuid,
    required this.amountMl,
    required this.consumedAt,
  });

  final String clientUuid;
  final int amountMl;
  final DateTime consumedAt;

  @override
  String get op => 'WATER_CREATE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'client_uuid': clientUuid,
    'amount_ml': amountMl,
    'consumed_at': wireInstant(consumedAt),
  };
}

final class WaterDeleteOp extends SyncOperation {
  const WaterDeleteOp({required super.opId, required this.logId});

  final int logId;

  @override
  String get op => 'WATER_DELETE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'log_id': logId,
  };
}

final class WeightPutOp extends SyncOperation {
  const WeightPutOp({
    required super.opId,
    required this.measuredOn,
    required this.weightKg,
    required this.updatedAt,
  });

  /// Local calendar date, YYYY-MM-DD.
  final String measuredOn;
  final double weightKg;
  final DateTime updatedAt;

  @override
  String get op => 'WEIGHT_PUT';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'measured_on': measuredOn,
    'weight_kg': weightKg,
    'updated_at': wireInstant(updatedAt),
  };
}

/// `INTERACTION_CREATE`. The app never sends `ACCEPT`; the server writes it.
final class InteractionCreateOp extends SyncOperation {
  const InteractionCreateOp({
    required super.opId,
    required this.clientUuid,
    required this.mealId,
    required this.eventType,
    this.planItemId,
    this.screen,
    this.value,
  });

  final String clientUuid;
  final int mealId;

  /// IMPRESSION, VIEW, SAVE, RATE, COOK or SKIP.
  final String eventType;
  final int? planItemId;
  final String? screen;

  /// 1 to 5, only for RATE.
  final int? value;

  @override
  String get op => 'INTERACTION_CREATE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'op': op,
    'op_id': opId,
    'client_uuid': clientUuid,
    'meal_id': mealId,
    'event_type': eventType,
    'plan_item_id': ?planItemId,
    'screen': ?screen,
    'value': ?value,
  };
}

/// An ISO-8601 instant in UTC with a `Z` suffix.
String wireInstant(DateTime value) => value.toUtc().toIso8601String();

enum SyncOpStatus { created, updated, duplicate, rejected }

/// The result of one operation in a `SyncResult`.
final class SyncOpOutcome {
  const SyncOpOutcome({
    required this.opId,
    required this.status,
    this.code,
    this.entityId,
  });

  /// Parses one result. An unknown status is treated as rejected so the
  /// operation is kept and shown instead of being dropped.
  factory SyncOpOutcome.fromJson(Map<String, Object?> json) {
    final status = switch (json['status']) {
      'CREATED' => SyncOpStatus.created,
      'UPDATED' => SyncOpStatus.updated,
      'DUPLICATE' => SyncOpStatus.duplicate,
      _ => SyncOpStatus.rejected,
    };
    final code = json['code'];
    final entityId = json['entity_id'];
    return SyncOpOutcome(
      opId: '${json['op_id']}',
      status: status,
      code: code is String ? code : null,
      entityId: entityId is int ? entityId : null,
    );
  }

  final String opId;
  final SyncOpStatus status;
  final String? code;
  final int? entityId;

  bool get stored => status != SyncOpStatus.rejected;
}

final class SyncBatchResult {
  const SyncBatchResult({required this.results, required this.serverTime});

  factory SyncBatchResult.fromJson(Map<String, Object?> json) {
    final raw = json['results'];
    final serverTime = DateTime.tryParse('${json['server_time']}');
    if (raw is! List || serverTime == null) {
      throw const FormatException('SyncResult');
    }
    return SyncBatchResult(
      results: <SyncOpOutcome>[
        for (final Object? item in raw)
          if (item is Map)
            SyncOpOutcome.fromJson(Map<String, Object?>.from(item)),
      ],
      serverTime: serverTime,
    );
  }

  final List<SyncOpOutcome> results;
  final DateTime serverTime;
}
