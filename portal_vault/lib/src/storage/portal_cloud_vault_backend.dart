import 'dart:convert';
import 'dart:typed_data';

import '../remote/vault_api_client.dart';
import 'vault_blob_meta.dart';
import 'vault_storage_backend.dart';

class PortalCloudVaultBackend implements VaultStorageBackend {
  PortalCloudVaultBackend(this._api);

  final VaultApiClient _api;

  @override
  String get backendId => 'portal_cloud';

  String _blobId(String path) =>
      path.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> putEncrypted(
    String path,
    Uint8List ciphertext, {
    VaultBlobMeta? meta,
  }) async {
    await _api.putBlob(
      blobId: _blobId(path),
      encodedBlob: utf8.decode(ciphertext),
      version: meta?.version ?? 1,
    );
  }

  @override
  Future<Uint8List?> getEncrypted(String path) async {
    final raw = await _api.getBlob(_blobId(path));
    if (raw == null) return null;
    return Uint8List.fromList(utf8.encode(raw));
  }

  @override
  Future<List<VaultBlobMeta>> list(String prefix) async {
    final meta = await _api.fetchMeta();
    final blobs = meta['blobs'];
    if (blobs is! List) return [];
    return blobs
        .whereType<Map>()
        .map((e) => VaultBlobMeta.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.path.startsWith(prefix))
        .toList();
  }

  @override
  Future<void> delete(String path) async {
    // Server may add DELETE later; no-op for MVP.
  }
}
