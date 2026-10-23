// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_range_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdherenceRangeOut _$AdherenceRangeOutFromJson(Map<String, dynamic> json) =>
    AdherenceRangeOut(
      days: (json['days'] as List<dynamic>)
          .map((e) => DayAdherenceOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      streak: (json['streak'] as num).toInt(),
    );

Map<String, dynamic> _$AdherenceRangeOutToJson(AdherenceRangeOut instance) =>
    <String, dynamic>{
      'days': instance.days.map((e) => e.toJson()).toList(),
      'streak': instance.streak,
    };
