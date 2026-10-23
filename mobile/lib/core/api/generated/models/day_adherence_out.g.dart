// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_adherence_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayAdherenceOut _$DayAdherenceOutFromJson(Map<String, dynamic> json) =>
    DayAdherenceOut(
      date: DateTime.parse(json['date'] as String),
      exceededLimits: (json['exceeded_limits'] as List<dynamic>)
          .map((e) => ExceededLimitOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      logCount: (json['log_count'] as num).toInt(),
      planItemsConsumed: (json['plan_items_consumed'] as num).toInt(),
      planItemsTotal: (json['plan_items_total'] as num).toInt(),
      totals: NutrientTotals.fromJson(json['totals'] as Map<String, dynamic>),
      unmetMinimums: (json['unmet_minimums'] as List<dynamic>)
          .map((e) => UnmetMinimumOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      completion: json['completion'] as num?,
      fiberTargetG: (json['fiber_target_g'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      status: json['status'] == null
          ? null
          : DayAdherenceOutStatus.fromJson(json['status'] as String),
      targetKcal: json['target_kcal'] as num?,
    );

Map<String, dynamic> _$DayAdherenceOutToJson(
  DayAdherenceOut instance,
) => <String, dynamic>{
  'completion': instance.completion,
  'date': instance.date.toIso8601String(),
  'exceeded_limits': instance.exceededLimits.map((e) => e.toJson()).toList(),
  'fiber_target_g': instance.fiberTargetG,
  'log_count': instance.logCount,
  'plan_items_consumed': instance.planItemsConsumed,
  'plan_items_total': instance.planItemsTotal,
  'reason': instance.reason,
  'status': instance.status?.toJson(),
  'target_kcal': instance.targetKcal,
  'totals': instance.totals.toJson(),
  'unmet_minimums': instance.unmetMinimums.map((e) => e.toJson()).toList(),
};
