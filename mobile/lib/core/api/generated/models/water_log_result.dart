// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'water_log_result_status.dart';

part 'water_log_result.g.dart';

/// POST /water-logs adds status. GET logs stay WaterLogOut.
@JsonSerializable()
class WaterLogResult {
  const WaterLogResult({
    required this.amountMl,
    required this.consumedAt,
    required this.logId,
    required this.status,
  });
  
  factory WaterLogResult.fromJson(Map<String, Object?> json) => _$WaterLogResultFromJson(json);
  
  @JsonKey(name: 'amount_ml')
  final int amountMl;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  @JsonKey(name: 'log_id')
  final int logId;
  final WaterLogResultStatus status;

  Map<String, Object?> toJson() => _$WaterLogResultToJson(this);
}
