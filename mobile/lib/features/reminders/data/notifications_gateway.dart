import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/timezone_source.dart';

/// What the reminders need from the platform; faked in tests.
abstract interface class NotificationsGateway {
  /// Called with the route of a tapped notification.
  Future<void> initialize(void Function(String route) onOpen);

  /// The route of the notification that launched the app, if any.
  Future<String?> launchRoute();

  /// Android 13+ runtime permission; true when granted (or not needed).
  Future<bool> requestPermission();

  Future<void> cancelAll();

  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String route,
  });

  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String route,
  });

  Future<void> openAppSettings();
}

const _channel = AndroidNotificationDetails(
  'reminders',
  'Reminders',
  channelDescription: 'Meal, water and weigh-in reminders',
  importance: Importance.defaultImportance,
  priority: Priority.defaultPriority,
);

final class PluginNotificationsGateway implements NotificationsGateway {
  PluginNotificationsGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _settings = MethodChannel('nutriguide/settings');
  var _ready = false;

  @override
  Future<void> initialize(void Function(String route) onOpen) async {
    if (_ready) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(normalizeIana(info.identifier)));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final route = response.payload;
        if (route != null) {
          onOpen(route);
        }
      },
    );
    _ready = true;
  }

  @override
  Future<String?> launchRoute() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) {
      return null;
    }
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return true;
    }
    if (await android.areNotificationsEnabled() ?? false) {
      return true;
    }
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _next(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (!at.isAfter(now) || (weekday != null && at.weekday != weekday)) {
      at = at.add(const Duration(days: 1));
    }
    return at;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String route,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: _next(hour, minute),
      notificationDetails: const NotificationDetails(android: _channel),
      // Inexact on purpose: no exact-alarm permission (#313).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: route,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String route,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: _next(hour, minute, weekday: weekday),
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: route,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await _settings.invokeMethod<void>('openAppSettings');
    } on Object {
      // Nothing more to offer; the explanation stays on screen.
    }
  }
}
