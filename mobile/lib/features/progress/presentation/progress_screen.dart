import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../../plan/domain/plan_dates.dart';
import '../../plan/presentation/offline_bar.dart';
import '../../plan/presentation/plan_format.dart';
import '../../today/presentation/today_screen.dart';
import '../../weight/presentation/weight_sheet.dart';
import '../data/badge_service.dart';
import '../data/progress_providers.dart';
import '../data/progress_repository.dart';
import '../domain/progress.dart';
import 'badges_section.dart';

/// The «تقدمي» tab (Decisions #276 to #282).
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

enum _Segment { report, weight, badges }

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  var _segment = _Segment.report;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  /// Badges come from the local tables, so they update offline too (#308).
  Future<void> _evaluateBadges() async {
    try {
      await ref.read(badgeServiceProvider).evaluate();
    } on Object {
      return;
    }
    if (mounted) {
      ref.invalidate(badgeBoardProvider);
    }
  }

  Future<void> _refresh() async {
    // Target grams, goal weight and sex live in memory only; after an
    // offline start they are loaded here too.
    if (ref.read(userContextProvider) == null) {
      unawaited(
        ref.read(userContextRefreshProvider)().catchError((Object _) {}),
      );
    }
    try {
      await ref.read(progressRepositoryProvider).refresh();
      if (mounted) {
        ref.read(planOfflineProvider.notifier).setOffline(false);
      }
      await _evaluateBadges();
    } on ProgressException catch (error) {
      if (mounted && error.network) {
        ref.read(planOfflineProvider.notifier).setOffline(true);
      }
    } on Object {
      // The cached report stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Scaffold(
      key: const Key('progress-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: <Widget>[
                    Text(
                      l10n.tabProgress,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.fg,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_Segment>(
                      key: const Key('progress-segments'),
                      showSelectedIcon: false,
                      segments: <ButtonSegment<_Segment>>[
                        ButtonSegment<_Segment>(
                          value: _Segment.report,
                          label: Text(l10n.progressSegReport),
                        ),
                        ButtonSegment<_Segment>(
                          value: _Segment.weight,
                          label: Text(l10n.progressSegWeight),
                        ),
                        ButtonSegment<_Segment>(
                          value: _Segment.badges,
                          label: Text(l10n.progressSegBadges),
                        ),
                      ],
                      selected: <_Segment>{_segment},
                      onSelectionChanged: (Set<_Segment> value) {
                        setState(() => _segment = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    switch (_segment) {
                      _Segment.report => const _ReportSection(),
                      _Segment.weight => const _WeightSection(),
                      _Segment.badges => const BadgesSection(),
                    },
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

/// Latin digits like the rest of the app (K.4).
String _dayMonth(BuildContext context, DateTime date) {
  return (DateFormat(
    'd MMMM',
    Localizations.localeOf(context).toString(),
  )..useNativeDigits = false).format(date);
}

class _ReportSection extends ConsumerWidget {
  const _ReportSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final report = ref.watch(weekReportProvider);
    final dates = ref.watch(weekDatesProvider);
    final offset = ref.watch(weekOffsetProvider);
    final user = ref.watch(userContextProvider);
    final general = user != null && !user.eligible;
    return Column(
      key: const Key('progress-report'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              key: const Key('week-prev'),
              tooltip: l10n.weekPrev,
              onPressed: offset >= maxWeeksBack
                  ? null
                  : () => ref.read(weekOffsetProvider.notifier).older(),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                l10n.weekRange(
                  _dayMonth(context, dates.first),
                  _dayMonth(context, dates.last),
                ),
                key: const Key('week-range'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              key: const Key('week-next'),
              tooltip: l10n.weekNext,
              onPressed: offset == 0
                  ? null
                  : () => ref.read(weekOffsetProvider.notifier).newer(),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (report.empty)
          _EmptyWeek(colors: colors)
        else ...<Widget>[
          if (!general && report.ratio != null)
            _HeroRing(report: report, sex: user?.sex),
          const SizedBox(height: 12),
          _Cards(report: report),
          const SizedBox(height: 12),
          _CaloriesCard(report: report, general: general),
          if (report.macros != null) ...<Widget>[
            const SizedBox(height: 12),
            _MacrosCard(macros: report.macros!),
          ],
          if (report.exceeded != null) ...<Widget>[
            const SizedBox(height: 12),
            _ExceededCard(summary: report.exceeded!),
          ],
        ],
        const SizedBox(height: 12),
        const _MonthCalendar(),
      ],
    );
  }
}

BoxDecoration _card(AppColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: colors.line),
  );
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('progress-empty-week'),
      padding: const EdgeInsets.all(24),
      decoration: _card(colors),
      child: Column(
        children: <Widget>[
          Icon(Icons.insights_outlined, size: 56, color: colors.brand),
          const SizedBox(height: 12),
          Text(l10n.emptyWeek, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('progress-go-today'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => context.go('/today'),
            child: Text(l10n.emptyWeekAction),
          ),
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing({required this.report, required this.sex});

  final WeekReport report;
  final String? sex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final ratio = report.ratio ?? 0;
    final percent = (ratio * 100).round();
    final headline = switch (report.headline) {
      WeekHeadline.excellent => l10n.headlineExcellent,
      WeekHeadline.good => l10n.headlineGood,
      _ => l10n.headlineFresh,
    };
    return Container(
      key: const Key('progress-ring'),
      padding: const EdgeInsets.all(16),
      decoration: _card(colors),
      child: Row(
        children: <Widget>[
          Semantics(
            label: l10n.adherenceRing(formatWhole(context, percent)),
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _RingPainter(
                  ratio: ratio,
                  color: colors.ok,
                  track: colors.line,
                ),
                child: Center(
                  child: Text(
                    '${formatWhole(context, percent)}%',
                    key: const Key('progress-ring-value'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.weekAchievedOf(
                    formatWhole(context, report.achieved),
                    formatWhole(context, report.counted),
                    sex == 'FEMALE' ? 'female' : 'other',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.color, required this.track});

  final double ratio;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * ratio.clamp(0, 1),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.ratio != ratio;
}

class _Cards extends StatelessWidget {
  const _Cards({required this.report});

  final WeekReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final best = report.bestDay;
    final missed = report.mostMissed;
    final water = report.waterAverageMl;
    final cards = <Widget>[
      if (best != null)
        _InfoCard(
          key: const Key('card-best-day'),
          icon: Icons.star_outline,
          title: l10n.bestDayTitle,
          body: l10n.bestDayBody(
            formatWeekday(context, dateFromIso(best.day.date)),
            formatWhole(context, best.percentOfTarget),
          ),
          colors: colors,
        ),
      if (missed != null)
        _InfoCard(
          key: const Key('card-most-missed'),
          icon: Icons.trending_down,
          title: l10n.mostMissedTitle,
          body: l10n.mostMissedBody(
            formatWhole(context, missed.days),
            formatWhole(context, missed.averageMinimum),
            nutrientName(l10n, missed.nutrient),
            formatWhole(context, missed.averageTotal),
          ),
          colors: colors,
        ),
      if (water != null)
        _InfoCard(
          key: const Key('card-water'),
          icon: Icons.water_drop_outlined,
          title: l10n.waterAvgTitle,
          body: l10n.waterAvgBody(formatWhole(context, water)),
          colors: colors,
        ),
    ];
    return Column(
      children: <Widget>[
        for (final card in cards)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.colors,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(colors),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(AppColors colors, DayTone tone) {
  return switch (tone) {
    DayTone.achieved => colors.ok,
    DayTone.partial => colors.part,
    DayTone.notAchieved => colors.miss,
    DayTone.none => colors.line,
  };
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.report, required this.general});

  final WeekReport report;
  final bool general;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final summary = l10n.caloriesChartSummary(
      <String>[
        for (final bar in report.bars)
          '${formatShortDay(context, dateFromIso(bar.date))} '
              '${bar.kcal == null ? l10n.legendNone : formatWhole(context, bar.kcal!)}',
      ].join('، '),
    );
    return Container(
      key: const Key('progress-calories'),
      padding: const EdgeInsets.all(16),
      decoration: _card(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.caloriesChartTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: summary,
            excludeSemantics: true,
            child: SizedBox(
              key: const Key('progress-calories-chart'),
              height: 140,
              child: CustomPaint(
                painter: _BarsPainter(
                  bars: report.bars,
                  target: general ? null : report.targetKcal,
                  colorOf: (DayTone tone) =>
                      general ? colors.line : _toneColor(colors, tone),
                  line: colors.fg2,
                  rtl: rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              // A Row already runs from the start side, like the painter.
              for (final bar in report.bars)
                Expanded(
                  child: Text(
                    formatShortDay(context, dateFromIso(bar.date)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: <Widget>[
              _Legend(color: colors.ok, label: l10n.legendAchieved),
              _Legend(color: colors.part, label: l10n.legendPartial),
              _Legend(color: colors.miss, label: l10n.legendNot),
              _Legend(color: colors.line, label: l10n.legendNone),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Seven bars, in reading order (the first date at the start side).
class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.target,
    required this.colorOf,
    required this.line,
    required this.rtl,
  });

  final List<WeekBar> bars;
  final double? target;
  final Color Function(DayTone tone) colorOf;
  final Color line;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    var top = target ?? 0;
    for (final bar in bars) {
      top = math.max(top, bar.kcal ?? 0);
    }
    if (top <= 0) {
      top = 1;
    }
    top *= 1.15;
    final slot = size.width / bars.length;
    final width = slot * 0.55;
    for (var index = 0; index < bars.length; index++) {
      final bar = bars[index];
      final position = rtl ? bars.length - 1 - index : index;
      final left = position * slot + (slot - width) / 2;
      final value = bar.kcal ?? 0;
      final height = value <= 0 ? 4.0 : size.height * value / top;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, width, height),
          const Radius.circular(6),
        ),
        Paint()..color = colorOf(bar.tone),
      );
    }
    final goal = target;
    if (goal != null && goal > 0) {
      final y = size.height - size.height * goal / top;
      final paint = Paint()
        ..color = line
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < size.width; x += 10) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 5, size.width), y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) {
    return oldDelegate.bars != bars || oldDelegate.target != target;
  }
}

class _MacrosCard extends ConsumerWidget {
  const _MacrosCard({required this.macros});

  final MacroAverages macros;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final target = ref.watch(userContextProvider)?.target;
    Widget row(String label, double value, double? goal, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(label)),
                Text(
                  goal == null
                      ? '${formatWhole(context, value)} ${l10n.mealServing('').trim()}'
                      : l10n.macroValue(
                          formatWhole(context, value),
                          formatWhole(context, goal),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: goal == null || goal <= 0
                  ? 0
                  : (value / goal).clamp(0, 1).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: color,
              backgroundColor: colors.line,
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('progress-macros'),
      padding: const EdgeInsets.all(16),
      decoration: _card(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.macrosTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          row(
            l10n.nutrientProtein,
            macros.proteinG,
            target?.proteinG,
            colors.protein,
          ),
          row(l10n.nutrientCarbs, macros.carbG, target?.carbG, colors.carb),
          row(l10n.nutrientFat, macros.fatG, target?.fatG, colors.fat),
        ],
      ),
    );
  }
}

class _ExceededCard extends StatelessWidget {
  const _ExceededCard({required this.summary});

  final ExceededSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Container(
      key: const Key('progress-exceeded'),
      padding: const EdgeInsets.all(16),
      decoration: _card(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.exceededTitle(formatWhole(context, summary.days)),
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final limit in summary.limits)
            Text(
              l10n.exceededLine(
                formatWhole(context, limit.limit),
                nutrientName(l10n, limit.nutrient),
                limit.total == null ? '—' : formatWhole(context, limit.total!),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends ConsumerWidget {
  const _MonthCalendar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final today = dateOnly(ref.watch(planClockProvider)());
    final days =
        ref.watch(monthDaysProvider).asData?.value ??
        const <String, AdherenceDay>{};
    final streak = ref.watch(streakProvider).asData?.value;
    final first = DateTime(today.year, today.month);
    final count = DateTime(today.year, today.month + 1, 0).day;
    // Saturday-first weeks, as in the region; lead blanks before day 1.
    final lead = (first.weekday + 1) % 7;
    final locale = Localizations.localeOf(context).toString();
    final cells = <Widget>[
      for (var blank = 0; blank < lead; blank++) const SizedBox.shrink(),
      for (var day = 1; day <= count; day++)
        _DayCell(
          date: DateTime(today.year, today.month, day),
          today: today,
          adherence: days[isoDate(DateTime(today.year, today.month, day))],
        ),
    ];
    return Container(
      key: const Key('progress-calendar'),
      padding: const EdgeInsets.all(16),
      decoration: _card(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  (DateFormat.yMMMM(
                    locale,
                  )..useNativeDigits = false).format(first),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (streak != null && streak > 0)
                Text(
                  l10n.calendarStreak(formatWhole(context, streak)),
                  key: const Key('progress-streak'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              // Saturday first, matching the grid below.
              for (var offset = 0; offset < 7; offset++)
                Expanded(
                  child: Text(
                    formatShortDay(context, DateTime(2026, 10, 24 + offset)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.fg2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.adherence,
  });

  final DateTime date;
  final DateTime today;
  final AdherenceDay? adherence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final future = date.isAfter(today);
    final isToday = date == today;
    final tone = toneOf(adherence);
    final hasData =
        adherence != null &&
        (adherence!.logged || adherence!.planItemsTotal > 0);
    final cell = Container(
      key: Key('cal-${isoDate(date)}'),
      decoration: BoxDecoration(
        color: future || tone == DayTone.none
            ? Colors.transparent
            : _toneColor(colors, tone).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: colors.brand, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        future ? '' : formatWhole(context, date.day),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
    if (future || !hasData || isToday) {
      return cell;
    }
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => unawaited(openPlanDay(context, ref, date)),
      child: cell,
    );
  }
}

class _WeightSection extends ConsumerWidget {
  const _WeightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final summary = ref.watch(weightSummaryProvider);
    final days = ref.watch(weightRangeProvider);
    final change = summary.change;
    String kg(double value) =>
        l10n.weightKgValue(formatFixed(context, value, 1));
    return Column(
      key: const Key('progress-weight'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _Tile(
              key: const Key('weight-tile-start'),
              label: l10n.weightStart,
              value: summary.start == null ? '—' : kg(summary.start!.weightKg),
            ),
            const SizedBox(width: 8),
            _Tile(
              key: const Key('weight-tile-now'),
              label: l10n.weightNow,
              value: summary.latest == null
                  ? '—'
                  : kg(summary.latest!.weightKg),
            ),
            const SizedBox(width: 8),
            _Tile(
              key: const Key('weight-tile-goal'),
              label: summary.maintenance
                  ? l10n.weightMaintain
                  : l10n.weightGoal,
              value: summary.maintenance
                  ? (summary.latest == null
                        ? '—'
                        : kg(summary.latest!.weightKg))
                  : (summary.targetKg == null ? '—' : kg(summary.targetKg!)),
            ),
          ],
        ),
        if (change != null) ...<Widget>[
          const SizedBox(height: 8),
          Center(
            child: Chip(
              key: const Key('weight-change'),
              label: Text(signedKg(context, l10n, change)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SegmentedButton<int>(
          key: const Key('weight-range'),
          showSelectedIcon: false,
          segments: <ButtonSegment<int>>[
            ButtonSegment<int>(
              value: 30,
              label: Text(l10n.weightDays(formatWhole(context, 30))),
            ),
            ButtonSegment<int>(
              value: 90,
              label: Text(l10n.weightDays(formatWhole(context, 90))),
            ),
          ],
          selected: <int>{days},
          onSelectionChanged: (Set<int> value) {
            ref.read(weightRangeProvider.notifier).set(value.first);
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(colors),
          child: summary.enough
              ? _WeightChart(summary: summary)
              : Padding(
                  key: const Key('weight-few-points'),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.weightFewPoints,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('weight-log-today'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => unawaited(showWeightSheet(context)),
          child: Text(l10n.weightLogToday),
        ),
      ],
    );
  }
}

/// «−1.5 كغ» with left-to-right marks so the sign stays first in RTL.
String signedKg(BuildContext context, AppLocalizations l10n, double change) {
  final lrm = String.fromCharCode(0x200E);
  final sign = change > 0 ? '+' : (change < 0 ? '−' : '');
  final value = formatFixed(context, change.abs(), 1);
  return l10n.weightKgValue('$lrm$sign$value$lrm');
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _card(colors),
        child: Column(
          children: <Widget>[
            Text(label, style: TextStyle(color: colors.fg2)),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.summary});

  final WeightSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final points = summary.points;
    final animate = animationsEnabled(context);
    var low = points.map((p) => p.weightKg).reduce(math.min);
    var high = points.map((p) => p.weightKg).reduce(math.max);
    final goal = summary.targetKg;
    if (goal != null) {
      low = math.min(low, goal);
      high = math.max(high, goal);
    }
    final ticks = axisTicks(low, high);
    final first = points.first.date;
    final last = points.last.date;
    final middle = first.add(
      Duration(days: last.difference(first).inDays ~/ 2),
    );
    final chart = SizedBox(
      key: Key(animate ? 'weight-chart-animated' : 'weight-chart-static'),
      height: 180,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (BuildContext context, double t, Widget? child) {
                return CustomPaint(
                  painter: _LinePainter(
                    points: points,
                    ticks: ticks,
                    goal: goal,
                    t: t,
                    line: colors.brand,
                    grid: colors.line,
                    label: colors.fg2,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                );
              },
            )
          : CustomPaint(
              painter: _LinePainter(
                points: points,
                ticks: ticks,
                goal: goal,
                t: 1,
                line: colors.brand,
                grid: colors.line,
                label: colors.fg2,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: l10n.weightChartSummary(
            formatWhole(context, points.length),
            formatFixed(context, points.first.weightKg, 1),
            formatFixed(context, points.last.weightKg, 1),
          ),
          excludeSemantics: true,
          child: chart,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final date in <DateTime>[first, middle, last])
              Text(
                formatMonthDay(context, date),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ],
    );
  }
}

/// Weight line with a soft area, a dashed goal line and the last point.
/// Time runs from the start side to the end side. No projection is drawn.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.ticks,
    required this.goal,
    required this.t,
    required this.line,
    required this.grid,
    required this.label,
    required this.rtl,
  });

  final List<WeightPointView> points;
  final List<double> ticks;
  final double? goal;
  final double t;
  final Color line;
  final Color grid;
  final Color label;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const axis = 36.0;
    final plotWidth = size.width - axis;
    final low = ticks.first;
    final high = ticks.last;
    final span = high - low <= 0 ? 1 : high - low;
    final start = points.first.date;
    final days = math.max(1, points.last.date.difference(start).inDays);
    double yOf(double value) =>
        size.height - (value - low) / span * size.height;
    double xOf(DateTime date) {
      final share = date.difference(start).inDays / days;
      final x = share * plotWidth;
      return rtl ? plotWidth - x : axis + x;
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final tick in ticks) {
      final y = yOf(tick);
      canvas.drawLine(
        Offset(rtl ? 0 : axis, y),
        Offset(rtl ? plotWidth : size.width, y),
        gridPaint,
      );
      final text = TextPainter(
        text: TextSpan(
          text: tick == tick.roundToDouble()
              ? tick.toStringAsFixed(0)
              : tick.toStringAsFixed(1),
          style: TextStyle(color: label, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(rtl ? plotWidth + 4 : 0, y - text.height / 2));
    }

    final target = goal;
    if (target != null) {
      final y = yOf(target);
      final dash = Paint()
        ..color = label
        ..strokeWidth = 1.5;
      final from = rtl ? 0.0 : axis;
      final to = rtl ? plotWidth : size.width;
      for (var x = from; x < to; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, to), y), dash);
      }
    }

    final shown = math.max(2, (points.length * t).ceil());
    final visible = points.take(math.min(shown, points.length)).toList();
    final path = Path();
    for (var index = 0; index < visible.length; index++) {
      final point = Offset(
        xOf(visible[index].date),
        yOf(visible[index].weightKg),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final area = Path.from(path)
      ..lineTo(xOf(visible.last.date), size.height)
      ..lineTo(xOf(visible.first.date), size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    if (t >= 1) {
      final last = points.last;
      canvas.drawCircle(
        Offset(xOf(last.date), yOf(last.weightKg)),
        5,
        Paint()..color = line,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.points != points ||
        oldDelegate.goal != goal;
  }
}
