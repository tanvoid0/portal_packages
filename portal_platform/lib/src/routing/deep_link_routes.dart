/// Deep link URI utilities and resolution result type.
///
/// Register app-specific path mapping via [DeepLinkRegistry] in `main()`.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment-driven deep link settings (read after [dotenv.load] in [main]).
abstract final class DeepLinkEnv {
  /// Defaults to `portalwarp` when `DEEP_LINK_SCHEME` is unset or empty.
  static String get scheme {
    final v = dotenv.env['DEEP_LINK_SCHEME']?.trim();
    if (v == null || v.isEmpty) return 'portalwarp';
    return v;
  }

  /// When set, `https` URIs with this host are accepted as deep links.
  static String? get httpsHost {
    final v = dotenv.env['DEEP_LINK_HTTPS_HOST']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}

/// Result of mapping a path string to an app route location.
class DeepLinkResolution {
  const DeepLinkResolution({
    required this.routePath,
    this.isPublic = false,
    this.extra,
  });

  /// Canonical app path (e.g. `/inbox`, `/habits/new`).
  final String routePath;

  /// When true, the link is reachable without auth (e.g. login).
  final bool isPublic;

  /// Optional route payload (GoRouter `extra` / controller route args).
  final Object? extra;
}

/// Normalizes [path] to a leading `/`, no trailing slash (except `/`).
String normalizeDeepLinkPath(String path) {
  var p = path.trim();
  if (p.isEmpty) return '/';
  if (!p.startsWith('/')) p = '/$p';
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// Extracts app path from a deep link [uri] (path only; fragment ignored).
String pathFromDeepLinkUri(Uri uri) => normalizeDeepLinkPath(uri.path);

bool deepLinkUriIsAllowed(Uri uri) {
  if (uri.scheme.toLowerCase() == DeepLinkEnv.scheme.toLowerCase()) {
    return true;
  }
  final host = DeepLinkEnv.httpsHost;
  if (host != null &&
      uri.scheme == 'https' &&
      uri.host.toLowerCase() == host.toLowerCase()) {
    return true;
  }
  return false;
}
