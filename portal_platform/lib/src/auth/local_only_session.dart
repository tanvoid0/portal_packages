import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

import '../services/api_client.dart';
import 'device_security/device_security_controller.dart';
import 'local_user_identity.dart';

enum LocalOnlySessionOutcome { started, unavailable, deviceLockDeclined }

/// Starts a device-local, no-server-auth session, after requiring the
/// device's own biometric/PIN lock to be on — that lock is the only
/// credential this session has. Never writes a session without it.
///
/// Native only: [DeviceSecurityService.authenticate] hard-codes `false` on
/// web and nothing wires up the web PIN-setup path to this flow, so
/// [PortalAuthConfig.allowLocalOnlyLogin] is hidden on web rather than routed
/// around here.
abstract final class LocalOnlySession {
  static Future<LocalOnlySessionOutcome> start({required bool encrypted}) async {
    if (kIsWeb || !Get.isRegistered<DeviceSecurityController>()) {
      return LocalOnlySessionOutcome.unavailable;
    }
    final security = Get.find<DeviceSecurityController>();
    if (!security.enabled.value) {
      await security.refreshSupport();
      // No screen lock on the device: say so, not "not available in this app".
      if (!security.isSupported.value) {
        return LocalOnlySessionOutcome.deviceLockDeclined;
      }
      await security.setEnabled(true); // prompts; snackbars its own failure
      if (!security.enabled.value) return LocalOnlySessionOutcome.deviceLockDeclined;
    }

    final id = await LocalUserIdentity.stableDeviceId();
    await Get.find<ApiClient>().startLocalOnlySession({
      'id': id,
      'encrypted': encrypted,
    });
    return LocalOnlySessionOutcome.started;
  }
}
