import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_platform/src/sync/encrypted_sync_queue_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  SyncOperation op(String id) => SyncOperation(
        id: 'op-$id',
        type: SyncOperationType.create,
        entityType: 'recipe',
        entityId: id,
        data: {'title': 'Recipe $id'},
        createdAt: DateTime.utc(2026, 1, 1),
      );

  test('round-trips operations through encryption', () async {
    final encoded = await EncryptedSyncQueueCodec.encryptOperations([op('a')]);
    expect(encoded, contains('portal-vault'));
    expect(encoded, isNot(contains('Recipe a')));

    final decoded = await EncryptedSyncQueueCodec.decryptOperations(encoded);
    expect(decoded.single.entityId, 'a');
  });

  // Guards the invariant _queueKey() exists to hold: once a blob is sealed,
  // later calls must reuse that key rather than mint a new one, or the
  // persisted queue becomes undecryptable.
  test('reuses the stored key instead of regenerating it', () async {
    final first = await EncryptedSyncQueueCodec.encryptOperations([op('a')]);
    await EncryptedSyncQueueCodec.encryptOperations([op('b')]);

    final decoded = await EncryptedSyncQueueCodec.decryptOperations(first);
    expect(decoded.single.entityId, 'a');
  });

  test('migrates plaintext queue json to encrypted form', () async {
    final plain = SyncOperation.listToJson([op('a')]);
    final migrated = await EncryptedSyncQueueCodec.migrateIfNeeded(plain);

    expect(migrated, isNot(plain));
    expect(
      (await EncryptedSyncQueueCodec.decryptOperations(migrated)).single.entityId,
      'a',
    );

    // Already-encrypted input is left alone.
    expect(await EncryptedSyncQueueCodec.migrateIfNeeded(migrated), migrated);
  });
}
