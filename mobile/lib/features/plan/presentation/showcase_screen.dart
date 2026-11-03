import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../catalog/presentation/nutrient_labels.dart';
import '../data/plan_providers.dart';
import '../data/user_context.dart';
import '../domain/plan.dart';
import 'plan_format.dart';
import 'showcase_controller.dart';

/// Colours of the prototype gen screen (always dark, like the prototype).
const _ink = Color(0xFFEAF4F8);
const _muted = Color(0xFF8FA6B8);
const _accent = Color(0xFF38BDF8);
const _ok = Color(0xFF2BD49A);
const _onOk = Color(0xFF04241A);
const _amber = Color(0xFFE6B15A);
const _line = Color(0xFF2A4458);
const _kcal = Color(0xFFFF9147);
const _glass = Color(0x0FFFFFFF);

/// Left-to-right mark (U+200E).
final _lrm = String.fromCharCode(0x200E);

class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref
            .read(showcaseControllerProvider.notifier)
            .start(hold: showcaseHoldFor(context)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(showcaseControllerProvider);
    final titles = <String>[
      l10n.genNeeds,
      l10n.genFilter,
      l10n.genSearch,
      l10n.genWeek,
    ];
    return Scaffold(
      key: const Key('showcase-screen'),
      backgroundColor: const Color(0xFF060D16),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.3,
            colors: <Color>[
              Color(0xFF12324A),
              Color(0xFF0A1622),
              Color(0xFF060D16),
            ],
            stops: <double>[0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Emoji('sparkles', size: 16),
                              SizedBox(width: 6),
                              Text(
                                'NutriGuide Engine',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7FD3F5),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n.genTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.3,
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const Key('gen-skip'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 40),
                        backgroundColor: const Color(0x1AFFFFFF),
                        shape: const StadiumBorder(
                          side: BorderSide(color: Color(0x26FFFFFF)),
                        ),
                      ),
                      onPressed: () => _leave(context),
                      child: Text(
                        l10n.genSkip,
                        style: const TextStyle(color: Color(0xFFCCEEEE)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Steps(titles: titles, step: state.step),
                const SizedBox(height: 16),
                if (state.days.isNotEmpty) ...<Widget>[
                  _Week(days: state.days, running: state.step == 3),
                  const SizedBox(height: 16),
                ],
                Semantics(
                  key: const Key('gen-live'),
                  liveRegion: true,
                  label: state.step >= titles.length
                      ? l10n.genReady
                      : titles[state.step],
                  child: const SizedBox(width: 48, height: 8),
                ),
                if (state.step == 0) const _Needs(),
                if (state.step == 1) const _Filter(),
                // As the prototype, the optimizer stays on screen while the
                // remaining days are built.
                if (state.step == 2 || (state.step == 3 && !state.finished))
                  _Optimizer(plan: state.dayOne),
                // Day one is enough to start; the rest keeps building in the
                // background and shows as a pill on Today and Plan.
                if (state.running && state.dayOne != null)
                  _EarlyStart(onLeave: () => _leave(context)),
                if (state.finished)
                  _Summary(state: state, onLeave: () => _leave(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _leave(BuildContext context) {
    ref.read(launchShowcaseProvider.notifier).close();
    context.go('/today');
  }
}

class _EarlyStart extends StatelessWidget {
  const _EarlyStart({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilledButton(
            key: const Key('gen-start-early'),
            style: _buttonStyle,
            onPressed: onLeave,
            child: Text(l10n.genStart),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.genContinuesInBackground,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

/// `.stp`: four numbered steps in two columns.
class _Steps extends StatelessWidget {
  const _Steps({required this.titles, required this.step});

  final List<String> titles;
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget cell(int index) {
      final done = step > index;
      final active = step == index;
      final color = done ? const Color(0xFF9BE7C8) : (active ? _ink : _muted);
      return Row(
        children: <Widget>[
          AnimatedContainer(
            duration: animationsEnabled(context)
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _ok : Colors.transparent,
              border: Border.all(
                color: done ? _ok : (active ? _accent : _line),
                width: 1.5,
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: _onOk)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? _accent : _muted,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titles[index],
              style: TextStyle(fontSize: 13.5, color: color),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        for (var row = 0; row < titles.length; row += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(child: cell(row)),
                const SizedBox(width: 12),
                Expanded(
                  child: row + 1 < titles.length
                      ? cell(row + 1)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Needs extends ConsumerWidget {
  const _Needs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = ref.watch(userContextProvider)?.target;
    final user = ref.watch(userContextProvider);
    final kcal = target?.kcal ?? 0;
    final bmr = target?.bmrKcal ?? 0;
    final tdee = target?.tdeeKcal ?? 0;
    final factor = bmr == 0 ? 0.0 : tdee / bmr;
    final delta = (kcal - tdee).abs();
    final sign = kcal >= tdee ? '+' : '−';
    return Column(
      children: <Widget>[
        RingPercent(
          key: const Key('gen-ring'),
          value: kcal > 0 ? 1 : 0,
          color: _kcal,
          track: const Color(0x14FFFFFF),
          size: 170,
          stroke: 14,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Emoji('fire', size: 30),
              _Count(value: kcal, enabled: animationsEnabled(context)),
              Text(
                l10n.genKcalPerDay,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            // Left-to-right marks keep the sign before the number in RTL.
            _Chip('${_lrm}BMR ${formatWhole(context, bmr)}$_lrm'),
            _Chip('$_lrm× ${formatFixed(context, factor, 3)}$_lrm'),
            _Chip('${_lrm}TDEE ${formatWhole(context, tdee)}$_lrm'),
            if (user?.goalType != 'MAINTAIN')
              _Chip(
                '$_lrm$sign ${formatWhole(context, delta)}$_lrm',
                color: _kcal,
              ),
          ],
        ),
      ],
    );
  }
}

class _Filter extends ConsumerWidget {
  const _Filter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(userContextProvider);
    final catalog = ref.watch(catalogMealCountProvider).asData?.value ?? 0;
    final candidates = ref.watch(showcaseControllerProvider).candidateMeals;
    final disliked = ref.watch(mealDislikeProvider).asData?.value ?? false;
    final shown = candidates ?? catalog;
    final conditions = user?.conditions ?? const <String>[];
    const filter = Color(0xFFFCA5A5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Count(value: shown, enabled: false),
              Text(
                l10n.genMealsInKitchen,
                style: const TextStyle(fontSize: 12.5, color: _muted),
              ),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: <Widget>[
              for (final code in user?.allergenCodes ?? const <String>[])
                _Chip(
                  l10n.genAvoid(allergenLabel(l10n, code)),
                  emoji: 'shield',
                  color: filter,
                ),
              if (conditions.contains('HYPERTENSION') ||
                  conditions.contains('HEART_DISEASE'))
                _Chip(l10n.genLessSalt, emoji: 'salt', color: filter),
              if (conditions.contains('DIABETES_T2'))
                _Chip(l10n.genLessSugar, emoji: 'honey-pot', color: filter),
              if ((user?.hasDislike ?? false) || disliked)
                _Chip(l10n.genNoDislike, emoji: 'thumbs-down', color: filter),
            ],
          ),
        ),
      ],
    );
  }
}

class _Optimizer extends StatelessWidget {
  const _Optimizer({required this.plan});

  final DayPlan? plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = plan == null ? const <PlanItem>[] : displayItems(plan!.items);
    final unmet = <String>{
      for (final row in plan?.unmetMinimums ?? const <UnmetMinimum>[])
        row.nutrient.toLowerCase(),
    };
    final stats = plan?.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final slot in slotOrder)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _Reel(
                    slot: slotLabel(l10n, slot),
                    item: _item(items, slot),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Check('fire', l10n.genWithin, plan?.kcalWithin10pct ?? false),
        _Check('poultry-leg', l10n.genProtein, !unmet.contains('protein')),
        _Check('leafy-green', l10n.genFiber, !unmet.contains('fiber')),
        _Check('sparkles', l10n.genNoRepeat, true),
        if (stats != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.genSolver(
                stats.solverStatus,
                formatFixed(context, stats.solveSeconds, 2),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7FD3F5)),
            ),
          ),
      ],
    );
  }
}

PlanItem? _item(List<PlanItem> items, String slot) {
  for (final item in items) {
    if (item.slot == slot) {
      return item;
    }
  }
  return null;
}

/// `.slot`: one meal slot, locked in green once the optimizer chose it.
class _Reel extends StatelessWidget {
  const _Reel({required this.slot, required this.item});

  final String slot;
  final PlanItem? item;

  @override
  Widget build(BuildContext context) {
    final locked = item != null;
    final icon = item?.iconName;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: locked ? _ok.withValues(alpha: 0.12) : _glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: locked ? _ok : const Color(0x1AFFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            slot,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: locked ? const Color(0xFFDFF7EE) : const Color(0xFF9FB3C4),
            ),
          ),
          const SizedBox(height: 6),
          Emoji(
            icon == null || icon.isEmpty ? 'fork-and-knife-with-plate' : icon,
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            item?.mealName ?? '·',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.3, color: _ink),
          ),
        ],
      ),
    );
  }
}

/// `.cm`: one check with its emoji and a bar that fills once it is met.
class _Check extends StatelessWidget {
  const _Check(this.emoji, this.label, this.on);

  final String emoji;
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Emoji(emoji, size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _ink),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TintBar(
              value: on ? 1 : 0.1,
              color: on ? _ok : _accent,
              track: const Color(0x14FFFFFF),
              height: 7,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? _ok : const Color(0x14FFFFFF),
            ),
            child: on
                ? const Icon(Icons.check_rounded, size: 13, color: _onOk)
                : null,
          ),
        ],
      ),
    );
  }
}

