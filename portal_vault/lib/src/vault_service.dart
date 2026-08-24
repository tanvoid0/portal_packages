import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:portal_crypto/portal_crypto.dart';

import 'backup/backup_settings.dart';
import 'local/local_vault_dek_store.dart';
import 'remote/vault_api_client.dart';
import 'storage/google_drive_vault_backend.dart';
import 'storage/vault_storage_backend.dart';

/// Holds the vault DEK in memory while the user session is unlocked.
class VaultService extends GetxService {
  VaultService({
    required VaultApiClient api,
    required GoogleDriveVaultBackend googleDrive,
  })  : _api = api,
        _googleDrive = googleDrive;

  final VaultApiClient _api;
  final GoogleDriveVaultBackend _googleDrive;

  SecretKey? _dek;
  final isUnlocked = false.obs;
  String? _userId;

  SecretKey? get dek => _dek;

  bool get hasDek => _dek != null;

  Future<VaultService> init() async {
    await _googleDrive.init();
    return this;
  }

  void lock() {
    _dek = null;
    _userId = null;
    isUnlocked.value = false;
  }

  /// Loads an already-unwrapped DEK (e.g. from device secure storage).
  void unlockWithDek({
    required String userId,
    required SecretKey dek,
  }) {
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
  }

  /// Caches the DEK on this device for silent unlock after app restart.
  Future<void> persistLocalDek(LocalVaultDekStore store) async {
    final key = _dek;
    final userId = _userId;
    if (key == null || userId == null) return;
    final bytes = await SecretBoxCodec.exportKey(key);
    await store.save(userId: userId, dekBytes: bytes);
  }

  /// Restores the DEK from [store] when the same [userId] is signed in.
  Future<bool> tryUnlockFromLocalStore({
    required String userId,
    required LocalVaultDekStore store,
  }) async {
    if (hasDek) return true;
    final bytes = await store.load(userId: userId);
    if (bytes == null) return false;
    unlockWithDek(userId: userId, dek: await SecretBoxCodec.importKey(bytes));
    return true;
  }

  /// Creates a new vault DEK and uploads wraps to the server.
  Future<void> createVaultForUser({
    required String userId,
    required String password,
    String? googleSub,
  }) async {
    final dek = await SecretBoxCodec.randomKey();
    await _persistWraps(
      userId: userId,
      dek: dek,
      password: password.isNotEmpty ? password : null,
      googleSub: googleSub,
      createRecovery: true,
    );
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
  }

  /// Creates a vault keyed only by Google (no Portal password wrap).
  Future<void> createVaultForGoogle({
    required String userId,
    required String googleSub,
  }) async {
    final dek = await SecretBoxCodec.randomKey();
    await _persistWraps(
      userId: userId,
      dek: dek,
      password: null,
      googleSub: googleSub,
      createRecovery: true,
    );
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
  }

  /// Unlocks vault using Portal account password.
  Future<void> unlockWithPassword({
    required String userId,
    required String password,
  }) async {
    final wraps = await _api.fetchWraps();
    final passwordWrap = wraps.passwordWrap;
    if (passwordWrap == null) {
      throw StateError('No password wrap on server; create vault first.');
    }
    final dek = await KeyWrap.unwrapDekWithPassword(
      bundle: passwordWrap,
      password: password,
    );
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
  }

  /// Unlocks using Google account subject (linked Drive backup).
  Future<void> unlockWithGoogle({
    required String userId,
    required String googleSub,
  }) async {
    final wraps = await _api.fetchWraps();
    WrappedKeyBundle? bundle = wraps.googleWrap;
    bundle ??= await _googleDrive.fetchWrapBundle();
    if (bundle == null) {
      throw StateError('Google wrap not found. Link Google Drive first.');
    }
    final SecretKey dek;
    if (bundle.kind == KeyWrap.kindGoogleSecret) {
      final secret = await _googleDrive.fetchGoogleSecret();
      if (secret == null) {
        throw StateError(
          'Google vault secret missing from Drive. Unlock with your password.',
        );
      }
      dek = await KeyWrap.unwrapDekWithGoogleSecret(
        bundle: bundle,
        googleSecret: secret,
      );
    } else {
      // Legacy wrap keyed by the Google subject, which is not a secret.
      // Open it once, then immediately re-seal against a Drive-held secret.
      // ignore: deprecated_member_use
      dek = await KeyWrap.unwrapDekWithGoogleSubject(
        bundle: bundle,
        googleSub: googleSub,
      );
    }
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
    if (bundle.kind != KeyWrap.kindGoogleSecret) {
      await _upgradeGoogleWrap(dek);
    }
  }

  /// Re-seals the Google wrap against a fresh Drive-held secret. Best effort:
  /// the vault is already unlocked, so a Drive hiccup must not fail the unlock.
  Future<void> _upgradeGoogleWrap(SecretKey dek) async {
    try {
      final googleWrap = await _writeGoogleSecretWrap(dek);
      final wraps = await _api.fetchWraps();
      await _api.putWraps(
        passwordWrap: wraps.passwordWrap,
        recoveryWrap: wraps.recoveryWrap,
        googleWrap: googleWrap,
      );
    } catch (e) {
      debugPrint('[VaultService] Google wrap upgrade deferred: $e');
    }
  }

