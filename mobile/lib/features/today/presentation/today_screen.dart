import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../catalog/domain/meal.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/plan_sync.dart';
import '../../plan/data/user_context.dart';
import '../../plan/domain/meal_timing.dart';
import '../../plan/domain/plan.dart';
import '../../plan/domain/plan_dates.dart';
import '../../plan/presentation/offline_bar.dart';
import '../../plan/presentation/plan_format.dart';
import '../../plan/presentation/reason_chips.dart';
import '../../plan/presentation/showcase_controller.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final now = ref.watch(planClockProvider)();
    final today = dateOnly(now);
    final user = ref.watch(userContextProvider);
    final general = user != null && !user.eligible;
    final plans =
        ref.watch(weekPlansProvider).asData?.value ?? const <DayPlan>[];
    final plan = ref.watch(todayPlanProvider).asData?.value;
    final summary = ref.watch(todaySummaryProvider).asData?.value;
    final windows =
        ref.watch(todayWindowsProvider).asData?.value ??
        const <MealWindowSpan>[];
    final names =
        ref.watch(conditionNamesProvider).asData?.value ??
        const <String, String>{};
    return Scaffold(
      key: const Key('today-screen'),
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
                    Text(
                      DateFormatHeading.format(context, today),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.fg2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      now.hour < 12 ? l10n.greetMorning : l10n.greetEvening,
                      key: const Key('today-greeting'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.fg,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _WeekStrip(today: today, plans: plans),
                    const SizedBox(height: 16),
                    if (general) ...<Widget>[
                      _GeneralCard(body: l10n.generalBody),
                      const SizedBox(height: 16),
                      const _HealthyRow(),
                    ] else if (plan == null) ...<Widget>[
                      _BuildCard(
                        title: l10n.todayNoPlan,
                        action: l10n.todayBuildWeek,
                        onPressed: () => openGeneration(context, ref),
                      ),
                    ] else ...<Widget>[
                      _CalorieCard(plan: plan, summary: summary),
                      const SizedBox(height: 12),
                      _NowCard(
                        plan: plan,
                        windows: windows,
                        now: now,
                        onOpen: (PlanItem item) {
                          context.push('/plan/item/${item.planItemId}');
                        },
                      ),
                      const SizedBox(height: 12),
                      _WaterCard(summary: summary),
                      const SizedBox(height: 16),
                      _Timeline(
                        plan: plan,
                        windows: windows,
                        now: now,
                        names: names,
                        onOpen: (PlanItem item) {
                          context.push('/plan/item/${item.planItemId}');
                        },
                      ),
                    ],
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

class DateFormatHeading {
  static String format(BuildContext context, DateTime date) {
    return formatDayHeading(context, date);
  }
}

void openGeneration(BuildContext context, WidgetRef ref) {
  unawaited(
    ref
        .read(showcaseControllerProvider.notifier)
        .start(force: true, hold: showcaseHoldFor(context)),
  );
  context.go('/generate');
}

Future<void> openPlanDay(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) async {
  ref.read(selectedPlanDateProvider.notifier).select(isoDate(date));
  try {
    await ref.read(todayRepositoryProvider).refreshDay(date);
  } on Object {
    // The cached plan stays on screen.
  }
  if (context.mounted) {
    context.go('/plan');
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.today, required this.plans});

  final DateTime today;
  final List<DayPlan> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final dates = weekDates(today);
    final planned = <String>{for (final plan in plans) plan.planDate};
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final date = dates[index];
          final iso = isoDate(date);
          final hasPlan = planned.contains(iso);
          final isToday = index == 0;
          return InkWell(
            key: Key('week-day-$iso'),
            onTap: () => openPlanDay(context, ref, date),
            borderRadius: BorderRadius.circular(16),
            child: _DayChip(
              label: formatShortDay(context, date),
              day: formatWhole(context, date.day),
              highlighted: isToday,
              dashed: !hasPlan,
              colors: colors,
            ),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.day,
    required this.highlighted,
    required this.dashed,
    required this.colors,
  });

  final String label;
  final String day;
  final bool highlighted;
  final bool dashed;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BorderPainter(
        color: highlighted ? colors.brand : colors.line,
        dashed: dashed,
      ),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              day,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                color: highlighted ? colors.brand : colors.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    if (!dashed) {
      canvas.drawRRect(rect, paint);
      return;
    }
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 4, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.dashed != dashed;
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.title,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      key: const Key('build-week-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('build-week'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onPressed,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _GeneralCard extends StatelessWidget {
  const _GeneralCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('general-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.generalTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _HealthyRow extends ConsumerWidget {
  const _HealthyRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final meals =
        ref.watch(healthyMealsProvider).asData?.value ??
        const <SuggestedMeal>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.healthyTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final meal = meals[index];
              return InkWell(
                key: Key('healthy-${meal.mealId}'),
                onTap: () => context.push('/meals/${meal.mealId}'),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Emoji(meal.iconName, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(l10n.mealKcal(formatWhole(context, meal.kcal))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalorieCard extends StatefulWidget {
  const _CalorieCard({required this.plan, required this.summary});

  final DayPlan plan;
  final DaySummary? summary;

  @override
  State<_CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<_CalorieCard> {
  var _left = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final target = widget.plan.target.kcal.toDouble();
    final eaten = widget.summary?.kcal ?? 0;
    final remaining = math.max(0, target - eaten);
    final shown = _left ? remaining : eaten;
    final percent = target <= 0 ? 0.0 : (shown / target).clamp(0, 1).toDouble();
    return Container(
      key: const Key('calorie-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: <Widget>[
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: Text(l10n.kcalModeEaten),
              ),
              ButtonSegment<bool>(value: true, label: Text(l10n.kcalModeLeft)),
            ],
            selected: <bool>{_left},
            onSelectionChanged: (Set<bool> value) {
              setState(() => _left = value.first);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _PercentRing(
                percent: percent,
                color: colors.kcal,
                track: colors.line,
              ),
              child: Center(
                child: Text(
                  formatWhole(context, shown),
                  key: const Key('calorie-value'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.kcal,
                  ),
                ),
              ),
            ),
          ),
          Text(_left ? l10n.kcalLeftCaption : l10n.kcalEatenCaption),
          Text(l10n.kcalOfTarget(formatWhole(context, target))),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Macro(
                label: l10n.nutrientProtein,
                eaten: widget.summary?.proteinG ?? 0,
                target: widget.plan.target.proteinG,
                left: _left,
                color: colors.protein,
              ),
              _Macro(
                label: l10n.nutrientCarbs,
                eaten: widget.summary?.carbG ?? 0,
                target: widget.plan.target.carbG,
                left: _left,
                color: colors.carb,
              ),
              _Macro(
                label: l10n.nutrientFat,
                eaten: widget.summary?.fatG ?? 0,
                target: widget.plan.target.fatG,
                left: _left,
                color: colors.fat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.eaten,
    required this.target,
    required this.left,
    required this.color,
  });

  final String label;
  final double eaten;
  final double target;
  final bool left;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shown = left ? math.max(0, target - eaten) : eaten;
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label, textAlign: TextAlign.center, maxLines: 2),
          Text(
            formatWhole(context, shown),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(formatWhole(context, target)),
        ],
      ),
    );
  }
}

class _PercentRing extends CustomPainter {
  _PercentRing({
    required this.percent,
    required this.color,
    required this.track,
  });

  final double percent;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * percent,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_PercentRing oldDelegate) =>
      oldDelegate.percent != percent;
}

class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.plan,
    required this.windows,
    required this.now,
    required this.onOpen,
  });

  final DayPlan plan;
  final List<MealWindowSpan> windows;
  final DateTime now;
  final void Function(PlanItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final minutes = now.hour * 60 + now.minute;
    PlanItem? current;
    MealWindowSpan? window;
    for (final item in displayItems(plan.items)) {
      final span = _span(windows, item.slot);
      if (span == null) {
        continue;
      }
      if (mealWhen(
            logged: item.logged,
            start: span.start,
            end: span.end,
            nowMinutes: minutes,
          ) ==
          MealWhen.now) {
        current = item;
        window = span;
        break;
      }
    }
    if (current == null || window == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final progress = windowProgress(
      start: window.start,
      end: window.end,
      nowMinutes: minutes,
    );
    final item = current;
    return InkWell(
      key: const Key('now-card'),
      onTap: () => onOpen(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.heroStart,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.nowCard(
                slotLabel(l10n, item.slot),
                formatHm(context, window.end),
              ),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(item.mealName, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.summary});

  final DaySummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final clinician = summary?.clinicianWithoutGoal ?? false;
    final total = summary?.totalMl ?? 0;
    final goal = summary?.goalMl;
    return InkWell(
      key: const Key('water-card'),
      onTap: () => context.go('/water'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.line),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.water_drop_outlined, color: colors.brand),
            const SizedBox(width: 8),
            Text(l10n.tabWater, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clinician
                    ? l10n.waterWithDoctor
                    : '${formatWhole(context, total)} / ${goal == null ? '—' : formatWhole(context, goal)}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.plan,
    required this.windows,
    required this.now,
    required this.names,
    required this.onOpen,
  });

  final DayPlan plan;
  final List<MealWindowSpan> windows;
  final DateTime now;
  final Map<String, String> names;
  final void Function(PlanItem item) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final minutes = now.hour * 60 + now.minute;
    final items = displayItems(plan.items);
    return Column(
      key: const Key('today-timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.todayMeals,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              key: const Key('full-plan'),
              onPressed: () {
                unawaited(
                  openPlanDay(context, ref, dateFromIso(plan.planDate)),
                );
              },
              child: Text(l10n.fullPlan),
            ),
          ],
        ),
        for (final item in items)
          _TimelineRow(
            item: item,
            window: _span(windows, item.slot),
            nowMinutes: minutes,
            names: names,
            onOpen: () => onOpen(item),
            colors: colors,
          ),
      ],
    );
  }
}

