import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../catalog/domain/meal.dart';
import '../../logging/data/logging_providers.dart';
import '../../logging/domain/logging.dart';
import '../../logging/presentation/eat_button.dart';
import '../../logging/presentation/extras_section.dart';
import '../../logging/presentation/missed_meal_card.dart';
import '../../logging/presentation/sync_status_chip.dart';
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
import '../../progress/data/progress_providers.dart';
import '../../water/data/water_providers.dart';
import '../../water/domain/water.dart';
import '../../water/presentation/water_screen.dart' show addWater;
import '../../weight/data/weight_providers.dart';
import '../../weight/presentation/weight_sheet.dart';
import 'quick_sheet.dart';
import 'today_look.dart';

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
    final logs = ref.watch(todayLogsProvider);
    if (plan != null && !general) {
      _queueImpressions(ref, plan);
    }
    final water = ref.watch(todayWaterProvider);
    final notice = ref.watch(targetNoticeProvider);
    return Scaffold(
      key: const Key('today-screen'),
      backgroundColor: colors.bg,
      floatingActionButton: FloatingActionButton(
        key: const Key('today-fab'),
        tooltip: l10n.fabLabel,
        backgroundColor: colors.brand,
        foregroundColor: colors.onBrand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          unawaited(showQuickSheet(context, hasPlan: plan != null && !general));
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(syncTriggerProvider).now();
                  await ref.read(planSyncProvider).refresh();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  children: <Widget>[
                    _Header(today: today, now: now, sex: user?.sex),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SyncStatusChip(),
                    ),
                    const SizedBox(height: 10),
                    if (notice) ...<Widget>[
                      AppCard(
                        tint: colors.brand,
                        child: const TargetNoticeBody(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _WeekStrip(today: today, plans: plans),
                    const SizedBox(height: 14),
                    if (general) ...<Widget>[
                      _GeneralCard(body: l10n.generalBody),
                      const SizedBox(height: 14),
                      _WaterCard(water: water),
                      const SizedBox(height: 14),
                      const _HealthyRow(),
                      const ExtrasSection(),
                    ] else if (plan == null) ...<Widget>[
                      _BuildCard(
                        title: l10n.todayNoPlan,
                        action: l10n.todayBuildWeek,
                        onPressed: () => openGeneration(context, ref),
                      ),
                    ] else ...<Widget>[
                      _CalorieCard(
                        plan: plan,
                        summary: summary,
                        provisional: provisionalTotals(plan.items, logs),
                      ),
                      const SizedBox(height: 14),
                      _NowCard(
                        plan: plan,
                        windows: windows,
                        logs: logs,
                        now: now,
                        onOpen: (PlanItem item) {
                          context.push('/plan/item/${item.planItemId}');
                        },
                      ),
                      MissedMealCard(plan: plan, windows: windows, now: now),
                      _WaterCard(water: water),
                      const SizedBox(height: 18),
                      _Timeline(
                        plan: plan,
                        windows: windows,
                        logs: logs,
                        now: now,
                        names: names,
                        onOpen: (PlanItem item) {
                          context.push('/plan/item/${item.planItemId}');
                        },
                      ),
                      const ExtrasSection(),
                      // Room so the FAB does not cover the last row.
                      const SizedBox(height: 72),
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

/// One IMPRESSION per plan item per day when Today first shows it (#267).
void _queueImpressions(WidgetRef ref, DayPlan plan) {
  final queue = ref.read(interactionQueueProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final item in plan.items) {
      unawaited(
        queue
            .impression(
              planItemId: item.planItemId,
              mealId: item.mealId,
              date: plan.planDate,
            )
            .catchError((Object _) {}),
      );
    }
  });
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

/// home() header: avatar tile, date, greeting, streak pill, bell.
class _Header extends ConsumerWidget {
  const _Header({required this.today, required this.now, required this.sex});

  final DateTime today;
  final DateTime now;
  final String? sex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final streak = ref.watch(streakProvider).asData?.value ?? 0;
    final greeting = now.hour < 12 ? l10n.greetMorning : l10n.greetEvening;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          EmojiTile(
            avatarEmoji(sex),
            size: 46,
            emojiSize: 32,
            radius: 16,
            background: colors.brandSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  DateFormatHeading.format(context, today),
                  style: TextStyle(fontSize: 13, color: colors.fg3),
                ),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        greeting,
                        key: const Key('today-greeting'),
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: colors.fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Emoji('waving-hand', size: 22),
                  ],
                ),
              ],
            ),
          ),
          if (streak > 0) ...<Widget>[
            const SizedBox(width: 8),
            Semantics(
              label: l10n.streakPill(formatWhole(context, streak)),
              excludeSemantics: true,
              child: Container(
                key: const Key('today-streak'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: mixColor(colors.kcal, 0.35, colors.line),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Emoji('fire', size: 18),
                    const SizedBox(width: 4),
                    Text(
                      formatWhole(context, streak),
                      style: colors.numeric.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.kcal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.remindersOpen,
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.line),
              ),
              child: InkWell(
                key: const Key('today-bell'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/me/reminders'),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: colors.fg2,
                    semanticLabel: l10n.remindersOpen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    return Row(
      children: <Widget>[
        for (var index = 0; index < dates.length; index++)
          Expanded(
            child: _DayChip(
              key: Key('week-day-${isoDate(dates[index])}'),
              label: formatShortDay(context, dates[index]),
              day: formatWhole(context, dates[index].day),
              highlighted: index == 0,
              dashed: !planned.contains(isoDate(dates[index])),
              colors: colors,
              onTap: () => openPlanDay(context, ref, dates[index]),
            ),
          ),
      ],
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
    required this.onTap,
    super.key,
  });

  final String label;
  final String day;
  final bool highlighted;
  final bool dashed;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final square = SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Text(
          day,
          style: colors.numeric.copyWith(
            fontSize: 14,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            color: highlighted ? colors.onBrand : colors.fg,
          ),
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: highlighted ? colors.brand : colors.fg3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (highlighted)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: square,
                )
              else
                CustomPaint(
                  painter: DashedBorderPainter(
                    color: colors.line,
                    dashed: dashed,
                    radius: 13,
                    width: 2,
                  ),
                  child: square,
                ),
            ],
          ),
        ),
      ),
    );
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
    return AppCard(
      key: const Key('build-week-card'),
      tint: colors.brand,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Emoji('spiral-calendar', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('build-week'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
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
    return AppCard(
      key: const Key('general-card'),
      child: Row(
        children: <Widget>[
          const Emoji('seedling', size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.generalTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 13, color: colors.fg3)),
              ],
            ),
          ),
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
        SectionHeader(title: l10n.healthyTitle),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            padding: const EdgeInsets.only(bottom: 8),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final meal = meals[index];
              return SizedBox(
                width: 150,
                child: AppCard(
                  key: Key('healthy-${meal.mealId}'),
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.push('/meals/${meal.mealId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mixColor(colors.kcal, 0.14, colors.surface2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Emoji(meal.iconName, size: 52),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.mealKcal(formatWhole(context, meal.kcal)),
                        style: TextStyle(fontSize: 13, color: colors.fg3),
                      ),
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
  const _CalorieCard({
    required this.plan,
    required this.summary,
    required this.provisional,
  });

  final DayPlan plan;
  final DaySummary? summary;

  /// Server values of logs the server does not have yet (#266).
  final ProvisionalTotals provisional;

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
    final provisional = widget.provisional;
    double sum(double? server, double extra) {
      return math.max(0, (server ?? 0) + extra);
    }

    final eaten = sum(widget.summary?.kcal, provisional.kcal);
    final remaining = math.max(0, target - eaten);
    final shown = _left ? remaining : eaten;
    final percent = target <= 0 ? 0.0 : (shown / target).clamp(0, 1).toDouble();
    Widget macro(
      String emoji,
      String label,
      double eatenG,
      double targetG,
      Color color,
    ) {
      final share = targetG <= 0 ? 0.0 : eatenG / targetG;
      final shownG = _left ? math.max(0, targetG - eatenG) : eatenG;
      return Expanded(
        child: MacroCard(
          emoji: emoji,
          label: label,
          shown: shownG.toDouble(),
          shownText: formatWhole(context, shownG),
          share: _left ? math.max(0, 1 - share) : share,
          targetText: l10n.macroOfTarget(formatWhole(context, targetG)),
          color: color,
        ),
      );
    }

    return Column(
      children: <Widget>[
        AppCard(
          key: const Key('calorie-card'),
          tint: colors.kcal,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Emoji('fire', size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.caloriesTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SegToggle<bool>(
                    options: <(bool, String)>[
                      (false, l10n.kcalModeEaten),
                      (true, l10n.kcalModeLeft),
                    ],
                    value: _left,
                    onChanged: (bool value) => setState(() => _left = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  RingPercent(
                    value: percent,
                    color: colors.kcal,
                    size: 108,
                    stroke: 12,
                    center: Text(
                      percentLabel(percent),
                      style: colors.numeric.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            formatWhole(context, shown),
                            key: const Key('calorie-value'),
                            style: colors.numeric.copyWith(
                              fontSize: 38,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: colors.fg,
                            ),
                          ),
                        ),
                        Text(
                          _left ? l10n.kcalLeftCaption : l10n.kcalEatenCaption,
                          style: TextStyle(color: colors.fg2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.kcalOfTarget(formatWhole(context, target)),
                          style: TextStyle(fontSize: 13, color: colors.fg3),
                        ),
                        if (provisional.active)
                          Text(
                            l10n.provisionalNote,
                            key: const Key('calorie-provisional'),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.fg2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            macro(
              'poultry-leg',
              l10n.nutrientProtein,
              sum(widget.summary?.proteinG, provisional.proteinG),
              widget.plan.target.proteinG,
              colors.protein,
            ),
            const SizedBox(width: 8),
            macro(
              'bread',
              l10n.nutrientCarbs,
              sum(widget.summary?.carbG, provisional.carbG),
              widget.plan.target.carbG,
              colors.carb,
            ),
            const SizedBox(width: 8),
            macro(
              'avocado',
              l10n.nutrientFat,
              sum(widget.summary?.fatG, provisional.fatG),
              widget.plan.target.fatG,
              colors.fat,
            ),
          ],
        ),
      ],
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.plan,
    required this.windows,
    required this.logs,
    required this.now,
    required this.onOpen,
  });

  final DayPlan plan;
  final List<MealWindowSpan> windows;
  final List<LoggedMeal> logs;
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
            logged: isEaten(item, logs),
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
    final progress = windowProgress(
      start: window.start,
      end: window.end,
      nowMinutes: minutes,
    );
    final item = current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GradientHero(
        key: const Key('now-card'),
        onTap: () => onOpen(item),
        child: Row(
          children: <Widget>[
            EmojiTile(
              mealEmoji(item),
              size: 64,
              emojiSize: 44,
              radius: 20,
              background: const Color(0x2EFFFFFF),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.nowCard(
                      slotLabel(l10n, item.slot),
                      formatHm(context, window.end),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                  Text(
                    item.mealName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TintBar(
                    value: progress,
                    color: Colors.white,
                    track: const Color(0x40FFFFFF),
                    height: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.water});

  /// The same view as the Water tab, provisional glasses included.
  final WaterView water;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final clinician = water.mode == WaterGoalMode.clinician;
    final total = water.totalMl;
    final goal = water.goalMl;
    final glasses = goal == null ? 0 : (goal / 250).ceil().clamp(1, 16);
    final filled = total ~/ 250;
    return AppCard(
      key: const Key('water-card'),
      onTap: () => context.go('/water'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          RingPercent(
            value: clinician ? 0 : water.progress,
            color: colors.water,
            size: 56,
            stroke: 7,
            center: const Emoji('droplet', size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.tabWater,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  clinician
                      ? l10n.waterWithDoctor
                      : goal == null
                      ? l10n.waterAmountMl(formatWhole(context, total))
                      : l10n.waterTotalOfGoal(
                          formatWhole(context, total),
                          formatWhole(context, goal),
                        ),
                  style: colors.numeric.copyWith(
                    fontSize: 13,
                    color: colors.fg3,
                  ),
                ),
                if (glasses > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: <Widget>[
                      for (var i = 0; i < glasses; i++)
                        Container(
                          width: 14,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i < filled
                                ? colors.water
                                : colors.water.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!clinician) ...<Widget>[
            const SizedBox(width: 8),
            Material(
              color: colors.water.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('today-water-add'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => unawaited(addWater(context, ref, 250)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    minWidth: 64,
                  ),
                  child: Center(
                    child: Text(
                      '+250',
                      textDirection: TextDirection.ltr,
                      style: colors.numeric.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.water,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.plan,
    required this.windows,
    required this.logs,
    required this.now,
    required this.names,
    required this.onOpen,
  });

  final DayPlan plan;
  final List<MealWindowSpan> windows;
  final List<LoggedMeal> logs;
  final DateTime now;
  final Map<String, String> names;
  final void Function(PlanItem item) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final minutes = now.hour * 60 + now.minute;
    final items = displayItems(plan.items);
    // A plan item can be logged only on its own date.
    final loggable = plan.planDate == isoDate(dateOnly(now));
    return Column(
      key: const Key('today-timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: l10n.todayMeals,
          action: TextButton(
            key: const Key('full-plan'),
            onPressed: () {
              unawaited(openPlanDay(context, ref, dateFromIso(plan.planDate)));
            },
            child: Text(
              l10n.fullPlan,
              style: TextStyle(
                color: colors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: <Widget>[
            PositionedDirectional(
              start: 23,
              top: 10,
              bottom: 10,
              width: 2,
              child: CustomPaint(painter: _RailPainter(color: colors.line)),
            ),
            Column(
              children: <Widget>[
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TimelineRow(
                      item: item,
                      eaten: isEaten(item, logs),
                      loggable: loggable,
                      window: _span(windows, item.slot),
                      nowMinutes: minutes,
                      names: names,
                      onOpen: () => onOpen(item),
                      colors: colors,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// `.tl::before`: the dashed vertical rail behind the dots.
class _RailPainter extends CustomPainter {
  _RailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + 6, size.height)),
        paint,
      );
      y += 11;
    }
  }

  @override
  bool shouldRepaint(_RailPainter oldDelegate) => oldDelegate.color != color;
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
    required this.eaten,
    required this.loggable,
    required this.window,
    required this.nowMinutes,
    required this.names,
    required this.onOpen,
    required this.colors,
  });

  final PlanItem item;
  final bool eaten;
  final bool loggable;
  final MealWindowSpan? window;
  final int nowMinutes;
  final Map<String, String> names;
  final VoidCallback onOpen;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = mealWhen(
      logged: eaten,
      start: window?.start,
      end: window?.end,
      nowMinutes: nowMinutes,
    );
    final badge = switch (when) {
      MealWhen.logged => (l10n.stateDone, colors.ok, Icons.check_rounded),
      MealWhen.now => (l10n.stateNow, colors.kcal, null),
      MealWhen.missed => (l10n.stateMissed, colors.warn, null),
      MealWhen.upcoming || MealWhen.untimed => null,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: <Widget>[
                TimelineDot(when: when),
                const SizedBox(height: 4),
                Container(
                  color: colors.bg,
                  child: Text(
                    window == null ? '' : formatHm(context, window!.start),
                    style: colors.numeric.copyWith(
                      fontSize: 11.5,
                      color: colors.fg3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppCard(
            key: Key('timeline-${item.planItemId}'),
            radius: 22,
            padding: const EdgeInsets.all(12),
            borderColor: when == MealWhen.now
                ? mixColor(colors.kcal, 0.5, colors.line)
                : null,
            onTap: onOpen,
            child: Row(
              children: <Widget>[
                EmojiTile(
                  mealEmoji(item),
                  size: 60,
                  emojiSize: 40,
                  radius: 20,
                  tint: slotTint(colors, item.slot),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            slotLabel(l10n, item.slot),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.fg3,
                            ),
                          ),
                          if (badge != null)
                            StateBadge(
                              key: Key('state-${item.planItemId}'),
                              label: badge.$1,
                              color: badge.$2,
                              icon: badge.$3,
                            ),
                          if (item.liked)
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: colors.protein,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.mealName,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.mealMetaLine(
                          formatWhole(context, item.kcal),
                          formatWhole(context, item.grams),
                        ),
                        style: colors.numeric.copyWith(
                          fontSize: 12.5,
                          color: colors.fg3,
                        ),
                      ),
                      ReasonChips(
                        codes: item.reasonCodes,
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                        conditionNames: names,
                      ),
                    ],
                  ),
                ),
                if (loggable) ...<Widget>[
                  const SizedBox(width: 8),
                  EatButton(item: item),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
