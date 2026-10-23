// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  const Account({
    required this.createdAt,
    required this.email,
    required this.hasProfile,
    required this.userId,
  });
  
  factory Account.fromJson(Map<String, Object?> json) => _$AccountFromJson(json);
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String email;
  @JsonKey(name: 'has_profile')
  final bool hasProfile;
  @JsonKey(name: 'user_id')
  final int userId;

  Map<String, Object?> toJson() => _$AccountToJson(this);
}
