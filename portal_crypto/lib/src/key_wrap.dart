import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_derivation.dart';
import 'secret_box_codec.dart';

/// Wraps a data encryption key (DEK) with a key-encryption key (KEK).
class WrappedKeyBundle {
  const WrappedKeyBundle({
    required this.salt,
    required this.wrappedDek,
    this.iterations = KeyDerivation.defaultIterations,
    this.kind = 'password',
  });

  final String kind;
  final List<int> salt;
  final int iterations;
  final Uint8List wrappedDek;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'salt': base64Encode(salt),
        'iterations': iterations,
        'wrapped_dek': base64Encode(wrappedDek),
      };

  factory WrappedKeyBundle.fromJson(Map<String, dynamic> json) {
    return WrappedKeyBundle(
      kind: json['kind'] as String? ?? 'password',
      salt: base64Decode(json['salt'] as String),
      iterations: json['iterations'] as int? ?? KeyDerivation.defaultIterations,
      wrappedDek: Uint8List.fromList(
        base64Decode(json['wrapped_dek'] as String),
      ),
    );
  }
}

abstract final class KeyWrap {
  /// [WrappedKeyBundle.kind] for the Drive-secret Google wrap.
  static const String kindGoogleSecret = 'google_secret';

  /// [WrappedKeyBundle.kind] for the superseded subject-derived Google wrap.
  static const String kindGoogleSubjectLegacy = 'google';

  static Future<WrappedKeyBundle> wrapDekWithPassword({
    required SecretKey dek,
    required String password,
    List<int>? salt,
  }) async {
    final useSalt = salt ?? await KeyDerivation.secureRandomSalt();
    final kek = await KeyDerivation.deriveFromPassword(
      password: password,
      salt: useSalt,
    );
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final wrapped = await SecretBoxCodec.encrypt(
      key: kek,
      plaintext: dekBytes,
      aad: utf8.encode('portal-dek-wrap-v1'),
    );
    return WrappedKeyBundle(salt: useSalt, wrappedDek: wrapped);
  }

  static Future<SecretKey> unwrapDekWithPassword({
    required WrappedKeyBundle bundle,
    required String password,
  }) async {
    final kek = await KeyDerivation.deriveFromPassword(
      password: password,
      salt: bundle.salt,
      iterations: bundle.iterations,
    );
    final dekBytes = await SecretBoxCodec.decrypt(
      key: kek,
      packed: bundle.wrappedDek,
      aad: utf8.encode('portal-dek-wrap-v1'),
    );
    return SecretBoxCodec.importKey(dekBytes);
  }

  @Deprecated(
    'The Google subject is not a secret. Use wrapDekWithGoogleSecret; this '
    'remains only to open wraps written before that change.',
  )
  static Future<WrappedKeyBundle> wrapDekWithGoogleSubject({
    required SecretKey dek,
    required String googleSub,
    List<int>? salt,
  }) async {
    final useSalt = salt ?? await KeyDerivation.secureRandomSalt();
    final kek = await KeyDerivation.deriveFromGoogleSubject(
      googleSub: googleSub,
      salt: useSalt,
    );
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final wrapped = await SecretBoxCodec.encrypt(
      key: kek,
      plaintext: dekBytes,
      aad: utf8.encode('portal-dek-wrap-google-v1'),
    );
    return WrappedKeyBundle(
      kind: 'google',
      salt: useSalt,
      iterations: 100000,
      wrappedDek: wrapped,
    );
  }

  static Future<SecretKey> unwrapDekWithGoogleSubject({
    required WrappedKeyBundle bundle,
    required String googleSub,
  }) async {
    final kek = await KeyDerivation.deriveFromGoogleSubject(
      googleSub: googleSub,
      salt: bundle.salt,
    );
    final dekBytes = await SecretBoxCodec.decrypt(
      key: kek,
      packed: bundle.wrappedDek,
      aad: utf8.encode('portal-dek-wrap-google-v1'),
    );
    return SecretBoxCodec.importKey(dekBytes);
  }

  /// Wraps the DEK with a random secret held in the user's Google Drive
  /// appdata, which only that Google account can read.
  ///
  /// Replaces [wrapDekWithGoogleSubject], whose KEK came from the Google
  /// subject id — an identifier the server and every relying party already
  /// know, so the wrap it produced could be opened by anyone holding it.
  static Future<WrappedKeyBundle> wrapDekWithGoogleSecret({
    required SecretKey dek,
    required List<int> googleSecret,
  }) async {
    final kek = await HkdfExpand.expand(
      ikm: SecretKey(googleSecret),
      info: utf8.encode('portal-google-kek-v1'),
    );
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final wrapped = await SecretBoxCodec.encrypt(
      key: kek,
      plaintext: dekBytes,
      aad: utf8.encode('portal-dek-wrap-google-v2'),
    );
    return WrappedKeyBundle(
      kind: kindGoogleSecret,
      salt: const [],
      iterations: 0,
      wrappedDek: wrapped,
    );
  }

  static Future<SecretKey> unwrapDekWithGoogleSecret({
    required WrappedKeyBundle bundle,
    required List<int> googleSecret,
  }) async {
    final kek = await HkdfExpand.expand(
      ikm: SecretKey(googleSecret),
      info: utf8.encode('portal-google-kek-v1'),
    );
    final dekBytes = await SecretBoxCodec.decrypt(
      key: kek,
      packed: bundle.wrappedDek,
      aad: utf8.encode('portal-dek-wrap-google-v2'),
    );
    return SecretBoxCodec.importKey(dekBytes);
  }

  /// Server recovery wrap uses a random 32-byte recovery secret stored server-side
  /// (opaque to client except during recovery grant flow).
  static Future<WrappedKeyBundle> wrapDekWithRecoverySecret({
    required SecretKey dek,
    required List<int> recoverySecret,
  }) async {
    final kek = await HkdfExpand.expand(
      ikm: SecretKey(recoverySecret),
      info: utf8.encode('portal-recovery-kek-v1'),
    );
    final dekBytes = await SecretBoxCodec.exportKey(dek);
    final wrapped = await SecretBoxCodec.encrypt(
      key: kek,
      plaintext: dekBytes,
      aad: utf8.encode('portal-dek-wrap-recovery-v1'),
    );
    return WrappedKeyBundle(
      kind: 'recovery',
      salt: const [],
      iterations: 0,
      wrappedDek: wrapped,
    );
  }

  static Future<SecretKey> unwrapDekWithRecoverySecret({
    required WrappedKeyBundle bundle,
    required List<int> recoverySecret,
  }) async {
    final kek = await HkdfExpand.expand(
      ikm: SecretKey(recoverySecret),
      info: utf8.encode('portal-recovery-kek-v1'),
    );
    final dekBytes = await SecretBoxCodec.decrypt(
      key: kek,
      packed: bundle.wrappedDek,
      aad: utf8.encode('portal-dek-wrap-recovery-v1'),
    );
    return SecretBoxCodec.importKey(dekBytes);
  }
}