/// `.dayc`: the seven days as circles that fill as each day is built.
class _Week extends StatelessWidget {
  const _Week({required this.days, required this.running});

  final List<ShowcaseDay> days;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The day being built follows the last finished one; a day kept because
    // it has logs stays dashed.
    var current = -1;
    if (running) {
      final last = days.lastIndexWhere((ShowcaseDay d) => d.done || d.failed);
      current = last + 1 < days.length ? last + 1 : -1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.genWeekDays,
          style: const TextStyle(fontSize: 12.5, color: _muted),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (var index = 0; index < days.length; index++)
              Expanded(
                child: _DayCircle(
                  key: Key('gen-day-${days[index].date.day}'),
                  day: days[index],
                  running: index == current,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.day, required this.running, super.key});

  final ShowcaseDay day;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final fill = day.done ? _ok : (day.failed ? _amber : Colors.transparent);
    final number = Text(
      formatWhole(context, day.date.day),
      style: TextStyle(
        fontFamily: 'Readex Pro',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: day.done || day.failed ? _onOk : _ink,
      ),
    );
    return Semantics(
      label: day.kcal == null
          ? formatShortDay(context, day.date)
          : '${formatShortDay(context, day.date)} ${formatWhole(context, day.kcal!)}',
      excludeSemantics: true,
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 34,
            height: 34,
            child: day.done || day.failed
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                    ),
                    child: Center(
                      child: day.done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: _onOk,
                            )
                          : number,
                    ),
                  )
                : CustomPaint(
                    painter: DashedBorderPainter(
                      color: running ? _accent : _line,
                      dashed: !running,
                      radius: 17,
                      width: 2,
                    ),
                    child: Center(child: number),
                  ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatShortDay(context, day.date),
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: day.done ? const Color(0xFFDFF7EE) : _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.state, required this.onLeave});

  final ShowcaseState state;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final message = _message(context, state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        const Center(child: Emoji('party-popper', size: 56)),
        const SizedBox(height: 8),
        Text(
          l10n.genReady,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        if (state.failed > 0)
          Text(
            l10n.genPartial(state.built),
            key: const Key('gen-partial'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ),
        const SizedBox(height: 16),
        if (state.stopCode == 'NO_TARGET' ||
            state.stopCode == 'PROFILE_NOT_FOUND')
          FilledButton(
            key: const Key('gen-recheck'),
            style: _buttonStyle,
            onPressed: () {
              ref.read(recheckOnboardingProvider.notifier).open();
              ref.read(launchShowcaseProvider.notifier).close();
              context.go('/onboarding');
            },
            child: Text(l10n.onbContinue),
          )
        else
          FilledButton(
            key: const Key('gen-start'),
            style: _buttonStyle,
            onPressed: onLeave,
            child: Text(l10n.genStart),
          ),
        if (state.failed > 0) ...<Widget>[
          const SizedBox(height: 8),
          TextButton(
            key: const Key('gen-retry'),
            onPressed: () {
              unawaited(
                ref
                    .read(showcaseControllerProvider.notifier)
                    .start(force: true, hold: showcaseHoldFor(context)),
              );
            },
            child: Text(l10n.genRetryLeft),
          ),
        ],
      ],
    );
  }
}

