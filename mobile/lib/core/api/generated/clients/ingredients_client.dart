// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/ingredient_page.dart';

part 'ingredients_client.g.dart';

@RestApi()
abstract class IngredientsClient {
  factory IngredientsClient(Dio dio, {String? baseUrl}) = _IngredientsClient;

  /// Search Ingredients.
  ///
  /// Search Arabic names, English names, and aliases. Ranked by exact match, then prefix, then contains, then similarity. Rejected ingredients are excluded. Log the hit's food_id, not a food search.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/ingredients')
  Future<IngredientPage> searchIngredients({
    @Query('q') required String q,
    @Query('limit') int? limit = 20,
    @Query('offset') int? offset = 0,
  });
}