MealWindowSpan? _span(List<MealWindowSpan> windows, String slot) {
  for (final window in windows) {
    if (window.slot == slot) {
      return window;
    }
  }
  return null;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.window,
    required this.nowMinutes,
    required this.names,
    required this.onOpen,
    required this.colors,
  });

  final PlanItem item;
  final MealWindowSpan? window;
  final int nowMinutes;
  final Map<String, String> names;
  final VoidCallback onOpen;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = mealWhen(
      logged: item.logged,
      start: window?.start,
      end: window?.end,
      nowMinutes: nowMinutes,
    );
    final badge = switch (when) {
      MealWhen.logged => l10n.stateDone,
      MealWhen.now => l10n.stateNow,
      MealWhen.missed => l10n.stateMissed,
      MealWhen.upcoming || MealWhen.untimed => null,
    };
    return InkWell(
      key: Key('timeline-${item.planItemId}'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 52,
              child: Text(
                window == null ? '' : formatHm(context, window!.start),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 10, color: colors.brand),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(slotLabel(l10n, item.slot)),
                      if (badge != null)
                        Text(
                          badge,
                          key: Key('state-${item.planItemId}'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.brand2),
                        ),
                      if (item.liked)
                        Icon(Icons.favorite, size: 16, color: colors.protein),
                    ],
                  ),
                  Text(
                    item.mealName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${formatWhole(context, item.kcal)} · ${l10n.mealServing(formatWhole(context, item.grams))}',
                  ),
                  ReasonChips(
                    codes: item.reasonCodes,
                    languageCode: Localizations.localeOf(context).languageCode,
                    conditionNames: names,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
