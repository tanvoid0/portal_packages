import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM encrypt/decrypt helpers.
abstract final class SecretBoxCodec {
  static final AesGcm _algorithm = AesGcm.with256bits();

  static Future<SecretKey> randomKey() async {
    return _algorithm.newSecretKey();
  }

  static Future<SecretKey> importKey(List<int> bytes) async {
    return SecretKey(bytes);
  }

  static Future<List<int>> exportKey(SecretKey key) async {
    return key.extractBytes();
  }

  static Future<Uint8List> encrypt({
    required SecretKey key,
    required List<int> plaintext,
    List<int>? aad,
    List<int>? nonce,
  }) async {
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: aad ?? const [],
    );
    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  static Future<Uint8List> decrypt({
    required SecretKey key,
    required List<int> packed,
    List<int>? aad,
  }) async {
    if (packed.length < 12 + 16) {
      throw FormatException('Ciphertext too short');
    }
    final nonceLen = _algorithm.nonceLength;
    final macLen = 16;
    final nonce = packed.sublist(0, nonceLen);
    final cipherText = packed.sublist(nonceLen, packed.length - macLen);
    final macBytes = packed.sublist(packed.length - macLen);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final plain = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
      aad: aad ?? const [],
    );
    return Uint8List.fromList(plain);
  }
}
