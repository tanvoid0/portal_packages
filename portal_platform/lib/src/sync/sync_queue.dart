import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/user_storage_scope.dart';
import 'encrypted_sync_queue_codec.dart';
import 'sync_operation.dart';

/// Persistent, deduplicated queue of mutations waiting to be pushed to
/// the server.
///
/// All pending [SyncOperation]s are stored as a JSON array in
/// [SharedPreferences] under the key `portal_sync_queue`, so they
/// survive app restarts.
///
/// ## Deduplication
///
/// When a new operation targets an entity that **already** has a
/// pending operation, the two are merged automatically:
///
/// | Existing  | Incoming  | Result                                   |
/// |-----------|-----------|------------------------------------------|
/// | create    | update    | create with latest data                  |
/// | create    | delete    | **both removed** (never existed remotely) |
/// | update    | update    | update with latest data                  |
/// | update    | delete    | replaced by delete                       |
/// | *other*   | *any*     | replaced by incoming                     |
///
/// ## Initialisation
///
/// ```dart
/// await Get.putAsync(() => SyncQueue().init());
/// ```
///
/// ## Observable state
///
/// [pendingCount] is a reactive `RxInt` that UI widgets can observe to
/// show a badge or status indicator:
///
/// ```dart
/// Obx(() {
///   final pending = Get.find<SyncQueue>().pendingCount.value;
///   if (pending == 0) return const SizedBox.shrink();
///   return Badge(label: Text('$pending'));
/// })
/// ```
class SyncQueue extends GetxService {
  static const _storageKeyBase = 'portal_sync_queue';

  String get _storageKey =>
      UserStorageScope.scopeKey(_storageKeyBase);

  /// Reactive count of operations still waiting to be pushed.
  final pendingCount = 0.obs;

  /// Load the persisted queue length and return `this` for use with
  /// [Get.putAsync].
  Future<SyncQueue> init() async {
    final ops = await _load();
    pendingCount.value = ops.length;
    return this;
  }

  /// Enqueue a [SyncOperation], automatically deduplicating against
  /// any existing pending operation for the same entity.
  ///
  /// See the class-level documentation for the full merge table.
  Future<void> enqueue(SyncOperation op) async {
    final ops = await _load();
    final idx = ops.indexWhere(
      (o) => o.entityType == op.entityType && o.entityId == op.entityId,
    );

    if (idx >= 0) {
      final existing = ops[idx];
      final merged = _merge(existing, op);
      if (merged == null) {
        ops.removeAt(idx);
      } else {
        ops[idx] = merged;
      }
    } else {
      ops.add(op);
    }

    await _save(ops);
    pendingCount.value = ops.length;
  }

  /// Return all pending operations for [entityType], sorted by
  /// [SyncOperation.createdAt] ascending (oldest first).
  Future<List<SyncOperation>> getByEntityType(String entityType) async {
    final ops = await _load();
    return ops.where((o) => o.entityType == entityType).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Remove a single completed operation by its [operationId].
  Future<void> remove(String operationId) async {
    final ops = await _load();
    ops.removeWhere((o) => o.id == operationId);
    await _save(ops);
    pendingCount.value = ops.length;
  }

  /// Remove **all** pending operations for [entityType].
  Future<void> clearEntityType(String entityType) async {
    final ops = await _load();
    ops.removeWhere((o) => o.entityType == entityType);
    await _save(ops);
    pendingCount.value = ops.length;
  }

  // ─── Deduplication ──────────────────────────────────────────────────

  SyncOperation? _merge(SyncOperation existing, SyncOperation incoming) {
    switch ((existing.type, incoming.type)) {
      case (SyncOperationType.create, SyncOperationType.update):
        return existing.copyWith(data: incoming.data);

      case (SyncOperationType.create, SyncOperationType.delete):
        return null;

      case (SyncOperationType.update, SyncOperationType.update):
        return existing.copyWith(data: incoming.data);

      case (SyncOperationType.update, SyncOperationType.delete):
        return incoming;

      default:
        return incoming;
    }
  }

  // ─── Persistence ───────────────────────────────────────────────────

  Future<List<SyncOperation>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final migrated = await EncryptedSyncQueueCodec.migrateIfNeeded(raw);
      if (migrated != raw) {
        await prefs.setString(_storageKey, migrated);
      }
      return EncryptedSyncQueueCodec.decryptOperations(migrated);
    } catch (e) {
      debugPrint('[SyncQueue] Failed to load queue: $e');
      return [];
    }
  }

  Future<void> _save(List<SyncOperation> ops) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = await EncryptedSyncQueueCodec.encryptOperations(ops);
    await prefs.setString(_storageKey, encrypted);
  }
}