final _buttonStyle = FilledButton.styleFrom(
  minimumSize: const Size(48, 54),
  backgroundColor: _ok,
  foregroundColor: _onOk,
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
);

String? _message(BuildContext context, ShowcaseState state) {
  final l10n = AppLocalizations.of(context);
  return switch (state.stopCode) {
    null => null,
    'NETWORK' => l10n.genNetwork,
    'NOT_ELIGIBLE' => l10n.genIneligible,
    'RATE_LIMITED' => l10n.failureRateLimitedSeconds(
      state.retryAfterSeconds ?? 0,
    ),
    'NO_TARGET' || 'PROFILE_NOT_FOUND' => l10n.failureNoTarget,
    'PLANNER_TIMEOUT' => l10n.failurePlannerTimeout,
    'PLANNER_BUSY' => l10n.failurePlannerBusy,
    'CONDITION_CONFLICT' => l10n.failureConditionConflict,
    'NO_FEASIBLE_PLAN' => l10n.failureNoFeasiblePlan,
    _ => l10n.genGeneric,
  };
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.enabled});

  final int value;
  final bool enabled;

  static const _style = TextStyle(
    fontFamily: 'Readex Pro',
    fontSize: 34,
    height: 1.15,
    color: _ink,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        formatWhole(context, value),
        key: const Key('gen-count'),
        style: _style,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1300),
      builder: (BuildContext context, double number, Widget? child) {
        return Text(
          formatWhole(context, number),
          key: const Key('gen-count'),
          style: _style,
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.emoji, this.color});

  final String label;
  final String? emoji;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (emoji != null) ...<Widget>[
            Emoji(emoji!, size: 14),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color == null ? _ink : tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
