import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
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
}
