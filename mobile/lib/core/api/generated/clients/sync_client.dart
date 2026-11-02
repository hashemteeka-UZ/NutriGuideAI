// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/sync_batch.dart';
import '../models/sync_changes.dart';
import '../models/sync_result.dart';

part 'sync_client.g.dart';

@RestApi()
abstract class SyncClient {
  factory SyncClient(Dio dio, {String? baseUrl}) = _SyncClient;

  /// Sync Batch.
  ///
  /// Apply 1 to 500 operations in the order given. Each operation runs in its own savepoint and the request commits once. A known error sets that operation to REJECTED with its code and the rest continue. An unexpected error returns 500 and stores nothing; resending the same batch is safe. A create or a correction whose client id and content are already stored, and a delete of a log this user already deleted, come back DUPLICATE. A weight with an older updated_at is DUPLICATE; a weight that replaced the stored value is UPDATED. server_time is the instant to send as the next since.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR, RATE_LIMITED.
  @POST('/api/v1/sync/batch')
  Future<SyncResult> syncBatch({
    @Body() required SyncBatch body,
  });

  /// Get Sync Changes.
  ///
  /// since may be at most 5 minutes after the server clock (CLOCK_SKEW) and not more than 30 days before it (VALIDATION_ERROR; the app reloads). Rows are read from since minus 2 minutes. Consumption and water include logs created after that cutoff and ids deleted after it. Weights are every weight of the last 30 local days, because their updated_at comes from the phone. meal_prefs is the full current list. plans are the current plan of each day from local yesterday onward when that plan was created after the cutoff or one of its items was updated after it, so a swap appears. profile_changed is true when the profile, health conditions, allergies, ingredient preferences, or a new target changed after the cutoff. Send server_time back as the next since.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, CLOCK_SKEW, VALIDATION_ERROR.
  @GET('/api/v1/sync/changes')
  Future<SyncChanges> getSyncChanges({
    @Query('since') required DateTime since,
  });
}
