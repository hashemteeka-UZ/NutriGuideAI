import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/account_deleter.dart';
import '../../auth/presentation/session_controller.dart';
import '../../logging/data/logging_providers.dart';

/// «حذف الحساب» (#311). Nothing on the phone is wiped unless the server
/// confirmed the deletion.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _word = TextEditingController();
  var _busy = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  bool _typed(AppLocalizations l10n) {
    final text = _word.text.trim();
    // Either language's word works, whichever keyboard is open.
    return text == l10n.deleteWord || text == 'حذف' || text == 'DELETE';
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await ref.read(accountDeleterProvider).delete();
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    // The same wipe as logout: tokens, personal tables, outbox, badges.
    await ref.read(sessionControllerProvider.notifier).logout();
    messenger?.showSnackBar(SnackBar(content: Text(l10n.deleteDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final counts =
        ref.watch(outboxCountsProvider).asData?.value ?? OutboxCounts.empty;
    final pending = counts.pending + counts.rejected + counts.events > 0;
    return Scaffold(
      key: const Key('delete-account-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.accountDelete),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(l10n.deleteBody, style: Theme.of(context).textTheme.bodyLarge),
            if (pending) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                key: const Key('delete-pending'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.signalSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n.deletePending),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('delete-word'),
              controller: _word,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.deleteTypeHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_failed) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                l10n.deleteFailed,
                key: const Key('delete-failed'),
                style: TextStyle(color: colors.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('delete-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 52),
              ),
              onPressed: _typed(l10n) && !_busy
                  ? () => unawaited(_delete())
                  : null,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.deleteConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
