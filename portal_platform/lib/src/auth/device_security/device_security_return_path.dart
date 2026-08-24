/// Query-parameter helpers for device-security unlock → return navigation.
abstract final class DeviceSecurityReturnPath {
  DeviceSecurityReturnPath._();

  /// GET query key, e.g. `/security?return=%2Fnotepad`.
  static const queryKey = 'return';

  static String? fromQuery(Map<String, String> query) {
    final raw = query[queryKey];
    if (raw == null || raw.isEmpty) return null;
    final decoded = Uri.decodeComponent(raw);
    return isSafe(decoded) ? decoded : null;
  }

  /// Builds `/security?return=%2Fnotepad` (caller supplies [securityRoute]).
  static String buildUnlockRoute({
    required String securityRoute,
    required String returnPath,
  }) {
    final safeReturn = isSafe(returnPath) ? returnPath : '/';
    return '$securityRoute?$queryKey=${Uri.encodeComponent(safeReturn)}';
  }

  /// Accepts in-app absolute paths only (blocks open redirects).
  static bool isSafe(String path) {
    if (path.isEmpty || !path.startsWith('/')) return false;
    if (path.startsWith('//')) return false;
    if (path.contains('\n') || path.contains('\r')) return false;
    return true;
  }
}
