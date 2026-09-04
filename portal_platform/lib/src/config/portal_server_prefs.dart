import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists a dev/QA override of which Portal API server this app install
/// talks to, and the one-time gesture that reveals the setting.
///
/// Per-app-install, not per-account: `SharedPreferences` is already scoped to
/// this app's package, so switching Recipe to Local never touches Shopping.
abstract final class PortalServerPrefs {
  static const _serverUrlKey = 'portal_server_url';
  static const _devToolsKey = 'portal_dev_tools_unlocked';

  /// The overridden base URL, or null when running against the build default.
  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_serverUrlKey);
    return (url == null || url.isEmpty) ? null : url;
  }

  /// Pass null to clear the override and return to the build default.
  static Future<void> write(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_serverUrlKey);
    } else {
      await prefs.setString(_serverUrlKey, url);
    }
  }

  static Future<bool> devToolsUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_devToolsKey) ?? false;
  }

  static Future<void> unlockDevTools() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devToolsKey, true);
  }

  /// Only a private/loopback host may become the local server target — the
  /// rail that actually stops someone typing real credentials into an
  /// arbitrary server, regardless of who finds the unlock gesture.
  ///
  /// Accepts `host:port` or a full `http(s)://...` URL; returns the
  /// normalised `http://host:port/api` form, or null when [input] doesn't
  /// parse or its host isn't in a private range.
  static String? localUrlFrom(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final hasScheme = trimmed.contains('://');
    final withScheme = hasScheme ? trimmed : 'http://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) return null;
    if (!_isPrivateHost(uri.host)) return null;

    final path = uri.path.isEmpty || uri.path == '/' ? '/api' : uri.path;
    return uri.replace(path: path).toString();
  }

  static bool _isPrivateHost(String host) {
    final lower = host.toLowerCase();
    if (lower == 'localhost' || lower.endsWith('.local')) return true;

    final address = InternetAddress.tryParse(host);
    if (address == null) return false;
    if (address.isLoopback) return true;

    if (address.type == InternetAddressType.IPv4) {
      final b = address.rawAddress;
      if (b[0] == 10) return true; // 10.0.0.0/8
      if (b[0] == 172 && b[1] >= 16 && b[1] <= 31) return true; // 172.16.0.0/12
      if (b[0] == 192 && b[1] == 168) return true; // 192.168.0.0/16
      if (b[0] == 169 && b[1] == 254) return true; // 169.254.0.0/16 (link-local)
      return false;
    }
    return address.isLinkLocal;
  }
}
