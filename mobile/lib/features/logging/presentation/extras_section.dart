import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/logging_providers.dart';
import '../domain/logging.dart';
import 'other_meal_screen.dart';

/// «إضافات اليوم»: catalog meals logged outside the plan, with «تراجع».
class ExtrasSection extends ConsumerWidget {
  const ExtrasSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs =
        <LoggedMeal>[
          for (final log in ref.watch(todayLogsProvider))
            if (log.kind == 'MEAL' && !log.deleting) log,
        ]..sort(
          (LoggedMeal a, LoggedMeal b) => a.consumedAt.compareTo(b.consumedAt),
        );
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Column(
      key: const Key('today-extras'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          l10n.extrasTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        for (final log in logs)
          ListTile(
            key: Key('extra-${log.clientUuid}'),
            contentPadding: EdgeInsets.zero,
            minTileHeight: 48,
            title: Text(log.name ?? ''),
            subtitle: Text(
              <String>[
                if (log.slot != null) slotLabel(l10n, log.slot!),
                l10n.servingsCount(servingsLabel(log.servingsConsumed ?? 1)),
                if (log.kcal != null)
                  l10n.mealKcal(formatWhole(context, log.kcal!)),
                if (log.pending) l10n.extraPending,
                if (log.rejected) l10n.syncRejected,
              ].join(' · '),
              style: TextStyle(color: colors.fg2),
            ),
            trailing: TextButton(
              key: Key('extra-undo-${log.clientUuid}'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () {
                unawaited(
                  ref.read(loggingRepositoryProvider).undoLog(log.clientUuid),
                );
              },
              child: Text(l10n.eatUndo),
            ),
          ),
      ],
    );
  }
}
