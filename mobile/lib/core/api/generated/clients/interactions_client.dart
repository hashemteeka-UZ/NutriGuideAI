// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/interaction_create.dart';
import '../models/interaction_out.dart';

part 'interactions_client.g.dart';

@RestApi()
abstract class InteractionsClient {
  factory InteractionsClient(Dio dio, {String? baseUrl}) = _InteractionsClient;

  /// Create Interaction.
  ///
  /// Record IMPRESSION, VIEW, SAVE, RATE, COOK, or SKIP. When plan_item_id is set, the server copies plan_id, slot, and algorithm_version into context. 201 when created, 200 on a duplicate client_uuid.
  /// Error codes: UNAUTHORIZED, MEAL_NOT_FOUND, PLAN_ITEM_NOT_FOUND, CLIENT_UUID_CONFLICT, VALIDATION_ERROR.
  @POST('/api/v1/interactions')
  Future<InteractionOut> createInteraction({
    @Body() required InteractionCreate body,
  });
}
