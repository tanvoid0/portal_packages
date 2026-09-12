import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;

import '../models/portal_notification_models.dart';

/// Handler for a button tapped with `opensApp: false`. Runs in its own
/// isolate with no app state, so it must be a top-level or static function
/// annotated `@pragma('vm:entry-point')` — a closure cannot be registered.
/// Read `response.actionId` for the button and `response.payload` for the
/// intent (decode with `PortalNotificationPayload.decode`).
typedef PortalBackgroundResponseHandler = void Function(
  NotificationResponse response,
);

/// Android notification channel and platform initialization options.
class PortalNotificationsConfig {
  const PortalNotificationsConfig({
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.androidIcon = '@mipmap/ic_launcher',
    this.importance = NotificationImportance.high,
    this.requestPermissionOnInit = true,
    this.buttonSets = const [],
    this.onBackgroundResponse,
  });

  /// Android notification channel id (must stay stable per app).
  final String channelId;

  /// User-visible channel name in system settings.
  final String channelName;

  /// Optional channel description shown in Android settings.
  final String? channelDescription;

  /// Android drawable/mipmap resource for the notification icon.
  final String androidIcon;

  /// Default importance for the Android channel.
  final NotificationImportance importance;

  /// When true, [PortalLocalNotifications.init] requests OS permission.
  final bool requestPermissionOnInit;

  /// Every distinct button combination the app will ever show. iOS registers
  /// action categories once at init and ignores buttons it was not told about;
  /// Android renders whatever is on the notification. Order within a set
  /// matters — it is the category identity.
  final List<List<PortalNotificationButton>> buttonSets;

  /// See [PortalBackgroundResponseHandler]. Required for any button with
  /// `opensApp: false`; without it those taps are dropped.
  final PortalBackgroundResponseHandler? onBackgroundResponse;
}

/// Subset of Android channel importance levels exposed by the package.
enum NotificationImportance {
  defaultImportance,
  low,
  high,
  max,
}
