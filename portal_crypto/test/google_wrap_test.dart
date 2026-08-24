import 'package:test/test.dart';
import 'package:portal_crypto/portal_crypto.dart';

void main() {
  test('the Google wrap opens with its Drive-held secret', () async {
    final dek = await SecretBoxCodec.randomKey();
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final secret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );

    final wrap = await KeyWrap.wrapDekWithGoogleSecret(
      dek: dek,
      googleSecret: secret,
    );
    expect(wrap.kind, KeyWrap.kindGoogleSecret);

    final opened = await KeyWrap.unwrapDekWithGoogleSecret(
      bundle: wrap,
      googleSecret: secret,
    );
    expect(await SecretBoxCodec.exportKey(opened), dekBytes);
  });

  // The whole point of the change: the Google subject is public, so holding
  // the wrap plus the subject must no longer be enough to open it.
  test('a different secret cannot open it', () async {
    final dek = await SecretBoxCodec.randomKey();
    final secret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );
    final other = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );

    final wrap = await KeyWrap.wrapDekWithGoogleSecret(
      dek: dek,
      googleSecret: secret,
    );

    await expectLater(
      KeyWrap.unwrapDekWithGoogleSecret(bundle: wrap, googleSecret: other),
      throwsA(isA<Object>()),
    );
  });

  test('the wrap survives a json round-trip', () async {
    final dek = await SecretBoxCodec.randomKey();
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final secret = await SecretBoxCodec.exportKey(
      await SecretBoxCodec.randomKey(),
    );

    final wrap = await KeyWrap.wrapDekWithGoogleSecret(
      dek: dek,
      googleSecret: secret,
    );
    final revived = WrappedKeyBundle.fromJson(wrap.toJson());

    final opened = await KeyWrap.unwrapDekWithGoogleSecret(
      bundle: revived,
      googleSecret: secret,
    );
    expect(await SecretBoxCodec.exportKey(opened), dekBytes);
  });
}
