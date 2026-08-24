import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Reads the OS username and machine identity for local Portal accounts.
abstract final class LocalUserIdentity {
  static const _deviceIdKey = 'portal_local_device_id_v1';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _uuid = Uuid();

  /// Best-effort OS username (Windows USERNAME, Unix USER, etc.).
  static String get osUsername {
    if (kIsWeb) return 'web';
    final value =
        Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        Platform.environment['LOGNAME'];
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return 'user';
  }

  /// Machine hostname, or a stable per-install device id when unavailable.
  static Future<String> resolveHostname() async {
    if (kIsWeb) return 'browser';
    final fromEnv =
        Platform.environment['HOSTNAME'] ??
        Platform.environment['COMPUTERNAME'];
    final trimmed = fromEnv?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return _stableDeviceId();
  }

  static Future<String> _stableDeviceId() async {
    final existing = await _secure.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await _secure.write(key: _deviceIdKey, value: id);
    return id;
  }
}
