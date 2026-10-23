// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_v1_consumption_logs_request_body_sealed.dart';
import '../models/consumption_log_out.dart';
import '../models/log_correction.dart';

part 'consumption_client.g.dart';

@RestApi()
abstract class ConsumptionClient {
  factory ConsumptionClient(Dio dio, {String? baseUrl}) = _ConsumptionClient;

  /// List Consumption Logs.
  ///
  /// Active logs of that local day.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/consumption-logs')
  Future<List<ConsumptionLogOut>> listConsumptionLogs({
    @Query('date') required DateTime date,
  });

  /// Create Consumption Log.
  ///
  /// Log a plan item, a catalog meal, or one food from ingredient search. A composite off-catalog dish is not supported yet. consumed_at may be at most 5 minutes after the server clock (CLOCK_SKEW) and its local date may not be more than 30 days before the user's local today (VALIDATION_ERROR). A plan item's local date must equal the item's plan date. 201 when created, 200 when the same client_uuid and content were already stored. The server writes ACCEPT when a plan-item log is created.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, PLAN_ITEM_NOT_FOUND, MEAL_NOT_FOUND, FOOD_NOT_FOUND, PLAN_ITEM_ALREADY_LOGGED, CLIENT_UUID_CONFLICT, INCOMPLETE_NUTRITION, CLOCK_SKEW, VALIDATION_ERROR.
  @POST('/api/v1/consumption-logs')
  Future<ConsumptionLogOut> createConsumptionLog({
    @Body() required ApiV1ConsumptionLogsRequestBodyUnion body,
  });

  /// Delete Consumption Log.
  ///
  /// Tombstone the log.
  /// Error codes: UNAUTHORIZED, LOG_NOT_FOUND.
  @DELETE('/api/v1/consumption-logs/{log_id}')
  Future<void> deleteConsumptionLog({
    @Path('log_id') required int logId,
  });

  /// Correct Consumption Log.
  ///
  /// Tombstone the old row and return the new one. At least one measured field must change. The correction uses a new client_uuid. If consumed_at is sent, it follows the same 30-day window and clock skew, and a plan-item log must stay on its plan date. No new ACCEPT is written.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, LOG_NOT_FOUND, PLAN_ITEM_NOT_FOUND, CLIENT_UUID_CONFLICT, INCOMPLETE_NUTRITION, CLOCK_SKEW, VALIDATION_ERROR.
  @POST('/api/v1/consumption-logs/{log_id}/correction')
  Future<ConsumptionLogOut> correctConsumptionLog({
    @Path('log_id') required int logId,
    @Body() required LogCorrection body,
  });
}
