import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_store.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';

/// The optional name of the onboarding name page (V5). It stays on this
/// phone only, in secure storage; it is never sent to the server.
const displayNameKey = 'ng.display_name';

/// Longest name kept, in characters.
const displayNameMaxLength = 30;

/// Whether onboarding opens with the name page. Widget tests of the other
/// steps turn it off; the name page has its own test.
final askNameProvider = Provider<bool>((ref) => true);

/// Where the name is kept; tests use memory.
final displayNameStoreProvider = Provider<SecureKeyValue>(
  (ref) => ref.watch(secureStoreProvider),
);

final displayNameProvider = NotifierProvider<DisplayNameController, String?>(
  DisplayNameController.new,
);

String? cleanDisplayName(String? raw) {
  final trimmed = raw?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed.length > displayNameMaxLength
      ? trimmed.substring(0, displayNameMaxLength).trim()
      : trimmed;
}

class DisplayNameController extends Notifier<String?> {
  var _loaded = false;

  /// True once the stored value was read (or could not be read).
  bool get loaded => _loaded;

  @override
  String? build() {
    // Signing out forgets the name with the rest of the account data.
    ref.listen<SessionState>(sessionControllerProvider, (
      SessionState? previous,
      SessionState next,
    ) {
      if (next is SignedOut && previous is SignedIn) {
        unawaited(save(null));
      }
    });
    unawaited(_load());
    return null;
  }

  Future<void> save(String? raw) async {
    final name = cleanDisplayName(raw);
    state = name;
    try {
      final store = ref.read(displayNameStoreProvider);
      if (name == null) {
        await store.delete(displayNameKey);
      } else {
        await store.write(displayNameKey, name);
      }
    } on Object {
      // The name still shows until the process ends.
    }
  }

  Future<void> _load() async {
    try {
      final stored = await ref
          .read(displayNameStoreProvider)
          .read(displayNameKey);
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      if (stored != null && state == null) {
        state = cleanDisplayName(stored);
      }
    } on Object {
      _loaded = true;
    }
  }
}
