import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/domain/meal_timing.dart';
import '../../plan/domain/plan.dart';
import '../../plan/domain/plan_dates.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/logging_providers.dart';
import '../domain/logging.dart';
import 'eat_button.dart';

/// «فاتك موعد …»: the last item whose window is over and that nothing logs.
/// Logging it here sets consumed_at to the end of its window.
class MissedMealCard extends ConsumerWidget {
  const MissedMealCard({
    required this.plan,
    required this.windows,
    required this.now,
    super.key,
  });

  final DayPlan plan;
  final List<MealWindowSpan> windows;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs =
        ref.watch(dayLogsProvider(plan.planDate)).asData?.value ??
        const <LoggedMeal>[];
    final missed = missedItem(plan, windows, logs, now);
    if (missed == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final item = missed.item;
    return Container(
      key: Key('missed-${item.planItemId}'),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.missedTitle(slotLabel(l10n, item.slot)),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(l10n.missedBody),
                Text(
                  item.mealName,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.fg2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: <Widget>[
              EatButton(item: item, consumedAt: missed.windowEnd),
              Text(
                l10n.missedAction,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The latest item of today's plan whose window has ended without a log.
({PlanItem item, DateTime windowEnd})? missedItem(
  DayPlan plan,
  List<MealWindowSpan> windows,
  List<LoggedMeal> logs,
  DateTime now,
) {
  if (plan.planDate != isoDate(dateOnly(now))) {
    return null;
  }
  final minutes = now.hour * 60 + now.minute;
  ({PlanItem item, DateTime windowEnd})? latest;
  for (final item in displayItems(plan.items)) {
    if (isEaten(item, logs) ||
        logStateOf(item, logs) == PlanItemLogState.rejected) {
      continue;
    }
    MealWindowSpan? span;
    for (final window in windows) {
      if (window.slot == item.slot) {
        span = window;
      }
    }
    if (span == null) {
      continue;
    }
    final when = mealWhen(
      logged: false,
      start: span.start,
      end: span.end,
      nowMinutes: minutes,
    );
    if (when != MealWhen.missed) {
      continue;
    }
    final end = clockMinutes(span.end);
    latest = (
      item: item,
      windowEnd: DateTime(now.year, now.month, now.day, end ~/ 60, end % 60),
    );
  }
  return latest;
}
