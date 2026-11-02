// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';
import 'sync_consumption_correct.dart';
import 'sync_consumption_create.dart';
import 'sync_consumption_delete.dart';
import 'sync_interaction_create.dart';
import 'sync_interaction_create_event_type.dart';
import 'sync_water_create.dart';
import 'sync_water_delete.dart';
import 'sync_weight_put.dart';


part 'sync_batch_operations_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class SyncBatchOperationsSealed {
  const SyncBatchOperationsSealed();
  
  factory SyncBatchOperationsSealed.fromJson(Map<String, dynamic> json) =>
      SyncBatchOperationsSealedDeserializer.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}

extension SyncBatchOperationsSealedDeserializer on SyncBatchOperationsSealed {
  static SyncBatchOperationsSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'op',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      SyncBatchOperationsSealedSyncConsumptionCorrect: 'CONSUMPTION_CORRECT',
      SyncBatchOperationsSealedSyncConsumptionCreate: 'CONSUMPTION_CREATE',
      SyncBatchOperationsSealedSyncConsumptionDelete: 'CONSUMPTION_DELETE',
      SyncBatchOperationsSealedSyncInteractionCreate: 'INTERACTION_CREATE',
      SyncBatchOperationsSealedSyncWaterCreate: 'WATER_CREATE',
      SyncBatchOperationsSealedSyncWaterDelete: 'WATER_DELETE',
      SyncBatchOperationsSealedSyncWeightPut: 'WEIGHT_PUT',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[SyncBatchOperationsSealedSyncConsumptionCorrect] => SyncBatchOperationsSealedSyncConsumptionCorrect.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncConsumptionCreate] => SyncBatchOperationsSealedSyncConsumptionCreate.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncConsumptionDelete] => SyncBatchOperationsSealedSyncConsumptionDelete.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncInteractionCreate] => SyncBatchOperationsSealedSyncInteractionCreate.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncWaterCreate] => SyncBatchOperationsSealedSyncWaterCreate.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncWaterDelete] => SyncBatchOperationsSealedSyncWaterDelete.fromJson(json),
      _ when value == effective[SyncBatchOperationsSealedSyncWeightPut] => SyncBatchOperationsSealedSyncWeightPut.fromJson(json),
      _ => throw FormatException('Unknown discriminator value "${json[key]}" for SyncBatchOperationsSealed'),
    };
  }
}

@JsonSerializable()
class SyncBatchOperationsSealedSyncConsumptionCorrect extends SyncBatchOperationsSealed implements SyncConsumptionCorrect {
  @override
  final DateTime? consumedAt;
  @override
  final num? gramsConsumed;
  @override
  final int logId;
  @override
  final String newClientUuid;
  @override
  final String op;
  @override
  final String opId;
  @override
  final num? servingsConsumed;
  @override
  final MealSlot? slot;

  const SyncBatchOperationsSealedSyncConsumptionCorrect({
    required this.consumedAt,
    required this.gramsConsumed,
    required this.logId,
    required this.newClientUuid,
    required this.op,
    required this.opId,
    required this.servingsConsumed,
    required this.slot,
  });
  
  factory SyncBatchOperationsSealedSyncConsumptionCorrect.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncConsumptionCorrectFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncConsumptionCorrectToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncConsumptionCreate extends SyncBatchOperationsSealed implements SyncConsumptionCreate {
  @override
  final SyncConsumptionCreateLogSealed log;
  @override
  final String op;
  @override
  final String opId;

  const SyncBatchOperationsSealedSyncConsumptionCreate({
    required this.log,
    required this.op,
    required this.opId,
  });
  
  factory SyncBatchOperationsSealedSyncConsumptionCreate.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncConsumptionCreateFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncConsumptionCreateToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncConsumptionDelete extends SyncBatchOperationsSealed implements SyncConsumptionDelete {
  @override
  final int logId;
  @override
  final String op;
  @override
  final String opId;

  const SyncBatchOperationsSealedSyncConsumptionDelete({
    required this.logId,
    required this.op,
    required this.opId,
  });
  
  factory SyncBatchOperationsSealedSyncConsumptionDelete.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncConsumptionDeleteFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncConsumptionDeleteToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncInteractionCreate extends SyncBatchOperationsSealed implements SyncInteractionCreate {
  @override
  final String clientUuid;
  @override
  final SyncInteractionCreateEventType eventType;
  @override
  final int mealId;
  @override
  final String op;
  @override
  final String opId;
  @override
  final int? planItemId;
  @override
  final String? screen;
  @override
  final int? value;

  const SyncBatchOperationsSealedSyncInteractionCreate({
    required this.clientUuid,
    required this.eventType,
    required this.mealId,
    required this.op,
    required this.opId,
    required this.planItemId,
    required this.screen,
    required this.value,
  });
  
  factory SyncBatchOperationsSealedSyncInteractionCreate.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncInteractionCreateFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncInteractionCreateToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncWaterCreate extends SyncBatchOperationsSealed implements SyncWaterCreate {
  @override
  final int amountMl;
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final String op;
  @override
  final String opId;

  const SyncBatchOperationsSealedSyncWaterCreate({
    required this.amountMl,
    required this.clientUuid,
    required this.consumedAt,
    required this.op,
    required this.opId,
  });
  
  factory SyncBatchOperationsSealedSyncWaterCreate.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncWaterCreateFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncWaterCreateToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncWaterDelete extends SyncBatchOperationsSealed implements SyncWaterDelete {
  @override
  final int logId;
  @override
  final String op;
  @override
  final String opId;

  const SyncBatchOperationsSealedSyncWaterDelete({
    required this.logId,
    required this.op,
    required this.opId,
  });
  
  factory SyncBatchOperationsSealedSyncWaterDelete.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncWaterDeleteFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncWaterDeleteToJson(this);
}
@JsonSerializable()
class SyncBatchOperationsSealedSyncWeightPut extends SyncBatchOperationsSealed implements SyncWeightPut {
  @override
  final DateTime measuredOn;
  @override
  final String op;
  @override
  final String opId;
  @override
  final DateTime updatedAt;
  @override
  final num weightKg;

  const SyncBatchOperationsSealedSyncWeightPut({
    required this.measuredOn,
    required this.op,
    required this.opId,
    required this.updatedAt,
    required this.weightKg,
  });
  
  factory SyncBatchOperationsSealedSyncWeightPut.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchOperationsSealedSyncWeightPutFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncBatchOperationsSealedSyncWeightPutToJson(this);
}
