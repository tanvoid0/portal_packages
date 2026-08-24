enum PortalLogSeverity {
  debug,
  warn,
  info,
  error;

  String get label {
    switch (this) {
      case PortalLogSeverity.debug:
        return 'DEBUG';
      case PortalLogSeverity.info:
        return 'INFO';
      case PortalLogSeverity.warn:
        return 'WARN';
      case PortalLogSeverity.error:
        return 'ERROR';
    }
  }

  static PortalLogSeverity? parse(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'DEBUG':
        return PortalLogSeverity.debug;
      case 'INFO':
        return PortalLogSeverity.info;
      case 'WARN':
        return PortalLogSeverity.warn;
      case 'ERROR':
        return PortalLogSeverity.error;
      default:
        return null;
    }
  }
}

int _severityRank(PortalLogSeverity severity) {
  switch (severity) {
    case PortalLogSeverity.debug:
      return 0;
    case PortalLogSeverity.info:
      return 1;
    case PortalLogSeverity.warn:
      return 2;
    case PortalLogSeverity.error:
      return 3;
  }
}

bool shouldLog(PortalLogSeverity message, PortalLogSeverity minimum) {
  return _severityRank(message) >= _severityRank(minimum);
}
