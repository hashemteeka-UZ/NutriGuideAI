// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';

part 'sync_consumption_correct.g.dart';

@JsonSerializable()
class SyncConsumptionCorrect {
  const SyncConsumptionCorrect({
    required this.logId,
    required this.newClientUuid,
    required this.op,
    required this.opId,
    this.consumedAt,
    this.gramsConsumed,
    this.servingsConsumed,
    this.slot,
  });
  
  factory SyncConsumptionCorrect.fromJson(Map<String, Object?> json) => _$SyncConsumptionCorrectFromJson(json);
  
  @JsonKey(name: 'consumed_at')
  final DateTime? consumedAt;
  @JsonKey(name: 'grams_consumed')
  final num? gramsConsumed;
  @JsonKey(name: 'log_id')
  final int logId;
  @JsonKey(name: 'new_client_uuid')
  final String newClientUuid;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;
  @JsonKey(name: 'servings_consumed')
  final num? servingsConsumed;
  final MealSlot? slot;

  Map<String, Object?> toJson() => _$SyncConsumptionCorrectToJson(this);
}
