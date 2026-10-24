import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/catalog/data/meal_pref_writer.dart';

void main() {
  late AppDatabase database;
  late _Remote remote;
  var missing = 0;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = _Remote();
    missing = 0;
  });

  tearDown(() => database.close());

  MealPrefWriter writer() {
    return MealPrefWriter(
      database: database,
      remote: remote,
      onMealMissing: () async {
        missing += 1;
      },
      now: () => DateTime.utc(2026, 1, 1),
    );
  }

  test('a failed LIKE rolls the optimistic row back', () async {
    remote.failPut = DioException(
      requestOptions: RequestOptions(path: '/api/v1/me/meal-prefs/3'),
      type: DioExceptionType.connectionError,
    );
    remote.onPut = () async {
      final rows = await database.select(database.localMealPrefs).get();
      expect(rows.single.stance, 'LIKE');
    };

    await expectLater(
      writer().apply(mealId: 3, stance: 'LIKE'),
      throwsA(isA<DioException>()),
    );
    expect(await database.select(database.localMealPrefs).get(), isEmpty);
    expect(remote.calls, <String>['PUT 3 LIKE']);
  });

  test('tapping the active stance sends DELETE', () async {
    final prefs = writer();
    await prefs.apply(mealId: 3, stance: 'LIKE');
    await prefs.apply(mealId: 3, stance: null);
    expect(remote.calls, <String>['PUT 3 LIKE', 'DELETE 3']);
    expect(await database.select(database.localMealPrefs).get(), isEmpty);
  });

  test('switching LIKE to DISLIKE sends one PUT', () async {
    final prefs = writer();
    await prefs.apply(mealId: 3, stance: 'LIKE');
    await prefs.apply(mealId: 3, stance: 'DISLIKE');
    expect(remote.calls, <String>['PUT 3 LIKE', 'PUT 3 DISLIKE']);
    final row = await database.select(database.localMealPrefs).getSingle();
    expect(row.stance, 'DISLIKE');
  });

  test('MEAL_NOT_FOUND rolls back and asks for a catalog sync', () async {
    remote.failPut = const ApiProblem(
      status: 404,
      code: 'MEAL_NOT_FOUND',
      title: null,
      detail: null,
      requestId: null,
      retryAfter: null,
    );
    await expectLater(
      writer().apply(mealId: 3, stance: 'LIKE'),
      throwsA(isA<ApiProblem>()),
    );
    expect(await database.select(database.localMealPrefs).get(), isEmpty);
    expect(missing, 1);
  });
}

final class _Remote implements MealPrefRemote {
  final calls = <String>[];
  Object? failPut;
  Future<void> Function()? onPut;

  @override
  Future<void> put(int mealId, String stance) async {
    calls.add('PUT $mealId $stance');
    await onPut?.call();
    final error = failPut;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> delete(int mealId) async {
    calls.add('DELETE $mealId');
  }
}
