abstract class LocalCache<T> {
  Future<void> save(T value);
  Future<T?> load();
  Future<void> clear();
}
