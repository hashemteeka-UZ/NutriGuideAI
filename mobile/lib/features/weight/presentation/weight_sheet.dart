import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../../plan/presentation/showcase_controller.dart';
import '../../profile/presentation/widgets/wheel_picker.dart';
import '../data/weight_providers.dart';
import '../domain/weight.dart';

/// «سجّل وزنك»: today's weight on a 30.0-250.0 wheel (Decision #271).
Future<void> showWeightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => const _WeightSheet(),
  );
}

class _WeightSheet extends ConsumerStatefulWidget {
  const _WeightSheet();

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  double? _value;
  var _busy = false;

  double _initial() {
    final stored = ref.read(latestWeightProvider).asData?.value?.weightKg;
    final profile = ref.read(userContextProvider)?.latestWeightKg;
    final value = stored ?? profile ?? 70;
    return value.clamp(weightMinKg, weightMaxKg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = _value ??= _initial();
    return SafeArea(
      child: Padding(
        key: const Key('weight-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.weightTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: NumberWheel(
                min: weightMinKg,
                max: weightMaxKg,
                step: weightStepKg,
                value: value,
                fractionDigits: 1,
                semanticLabel: l10n.weightTitle,
                onChanged: (double next) => setState(() => _value = next),
              ),
            ),
            Text(
              l10n.weightKgValue(value.toStringAsFixed(1)),
              key: const Key('weight-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('weight-save'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _busy ? null : () => unawaited(_save(value)),
              child: Text(l10n.weightSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(double value) async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.maybeOf(context);
    final sex = ref.read(userContextProvider)?.sex == 'FEMALE'
        ? 'female'
        : 'other';
    final animate = animationsEnabled(context);
    WeightSaveResult result;
    try {
      result = await ref.read(weightRepositoryProvider).save(value);
    } on WeightException catch (error) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'VALIDATION_ERROR'
                ? l10n.weightRangeError
                : l10n.failureGeneric,
          ),
        ),
      );
      return;
    }
    navigator.pop();
    switch (result.status) {
      case WeightSaveStatus.queued:
        messenger.showSnackBar(SnackBar(content: Text(l10n.weightQueued)));
        return;
      case WeightSaveStatus.staleIgnored:
        messenger.showSnackBar(SnackBar(content: Text(l10n.weightStale)));
        return;
      case WeightSaveStatus.created || WeightSaveStatus.updated:
        messenger.showSnackBar(SnackBar(content: Text(l10n.weightSaved)));
    }
    if (result.newTargetId != null) {
      ref.read(targetNoticeProvider.notifier).show();
    }
    unawaited(ref.read(userContextRefreshProvider)().catchError((Object _) {}));
    final host = navigator.context;
    if (result.goalReached && host.mounted) {
      await showGoalReachedSheet(host, sex: sex, animate: animate);
    }
    if (result.newTargetId != null && host.mounted && router != null) {
      await showTargetNoticeDialog(host);
    }
  }
}

/// «وصلت إلى هدفك!» (gendered); the burst is skipped with reduce motion.
Future<void> showGoalReachedSheet(
  BuildContext context, {
  required String sex,
  required bool animate,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      final colors = context.appColors;
      return SafeArea(
        child: Padding(
          key: const Key('goal-reached-sheet'),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (animate)
                TweenAnimationBuilder<double>(
                  key: const Key('goal-burst'),
                  tween: Tween<double>(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (BuildContext context, double scale, Widget? child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Icon(
                    Icons.emoji_events,
                    size: 72,
                    color: colors.brand,
                  ),
                )
              else
                Icon(Icons.emoji_events, size: 72, color: colors.brand),
              const SizedBox(height: 12),
              Text(
                l10n.weightGoalReached(sex),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.weightGoalReachedBody(sex),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The new-target notice as a dialog after a direct save (#275).
Future<void> showTargetNoticeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return const AlertDialog(content: TargetNoticeBody(inDialog: true));
    },
  );
}

/// The notice text with «أعد بناء خطة الأيام القادمة» and «لاحقًا». The
/// app never rebuilds by itself; the rebuild keeps logged days.
class TargetNoticeBody extends ConsumerWidget {
  const TargetNoticeBody({this.inDialog = false, super.key});

  final bool inDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('target-notice'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.targetNoticeBody,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('target-rebuild'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () {
            ref.read(targetNoticeProvider.notifier).dismiss();
            final router = GoRouter.of(context);
            if (inDialog) {
              Navigator.of(context).pop();
            }
            unawaited(
              ref
                  .read(showcaseControllerProvider.notifier)
                  .start(force: true, fromTomorrow: true),
            );
            router.go('/generate');
          },
          child: Text(l10n.targetNoticeRebuild),
        ),
        TextButton(
          key: const Key('target-later'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () {
            ref.read(targetNoticeProvider.notifier).dismiss();
            if (inDialog) {
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.targetNoticeLater),
        ),
      ],
    );
  }
}
