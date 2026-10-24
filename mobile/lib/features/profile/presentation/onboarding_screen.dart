import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/failure_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/onboarding_steps.dart';
import 'onboarding_controller.dart';
import 'result_screen.dart';
import 'steps/about_step.dart';
import 'steps/activity_step.dart';
import 'steps/allergy_step.dart';
import 'steps/care_step.dart';
import 'steps/fluid_step.dart';
import 'steps/goal_step.dart';
import 'steps/measure_step.dart';
import 'steps/pace_step.dart';
import 'steps/rhythm_step.dart';
import 'steps/safety_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(onboardingControllerProvider.notifier).start());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final colors = context.appColors;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop ||
            state.phase == OnboardingPhase.saving ||
            state.phase == OnboardingPhase.checking) {
          return;
        }
        notifier.back();
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: switch (state.phase) {
            OnboardingPhase.checking => const _CenterMessage(loading: true),
            OnboardingPhase.saving => const _SavingView(),
            _ when state.loadError != null && state.reference == null =>
              _LoadError(onRetry: notifier.reloadReference),
            OnboardingPhase.result => _QuestionFrame(
              state: state,
              child: const ResultView(),
            ),
            _ => _QuestionFrame(state: state, child: _step(state.step)),
          },
        ),
      ),
    );
  }

  Widget _step(OnboardingStep? step) {
    return switch (step) {
      OnboardingStep.about => const AboutStep(),
      OnboardingStep.measure => const MeasureStep(),
      OnboardingStep.goal => const GoalStep(),
      OnboardingStep.pace => const PaceStep(),
      OnboardingStep.activity => const ActivityStep(),
      OnboardingStep.care => const CareStep(),
      OnboardingStep.allergy => const AllergyStep(),
      OnboardingStep.safety => const SafetyStep(),
      OnboardingStep.rhythm => const RhythmStep(),
      OnboardingStep.fluid => const FluidStep(),
      null => const SizedBox.shrink(),
    };
  }
}

class _QuestionFrame extends ConsumerWidget {
  const _QuestionFrame({required this.state, required this.child});

  final OnboardingState state;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final steps = state.steps;
    final index = state.stepIndex.clamp(
      0,
      steps.isEmpty ? 0 : steps.length - 1,
    );
    final total = steps.isEmpty ? 1 : steps.length;
    final progress = (index + 1) / total;
    final result = state.phase == OnboardingPhase.result;
    final step = state.step;
    final valid = result || (step != null && stepIsValid(step, state.draft));
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final motion = animationsEnabled(context);
    final failure = state.fieldError ?? state.actionError;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      result ? '' : l10n.onbStepProgress(index + 1, total),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.fg2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        ref.read(sessionControllerProvider.notifier).logout(),
                      );
                    },
                    child: Text(l10n.logout),
                  ),
                ],
              ),
              if (!result)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: progress),
                    duration: motion
                        ? const Duration(milliseconds: 280)
                        : Duration.zero,
                    builder:
                        (BuildContext context, double value, Widget? child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: colors.surface3,
                            color: colors.brand,
                          );
                        },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: motion
                ? const Duration(milliseconds: 280)
                : Duration.zero,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (Widget? current, List<Widget> previous) {
              return current ?? const SizedBox.shrink();
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
              final sign = (rtl ? -1.0 : 1.0) * (state.forward ? 1.0 : -1.0);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(sign, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: SingleChildScrollView(
              key: ValueKey<String>(result ? 'result' : '${step?.name}-$index'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: child,
            ),
          ),
        ),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              failureMessage(l10n, failure),
              key: const Key('onb-error'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.danger),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: <Widget>[
              IconButton(
                key: const Key('onb-back'),
                tooltip: l10n.onbBack,
                onPressed: (result || index > 0) ? notifier.back : null,
                icon: Icon(rtl ? Icons.arrow_forward : Icons.arrow_back),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: Key(result ? 'onb-finish' : 'onb-continue'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: valid
                      ? () {
                          if (result) {
                            unawaited(notifier.finish());
                            return;
                          }
                          notifier.next(reduceMotion: !motion);
                        }
                      : null,
                  child: Text(
                    result
                        ? (state.result?.showPersonalPlan ?? false
                              ? l10n.onbBuildPlan
                              : l10n.onbEnterApp)
                        : state.actionError == null
                        ? l10n.onbContinue
                        : l10n.onbRetry,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavingView extends StatelessWidget {
  const _SavingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Emoji('sparkles', size: 72),
            const SizedBox(height: 16),
            Text(
              l10n.onbCalculating,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (loading) const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).onbChecking),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.onbReferenceError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('onb-retry'),
              onPressed: () => unawaited(onRetry()),
              child: Text(l10n.onbRetry),
            ),
          ],
        ),
      ),
    );
  }
}
