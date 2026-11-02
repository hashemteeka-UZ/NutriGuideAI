// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'consumption_log_out.dart';
import 'day_plan_out.dart';
import 'meal_pref.dart';
import 'water_log_out.dart';
import 'weight_point.dart';

part 'sync_changes.g.dart';

@JsonSerializable()
class SyncChanges {
  const SyncChanges({
    required this.consumptionLogs,
    required this.deletedConsumptionLogIds,
    required this.deletedWaterLogIds,
    required this.mealPrefs,
    required this.plans,
    required this.profileChanged,
    required this.serverTime,
    required this.waterLogs,
    required this.weights,
  });
  
  factory SyncChanges.fromJson(Map<String, Object?> json) => _$SyncChangesFromJson(json);
  
  @JsonKey(name: 'consumption_logs')
  final List<ConsumptionLogOut> consumptionLogs;
  @JsonKey(name: 'deleted_consumption_log_ids')
  final List<int> deletedConsumptionLogIds;
  @JsonKey(name: 'deleted_water_log_ids')
  final List<int> deletedWaterLogIds;
  @JsonKey(name: 'meal_prefs')
  final List<MealPref> mealPrefs;
  final List<DayPlanOut> plans;
  @JsonKey(name: 'profile_changed')
  final bool profileChanged;
  @JsonKey(name: 'server_time')
  final DateTime serverTime;
  @JsonKey(name: 'water_logs')
  final List<WaterLogOut> waterLogs;
  final List<WeightPoint> weights;

  Map<String, Object?> toJson() => _$SyncChangesToJson(this);
}
