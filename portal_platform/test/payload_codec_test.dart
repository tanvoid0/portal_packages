import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';

/// A payload that looks encrypted (per [VaultPayloadCodec.looksEncrypted]'s
/// marker check) but cannot actually be decrypted with this device's key.
const _staleEncryptedPayload =
    '{"version":1,"portal-vault":true,"ct":"garbage"}';

/// In-memory stand-in for [LocalVaultDekStore] — no real secure storage in a
/// plain `flutter_test` run. Counts [save] so the concurrency test can
/// assert exactly one key was minted.
class _CountingDekStore extends LocalVaultDekStore {
  final Map<String, List<int>> _saved = {};
  int saveCalls = 0;

  @override
  Future<void> save({required String userId, required List<int> dekBytes}) async {
    saveCalls++;
    _saved[userId] = dekBytes;
  }

  @override
  Future<List<int>?> load({required String userId}) async => _saved[userId];

  @override
  Future<void> clear({required String userId}) async => _saved.remove(userId);
}

void main() {
  group('VaultPayloadCodec.decode', () {
    test('a looksEncrypted payload that cannot decrypt never becomes []',
        () async {
      final codec = VaultPayloadCodec(dekStore: _CountingDekStore());
      await expectLater(
        () => codec.decode(_staleEncryptedPayload),
        throwsA(isA<StaleDecryptException>()),
      );
      expect(codec.staleDecryptDetected, isTrue);
    });

    test('plaintext (not looksEncrypted) passes through unchanged', () async {
      final codec = VaultPayloadCodec(dekStore: _CountingDekStore());
      expect(await codec.decode('[]'), '[]');
      expect(await codec.decode('[{"id":"1"}]'), '[{"id":"1"}]');
    });
  });

  group('VaultPayloadCodec key memoisation', () {
    test('10 concurrent first uses mint exactly one key', () async {
      final dekStore = _CountingDekStore();
      final codec = VaultPayloadCodec(dekStore: dekStore);

      // All fired before any of them awaits past the first `dekStore.load`
      // — the race the memoised Future<SecretKey> exists to close.
      await Future.wait(
        List.generate(10, (i) => codec.encode('payload $i')),
      );

      expect(dekStore.saveCalls, 1);
    });
  });

  group('payloadCodecForEncrypted', () {
    test('true resolves to VaultPayloadCodec, false to PlaintextCodec', () {
      expect(payloadCodecForEncrypted(true), isA<VaultPayloadCodec>());
      expect(payloadCodecForEncrypted(false), isA<PlaintextCodec>());
    });
  });
}
