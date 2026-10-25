import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../today/presentation/today_screen.dart';
import '../data/plan_providers.dart';
import '../data/plan_sync.dart';
import '../data/user_context.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import 'offline_bar.dart';
import 'plan_chart.dart';
import 'plan_format.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final now = ref.watch(planClockProvider)();
    final dates = weekDates(dateOnly(now));
    final selected =
        ref.watch(selectedPlanDateProvider) ?? isoDate(dates.first);
    final plans =
        ref.watch(weekPlansProvider).asData?.value ?? const <DayPlan>[];
    final byDate = <String, DayPlan>{
      for (final plan in plans) plan.planDate: plan,
    };
    final day = byDate[selected];
    final windows =
        ref.watch(selectedWindowsProvider).asData?.value ?? const [];
    final likes = ref.watch(likeCountProvider).asData?.value ?? 0;
    final general = ref.watch(userContextProvider)?.eligible == false;
    final target = day?.target.kcal ?? _firstTarget(plans);
    return Scaffold(
      key: const Key('plan-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(planSyncProvider).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.planTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (!general)
                          IconButton(
                            key: const Key('plan-rebuild'),
                            tooltip: l10n.planRebuild,
                            onPressed: () => _confirmRebuild(context, ref),
                            icon: const Icon(Icons.refresh),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      l10n.planRange(
                        formatMonthDay(context, dates.first),
                        formatMonthDay(context, dates.last),
                      ),
                    ),
                    Text(
                      l10n.planOptimizer,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.fg2),
                    ),
                    const SizedBox(height: 12),
                    _DaySelector(dates: dates, selected: selected),
                    const SizedBox(height: 12),
                    PlanChart(
                      days: <ChartDay>[
                        for (final date in dates)
                          ChartDay(
                            label: formatShortDay(context, date),
                            kcal: byDate[isoDate(date)]?.totals.kcal?.round(),
                            selected: isoDate(date) == selected,
                          ),
                      ],
                      targetKcal: target,
                      summary: _chartSummary(context, dates, byDate),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _LinkCard(
                            key: const Key('plan-shopping'),
                            title: l10n.shopTitle,
                            subtitle: l10n.shopFromPlan,
                            onTap: () => context.push('/plan/shopping'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LinkCard(
                            key: const Key('plan-favourites'),
                            title: l10n.favouritesCard,
                            subtitle: l10n.favouritesCount(likes),
                            onTap: () => context.push('/meals/favourites'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (general)
                      Text(
                        l10n.generalPlanTip,
                        key: const Key('general-plan-tip'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else if (day == null)
                      _EmptyDay(onBuild: () => openGeneration(context, ref))
                    else
                      _DayBody(day: day, windows: windows),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? _firstTarget(List<DayPlan> plans) {
  for (final plan in plans) {
    return plan.target.kcal;
  }
  return null;
}

String _chartSummary(
  BuildContext context,
  List<DateTime> dates,
  Map<String, DayPlan> byDate,
) {
  final l10n = AppLocalizations.of(context);
  return <String>[
    for (final date in dates)
      '${formatShortDay(context, date)} ${byDate[isoDate(date)]?.totals.kcal == null ? l10n.chartNoPlan : formatWhole(context, byDate[isoDate(date)]!.totals.kcal!)}',
  ].join(', ');
}

Future<void> _confirmRebuild(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        key: const Key('rebuild-dialog'),
        content: Text(l10n.planRebuildBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.planCancel),
          ),
          TextButton(
            key: const Key('rebuild-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.planRebuildConfirm),
          ),
        ],
      );
    },
  );
  if (confirmed == true && context.mounted) {
    openGeneration(context, ref);
  }
}

class _DaySelector extends ConsumerWidget {
  const _DaySelector({required this.dates, required this.selected});

  final List<DateTime> dates;
  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final date = dates[index];
          final iso = isoDate(date);
          final on = iso == selected;
          return ChoiceChip(
            key: Key('plan-day-$iso'),
            label: Text(formatShortDay(context, date)),
            selected: on,
            onSelected: (_) {
              ref.read(selectedPlanDateProvider.notifier).select(iso);
              unawaited(_quiet(ref, date));
            },
            selectedColor: colors.brandSoft,
          );
        },
      ),
    );
  }
}

Future<void> _quiet(WidgetRef ref, DateTime date) async {
  try {
    await ref.read(todayRepositoryProvider).refreshDay(date);
  } on Object {
    // Keep the cached windows.
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.planEmpty, key: const Key('plan-empty')),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('plan-build'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: onBuild,
          child: Text(l10n.todayBuildWeek),
        ),
      ],
    );
  }
}

class _DayBody extends StatelessWidget {
  const _DayBody({required this.day, required this.windows});

  final DayPlan day;
  final List<MealWindowSpan> windows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final kcal = day.totals.kcal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.planDayKcal(
            formatWeekday(context, dateFromIso(day.planDate)),
            kcal == null ? '—' : formatWhole(context, kcal),
          ),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (day.kcalWithin10pct)
              Chip(key: const Key('within-band'), label: Text(l10n.withinBand)),
            for (final unmet in day.unmetMinimums)
              Chip(
                label: Text(
                  l10n.belowMinimum(nutrientName(l10n, unmet.nutrient)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in displayItems(day.items))
          ListTile(
            key: Key('plan-row-${item.planItemId}'),
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 12,
            title: Text(item.mealName),
            subtitle: Text(
              '${slotLabel(l10n, item.slot)} · ${_start(context, windows, item.slot)}',
            ),
            trailing: Text(formatWhole(context, item.kcal)),
            onTap: () => context.push('/plan/item/${item.planItemId}'),
          ),
        if (day.items.isEmpty)
          Text(l10n.planEmpty, style: TextStyle(color: colors.fg2)),
      ],
    );
  }
}

String _start(BuildContext context, List<MealWindowSpan> windows, String slot) {
  for (final window in windows) {
    if (window.slot == slot) {
      return formatHm(context, window.start);
    }
  }
  return '';
}
