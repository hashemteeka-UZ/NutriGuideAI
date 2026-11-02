// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_batch_operations_sealed.dart';

part 'sync_batch.g.dart';

@JsonSerializable()
class SyncBatch {
  const SyncBatch({
    required this.operations,
  });
  
  factory SyncBatch.fromJson(Map<String, Object?> json) => _$SyncBatchFromJson(json);
  
  final List<SyncBatchOperationsSealed> operations;

  Map<String, Object?> toJson() => _$SyncBatchToJson(this);
}
