import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hashed app PIN for web (no system biometrics).
abstract final class WebAppPinStore {
  static const _hashKey = 'portal_web_app_pin_hash';
  static const _storage = FlutterSecureStorage();

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final hash = await _hashPin(pin);
    await _storage.write(key: _hashKey, value: hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _hashKey);
    if (stored == null || stored.isEmpty) return false;
    final hash = await _hashPin(pin);
    return stored == hash;
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _hashKey);
  }

  static Future<String> _hashPin(String pin) async {
    final algo = Sha256();
    final digest = await algo.hash(utf8.encode('portal_web_pin_v1:$pin'));
    return base64Encode(digest.bytes);
  }
}
