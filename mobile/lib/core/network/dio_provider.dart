import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'debug_request_log.dart';
import 'server_wake.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final wake = ref.read(serverWakeProvider.notifier);
  dio.interceptors.add(
    ServerWakeInterceptor(
      onSlow: wake.slow,
      onAnswered: wake.answered,
      onFailed: wake.failed,
    )..dio = dio,
  );
  if (kDebugMode) {
    dio.interceptors.add(const DebugRequestLogInterceptor());
  }
  ref.onDispose(() {
    dio.close();
  });
  return dio;
});

/// Sends one health call when the app opens so the hosted server starts
/// waking before the first real request. Errors are ignored.
final serverWarmUpProvider = Provider<void>((ref) {
  final dio = ref.read(dioProvider);
  unawaited(
    dio.get<Object>('/api/v1/health').then<void>((_) {}, onError: (_) {}),
  );
});
