import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/water_day.dart';
import 'package:nutriguide/core/db/app_database.dart' hide DaySummary;
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/water/data/water_api.dart';
import 'package:nutriguide/features/water/data/water_repository.dart';
import 'package:nutriguide/features/water/domain/water.dart';

final _now = DateTime(2026, 10, 25, 9);

void main() {
  late AppDatabase database;
  late OutboxStore outbox;
  late WaterRepository water;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database, now: () => _now);
    water = WaterRepository(database, outbox, _DayApi(), now: () => _now);
  });

  tearDown(() => database.close());

  Future<List<WaterLog>> rows() => database.select(database.waterLogs).get();

  test('a glass and its WATER_CREATE are written together', () async {
    await water.add(250);
    final row = (await rows()).single;
    expect(row.state, 'PENDING');
    expect(row.logDate, '2026-10-25');
    final op = (await outbox.pending(10)).single;
    expect(op.opType, 'WATER_CREATE');
    expect(op.payload['client_uuid'], row.clientUuid);
    expect(op.payload['amount_ml'], 250);
    expect(op.entityRef, waterRef(row.clientUuid));
  });

  test('out-of-range amounts are refused before anything is stored', () async {
    await expectLater(water.add(40), throwsA(isA<WaterException>()));
    await expectLater(water.add(1050), throwsA(isA<WaterException>()));
    expect(await rows(), isEmpty);
  });

  test('deleting a pending glass removes its operation', () async {
    await water.add(150);
    await water.remove((await rows()).single.clientUuid);
    expect(await rows(), isEmpty);
    expect(await outbox.pending(10), isEmpty);
  });

  test('deleting a confirmed glass queues WATER_DELETE', () async {
    await database
        .into(database.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            clientUuid: 'c-1',
            serverLogId: const Value(12),
            amountMl: 250,
            consumedAt: _now.toUtc(),
            logDate: '2026-10-25',
            state: 'CONFIRMED',
          ),
        );
    await water.remove('c-1');
    expect((await rows()).single.state, 'DELETING');
    final op = (await outbox.pending(10)).single;
    expect(op.opType, 'WATER_DELETE');
    expect(op.payload['log_id'], 12);
  });

  test('provisional total: server + pending - deleting', () {
    const summary = DaySummary(
      date: '2026-10-25',
      planItemsTotal: 0,
      planItemsConsumed: 0,
      totalMl: 750,
      requiresClinician: false,
      goalMl: 2000,
    );
    final view = waterView(summary, <WaterEntry>[
      WaterEntry(
        clientUuid: 'a',
        amountMl: 500,
        consumedAt: _now,
        state: 'PENDING',
      ),
      WaterEntry(
        clientUuid: 'b',
        amountMl: 250,
        consumedAt: _now,
        state: 'DELETING',
      ),
      WaterEntry(
        clientUuid: 'c',
        amountMl: 500,
        consumedAt: _now,
        state: 'CONFIRMED',
      ),
    ]);
    expect(view.totalMl, 1000);
    expect(view.provisional, isTrue);
    expect(view.entries.map((entry) => entry.clientUuid), <String>['a', 'c']);
    expect(view.mode, WaterGoalMode.goal);
  });

  test('a doctor-set amount with none stored has no number mode', () {
    const summary = DaySummary(
      date: '2026-10-25',
      planItemsTotal: 0,
      planItemsConsumed: 0,
      totalMl: 0,
      requiresClinician: true,
    );
    final view = waterView(summary, const <WaterEntry>[]);
    expect(view.mode, WaterGoalMode.clinician);
    expect(view.progress, 0);
  });

  test('refresh stores the server total, goal and glasses', () async {
    await water.refresh(_now);
    final summary = await database.select(database.daySummaries).getSingle();
    expect(summary.totalMl, 750);
    expect(summary.goalMl, 2500);
    expect(summary.waterSource, 'USER');
    expect((await rows()).map((row) => row.serverLogId), <int>[3, 4]);
  });

  test('the goal goes back with the whole profile', () async {
    final adapter = _Recorder();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    await WaterApi(dio).setGoal(1500);
    final put = adapter.requests.last;
    expect(put.method, 'PUT');
    expect(put.path, '/api/v1/me/profile');
    final body = put.body!;
    expect(body['water_goal_ml'], 1500);
    expect(body['sex'], 'FEMALE');
    expect(body['birth_date'], '1996-10-25');
    expect(body.containsKey('latest_weight_kg'), isFalse);
    expect(body.containsKey('latest_weight_on'), isFalse);
  });
}

class _DayApi extends WaterApi {
  _DayApi() : super(Dio());

  @override
  Future<WaterDay> day(DateTime date) async {
    return WaterDay.fromJson(<String, Object?>{
      'date': '2026-10-25',
      'total_ml': 750,
      'goal': <String, Object?>{
        'goal_ml': 2500,
        'reminders_default_off': false,
        'requires_clinician': false,
        'source': 'USER',
      },
      'logs': <Object?>[
        <String, Object?>{
          'log_id': 3,
          'amount_ml': 250,
          'consumed_at': '2026-10-25T06:00:00Z',
        },
        <String, Object?>{
          'log_id': 4,
          'amount_ml': 500,
          'consumed_at': '2026-10-25T07:00:00Z',
        },
      ],
    });
  }
}

class _Recorded {
  _Recorded(this.method, this.path, this.body);

  final String method;
  final String path;
  final Map<String, Object?>? body;
}

class _Recorder implements HttpClientAdapter {
  final List<_Recorded> requests = <_Recorded>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Map<String, Object?>? body;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      body = Map<String, Object?>.from(jsonDecode(utf8.decode(bytes)) as Map);
    }
    requests.add(_Recorded(options.method, options.path, body));
    final reply = options.method == 'GET'
        ? <String, Object?>{
            'profile': <String, Object?>{
              'sex': 'FEMALE',
              'birth_date': '1996-10-25',
              'height_cm': 165,
              'activity_level': 'LIGHT',
              'goal_type': 'LOSE',
              'timezone': 'Africa/Cairo',
              'wake_time': '07:00',
              'sleep_time': '23:00',
              'conditions': <Object?>[
                <String, Object?>{'code': 'HEART_DISEASE', 'severity': null},
              ],
              'allergens': <Object?>[],
              'ingredient_prefs': <Object?>[],
              'cuisines': <Object?>[],
              'latest_weight_kg': 80,
              'latest_weight_on': '2026-10-24',
              'water_goal_ml': null,
            },
            'screening': <String, Object?>{'eligible': true},
          }
        : <String, Object?>{};
    return ResponseBody.fromString(
      jsonEncode(reply),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
