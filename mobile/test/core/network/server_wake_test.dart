import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/l10n/app_localizations.dart';
import 'package:nutriguide/core/network/server_wake.dart';
import 'package:nutriguide/core/network/server_wake_banner.dart';
import 'package:nutriguide/core/theme/app_theme.dart';

void main() {
  group('ServerWakeInterceptor', () {
    late _Script adapter;
    late List<String> events;
    late Dio dio;

    setUp(() {
      adapter = _Script();
      events = <String>[];
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.test',
          receiveTimeout: const Duration(seconds: 30),
        ),
      )..httpClientAdapter = adapter;
      dio.interceptors.add(
        ServerWakeInterceptor(
          onSlow: () => events.add('slow'),
          onAnswered: () => events.add('answered'),
          onFailed: () => events.add('failed'),
          slowAfter: const Duration(milliseconds: 20),
        )..dio = dio,
      );
    });

    test('sign-in and health calls wait 90 s, others keep 30 s', () async {
      await dio.get<Object>('/api/v1/health');
      await dio.post<Object>('/api/v1/auth/login');
      await dio.get<Object>('/api/v1/me/profile');

      expect(adapter.seen.map((o) => o.receiveTimeout), <Duration>[
        wakeReceiveTimeout,
        wakeReceiveTimeout,
        const Duration(seconds: 30),
      ]);
      expect(wakeReceiveTimeout, const Duration(seconds: 90));
    });

    test('a login that times out is sent once more', () async {
      adapter.timeouts = 1;

      final response = await dio.post<Object>('/api/v1/auth/login');

      expect(response.statusCode, 200);
      expect(adapter.seen, hasLength(2));
      expect(events.last, 'answered');
    });

    test('a second timeout is not retried again', () async {
      adapter.timeouts = 5;

      await expectLater(
        dio.get<Object>('/api/v1/health'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.seen, hasLength(2));
      expect(events, contains('failed'));
    });

    test('register and refresh are never sent twice', () async {
      for (final path in <String>[
        '/api/v1/auth/register',
        '/api/v1/auth/refresh',
      ]) {
        adapter
          ..seen.clear()
          ..timeouts = 1;
        await expectLater(dio.post<Object>(path), throwsA(isA<DioException>()));
        expect(adapter.seen, hasLength(1), reason: path);
      }
    });

    test('a slow wake call reports slow, then answered', () async {
      adapter.delay = const Duration(milliseconds: 60);

      await dio.get<Object>('/api/v1/health');

      expect(events, <String>['slow', 'answered']);
    });

    test('a quick call or a non-wake call never reports slow', () async {
      await dio.get<Object>('/api/v1/health');
      adapter.delay = const Duration(milliseconds: 60);
      await dio.get<Object>('/api/v1/days/2026-11-03');

      expect(events, <String>['answered']);
    });
  });

  group('ServerWakeController', () {
    test('waking clears once the server answers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wake = container.read(serverWakeProvider.notifier);

      wake.slow();
      expect(container.read(serverWakeProvider), ServerWake.waking);
      wake.answered();
      expect(container.read(serverWakeProvider), ServerWake.awake);
      wake.slow();
      expect(container.read(serverWakeProvider), ServerWake.awake);
    });

    test('a failed wake drops the banner', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wake = container.read(serverWakeProvider.notifier);

      wake
        ..slow()
        ..failed();
      expect(container.read(serverWakeProvider), ServerWake.unknown);
    });
  });

  testWidgets('the banner shows the Arabic waking notice only while waking', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ServerWakeBanner(child: child!),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );

    expect(find.byKey(const Key('server-waking')), findsNothing);

    container.read(serverWakeProvider.notifier).slow();
    await tester.pump();
    expect(find.text('الخادم يستيقظ، قد يستغرق دقيقة'), findsOneWidget);

    container.read(serverWakeProvider.notifier).answered();
    await tester.pump();
    expect(find.byKey(const Key('server-waking')), findsNothing);
  });
}

/// Answers 200, or times out for the first [timeouts] requests.
class _Script implements HttpClientAdapter {
  final List<RequestOptions> seen = <RequestOptions>[];
  int timeouts = 0;
  Duration delay = Duration.zero;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (timeouts > 0) {
      timeouts -= 1;
      throw DioException.receiveTimeout(
        timeout: options.receiveTimeout ?? Duration.zero,
        requestOptions: options,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'status': 'ok'}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
