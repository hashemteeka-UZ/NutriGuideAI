// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_day_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanDayRequest _$PlanDayRequestFromJson(Map<String, dynamic> json) =>
    PlanDayRequest(date: DateTime.parse(json['date'] as String));

Map<String, dynamic> _$PlanDayRequestToJson(PlanDayRequest instance) =>
    <String, dynamic>{'date': instance.date.toIso8601String()};