  /// Mints a Drive-held secret, seals [dek] with it, and stores both.
  Future<WrappedKeyBundle> _writeGoogleSecretWrap(SecretKey dek) async {
    final secret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    final wrap = await KeyWrap.wrapDekWithGoogleSecret(
      dek: dek,
      googleSecret: secret,
    );
    await _googleDrive.storeGoogleSecret(secret);
    await _googleDrive.storeWrapBundle(wrap);
    return wrap;
  }

  /// After password reset + recovery grant from server.
  Future<void> rewrapAfterRecovery({
    required String userId,
    required String newPassword,
    required List<int> recoverySecret,
  }) async {
    final wraps = await _api.fetchWraps();
    if (wraps.recoveryWrap == null) {
      throw StateError('No recovery wrap available.');
    }
    final dek = await KeyWrap.unwrapDekWithRecoverySecret(
      bundle: wraps.recoveryWrap!,
      recoverySecret: recoverySecret,
    );
    await _persistWraps(
      userId: userId,
      dek: dek,
      password: newPassword,
      googleSub: wraps.googleWrap != null ? 'linked' : null,
      createRecovery: true,
      existingGoogleWrap: wraps.googleWrap,
    );
    _dek = dek;
    _userId = userId;
    isUnlocked.value = true;
  }

  Future<void> _persistWraps({
    required String userId,
    required SecretKey dek,
    required String? password,
    String? googleSub,
    required bool createRecovery,
    WrappedKeyBundle? existingGoogleWrap,
  }) async {
    WrappedKeyBundle? passwordWrap;
    if (password != null && password.isNotEmpty) {
      passwordWrap = await KeyWrap.wrapDekWithPassword(
        dek: dek,
        password: password,
      );
    }
    WrappedKeyBundle? recoveryWrap;
    List<int>? recoverySecret;
    if (createRecovery) {
      recoverySecret = await SecretBoxCodec.exportKey(
        await SecretBoxCodec.randomKey(),
      );
      recoveryWrap = await KeyWrap.wrapDekWithRecoverySecret(
        dek: dek,
        recoverySecret: recoverySecret,
      );
    }
    WrappedKeyBundle? googleWrap = existingGoogleWrap;
    if (googleSub != null && googleSub != 'linked') {
      googleWrap = await _writeGoogleSecretWrap(dek);
    }
    if (passwordWrap == null && googleWrap == null) {
      throw StateError('Vault requires at least one of password or Google wrap.');
    }
    await _api.putWraps(
      passwordWrap: passwordWrap,
      recoveryWrap: recoveryWrap,
      googleWrap: googleWrap,
      recoverySecretForGrant: recoverySecret,
    );
  }

  Future<Uint8List> encryptPayload(List<int> plaintext) async {
    final key = _dek;
    if (key == null) throw StateError('Vault is locked');
    final blob = await PortalVaultBlob.encryptBytes(dek: key, plaintext: plaintext);
    return Uint8List.fromList(utf8.encode(blob.encode()));
  }

  Future<Uint8List> decryptPayload(Uint8List stored) async {
    final key = _dek;
    if (key == null) throw StateError('Vault is locked');
    final blob = PortalVaultBlob.decode(utf8.decode(stored));
    return PortalVaultBlob.decryptBytes(dek: key, blob: blob);
  }

  Future<String> encryptString(String plaintext) async {
    final bytes = await encryptPayload(utf8.encode(plaintext));
    return utf8.decode(bytes);
  }

  Future<String?> tryDecryptString(String? stored) async {
    if (stored == null || stored.isEmpty) return stored;
    if (!looksEncrypted(stored)) return stored;
    try {
      final bytes = await decryptPayload(Uint8List.fromList(utf8.encode(stored)));
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('[VaultService] decrypt failed: $e');
      return null;
    }
  }

  static bool looksEncrypted(String value) {
    return value.trimLeft().startsWith('{') &&
        value.contains('"version"') &&
        value.contains('portal-vault');
  }

  /// Migrates plaintext JSON value to encrypted form when vault is unlocked.
  Future<String> migratePlaintextIfNeeded(String? raw) async {
    if (raw == null || raw.isEmpty) return raw ?? '';
    if (looksEncrypted(raw) || !hasDek) return raw;
    return encryptString(raw);
  }

  /// Updates the password wrap while keeping recovery / Google wraps unchanged.
  Future<void> rewrapPassword({required String newPassword}) async {
    final key = _dek;
    if (key == null) throw StateError('Vault is locked');
    final wraps = await _api.fetchWraps();
    if (wraps.passwordWrap == null) {
      throw StateError('No password wrap on server.');
    }
    final passwordWrap = await KeyWrap.wrapDekWithPassword(
      dek: key,
      password: newPassword,
    );
    await _api.putWraps(
      passwordWrap: passwordWrap,
      recoveryWrap: wraps.recoveryWrap,
      googleWrap: wraps.googleWrap,
    );
  }

  /// [googleSub] is no longer key material — the wrap is sealed with a secret
  /// held in Drive appdata. The parameter stays for the existing callers in
  /// portal_task and to identify the account being linked.
  Future<void> linkGoogleAccount(String googleSub) async {
    final key = _dek;
    if (key == null) throw StateError('Vault is locked');
    final googleWrap = await _writeGoogleSecretWrap(key);
    final wraps = await _api.fetchWraps();
    await _api.putWraps(
      passwordWrap: wraps.passwordWrap,
      recoveryWrap: wraps.recoveryWrap,
      googleWrap: googleWrap,
    );
    await BackupSettingsStore.setGoogleLinked(true);
  }

  String? get userId => _userId;
}
