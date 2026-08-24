import 'package:cryptography/cryptography.dart';
import 'package:portal_crypto/portal_crypto.dart';

import '../services/device_secret_storage.dart';
import 'sync_operation.dart';

/// Encrypts the sync outbox JSON at rest using a device-local key.
abstract final class EncryptedSyncQueueCodec {
  static final DeviceSecretStorage _secrets = DeviceSecretStorage();

  /// Reads the device key, minting one only on first use. Writing on every
  /// call put a secure-storage write on the path of every encrypt and decrypt
  /// for no gain.
  static Future<SecretKey> _queueKey() async {
    final existing = await _secrets.getSyncQueueKey();
    if (existing != null) return SecretBoxCodec.importKey(existing);

    final fresh = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    await _secrets.setSyncQueueKey(fresh);
    return SecretBoxCodec.importKey(fresh);
  }

  static Future<String> encryptOperations(List<SyncOperation> ops) async {
    final key = await _queueKey();
    final plain = SyncOperation.listToJson(ops);
    final blob = await PortalVaultBlob.encryptString(dek: key, plaintext: plain);
    return blob.encode();
  }

  static Future<List<SyncOperation>> decryptOperations(String stored) async {
    if (stored.isEmpty) return [];
    if (!_looksEncrypted(stored)) {
      return SyncOperation.listFromJson(stored);
    }
    final key = await _queueKey();
    final blob = PortalVaultBlob.decode(stored);
    final plain = await PortalVaultBlob.decryptString(dek: key, blob: blob);
    return SyncOperation.listFromJson(plain);
  }

  static bool _looksEncrypted(String raw) {
    return raw.trimLeft().startsWith('{') && raw.contains('portal-vault');
  }

  /// Migrates unencrypted plaintext queue entries to encrypted form.
  static Future<String> migrateIfNeeded(String raw) async {
    if (raw.isEmpty || _looksEncrypted(raw)) return raw;
    final ops = SyncOperation.listFromJson(raw);
    return encryptOperations(ops);
  }
}
