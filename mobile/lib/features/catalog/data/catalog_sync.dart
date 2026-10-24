import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/clients/meal_prefs_client.dart';
import '../../../core/api/generated/clients/profile_client.dart';
import '../../../core/api/generated/models/catalog_snapshot.dart';
import '../../../core/api/generated/models/meal_stance.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/personal_data.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_provider.dart';
import 'catalog_mapper.dart';

abstract interface class CatalogSync {
  Future<void> sync({required String lang});
}

final class NoopCatalogSync implements CatalogSync {
  const NoopCatalogSync();

  @override
  Future<void> sync({required String lang}) async {}
}

final class DioCatalogSync implements CatalogSync {
  DioCatalogSync({
    required this._dio,
    required this._database,
    required this._personal,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Dio _dio;
  final AppDatabase _database;
  final PersonalDataStore _personal;
  final DateTime Function() _now;
  Future<void>? _inFlight;
  String? _lastLang;

  @override
  Future<void> sync({required String lang}) {
    final current = _inFlight;
    if (current != null) {
      return current.then((_) {
        if (_lastLang == lang) {
          return Future<void>.value();
        }
        return sync(lang: lang);
      });
    }
    final future = _run(lang);
    _inFlight = future;
    return future.whenComplete(() {
      _lastLang = lang;
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<void> _run(String lang) async {
    try {
      await _snapshot(lang);
    } on Object {
      // A network failure stays quiet. The meals screen uses the local copy.
    }
    try {
      await _prefs();
    } on Object {
      // Keep the stances already on the phone.
    }
    try {
      await _allergens();
    } on Object {
      // Keep the allergens already on the phone.
    }
  }

  Future<void> _snapshot(String lang) async {
    final etag = await catalogEtag(_database, lang);
    final response = await _dio.get<String>(
      '/api/v1/catalog/snapshot',
      options: Options(
        headers: <String, Object?>{
          'Accept-Language': lang,
          'If-None-Match': ?etag,
        },
        responseType: ResponseType.plain,
        validateStatus: (int? status) => status == 200 || status == 304,
      ),
    );
    final now = _now().toUtc();
    if (response.statusCode == 304) {
      await touchCatalogFetchedAt(_database, lang: lang, fetchedAt: now);
      return;
    }
    if (response.statusCode != 200) {
      return;
    }
    final body = response.data;
    if (body == null || body.isEmpty) {
      return;
    }
    final CatalogSnapshot snapshot;
    try {
      snapshot = await Isolate.run(() => _parseSnapshot(body));
    } on Object {
      return;
    }
    final received = response.headers['etag'];
    final nextEtag = received == null || received.isEmpty ? '' : received.first;
    await replaceCatalogLanguage(
      _database,
      lang: lang,
      snapshot: snapshot,
      etag: nextEtag,
      fetchedAt: now,
    );
  }

  Future<void> _prefs() async {
    final seen = _personal.generation;
    final prefs = await MealPrefsClient(_dio).listMealPrefs();
    if (seen != _personal.generation) {
      return;
    }
    await _personal.replacePrefs([
      for (final pref in prefs)
        if (pref.stance == MealStance.like || pref.stance == MealStance.dislike)
          (
            mealId: pref.mealId,
            stance: pref.stance.json!,
            updatedAt: pref.updatedAt.toUtc(),
          ),
    ]);
  }

  Future<void> _allergens() async {
    final seen = _personal.generation;
    try {
      final state = await ProfileClient(_dio).getProfile();
      if (seen != _personal.generation) {
        return;
      }
      await _personal.replaceAllergens([
        for (final allergen in state.profile.allergens)
          if (allergen.severity.json != null)
            (code: allergen.code, severity: allergen.severity.json!),
      ]);
    } on DioException catch (error) {
      final failure = mapDioException(error);
      if (failure is ApiProblem && failure.code == 'PROFILE_NOT_FOUND') {
        if (seen != _personal.generation) {
          return;
        }
        await _personal.replaceAllergens(
          const <({String code, String severity})>[],
        );
      }
    }
  }
}

CatalogSnapshot _parseSnapshot(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('catalog snapshot');
  }
  return CatalogSnapshot.fromJson(Map<String, dynamic>.from(decoded));
}

final catalogSyncProvider = Provider<CatalogSync>((ref) {
  return DioCatalogSync(
    dio: ref.watch(dioProvider),
    database: ref.watch(appDatabaseProvider),
    personal: ref.watch(personalDataStoreProvider),
  );
});
