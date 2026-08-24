import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'secret_box_codec.dart';

/// Versioned encrypted payload (`portal-vault-v1`).
class PortalVaultBlob {
  const PortalVaultBlob({
    this.version = 'portal-vault-v1',
    required this.ciphertext,
    this.contentType = 'application/octet-stream',
  });

  static const String currentVersion = 'portal-vault-v1';

  final String version;
  final String contentType;
  final Uint8List ciphertext;

  Map<String, dynamic> toJson() => {
        'version': version,
        'content_type': contentType,
        'ciphertext': base64Encode(ciphertext),
      };

  factory PortalVaultBlob.fromJson(Map<String, dynamic> json) {
    return PortalVaultBlob(
      version: json['version'] as String? ?? currentVersion,
      contentType:
          json['content_type'] as String? ?? 'application/octet-stream',
      ciphertext: Uint8List.fromList(
        base64Decode(json['ciphertext'] as String),
      ),
    );
  }

  String encode() => jsonEncode(toJson());

  static PortalVaultBlob decode(String raw) =>
      PortalVaultBlob.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static Future<PortalVaultBlob> encryptBytes({
    required SecretKey dek,
    required List<int> plaintext,
    String contentType = 'application/octet-stream',
    List<int>? aad,
  }) async {
    final packed = await SecretBoxCodec.encrypt(
      key: dek,
      plaintext: plaintext,
      aad: aad ?? utf8.encode(currentVersion),
    );
    return PortalVaultBlob(contentType: contentType, ciphertext: packed);
  }

  static Future<Uint8List> decryptBytes({
    required SecretKey dek,
    required PortalVaultBlob blob,
    List<int>? aad,
  }) async {
    if (blob.version != currentVersion) {
      throw FormatException('Unsupported blob version: ${blob.version}');
    }
    return SecretBoxCodec.decrypt(
      key: dek,
      packed: blob.ciphertext,
      aad: aad ?? utf8.encode(currentVersion),
    );
  }

  static Future<PortalVaultBlob> encryptString({
    required SecretKey dek,
    required String plaintext,
    List<int>? aad,
  }) =>
      encryptBytes(
        dek: dek,
        plaintext: utf8.encode(plaintext),
        contentType: 'text/plain; charset=utf-8',
        aad: aad,
      );

  static Future<String> decryptString({
    required SecretKey dek,
    required PortalVaultBlob blob,
    List<int>? aad,
  }) async {
    final bytes = await decryptBytes(dek: dek, blob: blob, aad: aad);
    return utf8.decode(bytes);
  }
}
