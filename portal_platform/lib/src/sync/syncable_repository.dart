import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../storage/user_storage_scope.dart';
import 'connectivity_service.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// Non-generic interface used by [SyncManager] to trigger sync on
/// repositories without caring about the entity type parameter.
abstract class Syncable {
  /// Push pending local changes, then pull fresh data from the server.
  Future<void> sync();
}

/// App-supplied feedback for the offline-first write path.
///
/// The repository layer cannot import UI, and a write that quietly lands in
/// [SyncQueue] instead of on the server is indistinguishable from one that
/// did nothing — which is exactly how it read to users. These hooks let an
/// app render that state (a toast, a banner) without the sync layer knowing
/// what a toast is. Unset by default, so nothing changes for apps that do not
/// opt in.
class SyncFeedback {
  SyncFeedback._();

  /// Called after a write is queued for later replay rather than pushed.
  ///
  /// [entityType] is the repository's own [SyncableRepository.entityType];
  /// [pendingCount] is the queue depth across all entity types afterwards.
  static void Function(String entityType, int pendingCount)? onQueued;

  /// Called after a sync cycle drains at least one queued operation.
  /// [pushed] is how many operations were accepted by the server.
  static void Function(int pushed)? onPushed;

  /// Called when the server *rejected* queued operations outright and they
  /// were dropped. This is the one case where a local change is lost, so it
  /// must never be silent.
  static void Function(String entityType, int dropped)? onRejected;
}

/// True when [error] means "the server refused this change" rather than "the
/// server was not reachable".
///
/// A refused mutation must be dropped: replaying it produces the same refusal
/// on every sync, forever, and it blocks nothing behind it from being noticed.
/// The excluded statuses are the ones that are really transient —
/// 401/403 clear after a token refresh or re-auth, 408 and 429 are explicit
/// "try again" answers — and offline (status 0) is never permanent.
bool isPermanentSyncFailure(Object error) {
  if (error is! ApiException) return false;
  if (error.statusCode == 401 ||
      error.statusCode == 403 ||
      error.statusCode == 408 ||
      error.statusCode == 429) {
    return false;
  }
  return error.statusCode >= 400 && error.statusCode < 500;
}

/// Abstract **offline-first** repository for **simple** entities stored in
/// [SharedPreferences].
///
/// **Experimental:** Portal Task and similar apps with rich local stores
/// should use [EntitySyncOutbox] and batch `/sync` endpoints instead.
///
/// `SyncableRepository` provides a Firebase-like data layer:
///
///  * **Reads** always attempt the server first when online, falling
///    back to the local [SharedPreferences] cache when offline or on
///    network error.
///  * **Writes** update the local cache **immediately** (so the UI
///    reflects the change with zero latency), then push to the server.
///    If the push fails the mutation is saved in [SyncQueue] and
///    retried the next time [sync] runs.
///  * **Sync** is triggered automatically on app startup and whenever
///    [ConnectivityService] detects a reconnection, courtesy of
///    [SyncManager].
///
/// ## Subclassing
///
/// To add offline-first support for a new entity, extend this class
/// and provide the six required overrides:
///
/// ```dart
/// class RecipeRepository extends SyncableRepository<Recipe> {
///   @override String get entityType  => 'recipe';
///   @override String get cacheKey    => 'portal_recipe_recipes';
///   @override String get apiBasePath => '$_moduleUrl/recipes';
///
///   @override Recipe fromJson(Map<String, dynamic> j) => Recipe.fromJson(j);
///   @override Map<String, dynamic> toJson(Recipe r) => r.toJson();
///   @override String getId(Recipe r) => r.id;
///
///   // optional: app-specific URL building
///   String get _moduleUrl => PortalApiPaths.module(api.baseUrl, 'recipe');
/// }
/// ```
///
/// Then register the repository with [SyncManager] in your `main()`:
///
/// ```dart
/// final syncManager = SyncManager();
/// syncManager.register(RecipeRepository());
/// await Get.putAsync(() => syncManager.init());
/// ```
///
/// ## Dependencies
///
/// The repository resolves [ApiClient], [ConnectivityService], and
/// [SyncQueue] via `Get.find()`.  Make sure all three are registered
/// **before** any repository method is called (see [SyncManager] for
/// the recommended boot order).
///
/// ## Conflict resolution
///
/// During [sync], the server pull honours pending local operations:
///
///  * Entities with un-pushed changes keep their **local** version.
///  * Entities with no pending operations are overwritten by the
///    server version (last-write-wins).
///  * Locally-created entities that don't exist on the server yet are
///    preserved until their create operation succeeds.
abstract class SyncableRepository<T> implements Syncable {
  // ─── Configuration (subclass must override) ─────────────────────────

