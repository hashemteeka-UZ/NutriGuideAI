// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncBatch _$SyncBatchFromJson(Map<String, dynamic> json) => SyncBatch(
  operations: (json['operations'] as List<dynamic>)
      .map((e) => SyncBatchOperationsSealed.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SyncBatchToJson(SyncBatch instance) => <String, dynamic>{
  'operations': instance.operations.map((e) => e.toJson()).toList(),
};
