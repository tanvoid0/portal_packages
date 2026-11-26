import 'dart:convert';

import 'package:portal_platform/portal_platform.dart'
    show SyncableRepository, PortalApiPaths;

import '../model/automation.dart';

/// Offline-first store for routine *definitions*.
///
/// Definitions sync across the user's devices; **execution is always
/// on-device** (triggers fire locally, there is no server-side scheduler).
/// Register with `SyncManager` in `main()`, like any other
/// [SyncableRepository].
class AutomationRepository extends SyncableRepository<Automation> {
  @override
  String get entityType => 'automation';

  @override
  String get cacheKey => 'portal_automation_automations';

  @override
  String get apiBasePath =>
      '${PortalApiPaths.module(api.baseUrl, 'automation')}/automations';

  @override
  Automation fromJson(Map<String, dynamic> json) => Automation.fromJson(json);

  @override
  Map<String, dynamic> toJson(Automation entity) => entity.toJson();

  @override
  String getId(Automation entity) => entity.id;

  /// Opt into newest-wins: a server copy edited on another device after this
  /// one queued its change should win on the next sync.
  @override
  DateTime? updatedAt(Automation entity) => entity.updatedAt;

  /// Strip server-managed fields before sending. A strict/whitelisting
  /// validator on the server rejects the whole write if an unknown field is
  /// present (it 400s and the change is silently dropped from the queue — see
  /// the finance wire-strip lesson), so send only what the DTO accepts:
  /// `id` on create, never `createdAt`/`updatedAt`.
  @override
  Map<String, dynamic> toWireJson(Automation entity, {required bool isCreate}) {
    return {
      if (isCreate) 'id': entity.id,
      'name': entity.name,
      'enabled': entity.enabled,
      'trigger': entity.trigger.toJson(),
      'actions': [for (final a in entity.actions) a.toJson()],
      // Always sent, even when empty: the server only changes conditions when
      // the key is present, so omitting an empty list could never clear them.
      'conditions': [for (final c in entity.conditions) c.toJson()],
    };
  }

  /// Older builds queued writes without `conditions`. Replayed as they are, a
  /// create stores none on the server and the next pull wipes the local ones,
  /// so the routine then fires unconditionally. Fill the key in from the cache
  /// before anything is pushed.
  // ponytail: upgrade shim, delete once no install can still hold such a queue.
  @override
  Future<void> sync() async {
    final stale = [
      for (final op in await syncQueue.getByEntityType(entityType))
        if (op.data != null && !op.data!.containsKey('conditions')) op,
    ];
    if (stale.isNotEmpty) {
      final cached = {for (final a in await readCache()) a.id: a};
      for (final op in stale) {
        final conditions = cached[op.entityId]?.conditions ?? const [];
        // Empty stays unsent, so it cannot clear what another device set.
        if (conditions.isEmpty) continue;
        // Re-read right before replacing: a concurrent delete drops the op and
        // a concurrent edit rewrites it (with `conditions`) — leave both alone.
        // ponytail: a re-check, not a lock; move into SyncQueue if it races.
        final current = (await syncQueue.getByEntityType(entityType))
            .where((queued) => queued.id == op.id);
        if (current.isEmpty ||
            jsonEncode(current.first.data) != jsonEncode(op.data)) {
          continue;
        }
        // Same id and type, so this replaces the queued operation in place.
        await syncQueue.enqueue(
          op.copyWith(
            data: {
              ...op.data!,
              'conditions': [for (final c in conditions) c.toJson()],
            },
          ),
        );
      }
    }
    await super.sync();
  }
}
