import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> write(String store, List<(String, String)> rows) =>
      PortalDatabase.transaction((txn) => PortalDatabase.writePayloads(
            txn,
            store,
            [for (final r in rows) (id: r.$1, payload: r.$2)],
          ));

  // The JSON list gave ordering for free; rows do not, and thirteen
  // repositories render straight from what readCache returns.
  test('rows come back in the order they were written', () async {
    await write('s', [('c', '3'), ('a', '1'), ('b', '2')]);
    expect(await PortalDatabase.readPayloads('s'), ['3', '1', '2']);

    await write('s', [('b', '2'), ('c', '3'), ('a', '1')]);
    expect(await PortalDatabase.readPayloads('s'), ['2', '3', '1']);
  });

  test('a write replaces the store, dropping rows no longer in the list',
      () async {
    await write('s', [('a', '1'), ('b', '2')]);
    await write('s', [('b', '2')]);
    expect(await PortalDatabase.readPayloads('s'), ['2']);
  });

  test('stores do not see each other', () async {
    await write('one', [('a', '1')]);
    await write('two', [('a', '9')]);
    expect(await PortalDatabase.readPayloads('one'), ['1']);
    expect(await PortalDatabase.readPayloads('two'), ['9']);
  });

  // The whole reason cache and queue share a database. If the cache write
  // fails, the mutation it belonged to must not be left queued on its own,
  // and vice versa: half of a save is worse than none of it.
  group('enqueueWith', () {
    SyncOperation op(String id) => SyncOperation(
          entityType: 'recipe',
          entityId: id,
          type: SyncOperationType.create,
          data: {'title': id},
        );

    test('commits the cache write and the queued mutation together', () async {
      final queue = await SyncQueue().init();

      final id = await queue.enqueueWith(
        op('a'),
        alsoWrite: (txn) => PortalDatabase.writePayloads(
            txn, 'recipes', [(id: 'a', payload: '{"title":"a"}')]),
      );

      expect(id, isNotNull);
      expect(queue.pendingCount.value, 1);
      expect(await PortalDatabase.readPayloads('recipes'), isNotEmpty);
    });

    test('rolls both halves back when the cache write throws', () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(op('already-here'));

      await expectLater(
        queue.enqueueWith(op('a'),
            alsoWrite: (_) async => throw StateError('disk')),
        throwsA(isA<StateError>()),
      );

      expect(await PortalDatabase.readPayloads('recipes'), isEmpty);
      expect(
        (await queue.getByEntityType('recipe')).map((o) => o.entityId),
        ['already-here'],
        reason: 'a failed transaction must not leave the mutation queued',
      );
      expect(queue.pendingCount.value, 1);
    });

    // Dedup can fold the new operation into a pending one under *that* one's
    // id. A caller that pushed the change and then removed its own id would
    // leave the merged operation behind to be replayed.
    test('reports the id of the operation that was actually stored', () async {
      final queue = await SyncQueue().init();
      // Merging only happens for a caller that can re-serialise, so this is
      // the path a SyncableRepository write takes.
      final first =
          await queue.enqueueWith(op('a'), dataFor: (t) => {'shape': t.name});

      final merged = await queue.enqueueWith(
        SyncOperation(
          entityType: 'recipe',
          entityId: 'a',
          type: SyncOperationType.update,
          data: {'title': 'a2'},
        ),
        dataFor: (t) => {'shape': t.name},
      );

      expect(merged, first);
      await queue.remove(merged!);
      expect(queue.pendingCount.value, 0);
    });

    // Found by the end-to-end test against a real server: merging an update
    // into a pending create keeps the create, so a body serialised for an
    // update gets POSTed. The server whitelists per verb, answers 400, and a
    // 400 is permanent — the operation is dropped and the entity is lost.
    test('re-serialises the payload for the verb that will be sent', () async {
      final queue = await SyncQueue().init();
      await queue.enqueueWith(op('a'),
          dataFor: (t) => {'shape': t.name});

      await queue.enqueueWith(
        SyncOperation(
          entityType: 'recipe',
          entityId: 'a',
          type: SyncOperationType.update,
          data: {'shape': 'update'},
        ),
        dataFor: (t) => {'shape': t.name},
      );

      final pending = (await queue.getByEntityType('recipe')).single;
      expect(pending.type, SyncOperationType.create);
      expect(pending.data, {'shape': 'create'});
    });

    // The outbox path: mutations carry their action in the payload, so a
    // merged create+update replays as an update for an id the server has
    // never seen. Three of the four batch handlers upsert it; the notes one
    // rejects it and the note is gone. Keeping both, in order, replays the
    // create first and the update against something that exists.
    test('keeps both when it cannot re-serialise for the surviving verb',
        () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(op('a'));
      await queue.enqueue(SyncOperation(
        entityType: 'recipe',
        entityId: 'a',
        type: SyncOperationType.update,
        data: {'title': 'a2'},
      ));

      final pending = await queue.getByEntityType('recipe');
      expect(pending.map((o) => o.type),
          [SyncOperationType.create, SyncOperationType.update],
          reason: 'oldest first: the create has to land before the update');
      expect(pending.last.data, {'title': 'a2'});
    });

    // Cancelling still applies — it needs no re-serialisation, because there
    // is nothing left to send.
    test('still cancels a create that is deleted before it is pushed',
        () async {
      final queue = await SyncQueue().init();
      await queue.enqueue(op('a'));
      await queue.enqueue(SyncOperation(
        entityType: 'recipe',
        entityId: 'a',
        type: SyncOperationType.delete,
      ));

      expect(await queue.getByEntityType('recipe'), isEmpty);
    });

    // create + delete cancel out, so there is nothing left to remove and the
    // caller must not be handed an id that no longer exists.
    test('reports null when the merge cancels the operation out', () async {
      final queue = await SyncQueue().init();
      await queue.enqueueWith(op('a'));

      final id = await queue.enqueueWith(SyncOperation(
        entityType: 'recipe',
        entityId: 'a',
        type: SyncOperationType.delete,
      ));

      expect(id, isNull);
      expect(queue.pendingCount.value, 0);
    });
  });
}
