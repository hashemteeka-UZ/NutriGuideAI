import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/failure_message.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/onboarding_steps.dart';
import 'onboarding_controller.dart';
import 'onboarding_screen.dart';
import 'result_screen.dart';

/// «تعديل بياناتي» (#309): the onboarding steps, opened from a list and
/// saved with PUT /me/profile. Weight is not edited here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(onboardingControllerProvider.notifier).startEdit());
      }
    });
  }

  Future<void> _done() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.of(context);
    await ref.read(onboardingControllerProvider.notifier).finishEdit();
    messenger?.showSnackBar(SnackBar(content: Text(l10n.editSavedNote)));
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/me');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final onStep = state.editing && state.stepIndex >= 0;
    final Widget body;
    if (!state.editing || state.phase == OnboardingPhase.checking) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.phase == OnboardingPhase.saving) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.edit == null) {
      final error = state.loadError;
      body = Center(
        child: Padding(
          key: const Key('edit-offline'),
          padding: const EdgeInsets.all(24),
          child: Text(
            error is NetworkUnavailable || error is Timeout
                ? l10n.offlineBar
                : error is AppFailure
                ? failureMessage(l10n, error)
                : l10n.onbReferenceError,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (state.phase == OnboardingPhase.result) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ResultView(),
            const SizedBox(height: 12),
            Text(
              l10n.editSavedNote,
              key: const Key('edit-saved-note'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.fg2),
            ),
          ],
        ),
      );
    } else if (onStep) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: onboardingStepView(state.step),
      );
    } else {
      body = ListView(
        key: const Key('edit-step-list'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.editIntro, style: TextStyle(color: colors.fg2)),
          const SizedBox(height: 8),
          for (final step in state.steps)
            Card(
              child: ListTile(
                key: Key('edit-step-${step.name}'),
                minTileHeight: 56,
                title: Text(editStepLabel(l10n, step)),
                trailing: Icon(
                  stepIsValid(step, state.draft)
                      ? Icons.chevron_left
                      : Icons.error_outline,
                  textDirection: Directionality.of(context),
                ),
                onTap: () => notifier.openStep(step),
              ),
            ),
        ],
      );
    }
    final failure = state.fieldError ?? state.actionError;
    final result = state.phase == OnboardingPhase.result;
    final canSave =
        state.edit != null &&
        state.phase == OnboardingPhase.ready &&
        notifier.editIsValid;
    return PopScope(
      canPop: !onStep && !result,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && onStep) {
          notifier.closeStep();
        }
      },
      child: Scaffold(
        key: const Key('edit-profile-screen'),
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.bg,
          foregroundColor: colors.fg,
          title: Text(l10n.accountEditProfile),
          leading: onStep
              ? IconButton(
                  key: const Key('edit-step-back'),
                  tooltip: l10n.onbBack,
                  icon: const BackButtonIcon(),
                  onPressed: notifier.closeStep,
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(child: body),
              if (failure != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    failureMessage(l10n, failure),
                    key: const Key('edit-error'),
                    style: TextStyle(color: colors.danger),
                  ),
                ),
              if (state.editing && state.edit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: Key(result ? 'edit-done' : 'edit-save'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 52),
                      ),
                      onPressed: result
                          ? () => unawaited(_done())
                          : canSave
                          ? () => unawaited(notifier.saveEdit())
                          : null,
                      child: Text(result ? l10n.editDone : l10n.editSave),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String editStepLabel(AppLocalizations l10n, OnboardingStep step) {
  return switch (step) {
    OnboardingStep.about => l10n.editStepAbout,
    OnboardingStep.measure => l10n.editStepMeasure,
    OnboardingStep.goal => l10n.editStepGoal,
    OnboardingStep.pace => l10n.editStepPace,
    OnboardingStep.activity => l10n.editStepActivity,
    OnboardingStep.care => l10n.editStepCare,
    OnboardingStep.allergy => l10n.editStepAllergy,
    OnboardingStep.safety => l10n.editStepSafety,
    OnboardingStep.rhythm => l10n.editStepRhythm,
    OnboardingStep.fluid => l10n.editStepFluid,
  };
}
