import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'portal_sentry_env.dart';

export 'portal_sentry_env.dart';

/// Optional Sentry integration for Portal Flutter apps.
///
/// Reads [PortalSentryEnv] keys from dotenv after [dotenv.load]. Skips init in
/// non-release builds and when the DSN is empty; every method is then a no-op.
abstract final class PortalSentry {
  static bool _initialized = false;

  static bool get isEnabled => _initialized;

  /// Loads dotenv (when [loadEnv] is true) and initializes Sentry when configured.
  static Future<void> initFromEnv({
    String envFileName = '.env',
    bool loadEnv = true,
  }) async {
    if (_initialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    if (loadEnv && !dotenv.isInitialized) {
      await dotenv.load(fileName: envFileName);
    }

    if (!kReleaseMode) {
      return;
    }

    final dsn = _env(PortalSentryEnv.dsn);
    if (dsn == null || dsn.isEmpty) {
      return;
    }

    if (_env(PortalSentryEnv.enabled)?.toLowerCase() == 'false') {
      return;
    }

    final appName = _env(PortalSentryEnv.appName);
    final environment = _env(PortalSentryEnv.environment);
    final release = _resolveRelease(appName);
    final tracesSampleRate = _parseSampleRate(
      _env(PortalSentryEnv.tracesSampleRate),
    );

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment =
            environment ?? (kReleaseMode ? 'production' : 'development');
        options.release = release;
        options.tracesSampleRate = tracesSampleRate;
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
        options.enableAutoSessionTracking = true;
        options.considerInAppFramesByDefault = true;
      },
    );

    if (appName != null && appName.isNotEmpty) {
      await Sentry.configureScope((scope) {
        scope.setTag(PortalSentryEnv.appName, appName);
      });
    }

    _initialized = true;
  }

  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
  }) async {
    if (!_initialized) return;
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }

  static void syncUser(Map<String, dynamic>? user) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      if (user == null) {
        scope.setUser(null);
        return;
      }

      scope.setUser(
        SentryUser(
          id: _userId(user),
          email: user['email'] as String?,
          username: (user['name'] as String?)?.trim(),
        ),
      );
    });
  }

  static String? _env(String key) => dotenv.env[key]?.trim();

  static String? _userId(Map<String, dynamic> user) {
    final id = user['id'] ?? user['_id'];
    if (id == null) return null;
    return id.toString();
  }

  static String? _resolveRelease(String? appName) {
    final configured = _env(PortalSentryEnv.release);
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    if (appName == null || appName.isEmpty) {
      return null;
    }
    return appName;
  }

  static double _parseSampleRate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return kReleaseMode ? 0.1 : 0;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN) {
      return kReleaseMode ? 0.1 : 0;
    }
    return parsed.clamp(0, 1);
  }
}
