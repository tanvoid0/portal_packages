import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'connectivity_service.dart';
import 'sync_queue.dart';
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
    _retryDelay = _minRetryDelay;
    syncAll();
  }

  /// Backoff schedule for a queue the server would not take.
  ///
  /// Reconnect covers "the network came back", but not "the network is fine
  /// and the server is failing": a 5xx used to park the queue until the next
  /// app launch, however long that was. Doubling from 30s to 15m keeps a
  /// short outage nearly invisible without hammering a struggling server.
  static const Duration _minRetryDelay = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(minutes: 15);
  Duration _retryDelay = _minRetryDelay;
  Timer? _retryTimer;

  /// Schedule another attempt when work is still queued after a cycle.
  ///
  /// Deliberately not scheduled while offline: reconnect already wakes the
  /// queue, and a timer firing into an interface that is down only burns the
  /// request timeout.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!Get.isRegistered<SyncQueue>()) return;
    if (Get.find<SyncQueue>().pendingCount.value == 0) {
      _retryDelay = _minRetryDelay;
      return;
    }
    if (Get.isRegistered<ConnectivityService>() &&
        !Get.find<ConnectivityService>().isOnline) {
      return;
    }
    debugPrint('[SyncManager] ${_retryDelay.inSeconds}s until next attempt');
    _retryTimer = Timer(_retryDelay, syncAll);
    final next = _retryDelay * 2;
    _retryDelay = next > _maxRetryDelay ? _maxRetryDelay : next;
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
      var failed = 0;
      for (final repo in _repositories) {
        // Isolate per repository: one unreadable queue or dead endpoint must
        // not skip every repository behind it in the cycle.
        try {
          await repo.sync();
        } catch (e) {
          failed++;
          debugPrint('[SyncManager] Sync error in ${repo.runtimeType}: $e');
        }
      }
      lastSyncAt.value = DateTime.now();
      debugPrint(
        '[SyncManager] Sync completed at ${lastSyncAt.value}'
        '${failed > 0 ? ' ($failed of ${_repositories.length} failed)' : ''}',
      );
    } finally {
      isSyncing.value = false;
      _scheduleRetry();
    }
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      final connectivity = Get.find<ConnectivityService>();
      connectivity.removeReconnectListener(_onReconnect);
    } catch (_) {}
    _repositories.clear();
    super.onClose();
  }
}
