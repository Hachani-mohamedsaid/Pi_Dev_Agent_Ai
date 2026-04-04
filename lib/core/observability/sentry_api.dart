import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

void reportHttpResponseError({
  required String feature,
  required http.Response response,
  String? note,
}) {
  unawaited(
    Sentry.captureMessage(
      'HTTP error on $feature: ${response.statusCode}',
      level: SentryLevel.error,
      withScope: (scope) {
        final sentRequestId = response.request?.headers['x-request-id'];
        final receivedRequestId = response.headers['x-request-id'];

        scope.setTag('feature', feature);
        scope.setTag('http.status_code', '${response.statusCode}');
        scope.setTag('http.method', response.request?.method ?? 'unknown');
        scope.setTag('http.request_id.sent', sentRequestId ?? '');
        scope.setTag('http.request_id.received', receivedRequestId ?? '');
        scope.setExtra('url', response.request?.url.toString());
        scope.setExtra('note', note);
        scope.setExtra('response.body', _safeBody(response.body));
      },
    ),
  );
}

void reportApiException({
  required String feature,
  required Object error,
  StackTrace? stackTrace,
  Map<String, dynamic>? context,
}) {
  unawaited(
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('feature', feature);
        if (context != null) {
          for (final entry in context.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    ),
  );
}

String _safeBody(String body) {
  const maxLength = 2000;
  if (body.length <= maxLength) return body;
  return '${body.substring(0, maxLength)}...[truncated]';
}
