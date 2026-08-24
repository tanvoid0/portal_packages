import 'dart:convert';

import 'models/portal_notification_models.dart';
import 'portal_notification_action_types.dart';

/// Encodes tap payloads stored on OS notifications.
abstract final class PortalNotificationPayload {
  static String encode({
    required String intentId,
    PortalNotificationAction? action,
  }) {
    return jsonEncode({
      'intentId': intentId,
      if (action != null) 'action': action.toJson(),
    });
  }

  static ({String? intentId, PortalNotificationAction? action}) decode(
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return (intentId: null, action: null);
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return (
          intentId: null,
          action: PortalNotificationAction(
            type: PortalNotificationActionTypes.taskIdValue,
            params: {'value': raw},
          ),
        );
      }
      final map = Map<String, dynamic>.from(json);
      return (
        intentId: map['intentId'] as String?,
        action: map['action'] is Map
            ? PortalNotificationAction.fromJson(
                Map<String, dynamic>.from(map['action'] as Map),
              )
            : null,
      );
    } catch (_) {
      return (
        intentId: null,
        action: PortalNotificationAction(
          type: PortalNotificationActionTypes.taskIdValue,
          params: {'value': raw},
        ),
      );
    }
  }
}
