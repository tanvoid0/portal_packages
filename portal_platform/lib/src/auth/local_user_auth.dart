import 'package:get/get.dart';

import '../observability/portal_logger.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';
import 'local_user_identity.dart';

/// Ensures a device-local Portal user exists via POST /auth/local.
abstract final class LocalUserAuth {
  /// Registers or signs in using [LocalUserIdentity] when no session exists.
  /// Returns true when a valid session is available afterward.
  static Future<bool> ensureRegistered() async {
    final api = Get.find<ApiClient>();
    if (await api.isLoggedIn()) return true;

    try {
      final hostname = await LocalUserIdentity.resolveHostname();
      await api.registerOrLoginLocal(
        username: LocalUserIdentity.osUsername,
        hostname: hostname,
      );
      if (Get.isRegistered<SessionController>()) {
        await Get.find<SessionController>().reloadFromStorage();
      }
      return true;
    } catch (e, st) {
      if (PortalLogger.isInitialized) {
        PortalLogger.I.error(
          'LocalUserAuth',
          'Local user registration failed: $e',
          {'stack': st.toString()},
        );
      }
      return false;
    }
  }
}
