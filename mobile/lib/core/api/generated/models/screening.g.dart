// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screening.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Screening _$ScreeningFromJson(Map<String, dynamic> json) => Screening(
  eligible: json['eligible'] as bool,
  reasons: (json['reasons'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ScreeningToJson(Screening instance) => <String, dynamic>{
  'eligible': instance.eligible,
  'reasons': instance.reasons,
};
