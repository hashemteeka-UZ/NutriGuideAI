import 'package:nutriguide/features/reminders/data/notifications_gateway.dart';

/// Records what the reminders would schedule; never touches a platform.
class FakeNotificationsGateway implements NotificationsGateway {
  FakeNotificationsGateway({this.granted = true});

  bool granted;
  int permissionRequests = 0;
  int cancelAllCalls = 0;
  int settingsOpened = 0;
  final scheduled =
      <
        int,
        ({int hour, int minute, int? weekday, String body, String route})
      >{};

  @override
  Future<void> initialize(void Function(String route) onOpen) async {}

  @override
  Future<String?> launchRoute() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return granted;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    scheduled.clear();
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String route,
  }) async {
    scheduled[id] = (
      hour: hour,
      minute: minute,
      weekday: null,
      body: body,
      route: route,
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
  }) async {
    scheduled[id] = (
      hour: hour,
      minute: minute,
      weekday: weekday,
      body: body,
      route: route,
    );
  }

  @override
  Future<void> openAppSettings() async {
    settingsOpened += 1;
  }
}
