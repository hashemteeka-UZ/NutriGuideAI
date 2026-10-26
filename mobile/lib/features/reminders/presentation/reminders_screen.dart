import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reminders_controller.dart';
import '../domain/reminders.dart';

/// «التذكيرات» (#313): three switches, all off by default.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  var _denied = false;
  var _needsGoal = false;
  var _busy = false;

  Future<void> _toggle(ReminderKind kind, bool on) async {
    setState(() => _busy = true);
    final outcome = await ref.read(remindersProvider.notifier).toggle(kind, on);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _denied = outcome == ToggleOutcome.denied;
      _needsGoal = outcome == ToggleOutcome.needsWaterGoal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final settings = ref.watch(remindersProvider);
    final rows = <(ReminderKind, String, String)>[
      (ReminderKind.meals, l10n.remindersMeals, l10n.remindersMealsSub),
      (ReminderKind.water, l10n.remindersWater, l10n.remindersWaterSub),
      (ReminderKind.weighIn, l10n.remindersWeighIn, l10n.remindersWeighInSub),
    ];
    return Scaffold(
      key: const Key('reminders-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.accountReminders),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(l10n.remindersIntro, style: TextStyle(color: colors.fg2)),
            const SizedBox(height: 8),
            for (final (kind, title, subtitle) in rows)
              SwitchListTile(
                key: Key('reminder-${kind.name}'),
                value: settings.isOn(kind),
                title: Text(title),
                // Up to two lines, so the hint is never cut (#319).
                subtitle: Text(subtitle, maxLines: 2),
                onChanged: _busy
                    ? null
                    : (bool on) => unawaited(_toggle(kind, on)),
              ),
            if (_needsGoal)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.remindersNeedWaterGoal,
                  key: const Key('reminders-need-goal'),
                ),
              ),
            if (_denied)
              Container(
                key: const Key('reminders-denied'),
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.signalSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.remindersDenied),
                    TextButton(
                      key: const Key('reminders-open-settings'),
                      onPressed: () => unawaited(
                        ref
                            .read(notificationsGatewayProvider)
                            .openAppSettings(),
                      ),
                      child: Text(l10n.remindersOpenSettings),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
