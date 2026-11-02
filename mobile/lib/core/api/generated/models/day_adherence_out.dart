// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'day_adherence_out_status.dart';
import 'exceeded_limit_out.dart';
import 'nutrient_totals.dart';
import 'unmet_minimum_out.dart';

part 'day_adherence_out.g.dart';

@JsonSerializable()
class DayAdherenceOut {
  const DayAdherenceOut({
    required this.date,
    required this.exceededLimits,
    required this.logCount,
    required this.planItemsConsumed,
    required this.planItemsTotal,
    required this.totals,
    required this.unmetMinimums,
    this.completion,
    this.fiberTargetG,
    this.reason,
    this.status,
    this.targetKcal,
  });
  
  factory DayAdherenceOut.fromJson(Map<String, Object?> json) => _$DayAdherenceOutFromJson(json);
  
  final num? completion;
  final DateTime date;
  @JsonKey(name: 'exceeded_limits')
  final List<ExceededLimitOut> exceededLimits;
  @JsonKey(name: 'fiber_target_g')
  final int? fiberTargetG;
  @JsonKey(name: 'log_count')
  final int logCount;
  @JsonKey(name: 'plan_items_consumed')
  final int planItemsConsumed;
  @JsonKey(name: 'plan_items_total')
  final int planItemsTotal;
  final String? reason;
  final DayAdherenceOutStatus? status;
  @JsonKey(name: 'target_kcal')
  final num? targetKcal;
  final NutrientTotals totals;
  @JsonKey(name: 'unmet_minimums')
  final List<UnmetMinimumOut> unmetMinimums;

  Map<String, Object?> toJson() => _$DayAdherenceOutToJson(this);
}
