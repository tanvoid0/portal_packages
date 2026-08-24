import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_platform/src/sync/encrypted_sync_queue_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _queueKey = 'portal_sync_queue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SyncOperation op(String id) => SyncOperation(
        id: 'op-$id',
        type: SyncOperationType.create,
        entityType: 'recipe',
        entityId: id,
        data: {'title': 'Recipe $id'},
        createdAt: DateTime.utc(2026, 1, 1),
      );

  Future<List<String>> storedEntityIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    final ops = await EncryptedSyncQueueCodec.decryptOperations(raw);
    return ops.map((o) => o.entityId).toList();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('enqueue persists operations', () async {
    final queue = await SyncQueue().init();
    await queue.enqueue(op('a'));
    await queue.enqueue(op('b'));

    expect(queue.pendingCount.value, 2);
    expect(await storedEntityIds(), ['a', 'b']);
  });

  // Regression: enqueue is load -> modify -> save with awaits in between, so
  // without serialisation concurrent callers each start from the same snapshot
  // and the last save wins, silently dropping the others.
  test('concurrent enqueues all survive', () async {
    final queue = await SyncQueue().init();
    final ids = List.generate(12, (i) => 'e$i');

    await Future.wait(ids.map((id) => queue.enqueue(op(id))));

    expect(await storedEntityIds(), ids);
    expect(queue.pendingCount.value, ids.length);
  });

  test('create then delete cancels both out', () async {
    final queue = await SyncQueue().init();
    await queue.enqueue(op('a'));
    await queue.enqueue(SyncOperation(
      type: SyncOperationType.delete,
      entityType: 'recipe',
      entityId: 'a',
    ));

    expect(queue.pendingCount.value, 0);
  });

  // Regression: _load() used to catch and return [], so a queue that failed
  // the plaintext->encrypted migration turned the next enqueue into
  // load([]) -> append -> save, destroying every pending operation. Only the
  // awaited part of the old body was actually guarded, so this legacy-format
  // path is the one that regressed.
  test('an unreadable queue fails loudly instead of truncating', () async {
    const corrupt = '[{"entityType": "recipe", truncated...';
    SharedPreferences.setMockInitialValues({_queueKey: corrupt});

    await expectLater(SyncQueue().enqueue(op('c')), throwsA(isA<Object>()));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(_queueKey),
      corrupt,
      reason: 'pending operations must survive a failed read',
    );
  });

  test('a legacy plaintext queue is migrated in place, not dropped', () async {
    SharedPreferences.setMockInitialValues({
      _queueKey: SyncOperation.listToJson([op('a')]),
    });

    final queue = await SyncQueue().init();
    expect(queue.pendingCount.value, 1);

    await queue.enqueue(op('b'));
    expect(await storedEntityIds(), ['a', 'b']);
  });

  test('init survives an unreadable queue', () async {
    SharedPreferences.setMockInitialValues({_queueKey: '[{"broken"'});

    final queue = await SyncQueue().init();
    expect(queue.pendingCount.value, 0);
  });
}
