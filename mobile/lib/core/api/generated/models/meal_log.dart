// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';

part 'meal_log.g.dart';

@JsonSerializable()
class MealLog {
  const MealLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.mealId,
    required this.servingsConsumed,
    this.slot,
  });
  
  factory MealLog.fromJson(Map<String, Object?> json) => _$MealLogFromJson(json);
  
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  final String kind;
  @JsonKey(name: 'meal_id')
  final int mealId;
  @JsonKey(name: 'servings_consumed')
  final num servingsConsumed;
  final MealSlot? slot;

  Map<String, Object?> toJson() => _$MealLogToJson(this);
}
