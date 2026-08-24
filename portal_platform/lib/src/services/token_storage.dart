import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JWT and user profile storage (Android Keystore / iOS Keychain).
class TokenStorage {
  static const String _accessTokenKey = 'portal_access_token';
  static const String _refreshTokenKey = 'portal_refresh_token';
  static const String _userKey = 'portal_user';

  // encryptedSharedPreferences is deprecated in flutter_secure_storage 10 and
  // removed in 11; v10 already encrypts by default.
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  bool _migrated = false;

  Future<void> init() async {
    if (_migrated) return;
    await _migrateFromSharedPreferences();
    _migrated = true;
  }

  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessTokenKey);
    final refresh = prefs.getString(_refreshTokenKey);
    final userJson = prefs.getString(_userKey);

    if (access == null && refresh == null && userJson == null) return;

    // Migrate whatever is there, then clear it unconditionally. Requiring both
    // tokens left a lone access token sitting in plaintext SharedPreferences
    // forever, which is exactly what this migration exists to stop.
    if (access != null || refresh != null) {
      if (access != null && refresh != null) {
        await saveTokens(accessToken: access, refreshToken: refresh);
      }
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    }
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      await saveUser(user);
      await prefs.remove(_userKey);
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await init();
    await _secure.write(key: _accessTokenKey, value: accessToken);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    await init();
    return _secure.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    await init();
    return _secure.read(key: _refreshTokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await init();
    await _secure.write(key: _userKey, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    await init();
    final userJson = await _secure.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearTokens() async {
    await init();
    await _secure.delete(key: _accessTokenKey);
    await _secure.delete(key: _refreshTokenKey);
    await _secure.delete(key: _userKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
