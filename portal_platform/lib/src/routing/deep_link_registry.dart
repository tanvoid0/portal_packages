import 'deep_link_routes.dart';

/// Resolves a normalized app path to a GetX route, or `null` if unknown.
typedef DeepLinkPathResolver = DeepLinkResolution? Function(
  String normalizedPath, {
  Map<String, String> queryParameters,
});

/// App-provided deep link resolution. Register in `main()` before handling links.
abstract final class DeepLinkRegistry {
  static DeepLinkPathResolver? _resolver;

  static void register(DeepLinkPathResolver resolver) {
    _resolver = resolver;
  }

  static void clear() {
    _resolver = null;
  }

  static DeepLinkResolution? resolve(
    String normalizedPath, {
    Map<String, String> queryParameters = const {},
  }) {
    final resolver = _resolver;
    if (resolver == null) return null;
    return resolver(
      normalizeDeepLinkPath(normalizedPath),
      queryParameters: queryParameters,
    );
  }
}
