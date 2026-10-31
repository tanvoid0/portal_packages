import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

import 'portal_log_severity.dart';

class PortalLogger {
  PortalLogger._();

  static PortalLogger? _instance;
  static PortalLogger get I {
    final instance = _instance;
    if (instance == null) {
      throw StateError('PortalLogger.init must be called before use.');
    }
    return instance;
  }

  static bool get isInitialized => _instance != null;

  static Future<PortalLogger> init({
    required String sourceName,
    bool? logToFile,
    PortalLogSeverity? logLevel,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final logger = PortalLogger._();
    await logger._initialize(
      sourceName: sourceName,
      logToFile: logToFile,
      logLevel: logLevel,
    );
    _instance = logger;
    return logger;
  }

  final _uuid = const Uuid();
  String _sourceName = 'portal-app';
  PortalLogSeverity _minLevel = kReleaseMode
      ? PortalLogSeverity.info
      : PortalLogSeverity.debug;
  bool _logToFile = !kReleaseMode;
  File? _logFile;
  String? _lastErrorTraceId;

  String? get logFilePath => _logFile?.path;
  String? get lastErrorTraceId => _lastErrorTraceId;

  /// In-memory log history for the on-device debug panel ([TalkerScreen]).
  /// Console output stays off: this logger already debugPrints in debug
  /// builds, so talker would double every line. HTTP shows here too — every
  /// [ApiClient] request logs through this logger, so its entries are routed
  /// into talker's http section (the panel's HTTP inspector) without a second
  /// integration in the client.
  final Talker talker = Talker(
    settings: TalkerSettings(useConsoleLogs: false),
  );

  String newTraceId() => _uuid.v4();

  Future<void> _initialize({
    required String sourceName,
    bool? logToFile,
    PortalLogSeverity? logLevel,
  }) async {
    _sourceName = sourceName;

    final envLogToFile = dotenv.isInitialized
        ? dotenv.env['LOG_TO_FILE']?.trim().toLowerCase()
        : null;
    if (envLogToFile == 'true' || envLogToFile == '1') {
      _logToFile = true;
    } else if (envLogToFile == 'false' || envLogToFile == '0') {
      _logToFile = false;
    } else if (logToFile != null) {
      _logToFile = logToFile;
    } else {
      _logToFile = !kReleaseMode;
    }

    final envLevel = dotenv.isInitialized
        ? PortalLogSeverity.parse(dotenv.env['LOG_LEVEL'])
        : null;
    _minLevel = logLevel ?? envLevel ?? _minLevel;

    // Web has no filesystem: getApplicationDocumentsDirectory() throws
    // MissingPluginException and takes the whole bootstrap down with it. Do
    // this after the env parsing above so LOG_TO_FILE=true cannot re-enable it.
    if (kIsWeb) _logToFile = false;

    if (_logToFile) {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      _logFile = File('${logsDir.path}/$sourceName-$timestamp.log');
      await _logFile!.create(recursive: true);
    }

    info('PortalLogger', 'Logger initialized', {
      'logFilePath': _logFile?.path,
      'logToFile': _logToFile,
      'logLevel': _minLevel.label,
    });
  }

  void debug(
    String component,
    String message, [
    Map<String, Object?>? context,
  ]) {
    log(
      severity: PortalLogSeverity.debug,
      component: component,
      message: message,
      context: context,
    );
  }

  void info(
    String component,
    String message, [
    Map<String, Object?>? context,
  ]) {
    log(
      severity: PortalLogSeverity.info,
      component: component,
      message: message,
      context: context,
    );
  }

  void warn(
    String component,
    String message, [
    Map<String, Object?>? context,
  ]) {
    log(
      severity: PortalLogSeverity.warn,
      component: component,
      message: message,
      context: context,
    );
  }

  void error(
    String component,
    String message, [
    Map<String, Object?>? context,
    String? traceId,
  ]) {
    final resolvedTraceId = traceId ?? newTraceId();
    _lastErrorTraceId = resolvedTraceId;
    log(
      severity: PortalLogSeverity.error,
      component: component,
      message: message,
      traceId: resolvedTraceId,
      context: context,
    );
  }

  void log({
    required PortalLogSeverity severity,
    required String component,
    required String message,
    String? traceId,
    Map<String, Object?>? context,
  }) {
    if (!shouldLog(severity, _minLevel)) return;

    final payload = <String, Object?>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'severity': severity.label,
      'source': _sourceName,
      'component': component,
      'message': message,
      if (traceId != null) 'traceId': traceId,
      if (context != null && context.isNotEmpty) 'context': context,
    };

    final jsonLine = jsonEncode(payload);

    if (kDebugMode) {
      debugPrint('[${severity.label}] $component: $message ${traceId ?? ''}'.trim());
    }

    _toTalker(severity, component, message, traceId, context);

    if (_logToFile && _logFile != null) {
      try {
        _logFile!.writeAsStringSync('$jsonLine\n', mode: FileMode.append);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[PortalLogger] Failed to write log file: $e\n$st');
        }
      }
    }
  }

  /// Mirror a log line into [talker] for the on-device debug panel.
  ///
  /// ApiClient is the fleet's one HTTP source and already logs through this
  /// logger, so rather than wire a second integration into the client its
  /// entries are keyed into talker's http section here — an error becomes an
  /// http-error, anything else an http-request — and show in the panel's HTTP
  /// inspector. Everything else logs by severity.
  void _toTalker(
    PortalLogSeverity severity,
    String component,
    String message,
    String? traceId,
    Map<String, Object?>? context,
  ) {
    final level = _talkerLevel(severity);
    final line = _talkerLine(component, message, traceId, context);
    if (component == 'ApiClient') {
      final key = severity == PortalLogSeverity.error
          ? TalkerKey.httpError
          : TalkerKey.httpRequest;
      talker.logCustom(TalkerLog(line, key: key, title: key, logLevel: level));
    } else {
      talker.log(line, logLevel: level);
    }
  }

  static LogLevel _talkerLevel(PortalLogSeverity severity) {
    switch (severity) {
      case PortalLogSeverity.debug:
        return LogLevel.debug;
      case PortalLogSeverity.info:
        return LogLevel.info;
      case PortalLogSeverity.warn:
        return LogLevel.warning;
      case PortalLogSeverity.error:
        return LogLevel.error;
    }
  }

  /// One compact line for the panel: component, message, then the request
  /// shape and trace id when the entry carries them (ApiClient does).
  static String _talkerLine(
    String component,
    String message,
    String? traceId,
    Map<String, Object?>? context,
  ) {
    final sb = StringBuffer('$component: $message');
    final method = context?['method'];
    final url = context?['url'];
    final status = context?['status'];
    if (method != null && url != null) sb.write(' $method $url');
    if (status != null) sb.write(' → $status');
    if (traceId != null) sb.write('  [$traceId]');
    return sb.toString();
  }
}