  /// Short, unique name for this entity type (e.g. `'recipe'`,
  /// `'cookbook'`).  Used as the key prefix in [SyncQueue].
  String get entityType;

  /// [SharedPreferences] key under which the local cache is stored.
  ///
  /// Choose a key that is unique across the entire app to avoid
  /// collisions (e.g. `'portal_recipe_recipes'`).
  String get cacheKey;

  /// Full URL of the entity collection endpoint.
  ///
  /// Example: `https://server.com/api/recipe/recipes`.
  ///
  /// Individual-entity endpoints are derived by appending `/$id`.
  String get apiBasePath;

  /// Deserialise a single entity from a JSON map.
  T fromJson(Map<String, dynamic> json);

  /// Serialise a single entity to a JSON map.
  Map<String, dynamic> toJson(T entity);

  /// Return the unique, stable identifier of [entity].
  String getId(T entity);

  /// JSON body sent to the server for a create/update request.
  ///
  /// Defaults to [toJson]. Override when the wire DTO is narrower than the
  /// cached representation — e.g. server-managed fields like `createdAt`
  /// that a strict/whitelisting validator on the server rejects if present,
  /// or fields only valid on one of create/update.
  Map<String, dynamic> toWireJson(T entity, {required bool isCreate}) =>
      toJson(entity);

  /// Query parameters applied to every **collection** read (`getAll` and the
  /// pull half of [sync]), for repositories that own only a slice of a shared
  /// endpoint — e.g. `{'source': 'recipe'}` on a shared shopping list.
  ///
  /// Not applied to single-entity reads or writes, which are addressed by id.
  Map<String, String>? get listQueryParams => null;

  /// Effective cache key including the signed-in user id when available.
  String get scopedCacheKey => UserStorageScope.scopeKey(cacheKey);

  // ─── Dependencies (via GetX service locator) ────────────────────────

  /// Authenticated HTTP client for server communication.
  ApiClient get api => Get.find<ApiClient>();

  /// Reactive connectivity monitor.
  ConnectivityService get connectivity => Get.find<ConnectivityService>();

  /// Persistent queue of un-pushed mutations.
  SyncQueue get syncQueue => Get.find<SyncQueue>();

  // ─── Public CRUD ────────────────────────────────────────────────────

  /// Fetch **all** entities of this type.
  ///
  /// * **Online:** fetches from the server, updates the local cache,
  ///   and returns the server list.
  /// * **Offline / error:** returns whatever is in the local cache.
  Future<List<T>> getAll() async {
    if (connectivity.isOnline) {
      try {
        final data = await api.get(apiBasePath, queryParams: listQueryParams);
        final serverList = (data as List)
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final pendingOps = await syncQueue.getByEntityType(entityType);
        final merged = pendingOps.isEmpty
            ? serverList
            : _mergeWithPending(serverList, await readCache(), pendingOps);
        await writeCache(merged);
        _lastReadError = null;
        return merged;
      } on ApiException catch (e) {
        debugPrint('[$entityType] API fetch failed, using cache: $e');
        _lastReadError = e;
      } catch (e) {
        debugPrint('[$entityType] API fetch failed, using cache: $e');
        _lastReadError = ApiException('$e', -1);
      }
    } else {
      _lastReadError = ApiException.networkFailure();
    }
    return readCache();
  }

  /// Why the last [getAll] fell back to the cache, or `null` if it returned
  /// live server data.
  ///
  /// [getAll] deliberately does not throw — an offline read returning cached
  /// data is the feature, not a failure. But it swallowed *server* failures
  /// the same way, so during an outage the app served stale data with no
  /// indication and every caller's error handler was unreachable. Read this
  /// straight after awaiting [getAll] to tell the three cases apart:
  /// live (`null`), offline (`isOffline`), and the server refusing or
  /// failing (anything else).
  ApiException? get lastReadError => _lastReadError;
  ApiException? _lastReadError;

  /// True when the last [getAll] served cached data instead of live data.
  bool get lastReadWasStale => _lastReadError != null;

  /// Fetch a single entity by [id].
  ///
  /// Tries the server first (if online), then falls back to the local
  /// cache.  Returns `null` if the entity is not found anywhere.
  Future<T?> getById(String id) async {
    if (connectivity.isOnline) {
      try {
        final data = await api.get('$apiBasePath/$id');
        return fromJson(Map<String, dynamic>.from(data));
      } catch (_) {}
    }
    final all = await readCache();
    try {
      return all.firstWhere((e) => getId(e) == id);
    } catch (_) {
      return null;
    }
  }

