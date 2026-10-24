import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCode {
  LocaleCode(this.code);

  String code;
}

final localeCodeProvider = Provider<LocaleCode>((ref) => LocaleCode('ar'));

const localePreferenceKey = 'ng.locale';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    unawaited(_load());
    return const Locale('ar');
  }

  Future<void> toggle() {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    return _persist(next);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(localePreferenceKey);
      if (!ref.mounted) {
        return;
      }
      if (stored == 'ar' || stored == 'en') {
        _publish(Locale(stored!));
      }
    } on Object {
      // Keep Arabic when preferences cannot be read.
    }
  }

  Future<void> _persist(Locale locale) async {
    _publish(locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(localePreferenceKey, locale.languageCode);
    } on Object {
      // The choice still applies until the process ends.
    }
  }

  void _publish(Locale locale) {
    if (!ref.mounted) {
      return;
    }
    // Listeners read this code while handling the locale change. It has to
    // move first, or a catalog reload still queries the previous language.
    ref.read(localeCodeProvider).code = locale.languageCode;
    state = locale;
  }
}
