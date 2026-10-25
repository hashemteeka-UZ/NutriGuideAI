import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/logging_providers.dart';
import '../domain/logging.dart';

/// The message for a code the server sent with REJECTED (Decision #268).
/// An unknown code gets the generic line, never a crash.
String rejectedMessage(
  AppLocalizations l10n,
  String code, [
  RejectedKind kind = RejectedKind.meal,
]) {
  return switch (code) {
    'VALIDATION_ERROR' when kind == RejectedKind.water => l10n.waterRangeError,
    'VALIDATION_ERROR' when kind == RejectedKind.weight =>
      l10n.weightRangeError,
    'CLIENT_UUID_CONFLICT' => l10n.failureClientUuidConflict,
    'PLAN_ITEM_NOT_FOUND' => l10n.failurePlanItemNotFound,
    'LOG_NOT_FOUND' => l10n.failureLogNotFound,
    'CLOCK_SKEW' => l10n.failureClockSkew,
    _ => l10n.logRejectedGeneric,
  };
}

String _title(BuildContext context, AppLocalizations l10n, RejectedLog log) {
  return switch (log.kind) {
    RejectedKind.meal => <String>[
      if (log.slot != null) slotLabel(l10n, log.slot!),
      if (log.mealName != null) log.mealName!,
    ].join(' · '),
    RejectedKind.water => l10n.waterAmountMl(
      formatWhole(context, log.amountMl ?? 0),
    ),
    RejectedKind.weight => l10n.weightKgValue(
      formatFixed(context, log.weightKg ?? 0, 1),
    ),
  };
}

/// Lists the records the server refused, each with «حذف».
Future<void> showRejectedLogs(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const _RejectedDialog(),
  );
}

class _RejectedDialog extends ConsumerWidget {
  const _RejectedDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logs =
        ref.watch(rejectedLogsProvider).asData?.value ?? const <RejectedLog>[];
    return AlertDialog(
      key: const Key('rejected-dialog'),
      title: Text(l10n.syncRejectedTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final log in logs)
              ListTile(
                key: Key('rejected-${log.opId}'),
                contentPadding: EdgeInsets.zero,
                title: Text(_title(context, l10n, log)),
                subtitle: Text(rejectedMessage(l10n, log.code, log.kind)),
                trailing: TextButton(
                  key: Key('rejected-delete-${log.opId}'),
                  onPressed: () {
                    unawaited(
                      ref.read(loggingRepositoryProvider).discardRejected(log),
                    );
                  },
                  child: Text(l10n.syncDelete),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.syncClose),
        ),
      ],
    );
  }
}
