// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/meal_detail.dart';
import '../models/meal_page.dart';
import '../models/meal_slot.dart';

part 'meals_client.g.dart';

@RestApi()
abstract class MealsClient {
  factory MealsClient(Dio dio, {String? baseUrl}) = _MealsClient;

  /// List Meals.
  ///
  /// Active meals for browsing and logging. With q, the meal name and every translation are ranked like ingredient search: exact, then prefix, then contains, then trigram similarity; one row per meal. Without q, meals are ordered by the normalized displayed name, then meal_id. slot keeps meals that carry that slot's occasion tag. cuisine filters by cuisine code; an unknown code returns an empty page. Results are not filtered by the caller's health conditions or allergies; each meal lists its allergen codes so the app can mark them. Names follow Accept-Language (ar default, en). Nutrition is for one serving.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/meals')
  Future<MealPage> listMeals({
    @Query('limit') int? limit = 20,
    @Query('offset') int? offset = 0,
    @Query('q') String? q,
    @Query('slot') MealSlot? slot,
    @Query('cuisine') String? cuisine,
  });

  /// Get Meal.
  ///
  /// One active meal. The name is the meal name when Accept-Language matches default_lang, otherwise the translation in that language, otherwise the meal name. Steps are in the requested language, then Arabic, or an empty list when the meal has none. kcal is the stored energy_kcal per serving. dataset_version is this meal's batch id. Not filtered by the caller's health conditions or allergies.
  /// Error codes: UNAUTHORIZED, MEAL_NOT_FOUND.
  @GET('/api/v1/meals/{meal_id}')
  Future<MealDetail> getMeal({
    @Path('meal_id') required int mealId,
  });
}
