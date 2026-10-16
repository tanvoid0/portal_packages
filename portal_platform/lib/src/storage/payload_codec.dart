import 'package:cryptography/cryptography.dart';
import 'package:portal_crypto/portal_crypto.dart';

import '../config/app_config.dart';
import 'local_vault_dek_store.dart';
import 'user_storage_scope.dart';

/// Thrown by [PayloadCodec.decode] when a payload looks encrypted but
/// cannot be decrypted (DEK rotated, restored device, wrap replaced).
/// Never swallow this into an empty list — the stored bytes are intact,
/// only the key to read them is missing.
class StaleDecryptException implements Exception {
  const StaleDecryptException();

  @override
  String toString() =>
      'StaleDecryptException: encrypted payload could not be decrypted';
}

/// Encrypts/decrypts entity JSON strings at the persistence boundary.
abstract interface class PayloadCodec {
  bool get staleDecryptDetected;

  void resetStaleDecryptState();

  Future<String> encode(String plaintext);

  Future<String> decode(String? stored);
}

final class PlaintextCodec implements PayloadCodec {
  @override
  bool get staleDecryptDetected => false;

  @override
  void resetStaleDecryptState() {}

  @override
  Future<String> encode(String plaintext) async => plaintext;

  @override
  Future<String> decode(String? stored) async => stored ?? '';
}

/// Encrypts entity JSON with a random 256-bit key held only on this device
/// (`LocalVaultDekStore`, secure storage) — there is no server-side escrow.
/// One key per signed-in user, minted on first use and never cleared on
/// sign-out: clearing it would turn the next login's still-intact ciphertext
/// into an unreadable [StaleDecryptException].
final class VaultPayloadCodec implements PayloadCodec {
  VaultPayloadCodec({LocalVaultDekStore? dekStore})
      : _dekStore = dekStore ?? LocalVaultDekStore();

  final LocalVaultDekStore _dekStore;

  // Memoised so two concurrent first reads await the same mint instead of
  // each writing their own key — the loser's data would be undecryptable.
  Future<SecretKey>? _keyFuture;

  @override
  bool staleDecryptDetected = false;

  @override
  void resetStaleDecryptState() {
    staleDecryptDetected = false;
  }

  Future<SecretKey> _key() => _keyFuture ??= _loadOrCreateKey();

  Future<SecretKey> _loadOrCreateKey() async {
    final userId = UserStorageScope.currentUserId ?? 'anonymous';
    final existing = await _dekStore.load(userId: userId);
    if (existing != null) return SecretKey(existing);
    final key = await SecretBoxCodec.randomKey();
    await _dekStore.save(
      userId: userId,
      dekBytes: await SecretBoxCodec.exportKey(key),
    );
    return key;
  }

  @override
  Future<String> encode(String plaintext) async {
    final blob = await PortalVaultBlob.encryptString(
      dek: await _key(),
      plaintext: plaintext,
    );
    return blob.encode();
  }

  @override
  Future<String> decode(String? stored) async {
    if (stored == null || stored.isEmpty) return stored ?? '';
    if (!looksEncrypted(stored)) return stored;

    try {
      final blob = PortalVaultBlob.decode(stored);
      return await PortalVaultBlob.decryptString(dek: await _key(), blob: blob);
    } catch (_) {
      staleDecryptDetected = true;
      throw const StaleDecryptException();
    }
  }

  /// Discards the on-device key and lets the next [encode]/[decode] mint a
  /// fresh one. Only [StaleDataRecovery] calls this, and only after the
  /// ciphertext under the old key has already been wiped — anything still
  /// under it would otherwise become permanently undecryptable.
  Future<void> rotateKey() async {
    final userId = UserStorageScope.currentUserId ?? 'anonymous';
    await _dekStore.clear(userId: userId);
    _keyFuture = null;
    resetStaleDecryptState();
  }

  /// True when [value] carries the `portal-vault` blob envelope, regardless
  /// of whether it can actually be decrypted with the current key.
  static bool looksEncrypted(String value) {
    return value.trimLeft().startsWith('{') &&
        value.contains('"version"') &&
        value.contains('portal-vault');
  }
}

/// [encrypted] is the one bool → [PayloadCodec] decision every caller shares
/// — [PayloadCodecFactory.fromConfig] resolves it from the build-time
/// `.env` flag; a local-only session resolves it from the user's one-time
/// runtime choice instead.
PayloadCodec payloadCodecForEncrypted(bool encrypted) =>
    encrypted ? VaultPayloadCodec() : PlaintextCodec();

abstract final class PayloadCodecFactory {
  static PayloadCodec fromConfig(AppConfig config) =>
      payloadCodecForEncrypted(config.dataEncrypted);
}
