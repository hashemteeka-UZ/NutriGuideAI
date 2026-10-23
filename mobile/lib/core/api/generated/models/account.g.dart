// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  createdAt: DateTime.parse(json['created_at'] as String),
  email: json['email'] as String,
  hasProfile: json['has_profile'] as bool,
  userId: (json['user_id'] as num).toInt(),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'created_at': instance.createdAt.toIso8601String(),
  'email': instance.email,
  'has_profile': instance.hasProfile,
  'user_id': instance.userId,
};
