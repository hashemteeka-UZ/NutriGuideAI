// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';

part 'meal_window.g.dart';

@JsonSerializable()
class MealWindow {
  const MealWindow({
    required this.end,
    required this.slot,
    required this.start,
  });
  
  factory MealWindow.fromJson(Map<String, Object?> json) => _$MealWindowFromJson(json);
  
  final String end;
  final MealSlot slot;
  final String start;

  Map<String, Object?> toJson() => _$MealWindowToJson(this);
}