  /// Create or update an entity (upsert).
  ///
  /// 1. The **local cache is updated immediately** so the UI can
  ///    reflect the change without waiting for the network.
  /// 2. If the device is online the change is pushed to the server
  ///    right away.
  /// 3. If the push fails — or the device is offline — a
  ///    [SyncOperation] is enqueued and will be retried on the next
  ///    [sync] cycle.
  ///
  /// The method determines create vs. update by checking whether an
  /// entity with the same ID already exists in the local cache.
  Future<void> save(T entity) async {
    final all = await readCache();
    final idx = all.indexWhere((e) => getId(e) == getId(entity));
    final isCreate = idx < 0;

    if (isCreate) {
      all.add(entity);
    } else {
      all[idx] = entity;
    }
    await writeCache(all);

    final opType =
        isCreate ? SyncOperationType.create : SyncOperationType.update;

    if (connectivity.isOnline) {
      try {
        if (isCreate) {
          await api.post(apiBasePath, body: toWireJson(entity, isCreate: true));
        } else {
          await api.put(
            '$apiBasePath/${getId(entity)}',
            body: toWireJson(entity, isCreate: false),
          );
        }
        return;
      } catch (e) {
        debugPrint('[$entityType] API save failed, queueing: $e');
      }
    }

    await syncQueue.enqueue(SyncOperation(
      entityType: entityType,
      entityId: getId(entity),
      type: opType,
      data: toWireJson(entity, isCreate: isCreate),
    ));
    await _reportQueued();
  }

  /// Delete an entity by [id].
  ///
  /// The entity is **removed from the cache immediately**.  If the
  /// server call fails the delete is queued for later retry.
  Future<void> delete(String id) async {
    final all = await readCache();
    all.removeWhere((e) => getId(e) == id);
    await writeCache(all);

    if (connectivity.isOnline) {
      try {
        await api.delete('$apiBasePath/$id');
        return;
      } catch (e) {
        debugPrint('[$entityType] API delete failed, queueing: $e');
      }
    }

    await syncQueue.enqueue(SyncOperation(
      entityType: entityType,
      entityId: id,
      type: SyncOperationType.delete,
    ));
    await _reportQueued();
  }

  /// Notify [SyncFeedback.onQueued] that a write is waiting to be pushed.
  ///
  /// Never lets a UI callback break the write it is reporting on.
  Future<void> _reportQueued() async {
    final cb = SyncFeedback.onQueued;
    if (cb == null) return;
    try {
      cb(entityType, syncQueue.pendingCount.value);
    } catch (e) {
      debugPrint('[$entityType] SyncFeedback.onQueued threw: $e');
    }
  }

  // ─── Sync ───────────────────────────────────────────────────────────

  /// Push all pending operations, then pull fresh data from the server.
  ///
  /// This is called automatically by [SyncManager] on startup and on
  /// reconnect.  It can also be invoked manually (e.g. pull-to-refresh).
  ///
  /// No-ops silently when the device is offline.
  @override
  Future<void> sync() async {
    if (!connectivity.isOnline) return;

    await _pushPending();
    await _pullFromServer();
  }

  /// Replay every queued [SyncOperation] for this [entityType] against
  /// the server, removing each one on success.
  ///
  /// Replay is **at-least-once**: a create whose response was lost still
  /// committed server-side, so a failed create is retried as an update rather
  /// than looping on a duplicate-key error forever. A create that genuinely
  /// never landed gets a 404 from that update and stays queued.
  ///
  /// Updates and deletes that 404 are dropped — the entity is gone
  /// server-side, so there is nothing left to replay against.
  Future<void> _pushPending() async {
    final ops = await syncQueue.getByEntityType(entityType);
    if (ops.isEmpty) return;

    debugPrint('[$entityType] Pushing ${ops.length} pending operations');

    var pushed = 0;
    var rejected = 0;
    for (final op in ops) {
      try {
        switch (op.type) {
          case SyncOperationType.create:
            await _pushCreate(op);
          case SyncOperationType.update:
            await api.put('$apiBasePath/${op.entityId}', body: op.data);
          case SyncOperationType.delete:
            await api.delete('$apiBasePath/${op.entityId}');
        }
        await syncQueue.remove(op.id);
        pushed++;
      } catch (e) {
        debugPrint('[$entityType] Failed to push ${op.type.name} '
            'for ${op.entityId}: $e');
        // Nothing reached the server, so the rest of the queue will fail the
        // same way. Stop instead of burning a 30s timeout per operation.
        if (e is ApiException && e.isOffline) break;
        if (isPermanentSyncFailure(e)) {
          // The server will refuse this on every future sync too. Left queued
          // it retries forever, and the pending count never returns to zero —
          // which reads to the user as "syncing" that never finishes.
          await syncQueue.remove(op.id);
          rejected++;
        }
      }
    }

    _notify(
      () => pushed > 0 ? SyncFeedback.onPushed?.call(pushed) : null,
      'onPushed',
    );
    _notify(
      () => rejected > 0
          ? SyncFeedback.onRejected?.call(entityType, rejected)
          : null,
      'onRejected',
    );
  }

