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

/// Extracts app path from a deep link [uri] (fragment ignored).
///
/// `portal-gym://gym` parses with an empty path and `gym` as the *host*, which
/// is how people actually write these links, so a custom-scheme link with no
/// path falls back to its host. Web links keep using the path alone -- there
/// the host is the domain, not a route.
String pathFromDeepLinkUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (uri.path.isEmpty && scheme != 'http' && scheme != 'https') {
    return normalizeDeepLinkPath(uri.host);
  }
  return normalizeDeepLinkPath(uri.path);
}

bool deepLinkUriIsAllowed(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == DeepLinkEnv.scheme.toLowerCase()) {
    return true;
  }
  // Every Portal app registers `portal-<app>` in its manifest, and Android
  // only delivers URIs matching this app's own intent-filter -- so accepting
  // the family here costs nothing and saves every app from silently dropping
  // its own links when DEEP_LINK_SCHEME is unset (the default is the legacy
  // `portalwarp`).
  if (scheme.startsWith('portal-')) {
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
