import '../../storage/portal_key_value_store.dart';

/// Reads/writes the device-security toggle in the host app's key-value store.
class DeviceSecurityPreferences {
  DeviceSecurityPreferences(this._box, {this.key = defaultKey});

  static const defaultKey = 'settings_device_security_enabled';

  final PortalKeyValueStore _box;
  final String key;

  bool get enabled => _box.read<bool>(key) ?? false;

  Future<void> setEnabled(bool value) => _box.write(key, value);
}
