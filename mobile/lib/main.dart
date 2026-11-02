import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on InsecureApiUrl catch (error) {
    // Refuse to start rather than send health data over plain HTTP.
    runApp(_MisconfiguredApp(message: error.toString()));
    return;
  }
  runApp(
    ProviderScope(
      retry: (int retryCount, Object error) => null,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}

class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'عنوان الخادم غير آمن أو غير مضبوط.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
