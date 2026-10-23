// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_log_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterLogResult _$WaterLogResultFromJson(Map<String, dynamic> json) =>
    WaterLogResult(
      amountMl: (json['amount_ml'] as num).toInt(),
      consumedAt: DateTime.parse(json['consumed_at'] as String),
      logId: (json['log_id'] as num).toInt(),
      status: WaterLogResultStatus.fromJson(json['status'] as String),
    );

Map<String, dynamic> _$WaterLogResultToJson(WaterLogResult instance) =>
    <String, dynamic>{
      'amount_ml': instance.amountMl,
      'consumed_at': instance.consumedAt.toIso8601String(),
      'log_id': instance.logId,
      'status': instance.status.toJson(),
    };
