import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_controller.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/catalog_sync.dart';

/// Downloads the catalog after sign-in and when the language changes.
/// The work never blocks the screen that triggered it.
final catalogLifecycleProvider = Provider<void>((ref) {
  void run() {
    if (ref.read(sessionControllerProvider) is! SignedIn) {
      return;
    }
    final lang = ref.read(localeProvider).languageCode;
    unawaited(ref.read(catalogSyncProvider).sync(lang: lang));
  }

  ref.listen(sessionControllerProvider, (
    SessionState? previous,
    SessionState next,
  ) {
    if (next is SignedIn) {
      run();
    }
  });
  ref.listen(localeProvider, (Locale? previous, Locale next) {
    if (previous?.languageCode != next.languageCode) {
      run();
    }
  });
});
