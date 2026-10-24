import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sign-out seam shared by the auth interceptor and the session controller.
///
/// The interceptor writes here and never reads the session notifier, so
/// interceptor -> session -> repository -> dio -> interceptor cannot cycle.
class SessionSignals {
  void Function()? onSessionEnded;
}

final sessionSignalsProvider = Provider<SessionSignals>(
  (ref) => SessionSignals(),
);
