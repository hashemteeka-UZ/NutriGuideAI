import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/generated/models/adherence_range_out.dart';
import '../../../core/api/generated/models/day_adherence_out.dart';
import '../../../core/api/generated/models/weight_point.dart';
import '../../../core/db/app_database.dart' as db;
import '../../../core/network/app_failure.dart';
import '../../../core/sync/sync_engine.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/progress.dart';

/// `GET /adherence` and `GET /weights`.
class ProgressApi {
  ProgressApi(this._dio);

  final Dio _dio;

  Future<AdherenceRangeOut> adherence(DateTime from, DateTime to) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/adherence',
        queryParameters: <String, Object?>{
          'from': isoDate(dateOnly(from)),
          'to': isoDate(dateOnly(to)),
        },
      );
      return AdherenceRangeOut.fromJson(_object(response.data));
    });
  }

  Future<List<WeightPoint>> weights(DateTime from, DateTime to) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/weights',
        queryParameters: <String, Object?>{
          'from': isoDate(dateOnly(from)),
          'to': isoDate(dateOnly(to)),
        },
      );
      final data = response.data;
      if (data is! List) {
        throw const ProgressException('UNEXPECTED');
      }
      return <WeightPoint>[
        for (final Object? item in data) WeightPoint.fromJson(_object(item)),
      ];
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ProgressException {
      rethrow;
    } on DioException catch (error) {
      final failure = mapDioException(error);
      throw switch (failure) {
        NetworkUnavailable() ||
        Timeout() => const ProgressException('NETWORK', network: true),
        ApiProblem(:final code) => ProgressException(code),
        UnexpectedResponse() => const ProgressException('UNEXPECTED'),
      };
    } on Object {
      throw const ProgressException('UNEXPECTED');
    }
  }
}

class ProgressException implements Exception {
  const ProgressException(this.code, {this.network = false});

  final String code;
  final bool network;

  @override
  String toString() => 'ProgressException($code, network: $network)';
}

Map<String, Object?> _object(Object? data) {
  if (data is Map) {
    return Map<String, Object?>.from(data);
  }
  throw const ProgressException('UNEXPECTED');
}

/// The longest range one `GET /adherence` accepts.
const adherenceChunkDays = 92;

const _streakKey = 'streak';

/// Caches adherence days, the streak and weights (Decisions #277, #281).
class ProgressRepository {
  ProgressRepository(this._database, this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final ProgressApi _api;
  final DateTime Function() _now;
  Future<void>? _refreshing;

  /// The days the tab shows: twelve weeks back and the current month.
  ({DateTime from, DateTime to}) reportRange() {
    final today = dateOnly(_now());
    final weeks = DateTime(today.year, today.month, today.day - 7 * 12 - 6);
    final month = DateTime(today.year, today.month);
    return (from: weeks.isBefore(month) ? weeks : month, to: today);
  }

  /// One refresh at a time; callers share it.
  Future<void> refresh() {
    final current = _refreshing;
    if (current != null) {
      return current;
    }
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
  }

  Future<void> _refresh() async {
    final range = reportRange();
    await fetchAdherence(range.from, range.to);
    await fetchWeights();
  }

  /// `GET /adherence` in chunks of at most 92 days, oldest first. The
  /// streak comes from the chunk that ends on [to].
  Future<void> fetchAdherence(DateTime from, DateTime to) async {
    final start = dateOnly(from);
    final end = dateOnly(to);
    final fetchedAt = _now().toUtc();
    var chunkStart = start;
    while (!chunkStart.isAfter(end)) {
      var chunkEnd = DateTime(
        chunkStart.year,
        chunkStart.month,
        chunkStart.day + adherenceChunkDays - 1,
      );
      if (chunkEnd.isAfter(end)) {
        chunkEnd = end;
      }
      final range = await _api.adherence(chunkStart, chunkEnd);
      await _database.transaction(() async {
        for (final day in range.days) {
          await _database
              .into(_database.adherenceDays)
              .insertOnConflictUpdate(_companion(day, fetchedAt));
        }
        if (isoDate(chunkEnd) == isoDate(end)) {
          await _database
              .into(_database.progressMeta)
              .insertOnConflictUpdate(
                db.ProgressMetaCompanion.insert(
                  key: _streakKey,
                  value: '${range.streak}',
                ),
              );
        }
      });
      chunkStart = DateTime(chunkEnd.year, chunkEnd.month, chunkEnd.day + 1);
    }
  }

  /// The last 90 days of weights. A PENDING local weight is kept.
  Future<void> fetchWeights() async {
    final today = dateOnly(_now());
    final points = await _api.weights(
      DateTime(today.year, today.month, today.day - 89),
      today,
    );
    await _database.transaction(() async {
      for (final point in points) {
        final measuredOn = isoDate(dateOnly(point.measuredOn));
        final existing = await (_database.select(
          _database.weights,
        )..where((t) => t.measuredOn.equals(measuredOn))).getSingleOrNull();
        if (existing != null && existing.state == logPending) {
          continue;
        }
        await _database
            .into(_database.weights)
            .insertOnConflictUpdate(
              db.WeightsCompanion.insert(
                measuredOn: measuredOn,
                weightKg: point.weightKg.toDouble(),
                updatedAt: existing?.updatedAt ?? _now().toUtc(),
                state: logConfirmed,
              ),
            );
      }
    });
  }

  Stream<Map<String, AdherenceDay>> watchDays(String from, String to) {
    final query = _database.select(_database.adherenceDays)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(from) &
            t.date.isSmallerOrEqualValue(to),
      );
    return query.watch().map(
      (List<db.AdherenceDay> rows) => <String, AdherenceDay>{
        for (final row in rows) row.date: adherenceFromRow(row),
      },
    );
  }

