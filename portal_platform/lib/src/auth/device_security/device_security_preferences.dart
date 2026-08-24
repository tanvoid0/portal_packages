import 'package:get_storage/get_storage.dart';

/// Reads/writes the device-security toggle in the host app's GetStorage box.
class DeviceSecurityPreferences {
  DeviceSecurityPreferences(this._box, {this.key = defaultKey});

  static const defaultKey = 'settings_device_security_enabled';

  final GetStorage _box;
  final String key;

  bool get enabled => _box.read<bool>(key) ?? false;

  Future<void> setEnabled(bool value) => _box.write(key, value);
}
