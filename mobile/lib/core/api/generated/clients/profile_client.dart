// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/profile_state.dart';
import '../models/profile_update.dart';
import '../models/targets_view.dart';

part 'profile_client.g.dart';

@RestApi()
abstract class ProfileClient {
  factory ProfileClient(Dio dio, {String? baseUrl}) = _ProfileClient;

  /// Get Profile.
  ///
  /// The saved profile, screening, and the current target when one exists.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND.
  @GET('/api/v1/me/profile')
  Future<ProfileState> getProfile();

  /// Update Profile.
  ///
  /// Replace the profile. The first save requires current_weight_kg; a later value is stored as today's weight. At most one target is created per save. An ineligible screening is returned in the body, not as an error, and closes the current target.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR, UNKNOWN_CODE, NO_WEIGHT, TARGET_VALIDATION, INVALID_TIMEZONE.
  @PUT('/api/v1/me/profile')
  Future<ProfileState> updateProfile({
    @Body() required ProfileUpdate body,
  });

  /// Get Targets.
  ///
  /// Screening, the current calorie target, and the water goal including reminders_default_off.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND.
  @GET('/api/v1/me/targets')
  Future<TargetsView> getTargets();
}