  Stream<int?> watchStreak() {
    final query = _database.select(_database.progressMeta)
      ..where((t) => t.key.equals(_streakKey));
    return query.watchSingleOrNull().map(
      (db.ProgressMetaData? row) =>
          row == null ? null : int.tryParse(row.value),
    );
  }

  Stream<List<WeightPointView>> watchWeights(String from) {
    final query = _database.select(_database.weights)
      ..where((t) => t.measuredOn.isBiggerOrEqualValue(from));
    return query.watch().map(
      (List<db.Weight> rows) => <WeightPointView>[
        for (final row in rows)
          WeightPointView(
            date: dateFromIso(row.measuredOn),
            weightKg: row.weightKg,
          ),
      ],
    );
  }

  /// Confirmed water per date that has any, from the local glasses.
  Stream<Map<String, int>> watchWater(String from, String to) {
    final query = _database.select(_database.waterLogs)
      ..where(
        (t) =>
            t.logDate.isBiggerOrEqualValue(from) &
            t.logDate.isSmallerOrEqualValue(to) &
            t.state.equals(logConfirmed),
      );
    return query.watch().map((List<db.WaterLog> rows) {
      final sums = <String, int>{};
      for (final row in rows) {
        sums[row.logDate] = (sums[row.logDate] ?? 0) + row.amountMl;
      }
      return sums;
    });
  }
}

db.AdherenceDaysCompanion _companion(DayAdherenceOut day, DateTime fetchedAt) {
  final totals = day.totals;
  return db.AdherenceDaysCompanion.insert(
    date: isoDate(dateOnly(day.date)),
    status: Value(day.status?.json),
    completion: Value(day.completion?.toDouble()),
    targetKcal: Value(day.targetKcal?.toDouble()),
    kcal: Value(totals.kcal?.toDouble()),
    proteinG: Value(totals.proteinG?.toDouble()),
    carbG: Value(totals.carbG?.toDouble()),
    fatG: Value(totals.fatG?.toDouble()),
    fiberG: Value(totals.fiberG?.toDouble()),
    saturatedFatG: Value(totals.saturatedFatG?.toDouble()),
    sodiumMg: Value(totals.sodiumMg?.toDouble()),
    sugarsG: Value(totals.sugarsG?.toDouble()),
    unmetJson: jsonEncode(<Object?>[
      for (final unmet in day.unmetMinimums)
        <String, Object?>{
          'nutrient': unmet.nutrient,
          'minimum': unmet.minimum,
          'total': unmet.total,
        },
    ]),
    exceededJson: jsonEncode(<Object?>[
      for (final limit in day.exceededLimits)
        <String, Object?>{
          'nutrient': limit.nutrient,
          'limit': limit.limit,
          'total': limit.total,
        },
    ]),
    planItemsTotal: day.planItemsTotal,
    planItemsConsumed: day.planItemsConsumed,
    logCount: day.logCount,
    reason: Value(day.reason),
    fetchedAt: fetchedAt,
  );
}

AdherenceDay adherenceFromRow(db.AdherenceDay row) {
  List<Map<String, Object?>> list(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[
      for (final Object? item in decoded)
        if (item is Map) Map<String, Object?>.from(item),
    ];
  }

  double? number(Object? value) => value is num ? value.toDouble() : null;

  return AdherenceDay(
    date: row.date,
    status: row.status,
    completion: row.completion,
    targetKcal: row.targetKcal,
    kcal: row.kcal,
    proteinG: row.proteinG,
    carbG: row.carbG,
    fatG: row.fatG,
    unmet: <MinimumAmount>[
      for (final item in list(row.unmetJson))
        MinimumAmount(
          nutrient: '${item['nutrient']}',
          minimum: number(item['minimum']) ?? 0,
          total: number(item['total']),
        ),
    ],
    exceeded: <LimitAmount>[
      for (final item in list(row.exceededJson))
        LimitAmount(
          nutrient: '${item['nutrient']}',
          limit: number(item['limit']) ?? 0,
          total: number(item['total']),
        ),
    ],
    planItemsTotal: row.planItemsTotal,
    planItemsConsumed: row.planItemsConsumed,
    logCount: row.logCount,
    reason: row.reason,
  );
}
