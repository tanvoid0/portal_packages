import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../storage/portal_database.dart';
import '../storage/user_storage_scope.dart';
import 'encrypted_sync_queue_codec.dart';
import 'sync_operation.dart';

/// Persistent, deduplicated queue of mutations waiting to be pushed to
/// the server.
///
/// All pending [SyncOperation]s are stored as one encrypted JSON array in
/// [PortalDatabase]'s `kv` table under the key `portal_sync_queue`, so they
/// survive app restarts. It lives in that database rather than in
/// [SharedPreferences] so a mutation and the cache write it belongs to can be
/// one commit -- see [enqueueWith]. A queue left in prefs by an older build is
/// imported on first read.
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
/// The create+update row applies only when the caller can re-serialise the
/// payload for the surviving verb (see `dataFor` on [enqueueWith]). Without
/// that, both operations are kept and replayed oldest-first — see
/// [_mustNotMerge].
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
  /// The queue is one encrypted string, rewritten in full on every mutation,
  /// so its cost is quadratic in a long offline stretch. Dedup keeps it to one operation per entity, which bounds normal
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
      final ops =
          await _withLock(() => PortalDatabase.transaction((txn) async {
                final loaded = await _load(txn);
                final kept = _prune(loaded);
                if (kept.length != loaded.length) await _save(kept, txn);
                return kept;
              }));
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
  Future<void> enqueue(SyncOperation op) => enqueueWith(op);

  /// Enqueue [op] and, in the *same* transaction, run [alsoWrite].
  ///
  /// This is the reason the queue moved into [PortalDatabase]. A repository
  /// writes its cache through [alsoWrite], so there is no instant where the
  /// local copy of an edit exists with nothing queued to push it -- the state
  /// that used to look saved and then silently never sync.
  ///
  /// Returns the id of the operation that now represents this entity: [op]'s
  /// own, the id of the pending operation it merged into, or `null` when the
  /// merge cancelled both out (a create then a delete) or eviction dropped it.
  /// A caller that goes on to push the change immediately must remove *that*
  /// id, not `op.id`, or it leaves a stale operation to be replayed.
  ///
  /// The lock is taken before the transaction is opened, never the other way
  /// round: SQLite serialises write transactions, so a caller holding the
  /// lock while waiting for one would deadlock against a caller holding a
  /// transaction while waiting for the lock.
  /// [dataFor] re-serialises the payload when dedup changes which verb will
  /// actually be sent. Merging an update into a pending create keeps the
  /// *create*, and a body serialised for an update is not a valid create body
  /// — the server whitelists per verb and answers 400, which is a permanent
  /// failure, which drops the operation and loses the entity. The queue knows
  /// the effective verb; only the caller knows how to serialise for it.
  Future<String?> enqueueWith(
    SyncOperation op, {
    Future<void> Function(DatabaseExecutor txn)? alsoWrite,
    Map<String, dynamic>? Function(SyncOperationType effective)? dataFor,
  }) async {
    final result =
        await _withLock(() => PortalDatabase.transaction((txn) async {
              if (alsoWrite != null) await alsoWrite(txn);

              final ops = await _load(txn);
              final idx = ops.indexWhere(
                (o) =>
                    o.entityType == op.entityType && o.entityId == op.entityId,
              );

              String? effectiveId = op.id;
              if (idx >= 0 && _mustNotMerge(ops[idx], op, dataFor)) {
                // Two operations for one entity, replayed oldest-first.
                ops.add(op);
              } else if (idx >= 0) {
                var merged = _merge(ops[idx], op);
                if (merged == null) {
                  ops.removeAt(idx);
                  effectiveId = null;
                } else {
                  if (dataFor != null && merged.type != op.type) {
                    merged = merged.copyWith(data: dataFor(merged.type));
                  }
                  ops[idx] = merged;
                  effectiveId = merged.id;
                }
              } else {
                ops.add(op);
              }

              final kept = _prune(ops);
              await _save(kept, txn);
              if (effectiveId != null &&
                  !kept.any((o) => o.id == effectiveId)) {
                effectiveId = null;
              }
              return (id: effectiveId, count: kept.length);
            }));
    // Outside the transaction: a rollback must not leave the badge claiming
    // work that was never stored.
    pendingCount.value = result.count;
    return result.id;
  }

  /// Return all pending operations for [entityType], sorted by
  /// [SyncOperation.createdAt] ascending (oldest first).
  ///
  /// Takes the lock too: [_load] rewrites the entry when it migrates a
  /// legacy plaintext queue.
  Future<List<SyncOperation>> getByEntityType(String entityType) =>
      _withLock(() => PortalDatabase.transaction((txn) async {
            final ops = await _load(txn);
            return ops.where((o) => o.entityType == entityType).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }));

  /// Remove a single completed operation by its [operationId].
  Future<void> remove(String operationId) async {
    final count = await _withLock(() => PortalDatabase.transaction((txn) async {
          final ops = await _load(txn);
          ops.removeWhere((o) => o.id == operationId);
          await _save(ops, txn);
          return ops.length;
        }));
    pendingCount.value = count;
  }

  /// Remove **all** pending operations for [entityType].
  Future<void> clearEntityType(String entityType) async {
    final count = await _withLock(() => PortalDatabase.transaction((txn) async {
          final ops = await _load(txn);
          ops.removeWhere((o) => o.entityType == entityType);
          await _save(ops, txn);
          return ops.length;
        }));
    pendingCount.value = count;
  }

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

  /// True when merging [incoming] into [existing] would produce an operation
  /// that cannot be replayed correctly, so both must be kept.
  ///
  /// There is exactly one such case. Every other row of the merge table either
  /// cancels the pair out or leaves a survivor whose type equals the incoming
  /// operation's; only create-then-update keeps the *create* while taking the
  /// update's payload. Two different replay models both break on that:
  ///
  ///  * [SyncableRepository] serialises per verb, so an update body is not a
  ///    valid create body — the server whitelists per verb and 400s.
  ///  * [EntitySyncOutbox] mutations carry their action *in the payload*, so
  ///    the merged operation replays as an update for an id the server has
  ///    never seen. Three of the four batch handlers upsert; the notes one
  ///    rejects it and the note is lost.
  ///
  /// A caller that can re-serialise for the surviving verb passes `dataFor`
  /// and the merge is safe. One that cannot — every outbox, and `delete`,
  /// which has no entity left to serialise — gets both operations kept and
  /// replayed in order instead. Ordering does the same job as merging: the
  /// create lands, then the update applies to something that exists.
  bool _mustNotMerge(
    SyncOperation existing,
    SyncOperation incoming,
    Map<String, dynamic>? Function(SyncOperationType)? dataFor,
  ) =>
      dataFor == null &&
      existing.type == SyncOperationType.create &&
      incoming.type == SyncOperationType.update;

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

  /// Throws when the persisted queue cannot be read.
  ///
  /// Deliberately not swallowed: every mutating caller does load → modify →
  /// save, so returning an empty list on a transient read failure would
  /// overwrite the pending operations with whatever survived that call.
  ///
  /// Ciphertext that will not authenticate is the exception, because it is
  /// not transient. The queue key lives in the Android keystore and the
  /// queue itself in [PortalDatabase]; a restore, a reinstall or a
  /// keystore invalidation takes the key and leaves the blob, and no key
  /// that can read it will ever exist again. Throwing then wedges the app
  /// for good: every write that has to queue -- which is every write the
  /// server rejects, and every write made offline -- fails on the read
  /// before it, so nothing can be saved or deleted again. So the
  /// unreadable blob is dropped once and the queue starts empty. The
  /// operations in it are lost, but they were already unrecoverable; the
  /// local database they came from is untouched.
  Future<List<SyncOperation>> _load(DatabaseExecutor txn) async {
    final raw =
        await PortalDatabase.kvGetOrImportFromPrefs(_storageKey, txn: txn);
    if (raw.isEmpty) return [];
    try {
      final migrated = await EncryptedSyncQueueCodec.migrateIfNeeded(raw);
      if (migrated != raw) {
        await PortalDatabase.kvPut(_storageKey, migrated, txn: txn);
      }
      return await EncryptedSyncQueueCodec.decryptOperations(migrated);
    } on SecretBoxAuthenticationError {
      // Only this one. Malformed bytes keep throwing and keep their blob:
      // corruption may be partial, and a queue nobody has proved
      // unrecoverable is not ours to delete.
      debugPrint('[sync] dropping the stored queue: its key is gone');
      await PortalDatabase.kvPut(_storageKey, '', txn: txn);
      return [];
    }
  }

  Future<void> _save(List<SyncOperation> ops, DatabaseExecutor txn) async {
    final encrypted = await EncryptedSyncQueueCodec.encryptOperations(ops);
    await PortalDatabase.kvPut(_storageKey, encrypted, txn: txn);
  }
}
