// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InteractionOut _$InteractionOutFromJson(Map<String, dynamic> json) =>
    InteractionOut(
      interactionId: (json['interaction_id'] as num).toInt(),
      status: InteractionOutStatus.fromJson(json['status'] as String),
    );

Map<String, dynamic> _$InteractionOutToJson(InteractionOut instance) =>
    <String, dynamic>{
      'interaction_id': instance.interactionId,
      'status': instance.status.toJson(),
    };
