import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The newest-wins half of `_mergeWithPending`: a refresh against an entity
/// with a queued local write keeps the local copy unless the server stamp
/// says the server copy was modified after this device wrote its own.
class _Item {
  const _Item(this.id, this.name, {this.updatedAt});
  final String id;
  final String name;
  final DateTime? updatedAt;
}

class _FakeApi extends ApiClient {
  List<Map<String, dynamic>> response = const [];
  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async =>
      response;
}

class _Repo extends SyncableRepository<_Item> {
  _Repo(this._api, this._queue, {this.stamped = true, this.duringMerge});
  final _FakeApi _api;
  final SyncQueue _queue;
  final bool stamped;

  /// Runs once, inside the merge — after the queue snapshot, before the
  /// drop — to stand in for a save that lands mid-refresh.
  Future<void> Function()? duringMerge;

  @override
  Future<List<_Item>> readCache() async {
    final hook = duringMerge;
    duringMerge = null;
    if (hook != null) await hook();
    return super.readCache();
  }

  @override
  String get entityType => 'item';
  @override
  String get cacheKey => 'test_items';
  @override
  String get apiBasePath => '/items';
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item(
        json['id'] as String,
        json['name'] as String,
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
  @override
  Map<String, dynamic> toJson(_Item e) => {
        'id': e.id,
        'name': e.name,
        'updatedAt': e.updatedAt?.toIso8601String(),
      };
  @override
  String getId(_Item e) => e.id;
  @override
  DateTime? updatedAt(_Item e) => stamped ? e.updatedAt : null;

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

  setUp(() async {
    await PortalDatabase.resetForTest();
    PortalDatabase.overrideFilePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = _FakeApi();
    queue = await SyncQueue().init();
  });

  Future<void> queueUpdate(String id) => queue.enqueue(SyncOperation(
        id: 'op-$id',
        type: SyncOperationType.update,
        entityType: 'item',
        entityId: id,
        data: {'name': 'local'},
      ));

  Map<String, dynamic> server(String id, DateTime stamp) =>
      {'id': id, 'name': 'server', 'updatedAt': stamp.toIso8601String()};

  test('server copy older than the local write: local wins, op kept',
      () async {
    final repo = _Repo(api, queue);
    await repo.writeCache([const _Item('a', 'local')]);
    await queueUpdate('a');
    api.response = [server('a', DateTime.now().subtract(const Duration(hours: 1)))];

    final got = await repo.getAll();

    expect(got.single.name, 'local');
    expect(await queue.getByEntityType('item'), hasLength(1));
  });

  test('server copy newer than the local write: server wins, op dropped',
      () async {
    final repo = _Repo(api, queue);
    await repo.writeCache([const _Item('a', 'local')]);
    await queueUpdate('a');
    api.response = [server('a', DateTime.now().add(const Duration(hours: 1)))];

    final got = await repo.getAll();

    expect(got.single.name, 'server');
    expect(await queue.getByEntityType('item'), isEmpty);
    expect((await repo.readCache()).single.name, 'server');
  });

  test('a save that lands mid-merge is not dropped', () async {
    late _Repo repo;
    repo = _Repo(api, queue, duringMerge: () async {
      await repo.writeCache([const _Item('a', 'newer local')]);
      await queue.enqueue(SyncOperation(
        id: 'op-a2',
        type: SyncOperationType.update,
        entityType: 'item',
        entityId: 'a',
        data: {'name': 'newer local'},
      ));
    });
    await repo.writeCache([const _Item('a', 'local')]);
    await queueUpdate('a');
    api.response = [server('a', DateTime.now().add(const Duration(hours: 1)))];

    await repo.getAll();

    final ops = await queue.getByEntityType('item');
    expect(ops.single.data, {'name': 'newer local'});
  });

  test('a type without a stamp keeps the local copy unconditionally',
      () async {
    final repo = _Repo(api, queue, stamped: false);
    await repo.writeCache([const _Item('a', 'local')]);
    await queueUpdate('a');
    api.response = [server('a', DateTime.now().add(const Duration(hours: 1)))];

    final got = await repo.getAll();

    expect(got.single.name, 'local');
    expect(await queue.getByEntityType('item'), hasLength(1));
  });

  test('a pending delete does not resurrect from the server list', () async {
    final repo = _Repo(api, queue);
    await repo.writeCache([]);
    await queue.enqueue(SyncOperation(
      id: 'op-del',
      type: SyncOperationType.delete,
      entityType: 'item',
      entityId: 'a',
    ));
    api.response = [server('a', DateTime.now().add(const Duration(hours: 1)))];

    final got = await repo.getAll();

    expect(got, isEmpty);
    expect(await queue.getByEntityType('item'), hasLength(1));
  });
}
