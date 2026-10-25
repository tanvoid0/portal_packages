import 'package:get/get.dart';

import '../../storage/portal_key_value_store.dart';
import 'device_security_controller.dart';
import 'device_security_preferences.dart';
import 'portal_device_security_strings.dart';

/// Registers [DeviceSecurityController] for device-security features.
class DeviceSecurityBinding extends Bindings {
  DeviceSecurityBinding({
    required PortalKeyValueStore prefs,
    this.strings,
    String? preferenceKey,
  }) : _preferences = DeviceSecurityPreferences(
          prefs,
          key: preferenceKey ?? DeviceSecurityPreferences.defaultKey,
        );

  final DeviceSecurityPreferences _preferences;
  final PortalDeviceSecurityStrings? strings;

  @override
  void dependencies() {
    if (Get.isRegistered<DeviceSecurityController>()) return;
    Get.put(
      DeviceSecurityController(
        preferences: _preferences,
        strings: strings,
      ),
      permanent: true,
    );
  }
}
