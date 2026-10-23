// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterDay _$WaterDayFromJson(Map<String, dynamic> json) => WaterDay(
  date: DateTime.parse(json['date'] as String),
  goal: WaterGoal.fromJson(json['goal'] as Map<String, dynamic>),
  logs: (json['logs'] as List<dynamic>)
      .map((e) => WaterLogOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalMl: (json['total_ml'] as num).toInt(),
);

Map<String, dynamic> _$WaterDayToJson(WaterDay instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'goal': instance.goal.toJson(),
  'logs': instance.logs.map((e) => e.toJson()).toList(),
  'total_ml': instance.totalMl,
};
