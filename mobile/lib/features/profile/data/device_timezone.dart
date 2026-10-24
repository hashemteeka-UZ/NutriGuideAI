import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/time/timezone_source.dart';

final class DeviceTimezoneSource implements TimezoneSource {
  const DeviceTimezoneSource();

  @override
  Future<String> ianaName() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return normalizeIana(info.identifier);
    } on Object {
      return 'UTC';
    }
  }
}

final timezoneSourceProvider = Provider<TimezoneSource>((ref) {
  return const DeviceTimezoneSource();
});
