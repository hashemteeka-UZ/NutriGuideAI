import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/plan_sync.dart';
import 'showcase_controller.dart';

/// Refreshes cached plans when a session is open and when the app resumes.
/// After the first refresh it finishes a week build the app was closed in.
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
    unawaited(_refreshThenResume(ref));
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

Future<void> _refreshThenResume(Ref ref) async {
  try {
    await ref.read(planSyncProvider).refresh();
  } on Object {
    // The offline bar covers a failed refresh; resuming still makes sense.
  }
  if (!ref.mounted) {
    return;
  }
  await ref.read(showcaseControllerProvider.notifier).resume();
}

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
