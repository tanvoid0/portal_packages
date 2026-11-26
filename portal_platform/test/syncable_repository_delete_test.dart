import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Deleting an entity whose create the server may already have: the two only
/// cancel out while no push of the create has started.
class _FakeApi extends ApiClient {
  final rows = <String>{};

  /// Requests in the order the server applied them.
  final log = <String>[];

  /// Keeps the next POST in flight until completed; [parked] fires once it is.
  Completer<void>? hold;
  final parked = Completer<void>();

  /// The next POST fails before anything is stored.
  bool failPost = false;

  /// The next POST is stored, but its response never arrives.
  bool loseResponse = false;

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async =>
      [for (final id in rows) {'id': id}];

  @override
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final held = hold;
    if (held != null) {
      hold = null;
      parked.complete();
      await held.future;
    }
    if (failPost) {
      failPost = false;
      throw ApiException.networkFailure();
    }
    final id = (body as Map)['id'] as String;
    log.add('POST $id');
    rows.add(id);
    if (loseResponse) {
      loseResponse = false;
      throw ApiException.networkFailure();
    }
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final id = endpoint.split('/').last;
    log.add('DELETE $id');
    if (!rows.remove(id)) throw ApiException('Not found', 404);
  }
}

/// Signals once a delete is queued, so a held POST is released only after the
/// delete has been merged with it.
class _Queue extends SyncQueue {
  final deleteQueued = Completer<void>();

  @override
  Future<String?> enqueueWith(
    SyncOperation op, {
    Future<void> Function(DatabaseExecutor txn)? alsoWrite,
    Map<String, dynamic>? Function(SyncOperationType effective)? dataFor,
  }) async {
    final id =
        await super.enqueueWith(op, alsoWrite: alsoWrite, dataFor: dataFor);
    if (op.type == SyncOperationType.delete) deleteQueued.complete();
    return id;
  }
}

class _Repo extends SyncableRepository<String> {
  _Repo(this.api, this.syncQueue, this.connectivity);

  @override
  final ApiClient api;
  @override
  final SyncQueue syncQueue;
  @override
  final ConnectivityService connectivity;

  @override
  String get entityType => 'item';
  @override
  String get cacheKey => 'test_items';
  @override
  String get apiBasePath => '/items';
  @override
  String fromJson(Map<String, dynamic> json) => json['id'] as String;
  @override
  Map<String, dynamic> toJson(String id) => {'id': id};
  @override
  String getId(String id) => id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _FakeApi api;
  late _Queue queue;
  late ConnectivityService net;
  late _Repo repo;

  setUp(() async {
    await PortalDatabase.resetForTest();
    PortalDatabase.overrideFilePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = _FakeApi();
    queue = _Queue();
    await queue.init();
    net = ConnectivityService();
    repo = _Repo(api, queue, net);
  });

  Future<void> expectGone(List<String> requests) async {
    expect(api.log, requests);
    expect(api.rows, isEmpty);
    expect(await queue.getByEntityType('item'), isEmpty);
  }

  /// Deletes 'a' while the POST that [push] starts is held, then lets it land.
  Future<void> deleteDuring(Future<void> Function() push) async {
    final release = api.hold = Completer<void>();
    final pushing = push();
    await api.parked.future;
    final deleting = repo.delete('a');
    await queue.deleteQueued.future;
    // Room for a DELETE that does not wait its turn to go out early.
    await pumpEventQueue();
    release.complete();
    await Future.wait([pushing, deleting]);

    await expectGone(['POST a', 'DELETE a']);
  }

  test('a delete while save() is POSTing is sent after the POST', () async {
    await deleteDuring(() => repo.save('a'));
  });

  test('a delete while sync() replays the create is sent after it', () async {
    net.reportReachable(false);
    await repo.save('a');
    net.reportReachable(true);

    await deleteDuring(repo.sync);
  });

  test('a delete after a lost create response is still sent', () async {
    api.loseResponse = true;
    await repo.save('a');
    await repo.delete('a');

    await expectGone(['POST a', 'DELETE a']);
  });

  test('a create and delete made offline send nothing', () async {
    net.reportReachable(false);
    await repo.save('a');
    await repo.delete('a');
    net.reportReachable(true);
    await repo.sync();

    await expectGone([]);
  });

  test('an edit keeps a tried create tried; its replayed 404 is not a refusal',
      () async {
    var rejected = 0;
    SyncFeedback.onRejected = (_, n) => rejected += n;
    addTearDown(() => SyncFeedback.onRejected = null);

    api.failPost = true;
    await repo.save('a');
    net.reportReachable(false);
    await repo.save('a');
    await repo.delete('a');
    net.reportReachable(true);
    await repo.sync();

    await expectGone(['DELETE a']);
    expect(rejected, 0);
  });
}
