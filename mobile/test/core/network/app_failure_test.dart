import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart' hide Timeout;
import 'package:nutriguide/core/l10n/app_localizations.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/core/network/failure_message.dart';

void main() {
  group('mapDioException', () {
    test('connection, send, receive, and transform timeouts', () {
      expect(
        mapDioException(_exception(DioExceptionType.connectionTimeout)),
        isA<Timeout>(),
      );
      expect(
        mapDioException(_exception(DioExceptionType.sendTimeout)),
        isA<Timeout>(),
      );
      expect(
        mapDioException(_exception(DioExceptionType.receiveTimeout)),
        isA<Timeout>(),
      );
      expect(
        mapDioException(_exception(DioExceptionType.transformTimeout)),
        isA<Timeout>(),
      );
    });

    test('connection errors and certificate failures are offline', () {
      expect(
        mapDioException(_exception(DioExceptionType.connectionError)),
        isA<NetworkUnavailable>(),
      );
      expect(
        mapDioException(_exception(DioExceptionType.badCertificate)),
        isA<NetworkUnavailable>(),
      );
      expect(
        mapDioException(
          _exception(
            DioExceptionType.unknown,
            error: const SocketException('failed'),
          ),
        ),
        isA<NetworkUnavailable>(),
      );
    });

    test('problem+json becomes ApiProblem and reads Retry-After', () {
      final failure = mapDioException(
        _exception(
          DioExceptionType.badResponse,
          response: _response(
            statusCode: 429,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>['application/problem+json'],
              'retry-after': <String>['12'],
            },
            data: <String, Object?>{
              'type': 'about:blank',
              'title': 'Too many requests',
              'status': 429,
              'code': 'RATE_LIMITED',
              'detail': 'slow down',
              'request_id': 'req-7',
            },
          ),
        ),
      );

      expect(failure, isA<ApiProblem>());
      final problem = failure as ApiProblem;
      expect(problem.status, 429);
      expect(problem.code, 'RATE_LIMITED');
      expect(problem.title, 'Too many requests');
      expect(problem.detail, 'slow down');
      expect(problem.requestId, 'req-7');
      expect(problem.retryAfter, 12);
    });

    test('a JSON body with code is ApiProblem without problem+json', () {
      final failure = mapResponse(
        _response(
          statusCode: 401,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
          data: '{"code":"TOKEN_REUSED","title":"Reused","status":401}',
        ),
      );

      expect(
        failure,
        isA<ApiProblem>()
            .having((problem) => problem.code, 'code', 'TOKEN_REUSED')
            .having((problem) => problem.status, 'status', 401)
            .having((problem) => problem.retryAfter, 'retryAfter', isNull),
      );
    });

    test('an unknown code is still ApiProblem', () {
      final failure = mapResponse(
        _response(
          statusCode: 409,
          data: <String, Object?>{'code': 'FUTURE_CODE', 'status': 409},
        ),
      );
      expect((failure as ApiProblem).code, 'FUTURE_CODE');
    });

    test('a 502 HTML body is an unexpected response', () {
      final failure = mapResponse(
        _response(
          statusCode: 502,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/html'],
          },
          data: '<html><body>502 Bad Gateway</body></html>',
        ),
      );
      expect(failure, isA<UnexpectedResponse>());
      expect((failure as UnexpectedResponse).status, 502);
    });

    test('an empty body is an unexpected response', () {
      expect(
        mapResponse(_response(statusCode: 500)),
        isA<UnexpectedResponse>().having(
          (failure) => failure.status,
          'status',
          500,
        ),
      );
      expect(mapResponse(null), isA<UnexpectedResponse>());
    });

    test('a cancelled request is an unexpected response', () {
      expect(
        mapDioException(_exception(DioExceptionType.cancel)),
        isA<UnexpectedResponse>(),
      );
    });
  });

  group('failureMessage', () {
    for (final locale in const <Locale>[Locale('ar'), Locale('en')]) {
      testWidgets('${locale.languageCode} covers every branch', (tester) async {
        final l10n = await _load(tester, locale);
        expect(
          failureMessage(l10n, _problem('RATE_LIMITED')),
          l10n.failureRateLimited,
        );
        expect(
          failureMessage(l10n, _problem('PLANNER_BUSY')),
          l10n.failurePlannerBusy,
        );
        expect(
          failureMessage(l10n, _problem('PLANNER_TIMEOUT')),
          l10n.failurePlannerTimeout,
        );
        expect(
          failureMessage(l10n, _problem('UNAUTHORIZED')),
          l10n.failureUnauthorized,
        );
        expect(
          failureMessage(l10n, _problem('TOKEN_REUSED')),
          l10n.failureTokenReused,
        );
        expect(
          failureMessage(l10n, _problem('VALIDATION_ERROR')),
          l10n.failureValidation,
        );
        expect(
          failureMessage(l10n, _problem('SERVICE_UNAVAILABLE')),
          l10n.failureServiceUnavailable,
        );
        expect(
          failureMessage(l10n, _problem('INTERNAL_ERROR')),
          l10n.failureInternal,
        );
        expect(
          failureMessage(l10n, _problem('FUTURE_CODE')),
          l10n.failureGeneric,
        );
        expect(
          failureMessage(l10n, const NetworkUnavailable()),
          l10n.failureNetwork,
        );
        expect(failureMessage(l10n, const Timeout()), l10n.failureTimeout);
        expect(
          failureMessage(l10n, const UnexpectedResponse(502)),
          l10n.failureUnexpectedResponse,
        );
        expect(l10n.failureGeneric, isNot(l10n.failureUnexpectedResponse));
      });
    }
  });
}

ApiProblem _problem(String code) {
  return ApiProblem(
    status: 400,
    code: code,
    title: null,
    detail: null,
    requestId: null,
    retryAfter: null,
  );
}

DioException _exception(
  DioExceptionType type, {
  Response<dynamic>? response,
  Object? error,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/health'),
    type: type,
    response: response,
    error: error,
  );
}

Response<dynamic> _response({
  required int statusCode,
  Object? data,
  Map<String, List<String>> headers = const <String, List<String>>{},
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/v1/health'),
    statusCode: statusCode,
    data: data,
    headers: Headers.fromMap(headers),
  );
}

Future<AppLocalizations> _load(WidgetTester tester, Locale locale) async {
  late AppLocalizations localizations;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          localizations = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return localizations;
}
