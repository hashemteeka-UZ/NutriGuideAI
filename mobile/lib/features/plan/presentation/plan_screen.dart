import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../today/presentation/today_look.dart';
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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.planTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: colors.fg,
                                ),
                              ),
                              Text(
                                l10n.planRange(
                                  formatMonthDay(context, dates.first),
                                  formatMonthDay(context, dates.last),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.fg3,
                                ),
                              ),
                              Text(
                                l10n.planOptimizer,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.fg3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!general)
                          Material(
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: colors.line),
                            ),
                            child: IconButton(
                              key: const Key('plan-rebuild'),
                              tooltip: l10n.planRebuild,
                              onPressed: () => _confirmRebuild(context, ref),
                              icon: Icon(Icons.refresh, color: colors.fg2),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DaySelector(dates: dates, selected: selected),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  l10n.planChartTitle,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (target != null)
                                Text(
                                  l10n.planChartTarget(
                                    formatWhole(context, target),
                                  ),
                                  style: colors.numeric.copyWith(
                                    fontSize: 13,
                                    color: colors.fg3,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PlanChart(
                            days: <ChartDay>[
                              for (final date in dates)
                                ChartDay(
                                  label: formatShortDay(context, date),
                                  kcal: byDate[isoDate(date)]?.totals.kcal
                                      ?.round(),
                                  selected: isoDate(date) == selected,
                                ),
                            ],
                            targetKcal: target,
                            summary: _chartSummary(context, dates, byDate),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              for (final date in dates)
                                Expanded(
                                  child: Text(
                                    formatWhole(context, date.day),
                                    textAlign: TextAlign.center,
                                    style: colors.numeric.copyWith(
                                      fontSize: 11,
                                      color: colors.fg3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _LinkCard(
                            key: const Key('plan-shopping'),
                            emoji: 'shopping-cart',
                            tint: colors.kcal,
                            title: l10n.shopTitle,
                            subtitle: l10n.shopFromPlan,
                            onTap: () => context.push('/plan/shopping'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LinkCard(
                            key: const Key('plan-favourites'),
                            emoji: 'red-heart',
                            tint: colors.protein,
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
    return Row(
      children: <Widget>[
        for (final date in dates)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayButton(
                key: Key('plan-day-${isoDate(date)}'),
                label: formatShortDay(context, date),
                day: formatWhole(context, date.day),
                on: isoDate(date) == selected,
                colors: colors,
                onTap: () {
                  ref
                      .read(selectedPlanDateProvider.notifier)
                      .select(isoDate(date));
                  unawaited(_quiet(ref, date));
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.day,
    required this.on,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String label;
  final String day;
  final bool on;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? colors.brand : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: on ? BorderSide.none : BorderSide(color: colors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: on ? colors.onBrand : colors.fg2,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day,
                  style: colors.numeric.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: on ? colors.onBrand : colors.fg,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required this.emoji,
    required this.tint,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String emoji;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      tint: tint,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Emoji(emoji, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: colors.fg3),
                ),
              ],
            ),
          ),
        ],
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (day.kcalWithin10pct)
              _Pill(
                key: const Key('within-band'),
                emoji: 'check-mark-button',
                label: l10n.withinBand,
                color: colors.brand2,
                background: colors.brand.withValues(alpha: 0.14),
              ),
            for (final unmet in day.unmetMinimums)
              _Pill(
                emoji: 'warning',
                label: l10n.belowMinimum(nutrientName(l10n, unmet.nutrient)),
                color: colors.fg,
                background: colors.part.withValues(alpha: 0.18),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in displayItems(day.items))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              key: Key('plan-row-${item.planItemId}'),
              radius: 22,
              padding: const EdgeInsets.all(12),
              onTap: () => context.push('/plan/item/${item.planItemId}'),
              child: Row(
                children: <Widget>[
                  EmojiTile(
                    mealEmoji(item),
                    size: 54,
                    emojiSize: 36,
                    radius: 18,
                    tint: slotTint(colors, item.slot),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${slotLabel(l10n, item.slot)} · ${_start(context, windows, item.slot)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.fg3,
                          ),
                        ),
                        Text(
                          item.mealName,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.mealKcal(formatWhole(context, item.kcal)),
                          style: colors.numeric.copyWith(
                            fontSize: 12.5,
                            color: colors.fg3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colors.fg3,
                  ),
                ],
              ),
            ),
          ),
        if (day.items.isEmpty)
          Text(l10n.planEmpty, style: TextStyle(color: colors.fg2)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.emoji,
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });

  final String emoji;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Emoji(emoji, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
