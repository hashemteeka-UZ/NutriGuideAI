// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_op_result.dart';

part 'sync_result.g.dart';

@JsonSerializable()
class SyncResult {
  const SyncResult({
    required this.results,
    required this.serverTime,
  });
  
  factory SyncResult.fromJson(Map<String, Object?> json) => _$SyncResultFromJson(json);
  
  final List<SyncOpResult> results;
  @JsonKey(name: 'server_time')
  final DateTime serverTime;

  Map<String, Object?> toJson() => _$SyncResultToJson(this);
}
