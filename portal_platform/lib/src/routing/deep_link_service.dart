import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import 'deep_link_registry.dart';
import 'deep_link_routes.dart';
import 'portal_navigation.dart';

/// Subscribes to app / universal links and navigates via [PortalNavigation].
class DeepLinkService extends GetxService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  bool _initialConsumed = false;

  Uri? _pendingWhileLoggedOut;

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.onClose();
  }

  /// Call once after the first frame (e.g. from the root app widget).
  Future<void> attach() async {
    if (!_initialConsumed) {
      _initialConsumed = true;
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial);
      }
    }

    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(handleUri(uri)),
      onError: (Object e, StackTrace st) {
        developer.log(
          'Deep link stream error',
          name: 'DeepLinkService',
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  /// After login / register success: navigate to pending target or [fallback].
  Future<void> navigatePostAuth({required String fallback}) async {
    final pending = _takePending();
    if (pending != null) {
      final path = pathFromDeepLinkUri(pending);
      final resolution = DeepLinkRegistry.resolve(
        path,
        queryParameters: pending.queryParameters,
      );
      if (resolution != null && !resolution.isPublic) {
        _navigateTo(resolution);
        return;
      }
    }
    _goAll(fallback);
  }

  void _goAll(String path, {Object? extra}) {
    PortalNavigation.require.go(path, extra: extra);
  }

  Uri? _takePending() {
    final p = _pendingWhileLoggedOut;
    _pendingWhileLoggedOut = null;
    return p;
  }

  /// Clears any stored pending link (e.g. after logout).
  void clearPending() => _pendingWhileLoggedOut = null;

  Future<void> handleUri(Uri uri) async {
    if (!deepLinkUriIsAllowed(uri)) {
      developer.log(
        'Ignored deep link (scheme/host): $uri',
        name: 'DeepLinkService',
      );
      return;
    }

    final path = pathFromDeepLinkUri(uri);
    final resolution = DeepLinkRegistry.resolve(
      path,
      queryParameters: uri.queryParameters,
    );
    if (resolution == null) {
      developer.log('Unknown deep link path: $path', name: 'DeepLinkService');
      return;
    }

    final api = Get.find<ApiClient>();
    final loggedIn = await api.isLoggedIn();
    final config = Get.find<AppConfig>();

    if (resolution.isPublic) {
      if (loggedIn) {
        _goAll(config.routeLoggedIn);
      } else {
        _goAll(config.routeLoggedOut);
      }
      return;
    }

    if (!loggedIn) {
      _pendingWhileLoggedOut = uri;
      _goAll(config.routeLoggedOut);
      return;
    }

    final current = PortalNavigation.require.currentPath;
    if (resolution.routePath == current && resolution.extra == null) {
      return;
    }
    _navigateTo(resolution);
  }

  void _navigateTo(DeepLinkResolution resolution) {
    _goAll(resolution.routePath, extra: resolution.extra);
  }
}
