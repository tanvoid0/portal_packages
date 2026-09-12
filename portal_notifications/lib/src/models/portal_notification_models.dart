import '../portal_notification_action_types.dart';

/// Where a notification intent originated.
enum PortalNotificationSource {
  app,
  server;

  static PortalNotificationSource fromJson(String? value) {
    return switch (value) {
      'server' => PortalNotificationSource.server,
      _ => PortalNotificationSource.app,
    };
  }

  String toJson() => name;
}

/// Why the notification exists — drives UI grouping and scheduling behavior.
enum PortalNotificationKind {
  /// Fires at a fixed time (task reminder, server-scheduled event).
  scheduledEvent,

  /// Triggered by a user or system action; may fire now or later.
  action,

  /// Deliver immediately (no OS schedule).
  immediate;

  static PortalNotificationKind fromJson(String? value) {
    return switch (value) {
      'action' => PortalNotificationKind.action,
      'immediate' => PortalNotificationKind.immediate,
      _ => PortalNotificationKind.scheduledEvent,
    };
  }

  String toJson() => switch (this) {
        PortalNotificationKind.scheduledEvent => 'scheduled_event',
        PortalNotificationKind.action => 'action',
        PortalNotificationKind.immediate => 'immediate',
      };
}

/// Tap target for a notification — apps interpret [type] and [params].
class PortalNotificationAction {
  const PortalNotificationAction({
    required this.type,
    this.params = const {},
  });

  /// App-defined action id, e.g. `open_task`, `open_route`.
  final String type;
  final Map<String, String> params;

  Map<String, dynamic> toJson() => {
        'type': type,
        'params': params,
      };

  factory PortalNotificationAction.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    return PortalNotificationAction(
      type: PortalNotificationActionTypes.normalize(json['type'] as String),
      params: rawParams is Map
          ? rawParams.map((key, value) => MapEntry('$key', '$value'))
          : const {},
    );
  }
}

/// Input for scheduling or showing a notification from app or server code.
class PortalNotificationIntent {
  const PortalNotificationIntent({
    required this.id,
    required this.source,
    required this.kind,
    required this.groupKey,
    required this.title,
    required this.body,
    this.fireAt,
    this.action,
    this.options = const PortalNotificationOptions(),
  });

  /// Stable id for dedup/sync (server-provided or app-generated).
  final String id;
  final PortalNotificationSource source;
  final PortalNotificationKind kind;
  final String groupKey;
  final String title;
  final String body;

  /// Required for [PortalNotificationKind.scheduledEvent]; optional for action.
  final DateTime? fireAt;
  final PortalNotificationAction? action;
  final PortalNotificationOptions options;

  bool get isImmediate =>
      kind == PortalNotificationKind.immediate ||
      fireAt == null ||
      !fireAt!.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.toJson(),
        'kind': kind.toJson(),
        'group_key': groupKey,
        'title': title,
        'body': body,
        if (fireAt != null) 'fire_at': fireAt!.toIso8601String(),
        if (action != null) 'action': action!.toJson(),
      };

  factory PortalNotificationIntent.fromServerJson(Map<String, dynamic> json) {
    return PortalNotificationIntent(
      id: json['id'] as String,
      source: PortalNotificationSource.fromJson(json['source'] as String?),
      kind: PortalNotificationKind.fromJson(json['kind'] as String?),
      groupKey: json['group_key'] as String? ?? json['groupKey'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      fireAt: json['fire_at'] != null
          ? DateTime.parse(json['fire_at'] as String)
          : json['fireAt'] != null
              ? DateTime.parse(json['fireAt'] as String)
              : null,
      action: json['action'] is Map
          ? PortalNotificationAction.fromJson(
              Map<String, dynamic>.from(json['action'] as Map),
            )
          : null,
    );
  }
}

/// Persisted notification tracked for OS scheduling and in-app UI.
class PortalNotificationEntry {
  const PortalNotificationEntry({
    required this.intentId,
    required this.notificationId,
    required this.source,
    required this.kind,
    required this.groupKey,
    required this.title,
    required this.body,
    this.fireAt,
    this.action,
    this.deliveredAt,
  });

