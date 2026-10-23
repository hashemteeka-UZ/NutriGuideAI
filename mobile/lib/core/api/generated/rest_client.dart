// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/adherence_client.dart';
import 'clients/auth_client.dart';
import 'clients/catalog_client.dart';
import 'clients/consumption_client.dart';
import 'clients/plans_client.dart';
import 'clients/health_client.dart';
import 'clients/ingredients_client.dart';
import 'clients/interactions_client.dart';
import 'clients/account_client.dart';
import 'clients/meal_prefs_client.dart';
import 'clients/profile_client.dart';
import 'clients/meals_client.dart';
import 'clients/reference_client.dart';
import 'clients/sync_client.dart';
import 'clients/water_client.dart';
import 'clients/weights_client.dart';

/// NutriGuideAI API `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  AdherenceClient? _adherence;
  AuthClient? _auth;
  CatalogClient? _catalog;
  ConsumptionClient? _consumption;
  PlansClient? _plans;
  HealthClient? _health;
  IngredientsClient? _ingredients;
  InteractionsClient? _interactions;
  AccountClient? _account;
  MealPrefsClient? _mealPrefs;
  ProfileClient? _profile;
  MealsClient? _meals;
  ReferenceClient? _reference;
  SyncClient? _sync;
  WaterClient? _water;
  WeightsClient? _weights;

  AdherenceClient get adherence => _adherence ??= AdherenceClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  CatalogClient get catalog => _catalog ??= CatalogClient(_dio, baseUrl: _baseUrl);

  ConsumptionClient get consumption => _consumption ??= ConsumptionClient(_dio, baseUrl: _baseUrl);

  PlansClient get plans => _plans ??= PlansClient(_dio, baseUrl: _baseUrl);

  HealthClient get health => _health ??= HealthClient(_dio, baseUrl: _baseUrl);

  IngredientsClient get ingredients => _ingredients ??= IngredientsClient(_dio, baseUrl: _baseUrl);

  InteractionsClient get interactions => _interactions ??= InteractionsClient(_dio, baseUrl: _baseUrl);

  AccountClient get account => _account ??= AccountClient(_dio, baseUrl: _baseUrl);

  MealPrefsClient get mealPrefs => _mealPrefs ??= MealPrefsClient(_dio, baseUrl: _baseUrl);

  ProfileClient get profile => _profile ??= ProfileClient(_dio, baseUrl: _baseUrl);

  MealsClient get meals => _meals ??= MealsClient(_dio, baseUrl: _baseUrl);

  ReferenceClient get reference => _reference ??= ReferenceClient(_dio, baseUrl: _baseUrl);

  SyncClient get sync => _sync ??= SyncClient(_dio, baseUrl: _baseUrl);

  WaterClient get water => _water ??= WaterClient(_dio, baseUrl: _baseUrl);

  WeightsClient get weights => _weights ??= WeightsClient(_dio, baseUrl: _baseUrl);
}
