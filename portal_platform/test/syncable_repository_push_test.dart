import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pushing a create the server has not confirmed: an edit made on top of it,
/// and the replay that falls back to an update.
class _Item {
  const _Item(this.id, this.name);
  final String id;
  final String name;
}

/// Answers like the real server: 409 for a taken id, 400 for `id` on an update
/// body, 404 for an update of an unknown id.
class _FakeApi extends ApiClient {
  final rows = <String, String>{};
  final puts = <Map<String, dynamic>>[];

  /// Statuses the next POSTs fail with, before anything is stored.
  final postErrors = <int>[];

  /// The next POST is stored, but its response never arrives.
  bool loseResponse = false;

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async =>
      [for (final r in rows.entries) {'id': r.key, 'name': r.value}];

  @override
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    if (postErrors.isNotEmpty) {
      throw ApiException('post failed', postErrors.removeAt(0));
    }
    final id = (body as Map)['id'] as String;
    if (rows.containsKey(id)) throw ApiException('Already exists', 409);
    rows[id] = body['name'] as String;
    if (loseResponse) {
      loseResponse = false;
      throw ApiException('gateway timeout', 504);
    }
  }

  @override
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    puts.add(Map<String, dynamic>.from(body as Map));
    if (body.containsKey('id')) throw ApiException('id should not exist', 400);
    final id = endpoint.split('/').last;
    if (!rows.containsKey(id)) throw ApiException('Not found', 404);
    rows[id] = body['name'] as String;
  }
}

class _Repo extends SyncableRepository<_Item> {
  _Repo(this._api, this._queue);
  final _FakeApi _api;
  final SyncQueue _queue;

  @override
  String get entityType => 'item';
  @override
  String get cacheKey => 'test_items';
  @override
  String get apiBasePath => '/items';
  @override
  _Item fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as String, json['name'] as String);
  @override
  Map<String, dynamic> toJson(_Item e) => {'id': e.id, 'name': e.name};
  @override
  Map<String, dynamic> toWireJson(_Item e, {required bool isCreate}) =>
      {if (isCreate) 'id': e.id, 'name': e.name};
  @override
  String getId(_Item e) => e.id;

  @override
  ApiClient get api => _api;
  @override
  ConnectivityService get connectivity => ConnectivityService();
  @override
  SyncQueue get syncQueue => _queue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _FakeApi api;
  late SyncQueue queue;
  late _Repo repo;

  setUp(() async {
    await PortalDatabase.resetForTest();
    PortalDatabase.overrideFilePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = _FakeApi();
    queue = await SyncQueue().init();
    repo = _Repo(api, queue);
  });

  const first = _Item('a', 'first');
  const edited = _Item('a', 'edited');

  test('an edit while the create is still queued keeps it a create', () async {
    api.postErrors.addAll([500, 500]);
    await repo.save(first);
    await repo.save(edited);

    final op = (await queue.getByEntityType('item')).single;
    expect(op.type, SyncOperationType.create);
    expect(op.data, {'id': 'a', 'name': 'edited'});

    await repo.sync();
    expect(api.rows, {'a': 'edited'});
    expect(await queue.getByEntityType('item'), isEmpty);
  });

  test('an edit after a lost create response still reaches the server',
      () async {
    api.loseResponse = true;
    await repo.save(first);
    await repo.save(edited);

    expect(api.rows, {'a': 'edited'});
    expect(await queue.getByEntityType('item'), isEmpty);
  });

  test('replaying a create the server already has sends an update body',
      () async {
    api.loseResponse = true;
    await repo.save(first);
    await repo.sync();

    expect(api.puts, [
      {'name': 'first'},
    ]);
    expect(await queue.getByEntityType('item'), isEmpty);
  });

  test('a replayed create: POST 5xx then PUT 404 stays queued', () async {
    api.postErrors.addAll([500, 500]);
    await repo.save(first);
    await repo.sync();

    final op = (await queue.getByEntityType('item')).single;
    expect(op.type, SyncOperationType.create);
  });
}
