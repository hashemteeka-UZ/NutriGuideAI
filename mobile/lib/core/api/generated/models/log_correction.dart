// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';

part 'log_correction.g.dart';

@JsonSerializable()
class LogCorrection {
  const LogCorrection({
    required this.newClientUuid,
    this.consumedAt,
    this.gramsConsumed,
    this.servingsConsumed,
    this.slot,
  });
  
  factory LogCorrection.fromJson(Map<String, Object?> json) => _$LogCorrectionFromJson(json);
  
  @JsonKey(name: 'consumed_at')
  final DateTime? consumedAt;
  @JsonKey(name: 'grams_consumed')
  final num? gramsConsumed;
  @JsonKey(name: 'new_client_uuid')
  final String newClientUuid;
  @JsonKey(name: 'servings_consumed')
  final num? servingsConsumed;
  final MealSlot? slot;

  Map<String, Object?> toJson() => _$LogCorrectionToJson(this);
}
