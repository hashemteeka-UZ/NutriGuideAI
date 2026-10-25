import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/l10n/app_localizations_ar.dart';
import 'package:nutriguide/features/logging/domain/logging.dart';
import 'package:nutriguide/features/logging/presentation/missed_meal_card.dart';
import 'package:nutriguide/features/logging/presentation/rejected_messages.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';

import '../../support/plan_samples.dart';

LoggedMeal _log(
  int planItemId,
  String state, {
  double servings = 1,
  double? kcal,
}) {
  return LoggedMeal(
    clientUuid: 'c-$planItemId-$state',
    kind: 'PLAN_ITEM',
    planItemId: planItemId,
    logDate: '2026-10-24',
    consumedAt: DateTime.utc(2026, 10, 24, 8),
    state: state,
    servingsConsumed: servings,
    kcal: kcal,
  );
}

void main() {
  final items = <PlanItem>[
    sampleItem(planItemId: 1, kcal: 400),
    sampleItem(planItemId: 2, slot: 'LUNCH', kcal: 600),
  ];

  test('a pending half portion adds half of the item server kcal', () {
    final totals = provisionalTotals(items, <LoggedMeal>[
      _log(1, 'PENDING', servings: 0.5),
    ]);
    expect(totals.kcal, 200);
    expect(totals.proteinG, 10);
    expect(totals.active, isTrue);
  });

  test('confirmed logs add nothing: the server totals hold them', () {
    final totals = provisionalTotals(items, <LoggedMeal>[
      _log(1, 'CONFIRMED', kcal: 400),
    ]);
    expect(totals.kcal, 0);
    expect(totals.active, isFalse);
  });

  test('an undo not sent yet takes its server kcal back out', () {
    final totals = provisionalTotals(items, <LoggedMeal>[
      _log(2, 'DELETING', kcal: 610),
    ]);
    expect(totals.kcal, -610);
    expect(totals.active, isTrue);
  });

  test('item state: pending, confirmed, undone and from another device', () {
    final item = items.first;
    expect(logStateOf(item, <LoggedMeal>[]), PlanItemLogState.none);
    expect(
      logStateOf(item, <LoggedMeal>[_log(1, 'PENDING')]),
      PlanItemLogState.pending,
    );
    expect(
      logStateOf(item, <LoggedMeal>[_log(1, 'DELETING')]),
      PlanItemLogState.none,
    );
    expect(
      logStateOf(sampleItem(planItemId: 1, logged: true), <LoggedMeal>[]),
      PlanItemLogState.confirmed,
    );
    expect(
      logStateOf(item, <LoggedMeal>[_log(1, 'REJECTED')]),
      PlanItemLogState.rejected,
    );
  });

  test('the missed card picks the last window that ended unlogged', () {
    final plan = sampleDay(planDate: '2026-10-24', items: items);
    const windows = <MealWindowSpan>[
      MealWindowSpan(
        date: '2026-10-24',
        slot: 'BREAKFAST',
        start: '07:30',
        end: '09:30',
      ),
      MealWindowSpan(
        date: '2026-10-24',
        slot: 'LUNCH',
        start: '13:00',
        end: '15:00',
      ),
    ];
    final afternoon = DateTime(2026, 10, 24, 16);
    final missed = missedItem(plan, windows, const <LoggedMeal>[], afternoon);
    expect(missed?.item.planItemId, 2);
    expect(missed?.windowEnd, DateTime(2026, 10, 24, 15));

    final lunchLogged = missedItem(plan, windows, <LoggedMeal>[
      _log(2, 'PENDING'),
    ], afternoon);
    expect(lunchLogged?.item.planItemId, 1);

    final morning = missedItem(
      plan,
      windows,
      const <LoggedMeal>[],
      DateTime(2026, 10, 24, 8),
    );
    expect(morning, isNull);
    final otherDay = missedItem(
      plan,
      windows,
      const <LoggedMeal>[],
      DateTime(2026, 10, 25, 16),
    );
    expect(otherDay, isNull);
  });

  test('status badge order', () {
    expect(SyncStatusView.idle.badge, SyncBadge.hidden);
    expect(
      const SyncStatusView(uploading: false, pending: 2, rejected: 0).badge,
      SyncBadge.waiting,
    );
    expect(
      const SyncStatusView(uploading: true, pending: 2, rejected: 0).badge,
      SyncBadge.uploading,
    );
    expect(
      const SyncStatusView(uploading: true, pending: 0, rejected: 0).badge,
      SyncBadge.hidden,
    );
    expect(
      const SyncStatusView(uploading: false, pending: 0, rejected: 1).badge,
      SyncBadge.rejected,
    );
  });

  test('rejected codes have messages and an unknown code gets the generic', () {
    final l10n = AppLocalizationsAr();
    expect(
      rejectedMessage(l10n, 'CLIENT_UUID_CONFLICT'),
      l10n.failureClientUuidConflict,
    );
    expect(
      rejectedMessage(l10n, 'PLAN_ITEM_NOT_FOUND'),
      l10n.failurePlanItemNotFound,
    );
    expect(rejectedMessage(l10n, 'LOG_NOT_FOUND'), l10n.failureLogNotFound);
    expect(rejectedMessage(l10n, 'CLOCK_SKEW'), l10n.failureClockSkew);
    expect(rejectedMessage(l10n, 'BRAND_NEW_CODE'), 'تعذر حفظ هذا التسجيل');
  });
}
