// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileState _$ProfileStateFromJson(Map<String, dynamic> json) => ProfileState(
  profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
  screening: Screening.fromJson(json['screening'] as Map<String, dynamic>),
  target: json['target'] == null
      ? null
      : Target.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProfileStateToJson(ProfileState instance) =>
    <String, dynamic>{
      'profile': instance.profile.toJson(),
      'screening': instance.screening.toJson(),
      'target': instance.target?.toJson(),
    };
