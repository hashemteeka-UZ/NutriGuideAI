import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/generated/models/weight_out.dart';
import '../../../core/api/manual/sync_models.dart';
import '../../../core/db/app_database.dart' as db;
import '../../../core/network/app_failure.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/weight.dart';

/// `PUT /weights/{measured_on}`. Thrown [WeightException] with code
/// NETWORK means no answer came back.
class WeightApi {
  WeightApi(this._dio);

  final Dio _dio;

  Future<WeightOut> put({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
  }) async {
    try {
      final response = await _dio.put<Object>(
        '/api/v1/weights/$measuredOn',
        data: <String, Object?>{
          'weight_kg': weightKg,
          'updated_at': wireInstant(updatedAt),
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const WeightException('UNEXPECTED');
      }
      return WeightOut.fromJson(Map<String, Object?>.from(data));
    } on DioException catch (error) {
      final failure = mapDioException(error);
      throw switch (failure) {
        NetworkUnavailable() || Timeout() => const WeightException('NETWORK'),
        ApiProblem(:final status, :final code) =>
          status >= 500
              ? const WeightException('NETWORK')
              : WeightException(code),
        UnexpectedResponse(:final status) =>
          status == null || status >= 500
              ? const WeightException('NETWORK')
              : const WeightException('UNEXPECTED'),
      };
    }
  }
}

/// The outbox key of the weight of one date.
String weightRef(String measuredOn) => 'weight:$measuredOn';

class WeightRepository {
  WeightRepository(
    this._database,
    this._outbox,
    this._api, {
    DateTime Function()? now,
    this._onAction,
  }) : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final OutboxStore _outbox;
  final WeightApi _api;
  final DateTime Function() _now;
  final void Function()? _onAction;

  /// Today's weight. Online it is a direct PUT, because the answer says
  /// whether the goal was reached or the target changed. Without a
  /// connection it waits in the outbox with the same `updated_at`.
  Future<WeightSaveResult> save(double weightKg) async {
    if (weightKg < 20 || weightKg > 400) {
      throw const WeightException('VALIDATION_ERROR');
    }
    final updatedAt = _now().toUtc();
    final measuredOn = isoDate(dateOnly(_now()));
    final WeightOut answer;
    try {
      answer = await _api.put(
        measuredOn: measuredOn,
        weightKg: weightKg,
        updatedAt: updatedAt,
      );
    } on WeightException catch (error) {
      if (error.code != 'NETWORK') {
        rethrow;
      }
      await queue(
        measuredOn: measuredOn,
        weightKg: weightKg,
        updatedAt: updatedAt,
      );
      return const WeightSaveResult(status: WeightSaveStatus.queued);
    }
    final status = switch (answer.status.json) {
      'CREATED' => WeightSaveStatus.created,
      'STALE_IGNORED' => WeightSaveStatus.staleIgnored,
      _ => WeightSaveStatus.updated,
    };
    await _database.transaction(() async {
      // The direct PUT supersedes an older weight waiting for that date.
      final ops = await _outbox.forEntity(weightRef(measuredOn));
      await _outbox.remove(<String>[for (final op in ops) op.opId]);
      if (status != WeightSaveStatus.staleIgnored) {
        await _database
            .into(_database.weights)
            .insertOnConflictUpdate(
              db.WeightsCompanion.insert(
                measuredOn: measuredOn,
                weightKg: weightKg,
                updatedAt: updatedAt,
                state: logConfirmed,
              ),
            );
      }
    });
    return WeightSaveResult(
      status: status,
      goalReached: answer.goalReached,
      newTargetId: answer.newTargetId,
      targetStatus: answer.targetStatus.json,
    );
  }

  /// Writes the weight PENDING and its WEIGHT_PUT in one transaction. A
  /// newer weight for the same date replaces the queued one.
  Future<void> queue({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
  }) async {
    await _database.transaction(() async {
      final ops = await _outbox.forEntity(weightRef(measuredOn));
      await _outbox.remove(<String>[for (final op in ops) op.opId]);
      await _database
          .into(_database.weights)
          .insertOnConflictUpdate(
            db.WeightsCompanion.insert(
              measuredOn: measuredOn,
              weightKg: weightKg,
              updatedAt: updatedAt,
              state: logPending,
            ),
          );
      await _outbox.enqueue(
        WeightPutOp(
          opId: _outbox.newId(),
          measuredOn: measuredOn,
          weightKg: weightKg,
          updatedAt: updatedAt,
        ),
        entityRef: weightRef(measuredOn),
      );
    });
    _onAction?.call();
  }

  /// The latest stored weight, newest date first.
  Stream<StoredWeight?> watchLatest() {
    final query = _database.select(_database.weights)
      ..orderBy(<OrderClauseGenerator<db.$WeightsTable>>[
        (t) => OrderingTerm.desc(t.measuredOn),
      ])
      ..limit(1);
    return query.watchSingleOrNull().map(
      (db.Weight? row) => row == null
          ? null
          : StoredWeight(
              measuredOn: row.measuredOn,
              weightKg: row.weightKg,
              pending: row.state == logPending,
            ),
    );
  }
}
