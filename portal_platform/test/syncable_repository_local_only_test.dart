import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Item {
  const _Item(this.id, this.name);
  final String id;
  final String name;
}

/// A local-only client: any call that reaches the server fails the test.
class _LocalApi extends ApiClient {
  @override
  bool get isLocalOnly => true;
  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) =>
      throw StateError('server read in a local-only session');
  @override
  Future<dynamic> post(String endpoint, {dynamic body}) =>
      throw StateError('server write in a local-only session');
  @override
  Future<dynamic> put(String endpoint, {dynamic body}) =>
      throw StateError('server write in a local-only session');
  @override
  Future<dynamic> delete(String endpoint, {Map<String, String>? queryParams}) =>
      throw StateError('server write in a local-only session');
}

class _Repo extends SyncableRepository<_Item> {
  _Repo(this._api, this._queue);
  final ApiClient _api;
  final SyncQueue _queue;

  @override
  String get entityType => 'item';
  @override
  String get cacheKey => 'test_local_items';
  @override
  String get apiBasePath => '/items';
  @override
  _Item fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as String, json['name'] as String);
  @override
  Map<String, dynamic> toJson(_Item e) => {'id': e.id, 'name': e.name};
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

  late SyncQueue queue;
  late _Repo repo;

  setUp(() async {
    await PortalDatabase.resetForTest();
    PortalDatabase.overrideFilePath = inMemoryDatabasePath;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    queue = await SyncQueue().init();
    repo = _Repo(_LocalApi(), queue);
  });

  test('save, read, update and delete stay on the cache; nothing is queued',
      () async {
    expect(await repo.getAll(), isEmpty);

    await repo.save(const _Item('a', 'one'));
    await repo.save(const _Item('b', 'two'));
    await repo.save(const _Item('a', 'one edited'));
    expect((await repo.getAll()).map((e) => e.name), ['one edited', 'two']);
    expect((await repo.getById('b'))?.name, 'two');

    await repo.delete('a');
    expect((await repo.getAll()).map((e) => e.id), ['b']);

    expect(await queue.getByEntityType('item'), isEmpty);
    expect(repo.lastReadWasStale, isFalse);
    await repo.sync(); // must not throw or reach the server
  });
}
