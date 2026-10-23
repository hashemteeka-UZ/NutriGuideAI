// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'screening.g.dart';

@JsonSerializable()
class Screening {
  const Screening({
    required this.eligible,
    required this.reasons,
  });
  
  factory Screening.fromJson(Map<String, Object?> json) => _$ScreeningFromJson(json);
  
  final bool eligible;
  final List<String> reasons;

  Map<String, Object?> toJson() => _$ScreeningToJson(this);
}
