import 'package:flutter_test/flutter_test.dart';
import 'package:portal_notifications/portal_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocal extends PortalLocalNotifications {
  _FakeLocal() : super(const PortalNotificationsConfig(channelId: 'test', channelName: 'Test'));

  final scheduled = <ScheduleNotificationRequest>[];
  final shown = <Map<String, dynamic>>[];

  @override
  Future<void> init() async {}

  @override
  bool get isInitialized => true;

  @override
  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
    PortalNotificationOptions options = const PortalNotificationOptions(),
  }) async {
    shown.add({
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  @override
  Future<PortalNotificationEntry?> schedule(
    ScheduleNotificationRequest request,
  ) async {
    scheduled.add(request);
    return PortalNotificationEntry(
      intentId: '${request.groupKey}:${request.notificationId}',
      notificationId: request.notificationId,
      source: PortalNotificationSource.app,
      kind: PortalNotificationKind.scheduledEvent,
      groupKey: request.groupKey,
      title: request.title,
      body: request.body,
      fireAt: request.fireAt,
    );
  }

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
    shown.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('applyIntent schedules reminders and action notifications separately', () async {
    final local = _FakeLocal();
    final hub = PortalNotificationHub(
      local: local,
      store: PortalNotificationStore(storageKey: 'test_entries'),
    );
    await hub.init();

    await hub.applyIntent(
      PortalNotificationIntent(
        id: 'task-1:alert:0',
        source: PortalNotificationSource.app,
        kind: PortalNotificationKind.scheduledEvent,
        groupKey: 'task-1',
        title: 'Morning run',
        body: 'Starts now',
        fireAt: DateTime.now().add(const Duration(hours: 1)),
        action: PortalNotificationActions.openTaskAction(taskId: 'task-1'),
      ),
    );

    await hub.applyIntent(
      PortalNotificationIntent(
        id: 'action-1',
        source: PortalNotificationSource.app,
        kind: PortalNotificationKind.immediate,
        groupKey: 'inbox',
        title: 'Task promoted',
        body: 'Your capture is on the timeline',
        action: PortalNotificationActions.openRouteAction(route: '/timeline'),
      ),
    );

    expect(local.scheduled, hasLength(1));
    expect(local.shown, hasLength(1));
    expect(hub.entriesForDisplay(), hasLength(1));
  });

  test('syncServerIntents replaces stale server schedules', () async {
    final local = _FakeLocal();
    final hub = PortalNotificationHub(
      local: local,
      store: PortalNotificationStore(storageKey: 'test_server_entries'),
    );
    await hub.init();

    await hub.syncServerIntents([
      PortalNotificationIntent(
        id: 'server-1',
        source: PortalNotificationSource.server,
        kind: PortalNotificationKind.scheduledEvent,
        groupKey: 'campaign',
        title: 'Weekly review',
        body: 'Due today',
        fireAt: DateTime.now().add(const Duration(hours: 2)),
      ),
    ]);

    await hub.syncServerIntents([
      PortalNotificationIntent(
        id: 'server-2',
        source: PortalNotificationSource.server,
        kind: PortalNotificationKind.scheduledEvent,
        groupKey: 'campaign',
        title: 'Weekly review',
        body: 'Moved to tomorrow',
        fireAt: DateTime.now().add(const Duration(days: 1)),
      ),
    ]);

    expect(
      hub.entries.where((entry) => entry.source == PortalNotificationSource.server),
      hasLength(1),
    );
    expect(hub.entries.single.intentId, 'server-2');
  });

  test('button tap resolves intent and action from the stored entry', () async {
    final local = _FakeLocal();
    final presses = <(String, String?, PortalNotificationAction?)>[];
    final hub = PortalNotificationHub(
      local: local,
      store: PortalNotificationStore(storageKey: 'test_button_entries'),
      onButton: (id, intentId, action) => presses.add((id, intentId, action)),
    );
    await hub.init();

    await hub.applyIntent(
      PortalNotificationIntent(
        id: 'bill-1',
        source: PortalNotificationSource.app,
        kind: PortalNotificationKind.immediate,
        groupKey: 'bills',
        title: 'Rent due',
        body: 'Tomorrow',
        action: PortalNotificationActions.openRouteAction(route: '/bills'),
        options: const PortalNotificationOptions(
          buttons: [PortalNotificationButton(id: 'paid', label: 'Mark paid')],
        ),
      ),
    );

    hub.handleButton('paid', local.shown.single['payload'] as String?);

    expect(presses.single.$1, 'paid');
    expect(presses.single.$2, 'bill-1');
    expect(presses.single.$3?.type, PortalNotificationActions.openRoute);
  });
}
