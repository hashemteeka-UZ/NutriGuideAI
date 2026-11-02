// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'day_adherence_out.dart';
import 'day_plan_out.dart';
import 'meal_window.dart';
import 'water_day.dart';

part 'day_view.g.dart';

@JsonSerializable()
class DayView {
  const DayView({
    required this.adherence,
    required this.date,
    required this.mealWindows,
    required this.water,
    this.plan,
  });
  
  factory DayView.fromJson(Map<String, Object?> json) => _$DayViewFromJson(json);
  
  final DayAdherenceOut adherence;
  final DateTime date;
  @JsonKey(name: 'meal_windows')
  final List<MealWindow> mealWindows;
  final DayPlanOut? plan;
  final WaterDay water;

  Map<String, Object?> toJson() => _$DayViewToJson(this);
}
