// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealWindow _$MealWindowFromJson(Map<String, dynamic> json) => MealWindow(
  end: json['end'] as String,
  slot: MealSlot.fromJson(json['slot'] as String),
  start: json['start'] as String,
);

Map<String, dynamic> _$MealWindowToJson(MealWindow instance) =>
    <String, dynamic>{
      'end': instance.end,
      'slot': instance.slot.toJson(),
      'start': instance.start,
    };
