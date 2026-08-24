import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derives a 256-bit key from a password and salt (PBKDF2-HMAC-SHA256).
abstract final class KeyDerivation {
  static const int defaultIterations = 210000;

  static Future<SecretKey> deriveFromPassword({
    required String password,
    required List<int> salt,
    int iterations = defaultIterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  static Future<SecretKey> deriveFromGoogleSubject({
    required String googleSub,
    required List<int> salt,
  }) async {
    return deriveFromPassword(
      password: 'google:$googleSub',
      salt: salt,
      iterations: 100000,
    );
  }

  static Future<List<int>> secureRandomSalt({int length = 16}) async {
    final algo = AesGcm.with256bits();
    final key = await algo.newSecretKey();
    final bytes = await key.extractBytes();
    return bytes.sublist(0, length);
  }
}

/// HKDF expand for wrapping keys.
abstract final class HkdfExpand {
  static Future<SecretKey> expand({
    required SecretKey ikm,
    required List<int> info,
    int length = 32,
  }) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: length,
    );
    return hkdf.deriveKey(
      secretKey: ikm,
      info: info,
      nonce: const [],
    );
  }
}
