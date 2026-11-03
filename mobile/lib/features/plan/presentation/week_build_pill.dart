import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/plan_providers.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import 'showcase_controller.dart';

/// Stop codes after which a retry from here cannot help.
const _finalStops = <String>{'NOT_ELIGIBLE', 'NO_TARGET', 'PROFILE_NOT_FOUND'};

/// Shows that the rest of the week is still being built, or that some days
/// could not be built and can be tried again. Hidden otherwise.
class WeekBuildPill extends ConsumerWidget {
  const WeekBuildPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(showcaseControllerProvider);
    if (!state.running && !state.finished) {
      return const SizedBox.shrink();
    }
    final plans =
        ref.watch(weekPlansProvider).asData?.value ?? const <DayPlan>[];
    final week = <String>[
      for (final date in weekDates(ref.watch(planClockProvider)()))
        isoDate(date),
    ];
    final planned = <String>{for (final plan in plans) plan.planDate};
    final built = week.where(planned.contains).length;
    final missing = week.length - built;
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;

    if (state.running) {
      return _Pill(
        key: const Key('week-build-pill'),
        tint: colors.brand,
        leading: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: colors.brand),
        ),
        label: l10n.weekBuildingPill(built, week.length),
      );
    }
    if (missing == 0 || _finalStops.contains(state.stopCode)) {
      return const SizedBox.shrink();
    }
    return _Pill(
      key: const Key('week-build-failed'),
      tint: colors.warn,
      leading: Icon(Icons.error_outline, size: 16, color: colors.fg),
      label: l10n.weekBuildFailed(missing),
      action: TextButton(
        key: const Key('week-build-retry'),
        onPressed: () => unawaited(
          ref.read(showcaseControllerProvider.notifier).retryMissing(),
        ),
        child: Text(l10n.weekBuildRetry),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.tint,
    required this.leading,
    required this.label,
    this.action,
    super.key,
  });

  final Color tint;
  final Widget leading;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              14,
              action == null ? 8 : 2,
              action == null ? 14 : 4,
              action == null ? 8 : 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                leading,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.fg),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
