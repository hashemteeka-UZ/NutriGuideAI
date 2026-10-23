// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'food_log.dart';
import 'meal_log.dart';
import 'meal_slot.dart';
import 'plan_item_log.dart';


part 'sync_consumption_create_log_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class SyncConsumptionCreateLogSealed {
  const SyncConsumptionCreateLogSealed();
  
  factory SyncConsumptionCreateLogSealed.fromJson(Map<String, dynamic> json) =>
      SyncConsumptionCreateLogSealedDeserializer.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}

extension SyncConsumptionCreateLogSealedDeserializer on SyncConsumptionCreateLogSealed {
  static SyncConsumptionCreateLogSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'kind',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      SyncConsumptionCreateLogSealedFoodLog: 'FOOD',
      SyncConsumptionCreateLogSealedMealLog: 'MEAL',
      SyncConsumptionCreateLogSealedPlanItemLog: 'PLAN_ITEM',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[SyncConsumptionCreateLogSealedFoodLog] => SyncConsumptionCreateLogSealedFoodLog.fromJson(json),
      _ when value == effective[SyncConsumptionCreateLogSealedMealLog] => SyncConsumptionCreateLogSealedMealLog.fromJson(json),
      _ when value == effective[SyncConsumptionCreateLogSealedPlanItemLog] => SyncConsumptionCreateLogSealedPlanItemLog.fromJson(json),
      _ => throw FormatException('Unknown discriminator value "${json[key]}" for SyncConsumptionCreateLogSealed'),
    };
  }
}

@JsonSerializable()
class SyncConsumptionCreateLogSealedFoodLog extends SyncConsumptionCreateLogSealed implements FoodLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final int foodId;
  @override
  final num gramsConsumed;
  @override
  final String kind;
  @override
  final MealSlot? slot;

  const SyncConsumptionCreateLogSealedFoodLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.foodId,
    required this.gramsConsumed,
    required this.kind,
    required this.slot,
  });
  
  factory SyncConsumptionCreateLogSealedFoodLog.fromJson(Map<String, dynamic> json) =>
      _$SyncConsumptionCreateLogSealedFoodLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncConsumptionCreateLogSealedFoodLogToJson(this);
}
@JsonSerializable()
class SyncConsumptionCreateLogSealedMealLog extends SyncConsumptionCreateLogSealed implements MealLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final String kind;
  @override
  final int mealId;
  @override
  final num servingsConsumed;
  @override
  final MealSlot? slot;

  const SyncConsumptionCreateLogSealedMealLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.mealId,
    required this.servingsConsumed,
    required this.slot,
  });
  
  factory SyncConsumptionCreateLogSealedMealLog.fromJson(Map<String, dynamic> json) =>
      _$SyncConsumptionCreateLogSealedMealLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncConsumptionCreateLogSealedMealLogToJson(this);
}
@JsonSerializable()
class SyncConsumptionCreateLogSealedPlanItemLog extends SyncConsumptionCreateLogSealed implements PlanItemLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final String kind;
  @override
  final int planItemId;
  @override
  final num servingsConsumed;

  const SyncConsumptionCreateLogSealedPlanItemLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.planItemId,
    required this.servingsConsumed,
  });
  
  factory SyncConsumptionCreateLogSealedPlanItemLog.fromJson(Map<String, dynamic> json) =>
      _$SyncConsumptionCreateLogSealedPlanItemLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$SyncConsumptionCreateLogSealedPlanItemLogToJson(this);
}
