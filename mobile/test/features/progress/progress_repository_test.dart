import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/adherence_range_out.dart';
import 'package:nutriguide/core/api/generated/models/weight_point.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/plan/domain/plan_dates.dart';
import 'package:nutriguide/features/progress/data/progress_repository.dart';

void main() {
  late AppDatabase database;
  late _RangeApi api;
  late ProgressRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = _RangeApi();
    repository = ProgressRepository(
      database,
      api,
      now: () => DateTime(2026, 10, 25, 9),
    );
  });

  tearDown(() => database.close());

  test('a 120-day range is two calls of at most 92 days', () async {
    await repository.fetchAdherence(
      DateTime(2026, 6, 28),
      DateTime(2026, 10, 25),
    );
    expect(api.calls, hasLength(2));
    for (final call in api.calls) {
      expect(call.$2.difference(call.$1).inDays + 1, lessThanOrEqualTo(92));
    }
    expect(api.calls.first.$1, DateTime(2026, 6, 28));
    expect(api.calls.last.$2, DateTime(2026, 10, 25));
    expect(api.calls.last.$1, api.calls.first.$2.add(const Duration(days: 1)));
    final rows = await database.select(database.adherenceDays).get();
    expect(rows, hasLength(120));
  });

  test(
    'rows are upserted and the streak comes from the chunk ending today',
    () async {
      await repository.fetchAdherence(
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 25),
      );
      api.kcal = 1700;
      await repository.fetchAdherence(
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 25),
      );
      final rows = await database.select(database.adherenceDays).get();
      expect(rows, hasLength(7));
      expect(rows.every((row) => row.kcal == 1700), isTrue);
      final day = adherenceFromRow(
        rows.firstWhere((row) => row.date == '2026-10-25'),
      );
      expect(day.status, 'ACHIEVED');
      expect(day.unmet.single.nutrient, 'fiber');
      expect(day.exceeded.single.limit, 2000);
      expect(await repository.watchStreak().first, 4);
    },
  );

  test('the report range is one call', () async {
    await repository.refresh();
    expect(api.calls, hasLength(1));
    final range = repository.reportRange();
    expect(range.to, DateTime(2026, 10, 25));
    expect(range.to.difference(range.from).inDays + 1, lessThanOrEqualTo(92));
  });

  test('server weights fill the table; a pending local weight stays', () async {
    await database
        .into(database.weights)
        .insert(
          WeightsCompanion.insert(
            measuredOn: '2026-10-25',
            weightKg: 78.1,
            updatedAt: DateTime.utc(2026, 10, 25, 7),
            state: 'PENDING',
          ),
        );
    await repository.fetchWeights();
    final rows = {
      for (final row in await database.select(database.weights).get())
        row.measuredOn: row,
    };
    expect(rows['2026-10-25']!.weightKg, 78.1);
    expect(rows['2026-10-01']!.weightKg, 80);
    expect(rows['2026-10-01']!.state, 'CONFIRMED');
  });
}

class _RangeApi extends ProgressApi {
  _RangeApi() : super(Dio());

  final List<(DateTime, DateTime)> calls = <(DateTime, DateTime)>[];
  double kcal = 1500;

  @override
  Future<AdherenceRangeOut> adherence(DateTime from, DateTime to) async {
    calls.add((from, to));
    final days = <Map<String, Object?>>[];
    for (
      var date = from;
      !date.isAfter(to);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      days.add(<String, Object?>{
        'date': isoDate(date),
        'status': 'ACHIEVED',
        'completion': 1,
        'target_kcal': 1540,
        'totals': <String, Object?>{'kcal': kcal, 'protein_g': 100},
        'log_count': 3,
        'plan_items_total': 4,
        'plan_items_consumed': 3,
        'unmet_minimums': <Object?>[
          <String, Object?>{'nutrient': 'fiber', 'minimum': 22, 'total': 15},
        ],
        'exceeded_limits': <Object?>[
          <String, Object?>{'nutrient': 'sodium', 'limit': 2000, 'total': 2400},
        ],
      });
    }
    return AdherenceRangeOut.fromJson(<String, Object?>{
      'days': days,
      'streak': 4,
    });
  }

  @override
  Future<List<WeightPoint>> weights(DateTime from, DateTime to) async {
    return <WeightPoint>[
      WeightPoint.fromJson(const <String, Object?>{
        'measured_on': '2026-10-01',
        'weight_kg': 80,
      }),
      WeightPoint.fromJson(const <String, Object?>{
        'measured_on': '2026-10-25',
        'weight_kg': 78.5,
      }),
    ];
  }
}
