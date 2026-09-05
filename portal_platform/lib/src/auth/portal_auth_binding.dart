import 'package:get/get.dart';

import 'portal_auth_controller.dart';

/// Shared binding that lazily registers [PortalAuthController].
/// Use as-is in your app's route definitions.
class PortalAuthBinding extends Bindings {
  PortalAuthBinding({this.credentials});

  /// Passed straight to [PortalAuthController]. See [PortalAuthCredentials].
  final PortalAuthCredentials? credentials;

  @override
  void dependencies() {
    Get.lazyPut<PortalAuthController>(
      () => PortalAuthController(credentials: credentials),
    );
  }
}
