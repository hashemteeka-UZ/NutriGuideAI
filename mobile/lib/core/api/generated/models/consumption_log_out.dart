// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'consumption_log_out_kind.dart';
import 'consumption_log_out_status.dart';
import 'meal_slot.dart';
import 'nutrient_totals.dart';

part 'consumption_log_out.g.dart';

@JsonSerializable()
class ConsumptionLogOut {
  const ConsumptionLogOut({
    required this.consumedAt,
    required this.kind,
    required this.logDate,
    required this.logId,
    required this.name,
    required this.nutrients,
    required this.status,
    this.foodId,
    this.gramsConsumed,
    this.mealId,
    this.planItemId,
    this.servingsConsumed,
    this.slot,
  });
  
  factory ConsumptionLogOut.fromJson(Map<String, Object?> json) => _$ConsumptionLogOutFromJson(json);
  
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  @JsonKey(name: 'food_id')
  final int? foodId;
  @JsonKey(name: 'grams_consumed')
  final num? gramsConsumed;
  final ConsumptionLogOutKind kind;
  @JsonKey(name: 'log_date')
  final DateTime logDate;
  @JsonKey(name: 'log_id')
  final int logId;
  @JsonKey(name: 'meal_id')
  final int? mealId;
  final String name;
  final NutrientTotals nutrients;
  @JsonKey(name: 'plan_item_id')
  final int? planItemId;
  @JsonKey(name: 'servings_consumed')
  final num? servingsConsumed;
  final MealSlot? slot;
  final ConsumptionLogOutStatus status;

  Map<String, Object?> toJson() => _$ConsumptionLogOutToJson(this);
}
