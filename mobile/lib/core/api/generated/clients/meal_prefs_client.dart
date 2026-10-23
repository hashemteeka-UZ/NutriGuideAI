// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/meal_pref.dart';
import '../models/meal_pref_update.dart';

part 'meal_prefs_client.g.dart';

@RestApi()
abstract class MealPrefsClient {
  factory MealPrefsClient(Dio dio, {String? baseUrl}) = _MealPrefsClient;

  /// List Meal Prefs.
  ///
  /// Stances the user has set. Meals with no row are omitted.
  /// Error codes: UNAUTHORIZED.
  @GET('/api/v1/me/meal-prefs')
  Future<List<MealPref>> listMealPrefs();

  /// Delete Meal Pref.
  ///
  /// Clear the stance. Also writes PREF_CLEAR.
  /// Error codes: UNAUTHORIZED, MEAL_NOT_FOUND.
  @DELETE('/api/v1/me/meal-prefs/{meal_id}')
  Future<void> deleteMealPref({
    @Path('meal_id') required int mealId,
  });

  /// Set Meal Pref.
  ///
  /// Set LIKE or DISLIKE. Also writes PREF_LIKE or PREF_DISLIKE.
  /// Error codes: UNAUTHORIZED, MEAL_NOT_FOUND.
  @PUT('/api/v1/me/meal-prefs/{meal_id}')
  Future<MealPref> setMealPref({
    @Path('meal_id') required int mealId,
    @Body() required MealPrefUpdate body,
  });
}