  final String intentId;
  final int notificationId;
  final PortalNotificationSource source;
  final PortalNotificationKind kind;
  final String groupKey;
  final String title;
  final String body;
  final DateTime? fireAt;
  final PortalNotificationAction? action;
  final DateTime? deliveredAt;

  bool get isPending {
    if (deliveredAt != null) return false;
    if (fireAt == null) return false;
    return fireAt!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
        'intentId': intentId,
        'notificationId': notificationId,
        'source': source.toJson(),
        'kind': kind.toJson(),
        'groupKey': groupKey,
        'title': title,
        'body': body,
        if (fireAt != null) 'fireAt': fireAt!.toIso8601String(),
        if (action != null) 'action': action!.toJson(),
        if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      };

  factory PortalNotificationEntry.fromJson(Map<String, dynamic> json) {
    return PortalNotificationEntry(
      intentId: json['intentId'] as String? ?? json['id'] as String,
      notificationId: json['notificationId'] as int,
      source: PortalNotificationSource.fromJson(json['source'] as String?),
      kind: PortalNotificationKind.fromJson(json['kind'] as String?),
      groupKey: json['groupKey'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      fireAt: json['fireAt'] != null
          ? DateTime.parse(json['fireAt'] as String)
          : null,
      action: json['action'] is Map
          ? PortalNotificationAction.fromJson(
              Map<String, dynamic>.from(json['action'] as Map),
            )
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
    );
  }

  /// Reads persisted records from the first on-disk schema (no intentId/source).
  factory PortalNotificationEntry.fromPersistedV1(Map<String, dynamic> json) {
    return PortalNotificationEntry(
      intentId: '${json['groupKey']}:${json['notificationId']}',
      notificationId: json['notificationId'] as int,
      source: PortalNotificationSource.app,
      kind: PortalNotificationKind.scheduledEvent,
      groupKey: json['groupKey'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      fireAt: DateTime.parse(json['fireAt'] as String),
      action: json['payload'] != null
          ? PortalNotificationAction(
              type: PortalNotificationActionTypes.taskIdValue,
              params: {'value': json['payload'] as String},
            )
          : null,
    );
  }
}

/// Request to schedule a single local notification with the OS plugin.
class ScheduleNotificationRequest {
  const ScheduleNotificationRequest({
    required this.notificationId,
    required this.groupKey,
    required this.title,
    required this.body,
    required this.fireAt,
    this.payload,
    this.options = const PortalNotificationOptions(),
  });

  final int notificationId;
  final String groupKey;
  final String title;
  final String body;
  final DateTime fireAt;
  final String? payload;
  final PortalNotificationOptions options;
}

/// A quick-action button rendered on the OS notification.
///
/// [opensApp] true: tapping brings the app to the foreground and the hub's
/// `onButton` fires. false: handled in a background isolate by
/// [PortalNotificationsConfig.onBackgroundResponse]; the app never opens.
class PortalNotificationButton {
  const PortalNotificationButton({
    required this.id,
    required this.label,
    this.opensApp = true,
    this.dismisses = true,
  });

  final String id;
  final String label;
  final bool opensApp;

  /// Remove the notification once the button is tapped.
  final bool dismisses;
}

/// OS-level repeat for a scheduled notification. The first delivery is
/// `fireAt`; later ones match its time (daily), weekday+time (weekly) or
/// day-of-month+time (monthly).
enum PortalNotificationRepeat { none, daily, weekly, monthly }

/// Presentation knobs shared by every notification the package shows.
class PortalNotificationOptions {
  const PortalNotificationOptions({
    this.buttons = const [],
    this.repeat = PortalNotificationRepeat.none,
    this.subtitle,
    this.silent = false,
    this.ongoing = false,
  });

  /// Up to three on Android; the same set must be listed in
  /// [PortalNotificationsConfig.buttonSets] for iOS to render it.
  final List<PortalNotificationButton> buttons;
  final PortalNotificationRepeat repeat;

  /// Android `subText` / iOS `subtitle` — a small line under the title.
  final String? subtitle;

  /// No sound, no heads-up.
  final bool silent;

  /// Cannot be swiped away (progress, live timers). Tap-to-dismiss is off too.
  final bool ongoing;
}
