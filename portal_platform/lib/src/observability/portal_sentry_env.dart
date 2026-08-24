/// Dotenv keys used by [PortalSentry]. Values are read from each app's `.env`.
abstract final class PortalSentryEnv {
  static const appName = 'SENTRY_APP_NAME';
  static const dsn = 'SENTRY_DSN';
  static const enabled = 'SENTRY_ENABLED';
  static const environment = 'SENTRY_ENVIRONMENT';
  static const release = 'SENTRY_RELEASE';
  static const tracesSampleRate = 'SENTRY_TRACES_SAMPLE_RATE';

  /// Opt-in for attaching email and display name to Sentry events. Off by
  /// default: the opaque user id is enough to correlate crashes, and these
  /// apps carry financial and health data.
  static const sendPii = 'SENTRY_SEND_PII';
}
