import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/plan_providers.dart';

class OfflineBar extends ConsumerWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(planOfflineProvider)) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;
    return Material(
      key: const Key('offline-bar'),
      color: colors.warn.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          AppLocalizations.of(context).offlineBar,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.fg),
        ),
      ),
    );
  }
}
