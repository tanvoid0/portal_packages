import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:portal_crypto/portal_crypto.dart';

import 'vault_blob_meta.dart';
import 'vault_storage_backend.dart';

const _vaultFolder = 'portal_task_vault';
const _wrapFileName = 'wrap_google.json';

/// Google Drive `appDataFolder` encrypted blob storage.
class GoogleDriveVaultBackend implements VaultStorageBackend {
  GoogleDriveVaultBackend({
    GoogleSignIn? signIn,
    List<String>? scopes,
    String? serverClientId,
  })  : _providedSignIn = signIn,
        _scopes = scopes ??
            const [
              drive.DriveApi.driveAppdataScope,
            ],
        _webClientId = serverClientId?.trim() ?? '';

  final GoogleSignIn? _providedSignIn;
  final List<String> _scopes;
  final String _webClientId;
  GoogleSignIn? _signIn;

  /// Deferred so web auth ([PortalAuthController]) initializes GIS first.
  GoogleSignIn get _googleSignIn => _providedSignIn ??
      (_signIn ??= createPortalGoogleSignIn(
        webClientId: _webClientId,
        scopes: _scopes,
      ));
  drive.DriveApi? _drive;
  String? _googleSub;

  @override
  String get backendId => 'google_drive';

  String? get googleSub => _googleSub;

  Future<void> init() async {}

  Future<drive.DriveApi?> _api() async {
    if (_drive != null) return _drive;
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    _googleSub = account.id;
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    _drive = drive.DriveApi(client);
    return _drive;
  }

  /// Restores or prompts for Google sign-in (shared GIS session on web).
  Future<bool> ensureSignedIn({bool interactive = true}) async {
    var account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null && interactive) {
      account = await _googleSignIn.signIn();
    }
    _googleSub = account?.id;
    _drive = null;
    return account != null;
  }

  Future<bool> signIn() => ensureSignedIn();

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _drive = null;
    _googleSub = null;
  }

  Future<WrappedKeyBundle?> fetchWrapBundle() async {
    final bytes = await getEncrypted(_wrapFileName);
    if (bytes == null) return null;
    return WrappedKeyBundle.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  Future<void> storeWrapBundle(WrappedKeyBundle bundle) async {
    await putEncrypted(
      _wrapFileName,
      Uint8List.fromList(utf8.encode(jsonEncode(bundle.toJson()))),
    );
  }

  String _drivePath(String path) => '$_vaultFolder/$path';

  /// Escapes a literal for Drive API `q` string comparisons.
  static String _escapeDriveQueryLiteral(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  @override
  Future<bool> isAvailable() async {
    final api = await _api();
    return api != null;
  }

  @override
  Future<void> putEncrypted(
    String path,
    Uint8List ciphertext, {
    VaultBlobMeta? meta,
  }) async {
    final api = await _api();
    if (api == null) throw StateError('Google Drive not connected');

    final name = _drivePath(path);
    final existing = await _findFileId(api, name);
    final media = drive.Media(
      Stream.value(ciphertext),
      ciphertext.length,
      contentType: 'application/octet-stream',
    );

    if (existing != null) {
      await api.files.update(
        drive.File()..name = name,
        existing,
        uploadMedia: media,
      );
    } else {
      await api.files.create(
        drive.File()
          ..name = name
          ..parents = ['appDataFolder'],
        uploadMedia: media,
      );
    }
  }

  @override
  Future<Uint8List?> getEncrypted(String path) async {
    final api = await _api();
    if (api == null) return null;
    final id = await _findFileId(api, _drivePath(path));
    if (id == null) return null;
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return media.stream.toBytes();
  }

  @override
  Future<List<VaultBlobMeta>> list(String prefix) async {
    final api = await _api();
    if (api == null) return [];
    final needle = _escapeDriveQueryLiteral('$_vaultFolder/$prefix');
    final q = "name contains '$needle'";
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: q,
      $fields: 'files(id,name,modifiedTime,size)',
    );
    return (result.files ?? [])
        .map(
          (f) => VaultBlobMeta(
            path: f.name ?? '',
            version: 1,
            updatedAt: f.modifiedTime ?? DateTime.now(),
            sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<void> delete(String path) async {
    final api = await _api();
    if (api == null) return;
    final id = await _findFileId(api, _drivePath(path));
    if (id != null) await api.files.delete(id);
  }

  Future<String?> _findFileId(drive.DriveApi api, String name) async {
    final escaped = _escapeDriveQueryLiteral(name);
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$escaped'",
      $fields: 'files(id)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }
}

extension on Stream<List<int>> {
  Future<Uint8List> toBytes() async {
    final builder = BytesBuilder();
    await for (final chunk in this) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
