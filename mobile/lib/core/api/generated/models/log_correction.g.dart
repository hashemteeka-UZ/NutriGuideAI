// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_correction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogCorrection _$LogCorrectionFromJson(Map<String, dynamic> json) =>
    LogCorrection(
      newClientUuid: json['new_client_uuid'] as String,
      consumedAt: json['consumed_at'] == null
          ? null
          : DateTime.parse(json['consumed_at'] as String),
      gramsConsumed: json['grams_consumed'] as num?,
      servingsConsumed: json['servings_consumed'] as num?,
      slot: json['slot'] == null
          ? null
          : MealSlot.fromJson(json['slot'] as String),
    );

Map<String, dynamic> _$LogCorrectionToJson(LogCorrection instance) =>
    <String, dynamic>{
      'consumed_at': instance.consumedAt?.toIso8601String(),
      'grams_consumed': instance.gramsConsumed,
      'new_client_uuid': instance.newClientUuid,
      'servings_consumed': instance.servingsConsumed,
      'slot': instance.slot?.toJson(),
    };
