import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'config/portal_notifications_config.dart';
import 'models/portal_notification_models.dart';

typedef NotificationTapCallback = void Function(String? payload);

/// A quick-action button tapped while the app was, or is now, in the
/// foreground. Buttons with `opensApp: false` never reach this — see
/// [PortalNotificationsConfig.onBackgroundResponse].
typedef NotificationButtonCallback = void Function(
  String buttonId,
  String? payload,
);

/// Cross-platform wrapper around [FlutterLocalNotificationsPlugin].
class PortalLocalNotifications {
  PortalLocalNotifications(
    this.config, {
    NotificationTapCallback? onNotificationTap,
    NotificationButtonCallback? onButtonTap,
  })  : _onNotificationTap = onNotificationTap,
        _onButtonTap = onButtonTap;

  final PortalNotificationsConfig config;
  final NotificationTapCallback? _onNotificationTap;
  final NotificationButtonCallback? _onButtonTap;

  final _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    final android = AndroidInitializationSettings(config.androidIcon);
    final ios = DarwinInitializationSettings(
      notificationCategories: [
        for (final set in config.buttonSets)
          DarwinNotificationCategory(
            _categoryId(set),
            actions: [
              for (final b in set)
                DarwinNotificationAction.plain(
                  b.id,
                  b.label,
                  options: {
                    if (b.opensApp) DarwinNotificationActionOption.foreground,
                  },
                ),
            ],
          ),
      ],
    );
    // A tap that cold-starts the app is replayed through this same callback
    // by the plugin's initialize on both platforms — do not also poll
    // getNotificationAppLaunchDetails, it fires the handler twice (measured).
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _dispatch,
      onDidReceiveBackgroundNotificationResponse: config.onBackgroundResponse,
    );

    await _createAndroidChannel();

    _initialized = true;

    if (config.requestPermissionOnInit) {
      await requestPermission();
    }
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        config.channelId,
        config.channelName,
        description: config.channelDescription,
        importance: _mapImportance(config.importance),
      ),
    );
  }

  Importance _mapImportance(NotificationImportance value) {
    switch (value) {
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }

  /// Requests the OS notification permission.
  ///
  /// Needs an Activity. Called from a background isolate (Workmanager, a boot
  /// receiver) the Android plugin has a null Context and throws
  /// NullPointerException, so this returns false instead of propagating —
  /// "no permission" is the honest answer with no UI to prompt from, and it
  /// must not abort the caller's whole [init].
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? false;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.requestPermissions(alert: true, badge: true, sound: true)) ??
            false;
      }

      return true;
    } on PlatformException catch (e) {
      debugPrint('[PortalLocalNotifications] permission request unavailable: $e');
      return false;
    }
  }

  void _dispatch(NotificationResponse response) {
    final actionId = response.actionId;
    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction &&
        actionId != null) {
      _onButtonTap?.call(actionId, response.payload);
      return;
    }
    _onNotificationTap?.call(response.payload);
  }

  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
    PortalNotificationOptions options = const PortalNotificationOptions(),
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      notificationId,
      title,
      body,
      _notificationDetails(body, options),
      payload: payload,
    );
  }

  Future<PortalNotificationEntry?> schedule(
    ScheduleNotificationRequest request,
  ) async {
    await _ensureInitialized();
    if (request.fireAt.isBefore(DateTime.now())) return null;

    final scheduled = _toTzDateTime(request.fireAt);
    final scheduleMode = await _resolveAndroidScheduleMode();

    await _plugin.zonedSchedule(
      request.notificationId,
      request.title,
      request.body,
      scheduled,
      _notificationDetails(request.body, request.options),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: switch (request.options.repeat) {
        PortalNotificationRepeat.none => null,
        PortalNotificationRepeat.daily => DateTimeComponents.time,
        PortalNotificationRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        PortalNotificationRepeat.monthly =>
          DateTimeComponents.dayOfMonthAndTime,
      },
      payload: request.payload,
    );

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

  tz.TZDateTime _toTzDateTime(DateTime when) {
    return tz.TZDateTime(
      tz.local,
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
      when.millisecond,
      when.microsecond,
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (canExact) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final granted = await android.requestExactAlarmsPermission() ?? false;
    return granted
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> cancel(int notificationId) {
    return _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }

  NotificationDetails _notificationDetails(
    String body,
    PortalNotificationOptions o,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        config.channelId,
        config.channelName,
        channelDescription: config.channelDescription,
        // Long bodies expand instead of truncating to one line.
        styleInformation: BigTextStyleInformation(body),
        subText: o.subtitle,
        silent: o.silent,
        playSound: !o.silent,
        ongoing: o.ongoing,
        autoCancel: !o.ongoing,
        actions: [
          for (final b in o.buttons)
            AndroidNotificationAction(
              b.id,
              b.label,
              showsUserInterface: b.opensApp,
              cancelNotification: b.dismisses,
            ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        subtitle: o.subtitle,
        presentSound: !o.silent,
        categoryIdentifier: o.buttons.isEmpty ? null : _categoryId(o.buttons),
      ),
    );
  }

  /// iOS category id for a button set — derived, so intents and config agree
  /// without a shared registry. Order-sensitive on purpose.
  static String _categoryId(List<PortalNotificationButton> buttons) =>
      'portal.${buttons.map((b) => b.id).join('.')}';

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}

/// Builds stable notification ids from a group key and alert index.
int portalNotificationId(String groupKey, int index, {int modulus = 100000}) {
  return groupKey.hashCode.abs() % modulus + index;
}
