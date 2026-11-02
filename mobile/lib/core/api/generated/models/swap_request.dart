// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'swap_request.g.dart';

@JsonSerializable()
class SwapRequest {
  const SwapRequest({
    required this.mealId,
  });
  
  factory SwapRequest.fromJson(Map<String, Object?> json) => _$SwapRequestFromJson(json);
  
  @JsonKey(name: 'meal_id')
  final int mealId;

  Map<String, Object?> toJson() => _$SwapRequestToJson(this);
}
