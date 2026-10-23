// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_plan_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayPlanOut _$DayPlanOutFromJson(Map<String, dynamic> json) => DayPlanOut(
  algorithmVersion: json['algorithm_version'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  date: DateTime.parse(json['date'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => PlanItemOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  kcalWithin10pct: json['kcal_within_10pct'] as bool,
  planId: (json['plan_id'] as num).toInt(),
  target: PlanTargetOut.fromJson(json['target'] as Map<String, dynamic>),
  totals: NutrientTotals.fromJson(json['totals'] as Map<String, dynamic>),
  unmetMinimums: (json['unmet_minimums'] as List<dynamic>)
      .map((e) => UnmetMinimumOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  stats: json['stats'] == null
      ? null
      : PlanStats.fromJson(json['stats'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DayPlanOutToJson(DayPlanOut instance) =>
    <String, dynamic>{
      'algorithm_version': instance.algorithmVersion,
      'created_at': instance.createdAt.toIso8601String(),
      'date': instance.date.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'kcal_within_10pct': instance.kcalWithin10pct,
      'plan_id': instance.planId,
      'stats': instance.stats?.toJson(),
      'target': instance.target.toJson(),
      'totals': instance.totals.toJson(),
      'unmet_minimums': instance.unmetMinimums.map((e) => e.toJson()).toList(),
    };
