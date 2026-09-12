import 'config/portal_notifications_config.dart';
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

/// A quick-action button press, resolved back to the intent it was on.
typedef PortalNotificationButtonHandler = void Function(
  String buttonId,
  String? intentId,
  PortalNotificationAction? action,
);

/// Coordinates app, server, and action-driven notifications for UI + OS delivery.
class PortalNotificationHub {
  PortalNotificationHub({
    required PortalLocalNotifications local,
    required PortalNotificationStore store,
    PortalNotificationActionHandler? onAction,
    PortalNotificationButtonHandler? onButton,
    PortalNotificationEntriesListener? onEntriesChanged,
  })  : _local = local,
        _store = store,
        _onAction = onAction,
        _onButton = onButton,
        _onEntriesChanged = onEntriesChanged;

  /// Builds the OS wrapper and the hub together so the tap and button
  /// callbacks are wired without the `late final` dance in every app.
  factory PortalNotificationHub.create({
    required PortalNotificationsConfig config,
    required String storageKey,
    PortalNotificationActionHandler? onAction,
    PortalNotificationButtonHandler? onButton,
    PortalNotificationEntriesListener? onEntriesChanged,
  }) {
    late final PortalNotificationHub hub;
    final local = PortalLocalNotifications(
      config,
      onNotificationTap: (payload) => hub.handlePayload(payload),
      onButtonTap: (id, payload) => hub.handleButton(id, payload),
    );
    return hub = PortalNotificationHub(
      local: local,
      store: PortalNotificationStore(storageKey: storageKey),
      onAction: onAction,
      onButton: onButton,
      onEntriesChanged: onEntriesChanged,
    );
  }

  final PortalLocalNotifications _local;
  final PortalNotificationStore _store;
  final PortalNotificationActionHandler? _onAction;
  final PortalNotificationButtonHandler? _onButton;
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
        options: intent.options,
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
          options: intent.options,
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
    final action = decoded.action ?? _actionFor(decoded.intentId);
    if (action == null || _onAction == null) return;
    _onAction(action);
  }

  void handleButton(String buttonId, String? payload) {
    final decoded = PortalNotificationPayload.decode(payload);
    _onButton?.call(
      buttonId,
      decoded.intentId,
      decoded.action ?? _actionFor(decoded.intentId),
    );
  }

  PortalNotificationAction? _actionFor(String? intentId) {
    if (intentId == null) return null;
    for (final entry in entries) {
      if (entry.intentId == intentId) return entry.action;
    }
    return null;
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
