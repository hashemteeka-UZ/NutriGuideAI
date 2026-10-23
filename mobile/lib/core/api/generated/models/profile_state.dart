// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'profile.dart';
import 'screening.dart';
import 'target.dart';

part 'profile_state.g.dart';

@JsonSerializable()
class ProfileState {
  const ProfileState({
    required this.profile,
    required this.screening,
    this.target,
  });
  
  factory ProfileState.fromJson(Map<String, Object?> json) => _$ProfileStateFromJson(json);
  
  final Profile profile;
  final Screening screening;
  final Target? target;

  Map<String, Object?> toJson() => _$ProfileStateToJson(this);
}
