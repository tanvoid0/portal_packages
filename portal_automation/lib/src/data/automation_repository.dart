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
    };
  }
}
