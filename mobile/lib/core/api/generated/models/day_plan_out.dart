// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'nutrient_totals.dart';
import 'plan_item_out.dart';
import 'plan_stats.dart';
import 'plan_target_out.dart';
import 'unmet_minimum_out.dart';

part 'day_plan_out.g.dart';

@JsonSerializable()
class DayPlanOut {
  const DayPlanOut({
    required this.algorithmVersion,
    required this.createdAt,
    required this.date,
    required this.items,
    required this.kcalWithin10pct,
    required this.planId,
    required this.target,
    required this.totals,
    required this.unmetMinimums,
    this.stats,
  });
  
  factory DayPlanOut.fromJson(Map<String, Object?> json) => _$DayPlanOutFromJson(json);
  
  @JsonKey(name: 'algorithm_version')
  final String algorithmVersion;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final DateTime date;
  final List<PlanItemOut> items;
  @JsonKey(name: 'kcal_within_10pct')
  final bool kcalWithin10pct;
  @JsonKey(name: 'plan_id')
  final int planId;
  final PlanStats? stats;
  final PlanTargetOut target;
  final NutrientTotals totals;
  @JsonKey(name: 'unmet_minimums')
  final List<UnmetMinimumOut> unmetMinimums;

  Map<String, Object?> toJson() => _$DayPlanOutToJson(this);
}
