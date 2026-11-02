import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/config/app_config.dart';

void main() {
  test('debug falls back to the emulator host', () {
    final config = AppConfig.resolve(defined: '', release: false);
    expect(config.apiBaseUrl, AppConfig.defaultApiBaseUrl);
  });

  test('debug accepts plain HTTP for local servers', () {
    final config = AppConfig.resolve(
      defined: 'http://localhost:8000',
      release: false,
    );
    expect(config.apiBaseUrl, 'http://localhost:8000');
  });

  test('release accepts an HTTPS address', () {
    final config = AppConfig.resolve(
      defined: 'https://nutriguide-api.onrender.com',
      release: true,
    );
    expect(config.apiBaseUrl, 'https://nutriguide-api.onrender.com');
  });

  test('release refuses HTTP, an empty value and junk', () {
    for (final value in <String>[
      'http://nutriguide-api.onrender.com',
      '',
      'nutriguide-api.onrender.com',
      'https://',
    ]) {
      expect(
        () => AppConfig.resolve(defined: value, release: true),
        throwsA(isA<InsecureApiUrl>()),
        reason: value,
      );
    }
  });

  test('release allows HTTP only with the explicit local-demo flag', () {
    final config = AppConfig.resolve(
      defined: 'http://192.168.1.20:8000',
      release: true,
      allowHttp: true,
    );
    expect(config.apiBaseUrl, 'http://192.168.1.20:8000');
  });
}
