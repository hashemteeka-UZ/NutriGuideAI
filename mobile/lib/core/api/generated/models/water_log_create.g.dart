// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_log_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterLogCreate _$WaterLogCreateFromJson(Map<String, dynamic> json) =>
    WaterLogCreate(
      amountMl: (json['amount_ml'] as num).toInt(),
      clientUuid: json['client_uuid'] as String,
      consumedAt: DateTime.parse(json['consumed_at'] as String),
    );

Map<String, dynamic> _$WaterLogCreateToJson(WaterLogCreate instance) =>
    <String, dynamic>{
      'amount_ml': instance.amountMl,
      'client_uuid': instance.clientUuid,
      'consumed_at': instance.consumedAt.toIso8601String(),
    };
