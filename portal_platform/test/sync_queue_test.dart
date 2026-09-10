import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_platform/src/sync/encrypted_sync_queue_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _queueKey = 'portal_sync_queue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Relative, not a fixed date: the queue evicts operations past
  // [SyncQueue.maxOperationAge], so a hardcoded timestamp silently starts
  // being pruned once it ages past the cutoff in real time.
  SyncOperation op(String id, {Duration age = Duration.zero}) => SyncOperation(
        id: 'op-$id',
        type: SyncOperationType.create,
        entityType: 'recipe',
        entityId: id,
        data: {'title': 'Recipe $id'},
        createdAt: DateTime.now().subtract(age),
      );

  // Reads the queue where it now lives: a row in the shared SQLite database,
  // not a SharedPreferences string.
  Future<List<String>> storedEntityIds() async {
    final raw = await PortalDatabase.kvGet(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    final ops = await EncryptedSyncQueueCodec.decryptOperations(raw);
    return ops.map((o) => o.entityId).toList();
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await PortalDatabase.resetForTest();
    PortalDatabase.overrideFilePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  // A restore or a keystore invalidation leaves the encrypted queue in
  // SharedPreferences with no key that can read it. Throwing on that read
  // wedges every later write, since each one loads before it saves.
  test('a queue sealed under a lost key is dropped, not fatal', () async {
    final sealed = await EncryptedSyncQueueCodec.encryptOperations([op('a')]);
    SharedPreferences.setMockInitialValues({_queueKey: sealed});
    FlutterSecureStorage.setMockInitialValues({});

    final queue = await SyncQueue().init();
    await queue.enqueue(op('b'));

    expect(await storedEntityIds(), ['b']);
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

    // The read throws inside the transaction that was importing it, so the
    // import rolls back and prefs is still the only copy — which is the point:
    // nothing was destroyed, and the next read tries again.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(_queueKey),
      corrupt,
      reason: 'pending operations must survive a failed read',
    );
    expect(await PortalDatabase.kvGet(_queueKey), isNull);
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

  group('eviction', () {
    tearDown(() => SyncQueue.onEvicted = null);

    /// The queue is one encrypted SharedPreferences string rewritten on every
    /// mutation, so it cannot be allowed to grow without bound.
    test('operations past the age limit are dropped', () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(op('fresh'));
      await queue.enqueue(
        op('ancient', age: SyncQueue.maxOperationAge + const Duration(days: 1)),
      );

      expect(await storedEntityIds(), ['fresh']);
      expect(queue.pendingCount.value, 1);
    });

    test('an operation just inside the limit is kept', () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(
        op('recent', age: SyncQueue.maxOperationAge - const Duration(days: 1)),
      );

      expect(await storedEntityIds(), ['recent']);
    });

    /// Dropping a change is data loss, so it must reach the user.
    test('eviction is reported, with a count and a reason', () async {
      var dropped = 0;
      String? reason;
      SyncQueue.onEvicted = (n, why) {
        dropped += n;
        reason = why;
      };

      final queue = await SyncQueue().init();
      await queue.enqueue(
        op('ancient', age: SyncQueue.maxOperationAge + const Duration(days: 1)),
      );

      expect(dropped, 1);
      expect(reason, contains('${SyncQueue.maxOperationAge.inDays} days'));
    });

    /// A clock that has moved makes every age comparison meaningless, and the
    /// cost of getting it wrong is deleting unsynced work.
    test('a future timestamp suspends the age rule entirely', () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(
        op('ancient', age: SyncQueue.maxOperationAge + const Duration(days: 1)),
      );
      expect(await storedEntityIds(), isEmpty);

      await queue.enqueue(op('tomorrow', age: const Duration(days: -1)));
      await queue.enqueue(
        op('ancient2', age: SyncQueue.maxOperationAge + const Duration(days: 1)),
      );

      expect(await storedEntityIds(), contains('ancient2'));
    });

    test('the size cap keeps the newest and reports the overflow', () async {
      var dropped = 0;
      SyncQueue.onEvicted = (n, _) => dropped += n;

      final queue = await SyncQueue().init();
      for (var i = 0; i < SyncQueue.maxOperations + 5; i++) {
        await queue.enqueue(op('e$i', age: Duration(seconds: 1000 - i)));
      }

      final stored = await storedEntityIds();
      expect(stored.length, SyncQueue.maxOperations);
      expect(stored, isNot(contains('e0')));
      expect(stored, contains('e${SyncQueue.maxOperations + 4}'));
      expect(dropped, 5);
    });
  });
}
