import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'vault_blob_meta.dart';
import 'vault_storage_backend.dart';

/// Stores encrypted blobs under the app documents directory.
class DeviceVaultBackend implements VaultStorageBackend {
  @override
  String get backendId => 'device';

  Directory? _root;

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final base = await getApplicationDocumentsDirectory();
    _root = Directory('${base.path}/portal_vault');
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
    return _root!;
  }

  File _file(String path) {
    final safe = path.replaceAll('..', '').replaceAll(RegExp(r'[\\/]+'), '_');
    return File('${_root!.path}/$safe.enc');
  }

  @override
  Future<bool> isAvailable() async {
    await _dir();
    return true;
  }

  @override
  Future<void> putEncrypted(
    String path,
    Uint8List ciphertext, {
    VaultBlobMeta? meta,
  }) async {
    await _dir();
    final file = _file(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(ciphertext);
    if (meta != null) {
      await File('${file.path}.meta')
          .writeAsString(meta.toJson().toString());
    }
  }

  @override
  Future<Uint8List?> getEncrypted(String path) async {
    await _dir();
    final file = _file(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<List<VaultBlobMeta>> list(String prefix) async {
    await _dir();
    final dir = _root!;
    if (!await dir.exists()) return [];
    final results = <VaultBlobMeta>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.enc')) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.startsWith(prefix.replaceAll('/', '_'))) continue;
      final stat = await entity.stat();
      results.add(
        VaultBlobMeta(
          path: name,
          version: 1,
          updatedAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    return results;
  }

  @override
  Future<void> delete(String path) async {
    await _dir();
    final file = _file(path);
    if (await file.exists()) await file.delete();
  }
}
