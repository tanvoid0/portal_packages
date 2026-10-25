/// Minimal key-value surface the platform's device-security prefs sit on.
///
/// [DeviceSecurityPreferences] used to be typed directly on `GetStorage`, which
/// forced every host app onto GetStorage for that one toggle. This interface is
/// the slice they actually use — a synchronous typed [read], an async [write]
/// and [remove] — so an app can back the prefs with any store (GetStorage via
/// [GetStorageKeyValueStore], `shared_preferences`, a fake in tests) without the
/// platform depending on which one.
abstract interface class PortalKeyValueStore {
  /// The value at [key], or null if absent. Synchronous, like GetStorage.
  T? read<T>(String key);

  Future<void> write(String key, Object? value);

  Future<void> remove(String key);
}
