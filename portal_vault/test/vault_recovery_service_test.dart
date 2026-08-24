import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_crypto/portal_crypto.dart';
import 'package:portal_vault/src/remote/vault_api_client.dart';
import 'package:portal_vault/src/vault_recovery_service.dart';

/// Captures what the recovery flow actually puts on the wire.
class _CapturingApi implements VaultApiClient {
  WrappedKeyBundle? wrapPassword;
  WrappedKeyBundle? wrapRecovery;
  List<int>? recoverySecret;

  @override
  Future<void> completeResetRecovery({
    required String email,
    required String grantToken,
    required WrappedKeyBundle wrapPassword,
    WrappedKeyBundle? wrapRecovery,
    List<int>? recoverySecret,
  }) async {
    this.wrapPassword = wrapPassword;
    this.wrapRecovery = wrapRecovery;
    this.recoverySecret = recoverySecret;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

void main() {
  test('a password reset escrows a secret that opens the wrap it ships with',
      () async {
    final dek = await SecretBoxCodec.randomKey();
    final dekBytes = await SecretBoxCodec.exportKey(dek);

    final oldSecret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    final oldWrap = await KeyWrap.wrapDekWithRecoverySecret(
      dek: dek,
      recoverySecret: oldSecret,
    );

    final api = _CapturingApi();
    await VaultRecoveryService.rewrapAfterPasswordReset(
      api: api,
      email: 'someone@example.com',
      newPassword: 'new-password-1',
      grantToken: 'grant-1',
      recoverySecretBase64: base64Encode(oldSecret),
      recoveryWrap: oldWrap,
    );

    // Regression: the rotated secret used to be minted, wrapped, and then
    // dropped, so the escrowed wrap could never be opened again.
    expect(api.recoverySecret, isNotNull);
    expect(api.wrapRecovery, isNotNull);
    expect(api.recoverySecret, isNot(oldSecret));

    final recovered = await KeyWrap.unwrapDekWithRecoverySecret(
      bundle: api.wrapRecovery!,
      recoverySecret: api.recoverySecret!,
    );
    expect(await SecretBoxCodec.exportKey(recovered), dekBytes);
  });

  test('the new password wrap opens with the new password', () async {
    final dek = await SecretBoxCodec.randomKey();
    final dekBytes = await SecretBoxCodec.exportKey(dek);

    final oldSecret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    final oldWrap = await KeyWrap.wrapDekWithRecoverySecret(
      dek: dek,
      recoverySecret: oldSecret,
    );

    final api = _CapturingApi();
    await VaultRecoveryService.rewrapAfterPasswordReset(
      api: api,
      email: 'someone@example.com',
      newPassword: 'new-password-1',
      grantToken: 'grant-1',
      recoverySecretBase64: base64Encode(oldSecret),
      recoveryWrap: oldWrap,
    );

    final recovered = await KeyWrap.unwrapDekWithPassword(
      bundle: api.wrapPassword!,
      password: 'new-password-1',
    );
    expect(await SecretBoxCodec.exportKey(recovered), dekBytes);
  });
}
