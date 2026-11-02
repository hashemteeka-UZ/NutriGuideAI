// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';

part 'food_log.g.dart';

@JsonSerializable()
class FoodLog {
  const FoodLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.foodId,
    required this.gramsConsumed,
    required this.kind,
    this.slot,
  });
  
  factory FoodLog.fromJson(Map<String, Object?> json) => _$FoodLogFromJson(json);
  
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  @JsonKey(name: 'food_id')
  final int foodId;
  @JsonKey(name: 'grams_consumed')
  final num gramsConsumed;
  final String kind;
  final MealSlot? slot;

  Map<String, Object?> toJson() => _$FoodLogToJson(this);
}
