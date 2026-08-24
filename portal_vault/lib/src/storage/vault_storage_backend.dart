import 'dart:typed_data';

import 'vault_blob_meta.dart';

/// Encrypted blob storage destination (device, Portal cloud, Google Drive).
abstract class VaultStorageBackend {
  String get backendId;

  Future<bool> isAvailable();

  Future<void> putEncrypted(
    String path,
    Uint8List ciphertext, {
    VaultBlobMeta? meta,
  });

  Future<Uint8List?> getEncrypted(String path);

  Future<List<VaultBlobMeta>> list(String prefix);

  Future<void> delete(String path);
}
