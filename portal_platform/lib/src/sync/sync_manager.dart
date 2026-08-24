import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'connectivity_service.dart';
import 'syncable_repository.dart';

/// Central orchestrator that keeps all registered repositories in sync
/// with the server.
///
/// [SyncManager] listens to [ConnectivityService] and, whenever the
/// device transitions from offline to online, calls [syncAll] to push
/// queued local changes and pull fresh data for every registered
/// [Syncable] (typically [SyncableRepository] subclasses).
///
/// ## Boot order
///
/// Services must be registered in this order because each depends on
/// the previous one:
///
/// ```dart
/// // 1. Connectivity monitor
/// await Get.putAsync(() => ConnectivityService().init());
///
/// // 2. Persistent operation queue
/// await Get.putAsync(() => SyncQueue().init());
///
/// // 3. Sync manager — register repos, then init
/// final syncManager = SyncManager();
/// syncManager.register(RecipeRepository());
/// syncManager.register(CookbookRepository());
/// await Get.putAsync(() => syncManager.init());
/// ```
///
/// ## Observable state
///
/// * [isSyncing] — `true` while a sync cycle is running.  Useful for
///   showing a progress indicator in the UI.
/// * [lastSyncAt] — timestamp of the last successful full sync.
///
/// ```dart
/// Obx(() {
///   if (Get.find<SyncManager>().isSyncing.value) {
///     return const LinearProgressIndicator();
///   }
///   return const SizedBox.shrink();
/// })
/// ```
class SyncManager extends GetxService {
  final _repositories = <Syncable>[];

  /// Whether a sync cycle is currently in progress.
  final isSyncing = false.obs;

  /// Timestamp of the last successful [syncAll] completion.
  final lastSyncAt = Rxn<DateTime>();

  /// Register a [Syncable] (usually a [SyncableRepository]) to be
  /// included in every [syncAll] cycle.
  ///
  /// Call this **before** [init] so the initial sync covers all repos.
  void register(Syncable repo) {
    _repositories.add(repo);
  }

  /// Subscribe to [ConnectivityService] reconnect events and, if the
  /// device is already online, kick off the initial sync.
  ///
  /// Returns itself so it can be used with [Get.putAsync].
  Future<SyncManager> init() async {
    try {
      final connectivity = Get.find<ConnectivityService>();
      connectivity.addReconnectListener(_onReconnect);

      if (connectivity.isOnline) {
        syncAll();
      }
    } catch (e) {
      debugPrint('[SyncManager] Init error: $e');
    }
    return this;
  }

  void _onReconnect() {
    debugPrint('[SyncManager] Device reconnected — syncing all');
    syncAll();
  }

  /// Push pending changes and pull fresh data for **every** registered
  /// repository.
  ///
  /// Safe to call multiple times concurrently — if a sync is already
  /// running the duplicate call is silently ignored.
  Future<void> syncAll() async {
    if (isSyncing.value) return;
    isSyncing.value = true;

    try {
      for (final repo in _repositories) {
        await repo.sync();
      }
      lastSyncAt.value = DateTime.now();
      debugPrint('[SyncManager] Sync completed at ${lastSyncAt.value}');
    } catch (e) {
      debugPrint('[SyncManager] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  @override
  void onClose() {
    try {
      final connectivity = Get.find<ConnectivityService>();
      connectivity.removeReconnectListener(_onReconnect);
    } catch (_) {}
    _repositories.clear();
    super.onClose();
  }
}
