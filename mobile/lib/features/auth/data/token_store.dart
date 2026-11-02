import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_store.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiry,
    required this.hasProfile,
    this.email,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiry;
  final bool hasProfile;

  /// Kept beside the tokens so the account page can show it after a restart
  /// even when the server is slow or unreachable.
  final String? email;

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessExpiry,
    bool? hasProfile,
    String? email,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessExpiry: accessExpiry ?? this.accessExpiry,
      hasProfile: hasProfile ?? this.hasProfile,
      email: email ?? this.email,
    );
  }
}

abstract interface class TokenStore {
  AuthTokens? get current;

  Future<void> ensureLoaded();

  Future<AuthTokens?> read();

  Future<void> save(AuthTokens tokens);

  Future<void> updateHasProfile(bool hasProfile);

  Future<void> updateEmail(String email);

  Future<void> clear();
}

final class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  static const accessKey = 'ng.auth.access';
  static const refreshKey = 'ng.auth.refresh';
  static const expiryKey = 'ng.auth.access_expiry';
  static const profileKey = 'ng.auth.has_profile';
  static const emailKey = 'ng.auth.email';

  static const keys = <String>[
    accessKey,
    refreshKey,
    expiryKey,
    profileKey,
    emailKey,
  ];

  final SecureKeyValue _storage;
  AuthTokens? _memory;
  var _loaded = false;

  @override
  AuthTokens? get current => _memory;

  @override
  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    await read();
  }

  @override
  Future<AuthTokens?> read() async {
    try {
      final refresh = await _storage.read(refreshKey);
      if (refresh == null || refresh.isEmpty) {
        await _deleteKeys();
        _memory = null;
        _loaded = true;
        return null;
      }
      final access = await _storage.read(accessKey);
      final expiryRaw = await _storage.read(expiryKey);
      final profileRaw = await _storage.read(profileKey);
      final emailRaw = await _storage.read(emailKey);
      final expiry = DateTime.tryParse(expiryRaw ?? '')?.toUtc();
      _memory = AuthTokens(
        accessToken: access ?? '',
        refreshToken: refresh,
        accessExpiry:
            expiry ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        hasProfile: profileRaw == 'true',
        email: emailRaw == null || emailRaw.isEmpty ? null : emailRaw,
      );
      _loaded = true;
      return _memory;
    } on Object {
      await _deleteKeys();
      _memory = null;
      _loaded = true;
      return null;
    }
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(accessKey, tokens.accessToken);
    await _storage.write(refreshKey, tokens.refreshToken);
    await _storage.write(
      expiryKey,
      tokens.accessExpiry.toUtc().toIso8601String(),
    );
    await _storage.write(profileKey, tokens.hasProfile ? 'true' : 'false');
    final email = tokens.email;
    if (email == null || email.isEmpty) {
      await _storage.delete(emailKey);
    } else {
      await _storage.write(emailKey, email);
    }
    _memory = tokens;
    _loaded = true;
  }

  @override
  Future<void> updateHasProfile(bool hasProfile) async {
    final current = _memory;
    if (current == null) {
      return;
    }
    await _storage.write(profileKey, hasProfile ? 'true' : 'false');
    _memory = current.copyWith(hasProfile: hasProfile);
  }

  @override
  Future<void> updateEmail(String email) async {
    final current = _memory;
    if (current == null || email.isEmpty || current.email == email) {
      return;
    }
    await _storage.write(emailKey, email);
    _memory = current.copyWith(email: email);
  }

  @override
  Future<void> clear() async {
    _memory = null;
    _loaded = true;
    await _deleteKeys();
  }

  Future<void> _deleteKeys() async {
    for (final key in keys) {
      try {
        await _storage.delete(key);
      } on Object {
        // A broken Keystore must not block sign-out.
      }
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SecureTokenStore(ref.watch(secureStoreProvider));
});
