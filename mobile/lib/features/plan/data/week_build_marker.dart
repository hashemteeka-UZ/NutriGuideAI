import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that a week build started and has not finished, so the next
/// app open can build the days that are still missing.
class WeekBuildMarker {
  WeekBuildMarker({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _key = 'week_build_pending';

  final Future<SharedPreferences> Function() _preferences;

  Future<bool> pending() async {
    try {
      return (await _preferences()).getBool(_key) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> mark(bool pending) async {
    try {
      final preferences = await _preferences();
      if (pending) {
        await preferences.setBool(_key, true);
      } else {
        await preferences.remove(_key);
      }
    } on Object {
      // Without storage the build simply does not resume on the next open.
    }
  }
}

final weekBuildMarkerProvider = Provider<WeekBuildMarker>(
  (ref) => WeekBuildMarker(),
);
