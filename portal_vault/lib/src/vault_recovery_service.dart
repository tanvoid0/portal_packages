import 'dart:convert';

import 'package:portal_crypto/portal_crypto.dart';

import 'remote/vault_api_client.dart';

/// Client-side vault re-wrap after account password reset.
abstract final class VaultRecoveryService {
  static Future<void> rewrapAfterPasswordReset({
    required VaultApiClient api,
    required String email,
    required String newPassword,
    required String grantToken,
    required String recoverySecretBase64,
    required WrappedKeyBundle recoveryWrap,
  }) async {
    final recoverySecret = base64Decode(recoverySecretBase64);
    final dek = await KeyWrap.unwrapDekWithRecoverySecret(
      bundle: recoveryWrap,
      recoverySecret: recoverySecret,
    );
    final passwordWrap = await KeyWrap.wrapDekWithPassword(
      dek: dek,
      password: newPassword,
    );
    final newRecoverySecret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    final newRecoveryWrap = await KeyWrap.wrapDekWithRecoverySecret(
      dek: dek,
      recoverySecret: newRecoverySecret,
    );
    await api.completeResetRecovery(
      email: email,
      grantToken: grantToken,
      wrapPassword: passwordWrap,
      wrapRecovery: newRecoveryWrap,
      // Without this the rotated secret is lost and the escrowed wrap can
      // never be opened again.
      recoverySecret: newRecoverySecret,
    );
  }
}
