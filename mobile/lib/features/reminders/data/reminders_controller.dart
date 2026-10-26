import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../../plan/presentation/plan_format.dart';
import '../domain/reminders.dart';
import 'notifications_gateway.dart';

const _preferenceKeys = <ReminderKind, String>{
  ReminderKind.meals: 'ng.reminders.meals',
  ReminderKind.water: 'ng.reminders.water',
  ReminderKind.weighIn: 'ng.reminders.weigh_in',
};

final notificationsGatewayProvider = Provider<NotificationsGateway>((ref) {
  return PluginNotificationsGateway();
});

enum ToggleOutcome { changed, denied, needsWaterGoal }

final remindersProvider =
    NotifierProvider<RemindersController, ReminderSettings>(
      RemindersController.new,
    );

/// The three switches of «التذكيرات» (#313). Stored in shared preferences;
/// every change, profile save and app start schedules them again.
class RemindersController extends Notifier<ReminderSettings> {
  final _loaded = Completer<void>();

  @override
  ReminderSettings build() {
    ref.listen(sessionControllerProvider, (SessionState? _, SessionState next) {
      if (next is SignedOut) {
        unawaited(_clear());
      }
    });
    unawaited(_load());
    return const ReminderSettings();
  }

  Future<void> get loaded => _loaded.future;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) {
        return;
      }
      state = ReminderSettings(
        meals: prefs.getBool(_preferenceKeys[ReminderKind.meals]!) ?? false,
        water: prefs.getBool(_preferenceKeys[ReminderKind.water]!) ?? false,
        weighIn: prefs.getBool(_preferenceKeys[ReminderKind.weighIn]!) ?? false,
      );
    } on Object {
      // All off.
    } finally {
      if (!_loaded.isCompleted) {
        _loaded.complete();
      }
    }
  }

  Future<bool> hasWaterGoal() async {
    final database = ref.read(appDatabaseProvider);
    final rows = await (database.select(
      database.daySummaries,
    )..where((t) => t.goalMl.isNotNull())).get();
    return rows.isNotEmpty;
  }

  Future<ToggleOutcome> toggle(ReminderKind kind, bool on) async {
    if (on) {
      if (kind == ReminderKind.water && !await hasWaterGoal()) {
        return ToggleOutcome.needsWaterGoal;
      }
      final granted = await ref
          .read(notificationsGatewayProvider)
          .requestPermission();
      if (!granted) {
        return ToggleOutcome.denied;
      }
    }
    state = state.with_(kind, on);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preferenceKeys[kind]!, on);
    } on Object {
      // Applies until the process ends.
    }
    await reschedule();
    return ToggleOutcome.changed;
  }

  Future<Map<String, int>> _mealStarts() async {
    final database = ref.read(appDatabaseProvider);
    final rows = await database.select(database.mealWindows).get();
    if (rows.isEmpty) {
      return const <String, int>{};
    }
    final latest = rows
        .map((row) => row.windowDate)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return <String, int>{
      for (final row in rows)
        if (row.windowDate == latest)
          if (clockMinutes(row.start) case final int minutes) row.slot: minutes,
    };
  }

  /// Cancels everything, then schedules what is on.
  Future<void> reschedule() async {
    final gateway = ref.read(notificationsGatewayProvider);
    await gateway.cancelAll();
    if (!state.any) {
      return;
    }
    final l10n = lookupAppLocalizations(
      Locale(ref.read(localeProvider).languageCode),
    );
    final specs = planReminders(
      state,
      mealStarts: await _mealStarts(),
      hasWaterGoal: await hasWaterGoal(),
    );
    for (final spec in specs) {
      final body = switch (spec.kind) {
        ReminderKind.meals => l10n.reminderMealBody(
          slotLabel(l10n, spec.slot!),
        ),
        ReminderKind.water => l10n.reminderWaterBody,
        ReminderKind.weighIn => l10n.reminderWeighInBody,
      };
      final weekday = spec.weekday;
      if (weekday == null) {
        await gateway.scheduleDaily(
          id: spec.id,
          hour: spec.hour,
          minute: spec.minute,
          title: l10n.appTitle,
          body: body,
          route: spec.route,
        );
      } else {
        await gateway.scheduleWeekly(
          id: spec.id,
          weekday: weekday,
          hour: spec.hour,
          minute: spec.minute,
          title: l10n.appTitle,
          body: body,
          route: spec.route,
        );
      }
    }
  }

  /// Logout and account deletion: nothing stays scheduled for the next user.
  Future<void> _clear() async {
    state = const ReminderSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _preferenceKeys.values) {
        await prefs.remove(key);
      }
    } on Object {
      // Preferences are cleared with the next toggle.
    }
    try {
      await ref.read(notificationsGatewayProvider).cancelAll();
    } on Object {
      // No plugin (tests) or nothing scheduled.
    }
  }
}

/// Watched by the app: sets the plugin up, opens a tapped notification's
/// tab, and schedules the saved switches again on start.
final remindersLifecycleProvider = Provider<void>((ref) {
  final gateway = ref.watch(notificationsGatewayProvider);
  void open(String route) {
    ref.read(routerProvider).go(route);
  }

  unawaited(() async {
    try {
      await gateway.initialize(open);
      final launch = await gateway.launchRoute();
      if (launch != null) {
        open(launch);
      }
      final controller = ref.read(remindersProvider.notifier);
      await controller.loaded;
      if (ref.read(remindersProvider).any) {
        await controller.reschedule();
      }
    } on Object {
      // Reminders are optional; the app works without them.
    }
  }());
});
