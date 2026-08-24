import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../session/session_controller.dart';

/// Redirects unauthenticated users away from protected routes.
class PortalAuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionController>() ||
        !Get.isRegistered<AppConfig>()) {
      return null;
    }
    final loggedIn = Get.find<SessionController>().user.value != null;
    if (loggedIn) return null;
    return RouteSettings(name: Get.find<AppConfig>().routeLoggedOut);
  }
}

/// Redirects authenticated users away from login-only routes.
class PortalGuestOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionController>() ||
        !Get.isRegistered<AppConfig>()) {
      return null;
    }
    final loggedIn = Get.find<SessionController>().user.value != null;
    if (!loggedIn) return null;
    return RouteSettings(name: Get.find<AppConfig>().routeLoggedIn);
  }
}
