// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_changes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncChanges _$SyncChangesFromJson(Map<String, dynamic> json) => SyncChanges(
  consumptionLogs: (json['consumption_logs'] as List<dynamic>)
      .map((e) => ConsumptionLogOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  deletedConsumptionLogIds:
      (json['deleted_consumption_log_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
  deletedWaterLogIds: (json['deleted_water_log_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  mealPrefs: (json['meal_prefs'] as List<dynamic>)
      .map((e) => MealPref.fromJson(e as Map<String, dynamic>))
      .toList(),
  plans: (json['plans'] as List<dynamic>)
      .map((e) => DayPlanOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  profileChanged: json['profile_changed'] as bool,
  serverTime: DateTime.parse(json['server_time'] as String),
  waterLogs: (json['water_logs'] as List<dynamic>)
      .map((e) => WaterLogOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  weights: (json['weights'] as List<dynamic>)
      .map((e) => WeightPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SyncChangesToJson(
  SyncChanges instance,
) => <String, dynamic>{
  'consumption_logs': instance.consumptionLogs.map((e) => e.toJson()).toList(),
  'deleted_consumption_log_ids': instance.deletedConsumptionLogIds,
  'deleted_water_log_ids': instance.deletedWaterLogIds,
  'meal_prefs': instance.mealPrefs.map((e) => e.toJson()).toList(),
  'plans': instance.plans.map((e) => e.toJson()).toList(),
  'profile_changed': instance.profileChanged,
  'server_time': instance.serverTime.toIso8601String(),
  'water_logs': instance.waterLogs.map((e) => e.toJson()).toList(),
  'weights': instance.weights.map((e) => e.toJson()).toList(),
};
