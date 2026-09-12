// Only the type a background button handler receives; everything else stays
// behind the wrapper.
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;

export 'src/config/portal_notifications_config.dart';
export 'src/models/portal_notification_models.dart';
export 'src/portal_local_notifications.dart';
export 'src/portal_notification_hub.dart';
export 'src/portal_notification_payload.dart';
export 'src/portal_notification_store.dart';

import 'src/models/portal_notification_models.dart';
import 'src/portal_notification_action_types.dart';

export 'src/portal_notification_action_types.dart';

/// Convenience helpers for common notification actions.
abstract final class PortalNotificationActions {
  static const openTask = PortalNotificationActionTypes.openTask;
  static const openRoute = PortalNotificationActionTypes.openRoute;
  static const taskIdValue = PortalNotificationActionTypes.taskIdValue;

  static PortalNotificationAction openTaskAction({
    required String taskId,
    String? type,
    String? location,
  }) {
    final storedType = _normalizeStoredTaskType(type ?? location ?? 'scheduled');
    return PortalNotificationAction(
      type: openTask,
      params: {
        'task_id': taskId,
        'type': storedType,
        'location': storedType,
      },
    );
  }

  static String _normalizeStoredTaskType(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == 'inbox' || value == 'unscheduled') return 'unscheduled';
    if (value == 'scheduled' || value == 'timeline') return 'scheduled';
    return 'scheduled';
  }

  static PortalNotificationAction openRouteAction({
    required String route,
    Map<String, String> params = const {},
  }) {
    return PortalNotificationAction(
      type: openRoute,
      params: {
        'route': route,
        ...params,
      },
    );
  }
}
