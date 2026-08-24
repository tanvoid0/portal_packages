/// Android notification channel and platform initialization options.
class PortalNotificationsConfig {
  const PortalNotificationsConfig({
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.androidIcon = '@mipmap/ic_launcher',
    this.importance = NotificationImportance.high,
    this.requestPermissionOnInit = true,
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
}

/// Subset of Android channel importance levels exposed by the package.
enum NotificationImportance {
  defaultImportance,
  low,
  high,
  max,
}
