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
}
