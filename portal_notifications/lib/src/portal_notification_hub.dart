import 'portal_local_notifications.dart';
import 'models/portal_notification_models.dart';
import 'portal_notification_payload.dart';
import 'portal_notification_store.dart';

typedef PortalNotificationActionHandler = void Function(
  PortalNotificationAction action,
);

typedef PortalNotificationEntriesListener = void Function(
  List<PortalNotificationEntry> entries,
);

/// Coordinates app, server, and action-driven notifications for UI + OS delivery.
class PortalNotificationHub {
  PortalNotificationHub({
    required PortalLocalNotifications local,
    required PortalNotificationStore store,
    PortalNotificationActionHandler? onAction,
    PortalNotificationEntriesListener? onEntriesChanged,
  })  : _local = local,
        _store = store,
        _onAction = onAction,
        _onEntriesChanged = onEntriesChanged;

  final PortalLocalNotifications _local;
  final PortalNotificationStore _store;
  final PortalNotificationActionHandler? _onAction;
  final PortalNotificationEntriesListener? _onEntriesChanged;

  final entries = <PortalNotificationEntry>[];

  Future<void> init() async {
    await _local.init();
    entries
      ..clear()
      ..addAll(await _store.load());
    _notifyListeners();
  }

  Future<bool> requestPermission() => _local.requestPermission();

  /// Schedules or immediately shows a notification from app code.
  Future<PortalNotificationEntry?> applyIntent(
    PortalNotificationIntent intent, {
    int? notificationId,
  }) async {
    await _ensureReady();
    await cancelIntent(intent.id, persist: false);

    final osId = notificationId ?? _osIdFor(intent);
    final payload = PortalNotificationPayload.encode(
      intentId: intent.id,
      action: intent.action,
    );

    PortalNotificationEntry? entry;
    if (intent.isImmediate) {
      await _local.showNow(
        notificationId: osId,
        title: intent.title,
        body: intent.body,
        payload: payload,
      );
      entry = PortalNotificationEntry(
        intentId: intent.id,
        notificationId: osId,
        source: intent.source,
        kind: intent.kind,
        groupKey: intent.groupKey,
        title: intent.title,
        body: intent.body,
        fireAt: intent.fireAt,
        action: intent.action,
        deliveredAt: DateTime.now(),
      );
    } else {
      final record = await _local.schedule(
        ScheduleNotificationRequest(
          notificationId: osId,
          groupKey: intent.groupKey,
          title: intent.title,
          body: intent.body,
          fireAt: intent.fireAt!,
          payload: payload,
        ),
      );
      if (record == null) return null;
      entry = PortalNotificationEntry(
        intentId: intent.id,
        notificationId: osId,
        source: intent.source,
        kind: intent.kind,
        groupKey: intent.groupKey,
        title: intent.title,
        body: intent.body,
        fireAt: intent.fireAt,
        action: intent.action,
      );
    }

    entries.add(entry);
    await _persist();
    return entry;
  }

  /// Reconciles server-provided intents without touching app-local schedules.
  Future<void> syncServerIntents(List<PortalNotificationIntent> intents) async {
    await _ensureReady();

    final serverIds = intents.map((intent) => intent.id).toSet();
    final stale = entries
        .where(
          (entry) =>
              entry.source == PortalNotificationSource.server &&
              entry.isPending &&
              !serverIds.contains(entry.intentId),
        )
        .toList();
    for (final entry in stale) {
      await _local.cancel(entry.notificationId);
      entries.remove(entry);
    }

    for (final intent in intents) {
      if (intent.source != PortalNotificationSource.server) continue;
      await applyIntent(intent);
    }

    await _persist();
  }

  Future<void> applyServerPayloads(List<Map<String, dynamic>> payloads) {
    return syncServerIntents(
      payloads.map(PortalNotificationIntent.fromServerJson).toList(),
    );
  }

  Future<void> cancelGroup(String groupKey) async {
    await _ensureReady();
    final toRemove =
        entries.where((entry) => entry.groupKey == groupKey).toList();
    for (final entry in toRemove) {
      await _local.cancel(entry.notificationId);
      entries.remove(entry);
    }
    await _persist();
  }

  Future<void> cancelIntent(String intentId, {bool persist = true}) async {
    final toRemove =
        entries.where((entry) => entry.intentId == intentId).toList();
    for (final entry in toRemove) {
      await _local.cancel(entry.notificationId);
      entries.remove(entry);
    }
    if (persist) {
      await _persist();
    }
  }

  Future<void> cancelAll() async {
    await _ensureReady();
    await _local.cancelAll();
    entries.clear();
    await _persist();
  }

  List<PortalNotificationEntry> entriesForDisplay({
    DateTime? now,
    Duration horizon = const Duration(days: 2),
  }) {
    final clock = now ?? DateTime.now();
    final end = clock.add(horizon);
    return entries
        .where(
          (entry) =>
              entry.isPending &&
              entry.fireAt != null &&
              !entry.fireAt!.isBefore(clock) &&
              entry.fireAt!.isBefore(end),
        )
        .toList()
      ..sort((a, b) => a.fireAt!.compareTo(b.fireAt!));
  }

  void handlePayload(String? payload) {
    final decoded = PortalNotificationPayload.decode(payload);
    PortalNotificationAction? action = decoded.action;
    if (action == null && decoded.intentId != null) {
      for (final entry in entries) {
        if (entry.intentId == decoded.intentId) {
          action = entry.action;
          break;
        }
      }
    }

    if (action == null || _onAction == null) return;
    _onAction(action);
  }

  Future<void> _persist() async {
    await _store.save(entries);
    _notifyListeners();
  }

  void _notifyListeners() {
    _onEntriesChanged?.call(List.unmodifiable(entries));
  }

  Future<void> _ensureReady() async {
    if (!_local.isInitialized) {
      await init();
    }
  }

  int _osIdFor(PortalNotificationIntent intent) {
    return portalNotificationId(intent.id, 0, modulus: 1000000);
  }
}
