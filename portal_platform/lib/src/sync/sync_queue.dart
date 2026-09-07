import 'dart:async';

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

  /// Hard ceiling on pending operations.
  ///
  /// The queue is one SharedPreferences string, encrypted and rewritten in
  /// full on every mutation, so its cost is quadratic in a long offline
  /// stretch. Dedup keeps it to one operation per entity, which bounds normal
  /// use well below this; the cap only catches genuine runaway.
  static const int maxOperations = 500;

  /// How long an un-pushed operation is kept before it is abandoned.
  ///
  /// A change that has failed to reach the server for a month is not going to,
  /// and replaying it against a server that has moved on is more likely to
  /// resurrect deleted data than to help.
  static const Duration maxOperationAge = Duration(days: 30);

  /// Called when operations are discarded to respect [maxOperations] or
  /// [maxOperationAge]. This drops user data, so it must not be silent —
  /// apps wire it to the same place they show sync failures.
  static void Function(int dropped, String reason)? onEvicted;

  String get _storageKey =>
      UserStorageScope.scopeKey(_storageKeyBase);

  /// Reactive count of operations still waiting to be pushed.
  final pendingCount = 0.obs;

  /// Serialises access so concurrent callers cannot interleave a
  /// load → modify → save cycle and drop each other's operations.
  ///
  /// ponytail: one lock for the whole queue. Every mutation is a single
  /// SharedPreferences write, so contention is not worth per-entity locks
  /// unless a profile says otherwise.
  Future<void> _lock = Future<void>.value();

  Future<T> _withLock<T>(Future<T> Function() action) {
    final result = Completer<T>();
    // The chain must never carry an error forward or every later caller
    // inherits it, so failures land on [result] and the lock stays clean.
    _lock = _lock.then((_) async {
      try {
        result.complete(await action());
      } catch (e, st) {
        result.completeError(e, st);
      }
    });
    return result.future;
  }

  /// Load the persisted queue length and return `this` for use with
  /// [Get.putAsync].
  Future<SyncQueue> init() async {
    try {
      final ops = await _withLock(() async {
        final loaded = await _load();
        final kept = _prune(loaded);
        if (kept.length != loaded.length) await _save(kept);
        return kept;
      });
      pendingCount.value = ops.length;
    } catch (e) {
      // Startup must not fail on an unreadable queue. The badge count is
      // cosmetic; mutating calls surface the real error and the persisted
      // operations are left untouched.
      debugPrint('[SyncQueue] Failed to read queue length: $e');
      pendingCount.value = 0;
    }
    return this;
  }

  /// Enqueue a [SyncOperation], automatically deduplicating against
  /// any existing pending operation for the same entity.
  ///
  /// See the class-level documentation for the full merge table.
  Future<void> enqueue(SyncOperation op) => _withLock(() async {
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

        final kept = _prune(ops);
        await _save(kept);
        pendingCount.value = kept.length;
      });

  /// Return all pending operations for [entityType], sorted by
  /// [SyncOperation.createdAt] ascending (oldest first).
  ///
  /// Takes the lock too: [_load] rewrites the entry when it migrates a
  /// legacy plaintext queue.
  Future<List<SyncOperation>> getByEntityType(String entityType) =>
      _withLock(() async {
        final ops = await _load();
        return ops.where((o) => o.entityType == entityType).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

  /// Remove a single completed operation by its [operationId].
  Future<void> remove(String operationId) => _withLock(() async {
        final ops = await _load();
        ops.removeWhere((o) => o.id == operationId);
        await _save(ops);
        pendingCount.value = ops.length;
      });

  /// Remove **all** pending operations for [entityType].
  Future<void> clearEntityType(String entityType) => _withLock(() async {
        final ops = await _load();
        ops.removeWhere((o) => o.entityType == entityType);
        await _save(ops);
        pendingCount.value = ops.length;
      });

  // ─── Eviction ───────────────────────────────────────────────────────

  /// Drop operations that are too old, then the oldest above [maxOperations].
  ///
  /// Pure and synchronous so the policy is testable on its own. Oldest-first
  /// because dedup already means each entity appears once: the oldest entries
  /// are the ones that have failed longest and whose data is most stale.
  List<SyncOperation> _prune(List<SyncOperation> ops) {
    final now = DateTime.now();
    // An operation stamped in the future means the device clock has moved —
    // a timezone change, a manual adjustment, an emulator resuming from a
    // snapshot. Age is meaningless against a clock we cannot trust, and the
    // cost of being wrong here is deleting somebody's unsynced work, so the
    // age rule sits out and the size cap still applies.
    final clockTrusted = !ops.any((o) => o.createdAt.isAfter(now));
    final cutoff = now.subtract(maxOperationAge);
    final fresh = clockTrusted
        ? ops.where((o) => o.createdAt.isAfter(cutoff)).toList()
        : List<SyncOperation>.of(ops);
    final expired = ops.length - fresh.length;
    if (expired > 0) {
      _reportEvicted(expired, 'older than ${maxOperationAge.inDays} days');
    }

    if (fresh.length <= maxOperations) return fresh;

    fresh.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final overflow = fresh.length - maxOperations;
    _reportEvicted(overflow, 'the pending limit of $maxOperations was reached');
    return fresh.sublist(overflow);
  }

  void _reportEvicted(int dropped, String reason) {
    debugPrint('[SyncQueue] Dropped $dropped operation(s): $reason');
    try {
      onEvicted?.call(dropped, reason);
    } catch (e) {
      debugPrint('[SyncQueue] onEvicted threw: $e');
    }
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

  /// Throws when the persisted queue cannot be read or decrypted.
  ///
  /// Deliberately not swallowed: every mutating caller does load → modify →
  /// save, so returning an empty list on a transient read failure would
  /// overwrite the pending operations with whatever survived that call.
  Future<List<SyncOperation>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final migrated = await EncryptedSyncQueueCodec.migrateIfNeeded(raw);
    if (migrated != raw) {
      await prefs.setString(_storageKey, migrated);
    }
    return await EncryptedSyncQueueCodec.decryptOperations(migrated);
  }

  Future<void> _save(List<SyncOperation> ops) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = await EncryptedSyncQueueCodec.encryptOperations(ops);
    await prefs.setString(_storageKey, encrypted);
  }
}
