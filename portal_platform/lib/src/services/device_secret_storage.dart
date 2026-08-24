import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local secrets (sync queue key, migration flags).
class DeviceSecretStorage {
  DeviceSecretStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _syncQueueKey = 'portal_sync_queue_key_v1';

  Future<List<int>?> getSyncQueueKey() async {
    final raw = await _storage.read(key: _syncQueueKey);
    if (raw == null) return null;
    return base64Decode(raw);
  }

  Future<void> setSyncQueueKey(List<int> keyBytes) async {
    await _storage.write(
      key: _syncQueueKey,
      value: base64Encode(keyBytes),
    );
  }

  Future<void> clearSyncQueueKey() async {
    await _storage.delete(key: _syncQueueKey);
  }
}
