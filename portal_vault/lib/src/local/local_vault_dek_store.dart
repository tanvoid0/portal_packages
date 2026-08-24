import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local cache of the vault DEK for the signed-in user.
///
/// Values are stored in platform secure storage (not the DEK itself in prefs).
/// Used with app-level device security so users are not prompted twice.
class LocalVaultDekStore {
  LocalVaultDekStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static String _keyFor(String userId) => 'portal_vault_local_dek_v1_$userId';

  Future<void> save({
    required String userId,
    required List<int> dekBytes,
  }) async {
    await _storage.write(
      key: _keyFor(userId),
      value: jsonEncode({
        'v': 1,
        'dek': base64Encode(dekBytes),
      }),
    );
  }

  Future<List<int>?> load({required String userId}) async {
    final raw = await _storage.read(key: _keyFor(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final encoded = map['dek'] as String?;
      if (encoded == null) return null;
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear({required String userId}) async {
    await _storage.delete(key: _keyFor(userId));
  }
}
