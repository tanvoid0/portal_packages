import 'package:get/get.dart';

import 'portal_navigation.dart';

/// [PortalNavigation] over GetX named routes, for apps on `GetMaterialApp`.
///
/// Registering an adapter is not optional: deep links, session expiry and the
/// post-login redirect all go through [PortalNavigation.require], which throws
/// when none was registered. An app that skips it signs the user in and then
/// fails on the navigation afterwards, which reads to the user as a failed
/// login even though the session was stored.
///
/// Apps with their own routing (nav2, nested navigators) keep their own
/// adapter instead.
class PortalGetNavigation implements PortalNavigation {
  const PortalGetNavigation();

  /// Registers this adapter. Call once, before `runApp`.
  static void register() =>
      PortalNavigation.register(const PortalGetNavigation());

  @override
  String? get currentPath {
    final route = Get.currentRoute;
    return route.isEmpty ? null : route;
  }

  @override
  void go(String path, {Object? extra}) =>
      Get.offAllNamed(path, arguments: extra);

  @override
  Future<void> push(String path, {Object? extra}) async {
    await Get.toNamed(path, arguments: extra);
  }

  @override
  void replace(String path, {Object? extra}) =>
      Get.offNamed(path, arguments: extra);

  @override
  void pop({Object? result}) => Get.back(result: result);
}
