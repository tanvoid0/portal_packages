import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
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
    await _awaitNavigator();
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

  /// Blocks until there is a router to navigate with.
  ///
  /// Bootstrap schedules [attach] in a post-frame callback, but the startup
  /// gate draws its own frames from a plain MaterialApp while it works -- so
  /// that callback fires several frames before GetMaterialApp exists. Get's
  /// contextless navigation throws in that window, and [attach] is started
  /// unawaited, so the throw is swallowed: a cold deep link silently opened
  /// the app on its normal route instead. Bounded at 120 frames (~2s at 60Hz)
  /// so an app that never builds a router cannot hang here.
  Future<void> _awaitNavigator() async {
    for (var i = 0; i < 120 && Get.key.currentContext == null; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
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

    final current = PortalNavigation.require.currentPath;

    if (resolution.isPublic) {
      // A public link (login) means "go where this session belongs". Skip it
      // when that is already the route on screen: re-navigating tears the page
      // down and rebuilds it without its binding.
      _goAllUnlessThere(
        loggedIn ? config.routeLoggedIn : config.routeLoggedOut,
        current,
      );
      return;
    }

    if (!loggedIn) {
      _pendingWhileLoggedOut = uri;
      _goAllUnlessThere(config.routeLoggedOut, current);
      return;
    }

    if (resolution.routePath == current && resolution.extra == null) {
      return;
    }
    _navigateTo(resolution);
  }

  void _goAllUnlessThere(String path, String? current) {
    if (path == current) return;
    _goAll(path);
  }

  void _navigateTo(DeepLinkResolution resolution) {
    _goAll(resolution.routePath, extra: resolution.extra);
  }
}
