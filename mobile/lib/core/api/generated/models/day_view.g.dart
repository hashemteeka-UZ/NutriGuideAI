// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayView _$DayViewFromJson(Map<String, dynamic> json) => DayView(
  adherence: DayAdherenceOut.fromJson(
    json['adherence'] as Map<String, dynamic>,
  ),
  date: DateTime.parse(json['date'] as String),
  mealWindows: (json['meal_windows'] as List<dynamic>)
      .map((e) => MealWindow.fromJson(e as Map<String, dynamic>))
      .toList(),
  water: WaterDay.fromJson(json['water'] as Map<String, dynamic>),
  plan: json['plan'] == null
      ? null
      : DayPlanOut.fromJson(json['plan'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DayViewToJson(DayView instance) => <String, dynamic>{
  'adherence': instance.adherence.toJson(),
  'date': instance.date.toIso8601String(),
  'meal_windows': instance.mealWindows.map((e) => e.toJson()).toList(),
  'plan': instance.plan?.toJson(),
  'water': instance.water.toJson(),
};
