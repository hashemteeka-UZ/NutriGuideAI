import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';

import '../../support/memory_secure.dart';

void main() {
  test('round-trips tokens through secure storage', () async {
    final storage = MemorySecure();
    final expiry = DateTime.utc(2026, 10, 23, 12, 15, 30);
    final saved = AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessExpiry: expiry,
      hasProfile: true,
    );
    await SecureTokenStore(storage).save(saved);

    final loaded = await SecureTokenStore(storage).read();

    expect(loaded?.accessToken, 'access');
    expect(loaded?.refreshToken, 'refresh');
    expect(loaded?.accessExpiry, expiry);
    expect(loaded?.hasProfile, isTrue);
    expect(storage.values.keys, containsAll(SecureTokenStore.keys));
  });

  test('a keystore read error signs out and clears auth keys', () async {
    final storage = MemorySecure()
      ..values.addAll(<String, String>{
        SecureTokenStore.accessKey: 'access',
        SecureTokenStore.refreshKey: 'refresh',
        SecureTokenStore.expiryKey: '2026-10-23T12:00:00.000Z',
        SecureTokenStore.profileKey: 'true',
      });
    storage.throwReads = true;
    storage.throwDeletes = true;

    final store = SecureTokenStore(storage);
    final loaded = await store.read();

    expect(loaded, isNull);
    expect(store.current, isNull);
    expect(storage.deleted, containsAll(SecureTokenStore.keys));
  });

  test('clear removes only the auth keys', () async {
    final storage = MemorySecure()..values['other'] = 'keep';
    final store = SecureTokenStore(storage);
    await store.save(
      AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiry: DateTime.utc(2026, 10, 23),
        hasProfile: false,
      ),
    );

    await store.clear();

    expect(store.current, isNull);
    expect(storage.values, <String, String>{'other': 'keep'});
  });
}
