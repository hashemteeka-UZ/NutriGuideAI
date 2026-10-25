import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/logging_providers.dart';
import '../domain/logging.dart';
import 'rejected_messages.dart';

/// The small sync status in Today's header (Decision #264). Nothing when
/// the outbox is empty and idle.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final status = ref.watch(syncStatusProvider);
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      liveRegion: true,
      child: switch (status.badge) {
        SyncBadge.hidden => const SizedBox.shrink(key: Key('sync-idle')),
        SyncBadge.uploading => Text(
          l10n.syncUploading,
          key: const Key('sync-uploading'),
          style: style?.copyWith(color: colors.fg2),
        ),
        SyncBadge.waiting => Text(
          l10n.syncWaiting(formatWhole(context, status.pending)),
          key: const Key('sync-waiting'),
          style: style?.copyWith(color: colors.fg2),
        ),
        SyncBadge.rejected => InkWell(
          key: const Key('sync-rejected'),
          onTap: () => unawaited(showRejectedLogs(context, ref)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.circle, size: 10, color: colors.protein),
                const SizedBox(width: 6),
                Text(l10n.syncRejected, style: style),
              ],
            ),
          ),
        ),
      },
    );
  }
}
