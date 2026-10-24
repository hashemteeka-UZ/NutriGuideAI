import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/db/personal_data.dart';
import 'package:nutriguide/features/catalog/data/catalog_mapper.dart';
import 'package:nutriguide/features/catalog/data/catalog_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PersonalDataStore personal;
  late _Script adapter;
  late DioCatalogSync sync;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase(NativeDatabase.memory());
    personal = PersonalDataStore(
      database,
      preferences: SharedPreferences.getInstance,
    );
    adapter = _Script();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'))
      ..httpClientAdapter = adapter;
    sync = DioCatalogSync(
      dio: dio,
      database: database,
      personal: personal,
      now: () => adapter.now,
    );
  });

  tearDown(() => database.close());

  test('a 200 stores rows and the ETag, and a 304 keeps them', () async {
    adapter.now = DateTime.utc(2026, 1, 1);
    adapter.enqueue(lang: 'ar', status: 200, etag: '"snap-1"', name: 'شكشوكة');
    await sync.sync(lang: 'ar');

    expect(await catalogEtag(database, 'ar'), '"snap-1"');
    expect(await _names(database, 'ar'), <String>['شكشوكة']);
    expect(await _fetchedAt(database, 'ar'), DateTime.utc(2026, 1, 1));
    expect(adapter.snapshotHeaders.single['If-None-Match'], isNull);

    adapter.now = DateTime.utc(2026, 1, 2);
    adapter.enqueue(lang: 'ar', status: 304, etag: '"snap-1"');
    await sync.sync(lang: 'ar');

    expect(adapter.snapshotHeaders.last['If-None-Match'], '"snap-1"');
    expect(await _names(database, 'ar'), <String>['شكشوكة']);
    expect(await catalogEtag(database, 'ar'), '"snap-1"');
    expect(await _fetchedAt(database, 'ar'), DateTime.utc(2026, 1, 2));
  });

  test('a 200 for one language leaves the other language alone', () async {
    adapter.enqueue(lang: 'ar', status: 200, etag: '"ar"', name: 'شكشوكة');
    await sync.sync(lang: 'ar');
    adapter.enqueue(lang: 'en', status: 200, etag: '"en"', name: 'Shakshuka');
    await sync.sync(lang: 'en');

    expect(await _names(database, 'ar'), <String>['شكشوكة']);
    expect(await _names(database, 'en'), <String>['Shakshuka']);
    expect(await catalogEtag(database, 'ar'), '"ar"');
  });

  test('a malformed body leaves the stored rows', () async {
    adapter.enqueue(lang: 'ar', status: 200, etag: '"ok"', name: 'شكشوكة');
    await sync.sync(lang: 'ar');
    adapter.enqueueRaw(status: 200, body: '{', etag: '"bad"');
    await sync.sync(lang: 'ar');

    expect(await _names(database, 'ar'), <String>['شكشوكة']);
    expect(await catalogEtag(database, 'ar'), '"ok"');
  });

  test('two concurrent syncs share one request', () async {
    final release = Completer<void>();
    adapter.hold = release.future;
    adapter.enqueue(lang: 'ar', status: 200, etag: '"once"', name: 'شكشوكة');

    final first = sync.sync(lang: 'ar');
    await adapter.started.future;
    final second = sync.sync(lang: 'ar');
    release.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(adapter.snapshotCount, 1);
    expect(await _names(database, 'ar'), <String>['شكشوكة']);
  });
}

Future<List<String>> _names(AppDatabase database, String lang) async {
  final rows = await database
      .customSelect(
        'SELECT name FROM meals WHERE lang = ? ORDER BY meal_id',
        variables: <Variable<Object>>[Variable<String>(lang)],
      )
      .get();
  return <String>[for (final row in rows) row.read<String>('name')];
}

Future<DateTime> _fetchedAt(AppDatabase database, String lang) async {
  final row = await database
      .customSelect(
        'SELECT fetched_at FROM catalog_meta WHERE lang = ?',
        variables: <Variable<Object>>[Variable<String>(lang)],
      )
      .getSingle();
  final value = row.read<DateTime>('fetched_at');
  return value.toUtc();
}

final class _Script implements HttpClientAdapter {
  final responses = <_Reply>[];
  final snapshotHeaders = <Map<String, dynamic>>[];
  var snapshotCount = 0;
  var now = DateTime.utc(2026, 1, 1);
  Future<void>? hold;
  final started = Completer<void>();

  void enqueue({
    required String lang,
    required int status,
    required String etag,
    String? name,
  }) {
    responses.add(
      _Reply(
        status: status,
        etag: etag,
        body: name == null ? '' : _snapshot(name),
        lang: lang,
      ),
    );
  }

  void enqueueRaw({
    required int status,
    required String body,
    required String etag,
  }) {
    responses.add(_Reply(status: status, etag: etag, body: body));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.endsWith('/catalog/snapshot')) {
      return ResponseBody.fromString('', 500);
    }
    snapshotCount += 1;
    snapshotHeaders.add(Map<String, dynamic>.from(options.headers));
    if (!started.isCompleted) {
      started.complete();
    }
    final pending = hold;
    if (pending != null) {
      await pending;
    }
    final reply = responses.removeAt(0);
    return ResponseBody.fromString(
      reply.body,
      reply.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        'etag': <String>[reply.etag],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Reply {
  _Reply({
    required this.status,
    required this.etag,
    required this.body,
    this.lang,
  });

  final int status;
  final String etag;
  final String body;
  final String? lang;
}

String _snapshot(String name) {
  return jsonEncode(<String, Object?>{
    'dataset_version': 'cat-1',
    'generated_at': '2026-01-01T00:00:00Z',
    'meals': <Object?>[
      <String, Object?>{
        'meal_id': 7,
        'name': name,
        'allergens': <String>[],
        'carb_g': 1,
        'dataset_version': 'b',
        'fat_g': 1,
        'ingredients': <Object?>[],
        'kcal': 100,
        'nutrients': <Object?>[],
        'protein_g': 1,
        'serving_grams': 100,
        'servings': 1,
        'source': 'test',
        'steps': <String>[],
        'tags': <String>[],
        'total_grams': 100,
      },
    ],
  });
}
