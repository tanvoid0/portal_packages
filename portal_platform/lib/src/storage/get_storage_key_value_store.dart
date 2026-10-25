import 'package:get_storage/get_storage.dart';

import 'portal_key_value_store.dart';

/// [PortalKeyValueStore] over a GetStorage box — the default, and what every
/// app that still passes a raw box gets through [PortalBootstrap].
class GetStorageKeyValueStore implements PortalKeyValueStore {
  GetStorageKeyValueStore(this._box);

  final GetStorage _box;

  @override
  T? read<T>(String key) => _box.read<T>(key);

  @override
  Future<void> write(String key, Object? value) => _box.write(key, value);

  @override
  Future<void> remove(String key) => _box.remove(key);
}
