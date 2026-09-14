# portal_crypto

AES-GCM encryption, key wrapping and a versioned vault blob format. Pure Dart,
built on `package:cryptography`.

- `key_derivation.dart` — password → key.
- `WrappedKeyBundle` — wrap a data-encryption key under a key-encryption key.
- `PortalVaultBlob` — versioned (`portal-vault-v1`) JSON blob: nonce, tag, ciphertext, content type.
- `SecretBoxCodec` — AES-GCM encrypt/decrypt to packed bytes.

```dart
import 'package:portal_crypto/portal_crypto.dart';

final blob = await PortalVaultBlob.encryptString(dek: dek, plaintext: 'secret');
final raw = blob.encode();                                   // JSON string
final back = await PortalVaultBlob.decryptString(dek: dek, blob: PortalVaultBlob.decode(raw));
```

Used by the Portal apps' local vaults; nothing here touches the network.
