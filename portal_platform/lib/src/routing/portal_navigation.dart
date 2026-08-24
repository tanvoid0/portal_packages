/// App-wide navigation facade (GoRouter, GetX, etc.).
///
/// Register via [PortalNavigation.register] during app bootstrap so shared
/// platform services (deep links, session expiry) can navigate without GetX.
abstract interface class PortalNavigation {
  static PortalNavigation? _instance;

  static PortalNavigation? get maybe => _instance;

  static PortalNavigation get require {
    final nav = _instance;
    if (nav == null) {
      throw StateError('PortalNavigation.register() was not called');
    }
    return nav;
  }

  static void register(PortalNavigation navigation) {
    _instance = navigation;
  }

  static void unregister() {
    _instance = null;
  }

  /// Current location path (e.g. `/inbox`, `/settings/cloud`).
  String? get currentPath;

  /// Replaces the entire navigation stack with [path].
  void go(String path, {Object? extra});

  /// Pushes [path] onto the current stack.
  Future<void> push(String path, {Object? extra});

  /// Replaces the top route with [path].
  void replace(String path, {Object? extra});

  /// Pops the current route when possible.
  void pop({Object? result});
}
