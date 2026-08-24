import 'dart:async';

import 'package:flutter/foundation.dart';

import 'portal_logger.dart';
import 'portal_sentry.dart';

abstract final class PortalErrorHandlers {
  static void install() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final traceId = PortalLogger.I.newTraceId();
      PortalLogger.I.error(
        'FlutterError',
        details.exceptionAsString(),
        {
          'library': details.library,
          'context': details.context?.toDescription(),
        },
        traceId,
      );
      PortalSentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
      previousFlutterHandler?.call(details);
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      final traceId = PortalLogger.I.newTraceId();
      PortalLogger.I.error(
        'PlatformDispatcher',
        error.toString(),
        {'stack': stack.toString()},
        traceId,
      );
      PortalSentry.captureException(error, stackTrace: stack);
      return previousPlatformHandler?.call(error, stack) ?? true;
    };
  }

  static Future<void> runGuarded(Future<void> Function() body) async {
    await runZonedGuarded(
      body,
      (error, stack) {
        final traceId = PortalLogger.isInitialized
            ? PortalLogger.I.newTraceId()
            : null;
        if (PortalLogger.isInitialized) {
          PortalLogger.I.error(
            'UncaughtAsyncError',
            error.toString(),
            {'stack': stack.toString()},
            traceId,
          );
        } else if (kDebugMode) {
          debugPrint('[UncaughtAsyncError] $error\n$stack');
        }
        PortalSentry.captureException(error, stackTrace: stack);
      },
    );
  }
}
