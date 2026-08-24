import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for backup destinations and scheduling.
abstract final class BackupSettingsStore {
  static const _portalCloudKey = 'vault_backup_portal_cloud';
  static const _googleDriveKey = 'vault_backup_google_drive';
  static const _wifiOnlyKey = 'vault_backup_wifi_only';
  static const _googleLinkedKey = 'vault_google_linked';
  static const _lastDeviceKey = 'vault_backup_last_device';
  static const _lastPortalKey = 'vault_backup_last_portal';
  static const _lastGoogleKey = 'vault_backup_last_google';

  static Future<bool> portalCloudEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_portalCloudKey) ?? true;
  }

  static Future<void> setPortalCloudEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_portalCloudKey, value);
  }

  static Future<bool> googleDriveEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_googleDriveKey) ?? false;
  }

  static Future<void> setGoogleDriveEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_googleDriveKey, value);
  }

  static Future<bool> wifiOnly() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_wifiOnlyKey) ?? false;
  }

  static Future<void> setWifiOnly(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_wifiOnlyKey, value);
  }

  static Future<bool> isGoogleLinked() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_googleLinkedKey) ?? false;
  }

  static Future<void> setGoogleLinked(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_googleLinkedKey, value);
  }

  static Future<void> markBackedUp(String backendId) async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().toIso8601String();
    switch (backendId) {
      case 'device':
        await p.setString(_lastDeviceKey, now);
      case 'portal_cloud':
        await p.setString(_lastPortalKey, now);
      case 'google_drive':
        await p.setString(_lastGoogleKey, now);
    }
  }

  static Future<DateTime?> lastBackupAt(String backendId) async {
    final p = await SharedPreferences.getInstance();
    final raw = switch (backendId) {
      'device' => p.getString(_lastDeviceKey),
      'portal_cloud' => p.getString(_lastPortalKey),
      'google_drive' => p.getString(_lastGoogleKey),
      _ => null,
    };
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
