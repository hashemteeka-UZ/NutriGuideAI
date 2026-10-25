import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/plan_sync.dart';

/// Refreshes cached plans when a session is open and when the app resumes.
final planLifecycleProvider = Provider<void>((ref) {
  final binding = WidgetsBinding.instance;
  final observer = _ResumeObserver(ref);
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));

  void run() {
    final session = ref.read(sessionControllerProvider);
    if (session is! SignedIn || !session.hasProfile) {
      return;
    }
    unawaited(ref.read(planSyncProvider).refresh());
  }

  ref.listen(sessionControllerProvider, (
    SessionState? previous,
    SessionState next,
  ) {
    if (next is SignedIn && next.hasProfile) {
      run();
    }
  });
  Future<void>.microtask(run);
});

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final session = _ref.read(sessionControllerProvider);
    if (session is! SignedIn || !session.hasProfile) {
      return;
    }
    unawaited(_ref.read(planSyncProvider).refresh(resume: true));
  }
}
