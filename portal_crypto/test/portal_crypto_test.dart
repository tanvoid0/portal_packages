import 'package:cryptography/cryptography.dart';
import 'package:portal_crypto/portal_crypto.dart';
import 'package:test/test.dart';

void main() {
  test('wrap and unwrap DEK with password', () async {
    final dek = await SecretBoxCodec.randomKey();
    final bundle = await KeyWrap.wrapDekWithPassword(
      dek: dek,
      password: 'test-password',
    );
    final unwrapped = await KeyWrap.unwrapDekWithPassword(
      bundle: bundle,
      password: 'test-password',
    );
    final a = await SecretBoxCodec.exportKey(dek);
    final b = await SecretBoxCodec.exportKey(unwrapped);
    expect(b, equals(a));
  });

  test('portal vault blob round-trip', () async {
    final dek = await SecretBoxCodec.randomKey();
    final blob = await PortalVaultBlob.encryptString(
      dek: dek,
      plaintext: '{"tasks":[]}',
    );
    final plain = await PortalVaultBlob.decryptString(dek: dek, blob: blob);
    expect(plain, '{"tasks":[]}');
  });
}
