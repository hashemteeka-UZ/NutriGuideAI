import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../catalog/presentation/nutrient_labels.dart';
import '../data/plan_providers.dart';
import '../data/user_context.dart';
import '../domain/plan.dart';
import 'plan_format.dart';
import 'showcase_controller.dart';

const _ink = Color(0xFFEAF4F8);
const _muted = Color(0xFF8FA6B8);
const _accent = Color(0xFF38BDF8);
const _ok = Color(0xFF2BD49A);
const _amber = Color(0xFFE6B15A);

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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: <Color>[
              Color(0xFF12324A),
              Color(0xFF0A1622),
              Color(0xFF060D16),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.genTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('gen-skip'),
                      onPressed: () => _leave(context),
                      child: Text(
                        l10n.genSkip,
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < titles.length; index++)
                  _StepTitle(
                    title: titles[index],
                    active: state.step == index,
                    done: state.step > index,
                  ),
                const SizedBox(height: 20),
                Semantics(
                  key: const Key('gen-live'),
                  liveRegion: true,
                  label: state.step >= titles.length
                      ? l10n.genReady
                      : titles[state.step],
                  child: const SizedBox(width: 48, height: 48),
                ),
                const SizedBox(height: 16),
                if (state.step == 0) const _Needs(),
                if (state.step == 1) const _Filter(),
                if (state.step == 2) _Optimizer(plan: state.dayOne),
                if (state.step == 3) _Week(days: state.days),
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

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.title,
    required this.active,
    required this.done,
  });

  final String title;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = active ? _accent : (done ? _ok : _muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(
            done ? Icons.check_circle : Icons.circle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Count(value: kcal, enabled: animationsEnabled(context)),
        Text(l10n.genKcalPerDay, style: const TextStyle(color: _muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            // Left-to-right marks keep the sign before the number in RTL.
            _Chip('${_lrm}BMR ${formatWhole(context, bmr)}$_lrm'),
            _Chip('$_lrm× ${formatFixed(context, factor, 3)}$_lrm'),
            _Chip('${_lrm}TDEE ${formatWhole(context, tdee)}$_lrm'),
            if (user?.goalType != 'MAINTAIN')
              _Chip('$_lrm$sign ${formatWhole(context, delta)}$_lrm'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Count(value: shown, enabled: false),
        Text(l10n.genMealsInKitchen, style: const TextStyle(color: _muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final code in user?.allergenCodes ?? const <String>[])
              _Chip(l10n.genAvoid(allergenLabel(l10n, code))),
            if (conditions.contains('HYPERTENSION') ||
                conditions.contains('HEART_DISEASE'))
              _Chip(l10n.genLessSalt),
            if (conditions.contains('DIABETES_T2')) _Chip(l10n.genLessSugar),
            if ((user?.hasDislike ?? false) || disliked)
              _Chip(l10n.genNoDislike),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final slot in slotOrder)
          _Reel(slot: slotLabel(l10n, slot), name: _name(items, slot)),
        const SizedBox(height: 12),
        _Check(l10n.genWithin, plan?.kcalWithin10pct ?? false),
        _Check(l10n.genProtein, !unmet.contains('protein')),
        _Check(l10n.genFiber, !unmet.contains('fiber')),
        _Check(l10n.genNoRepeat, true),
        if (stats != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.genSolver(
                stats.solverStatus,
                formatFixed(context, stats.solveSeconds, 2),
              ),
              style: const TextStyle(color: _muted),
            ),
          ),
      ],
    );
  }
}

String _name(List<PlanItem> items, String slot) {
  for (final item in items) {
    if (item.slot == slot) {
      return item.mealName;
    }
  }
  return '·';
}

class _Reel extends StatelessWidget {
  const _Reel({required this.slot, required this.name});

  final String slot;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(slot, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(name, style: const TextStyle(color: _ink)),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.label, this.on);

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(
            on ? Icons.check_circle : Icons.radio_button_unchecked,
            color: on ? _ok : _muted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: _ink)),
          ),
        ],
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.days});

  final List<ShowcaseDay> days;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final day in days)
          Container(
            key: Key('gen-day-${day.date.day}'),
            width: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: day.failed
                  ? _amber.withValues(alpha: 0.2)
                  : day.done
                  ? _ok.withValues(alpha: 0.16)
                  : const Color(0xFF12324A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  formatShortDay(context, day.date),
                  style: const TextStyle(color: _ink),
                ),
                Text(
                  day.kcal == null ? '·' : formatWhole(context, day.kcal!),
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
      ],
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
        const Emoji('fork-and-knife', size: 48),
        const SizedBox(height: 8),
        Text(
          l10n.genReady,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: _ink),
        ),
        if (state.failed > 0)
          Text(
            l10n.genPartial(state.built),
            key: const Key('gen-partial'),
            style: const TextStyle(color: _ink),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message, style: const TextStyle(color: _muted)),
          ),
        const SizedBox(height: 16),
        if (state.stopCode == 'NO_TARGET' ||
            state.stopCode == 'PROFILE_NOT_FOUND')
          FilledButton(
            key: const Key('gen-recheck'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
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
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
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

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        formatWhole(context, value),
        key: const Key('gen-count'),
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(color: _ink, fontWeight: FontWeight.w700),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      builder: (BuildContext context, double number, Widget? child) {
        return Text(
          formatWhole(context, number),
          key: const Key('gen-count'),
          style: Theme.of(context).textTheme.displaySmall
              ?.copyWith(color: _ink, fontWeight: FontWeight.w700),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF12324A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: _ink)),
    );
  }
}
