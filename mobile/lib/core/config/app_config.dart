import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const String defaultApiBaseUrl = 'http://10.0.2.2:8000';

  final String apiBaseUrl;

  /// Reads `--dart-define=API_BASE_URL=...`.
  ///
  /// A release build must talk to the hosted server over HTTPS. The only
  /// exception is `--dart-define=ALLOW_HTTP_IN_RELEASE=true`, kept for the
  /// local Wi-Fi demo APK described in docs/INSTALL_APK.md.
  factory AppConfig.fromEnvironment() {
    const defined = String.fromEnvironment('API_BASE_URL');
    const allowHttp = bool.fromEnvironment('ALLOW_HTTP_IN_RELEASE');
    return AppConfig.resolve(
      defined: defined,
      release: kReleaseMode,
      allowHttp: allowHttp,
    );
  }

  /// Throws [InsecureApiUrl] when a release build would use a missing,
  /// malformed or non-HTTPS address.
  factory AppConfig.resolve({
    required String defined,
    required bool release,
    bool allowHttp = false,
  }) {
    final url = defined.trim();
    if (!release) {
      return AppConfig(apiBaseUrl: url.isEmpty ? defaultApiBaseUrl : url);
    }
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || (allowHttp && uri.scheme == 'http'));
    if (!valid) {
      throw InsecureApiUrl(url);
    }
    return AppConfig(apiBaseUrl: url);
  }
}

final class InsecureApiUrl implements Exception {
  const InsecureApiUrl(this.url);

  final String url;

  @override
  String toString() =>
      'Release builds need --dart-define=API_BASE_URL=https://<host> '
      '(got "${url.isEmpty ? '<empty>' : url}").';
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
