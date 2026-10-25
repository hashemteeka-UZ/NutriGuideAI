import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/logging_providers.dart';

/// Runs a sync when a session with a profile opens, when the app resumes,
/// and every five minutes while the app is in the foreground (#264).
final syncLifecycleProvider = Provider<void>((ref) {
  final binding = WidgetsBinding.instance;
  Timer? timer;

  bool ready() {
    final session = ref.read(sessionControllerProvider);
    return session is SignedIn && session.hasProfile;
  }

  void run() {
    if (ready()) {
      unawaited(ref.read(syncTriggerProvider).now());
    }
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(minutes: 5), (_) => run());
  }

  final observer = _LifecycleObserver((AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      run();
      startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      timer?.cancel();
    }
  });
  binding.addObserver(observer);
  ref.onDispose(() {
    binding.removeObserver(observer);
    timer?.cancel();
  });

  ref.listen(sessionControllerProvider, (
    SessionState? previous,
    SessionState next,
  ) {
    if (next is SignedIn && next.hasProfile) {
      run();
    }
  });
  startTimer();
  Future<void>.microtask(run);
});

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._onChange);

  final void Function(AppLifecycleState state) _onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _onChange(state);
}
