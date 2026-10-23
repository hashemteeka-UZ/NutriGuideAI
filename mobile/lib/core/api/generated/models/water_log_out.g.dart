// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_log_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterLogOut _$WaterLogOutFromJson(Map<String, dynamic> json) => WaterLogOut(
  amountMl: (json['amount_ml'] as num).toInt(),
  consumedAt: DateTime.parse(json['consumed_at'] as String),
  logId: (json['log_id'] as num).toInt(),
);

Map<String, dynamic> _$WaterLogOutToJson(WaterLogOut instance) =>
    <String, dynamic>{
      'amount_ml': instance.amountMl,
      'consumed_at': instance.consumedAt.toIso8601String(),
      'log_id': instance.logId,
    };
