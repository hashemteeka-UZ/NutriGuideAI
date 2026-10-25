import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/weight_out.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/plan/data/user_context.dart';
import 'package:nutriguide/features/plan/domain/cached_user.dart';
import 'package:nutriguide/features/weight/data/weight_providers.dart';
import 'package:nutriguide/features/weight/data/weight_repository.dart';
import 'package:nutriguide/features/weight/domain/weight.dart';

import '../../support/pump_app.dart';

void main() {
  late AppDatabase database;
  late OutboxStore outbox;
  var clock = DateTime(2026, 10, 25, 9);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxStore(database);
    clock = DateTime(2026, 10, 25, 9);
  });

  tearDown(() => database.close());

  test('online: the answer reports goal reached and a new target', () async {
    final api = _AnswerApi(<String, Object?>{
      'measured_on': '2026-10-25',
      'weight_kg': 74.8,
      'status': 'CREATED',
      'target_status': 'CREATED',
      'goal_reached': true,
      'new_target_id': 31,
    });
    final repository = WeightRepository(
      database,
      outbox,
      api,
      now: () => clock,
    );
    final result = await repository.save(74.8);
    expect(result.status, WeightSaveStatus.created);
    expect(result.goalReached, isTrue);
    expect(result.newTargetId, 31);
    expect(result.targetStatus, 'CREATED');
    expect(api.sent.single['weight_kg'], 74.8);
    expect(await outbox.pending(10), isEmpty);
    final row = await database.select(database.weights).getSingle();
    expect(row.state, 'CONFIRMED');
  });

  test('STALE_IGNORED keeps the stored value', () async {
    final repository = WeightRepository(
      database,
      outbox,
      _AnswerApi(<String, Object?>{
        'measured_on': '2026-10-25',
        'weight_kg': 80,
        'status': 'STALE_IGNORED',
        'target_status': 'NOT_TRIGGERED',
        'goal_reached': false,
      }),
      now: () => clock,
    );
    final result = await repository.save(81);
    expect(result.status, WeightSaveStatus.staleIgnored);
    expect(await database.select(database.weights).get(), isEmpty);
  });

  test('offline: the weight waits as WEIGHT_PUT', () async {
    final repository = WeightRepository(
      database,
      outbox,
      OfflineWeightApi(),
      now: () => clock,
    );
    final result = await repository.save(79.6);
    expect(result.status, WeightSaveStatus.queued);
    final op = (await outbox.pending(10)).single;
    expect(op.opType, 'WEIGHT_PUT');
    expect(op.payload['measured_on'], '2026-10-25');
    expect(op.payload['weight_kg'], 79.6);
    final row = await database.select(database.weights).getSingle();
    expect(row.state, 'PENDING');
    expect(op.payload['updated_at'], row.updatedAt.toUtc().toIso8601String());
  });

  test('a second weight for the same day replaces the queued one', () async {
    final repository = WeightRepository(
      database,
      outbox,
      OfflineWeightApi(),
      now: () => clock,
    );
    await repository.save(79.6);
    clock = clock.add(const Duration(minutes: 10));
    await repository.save(79.1);
    final ops = await outbox.pending(10);
    expect(ops, hasLength(1));
    expect(ops.single.payload['weight_kg'], 79.1);
    expect(
      (await database.select(database.weights).getSingle()).weightKg,
      79.1,
    );
  });

  test('a validation refusal is not queued', () async {
    final repository = WeightRepository(
      database,
      outbox,
      OfflineWeightApi(),
      now: () => clock,
    );
    await expectLater(repository.save(10), throwsA(isA<WeightException>()));
    expect(await outbox.pending(10), isEmpty);
  });

  test('a changed target id raises the notice after a sync', () async {
    var refreshes = 0;
    final container = ProviderContainer(
      overrides: [
        userContextRefreshProvider.overrideWith((ref) {
          return () async {
            refreshes += 1;
            ref.read(userContextProvider.notifier).replace(_user(targetId: 31));
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(userContextProvider.notifier).replace(_user(targetId: 30));

    await container.read(targetRecheckProvider)();
    expect(refreshes, 1);
    expect(container.read(targetNoticeProvider), isTrue);

    container.read(targetNoticeProvider.notifier).dismiss();
    await container.read(targetRecheckProvider)();
    expect(container.read(targetNoticeProvider), isFalse);
  });
}

CachedUser _user({required int targetId}) {
  return CachedUser(
    eligible: true,
    goalType: 'LOSE',
    conditions: const <String>[],
    allergenCodes: const <String>[],
    hasDislike: false,
    target: EnergyTarget(
      kcal: 1540,
      bmrKcal: 1520,
      tdeeKcal: 2090,
      targetId: targetId,
    ),
  );
}

class _AnswerApi extends WeightApi {
  _AnswerApi(this.answer) : super(Dio());

  final Map<String, Object?> answer;
  final List<Map<String, Object?>> sent = <Map<String, Object?>>[];

  @override
  Future<WeightOut> put({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
  }) async {
    sent.add(<String, Object?>{
      'measured_on': measuredOn,
      'weight_kg': weightKg,
    });
    return WeightOut.fromJson(answer);
  }
}