  /// Runs a [SyncFeedback] callback without letting it break the sync cycle.
  void _notify(void Function() body, String name) {
    try {
      body();
    } catch (e) {
      debugPrint('[$entityType] SyncFeedback.$name threw: $e');
    }
  }

  /// POST a queued create, falling back to PUT when the server already has
  /// the entity — the case where an earlier push committed but its response
  /// never reached the device.
  Future<void> _pushCreate(SyncOperation op) async {
    Object postError;
    try {
      await api.post(apiBasePath, body: op.data);
      return;
    } catch (e) {
      postError = e;
    }
    try {
      await api.put('$apiBasePath/${op.entityId}', body: op.data);
    } on ApiException catch (e) {
      // A 404 here means the entity really is absent server-side, so the POST
      // is still the operation that matters and its error is the real cause.
      // Reporting the 404 instead hid it — a create the server had *refused*
      // (a rejected field, say) looked identical to one that simply had not
      // landed yet, so it stayed queued and retried forever.
      if (e.statusCode == 404) throw postError;
      rethrow;
    }
  }

  /// Fetch the full entity list from the server and merge it into the
  /// local cache.
  ///
  /// Merge strategy:
  ///  * Entities with **no** pending local operations → overwritten by
  ///    the server version (last-write-wins).
  ///  * Entities with **pending** operations → the local version is
  ///    kept to avoid clobbering un-pushed changes.
  ///  * Locally-created entities that don't exist on the server yet →
  ///    preserved until their create operation succeeds.
  Future<void> _pullFromServer() async {
    try {
      final data = await api.get(apiBasePath, queryParams: listQueryParams);
      final serverList = (data as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final pendingOps = await syncQueue.getByEntityType(entityType);
      if (pendingOps.isEmpty) {
        await writeCache(serverList);
        return;
      }

      await writeCache(
        _mergeWithPending(serverList, await readCache(), pendingOps),
      );
    } catch (e) {
      debugPrint('[$entityType] Pull from server failed: $e');
    }
  }

  /// Merge a freshly-fetched [serverList] with [localCache], keeping the
  /// local version of any entity with a pending [SyncOperation] — used by
  /// both [getAll] and [_pullFromServer] so a server refresh can never
  /// clobber a write that hasn't synced yet.
  List<T> _mergeWithPending(
    List<T> serverList,
    List<T> localCache,
    List<SyncOperation> pendingOps,
  ) {
    final pendingIds = pendingOps.map((o) => o.entityId).toSet();
    final serverMap = {for (final e in serverList) getId(e): e};
    final merged = <T>[];

    for (final entry in serverMap.entries) {
      if (pendingIds.contains(entry.key)) {
        final local = localCache.where((e) => getId(e) == entry.key);
        merged.add(local.isNotEmpty ? local.first : entry.value);
      } else {
        merged.add(entry.value);
      }
    }

    for (final op in pendingOps) {
      if (op.type == SyncOperationType.create &&
          !serverMap.containsKey(op.entityId)) {
        final local = localCache.where((e) => getId(e) == op.entityId);
        if (local.isNotEmpty) merged.add(local.first);
      }
    }

    return merged;
  }

  // ─── Cache helpers ─────────────────────────────────────────────────

  /// Read the full entity list from the local [SharedPreferences]
  /// cache.  Returns an empty list if nothing is cached or the stored
  /// JSON is corrupt.
  Future<List<T>> readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(scopedCacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[$entityType] Cache read error: $e');
      return [];
    }
  }

  /// Overwrite the local cache with [items].
  Future<void> writeCache(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      scopedCacheKey,
      jsonEncode(items.map((e) => toJson(e)).toList()),
    );
  }
}
