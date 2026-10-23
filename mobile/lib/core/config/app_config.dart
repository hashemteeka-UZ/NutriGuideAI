import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const String defaultApiBaseUrl = 'http://10.0.2.2:8000';

  final String apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    const defined = String.fromEnvironment('API_BASE_URL');
    return AppConfig(apiBaseUrl: defined.isEmpty ? defaultApiBaseUrl : defined);
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
