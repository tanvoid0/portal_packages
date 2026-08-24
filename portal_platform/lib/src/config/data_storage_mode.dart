/// Where task/habit/board entity payloads are persisted (build-time config).
enum DataStorageMode {
  /// In-memory session + encrypted vault blobs on Portal cloud.
  server,

  /// GetStorage on device; optional plaintext API sync when logged in.
  local,

  /// In-memory session + encrypted aggregate on Google Drive appDataFolder.
  googleDrive,
}

/// Parses [DATA_STORAGE] from dotenv. Defaults to [DataStorageMode.server].
DataStorageMode parseDataStorageMode(String? raw) {
  final v = raw?.trim().toLowerCase() ?? '';
  if (v.isEmpty) return DataStorageMode.server;
  switch (v) {
    case 'server':
      return DataStorageMode.server;
    case 'local':
      return DataStorageMode.local;
    case 'google_drive':
    case 'googledrive':
    case 'google-drive':
      return DataStorageMode.googleDrive;
    default:
      throw StateError(
        'Invalid DATA_STORAGE="$raw". Use server, local, or google_drive.',
      );
  }
}
