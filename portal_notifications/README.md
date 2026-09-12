# portal_notifications

Local + scheduled OS notifications for every Portal app: quick-action
buttons, daily/weekly/monthly repeats, subtitle, silent, ongoing, and a
persisted list of what is pending for in-app UI. No Firebase — nothing here
needs a server.

## Wire an app (once)

```dart
final hub = PortalNotificationHub.create(
  config: PortalNotificationsConfig(
    channelId: 'portal_x_reminders',        // stable forever
    channelName: 'Reminders',
    buttonSets: const [myButtons],          // every combo you will show (iOS)
    onBackgroundResponse: onBackground,     // only if a button has opensApp: false
  ),
  storageKey: 'portal_x_notification_entries',
  onAction: (action) => Get.toNamed(action.params['route']!),
  onButton: (buttonId, intentId, action) { /* app opened by a button */ },
);
await hub.init();                           // in a PortalStartupStep; a tap
                                            // that cold-started the app replays
                                            // through onAction/onButton here
```

```dart
// Buttons with opensApp: false run here, app closed, no Get / no stores.
@pragma('vm:entry-point')
Future<void> onBackground(NotificationResponse r) async { ... }
```

Android, per app: `POST_NOTIFICATIONS`, `VIBRATE`, `SCHEDULE_EXACT_ALARM`,
`USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` in the manifest, the three
`com.dexterous.flutterlocalnotifications.*Receiver` entries (`Scheduled…`,
`ScheduledNotificationBoot…`, and `ActionBroadcastReceiver` — the plugin's
own manifest declares none of them; a missing `ActionBroadcastReceiver`
drops background button taps with no error), and
`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring(...)` in
`app/build.gradle.kts`. Copy from `apps/portal_finance`.

## Show or schedule

```dart
await hub.applyIntent(PortalNotificationIntent(
  id: bill.id,                              // re-applying the same id replaces
  source: PortalNotificationSource.app,
  kind: PortalNotificationKind.scheduledEvent,   // or .immediate
  groupKey: 'bills',                        // hub.cancelGroup('bills')
  title: 'Rent due tomorrow',
  body: '£950.00',
  fireAt: when,                             // omit / past => shows now
  action: PortalNotificationActions.openRouteAction(route: '/bills'),
  options: const PortalNotificationOptions(
    buttons: [
      PortalNotificationButton(id: 'paid', label: 'Mark paid'),
      PortalNotificationButton(id: 'snooze', label: 'Snooze', opensApp: false),
    ],
    repeat: PortalNotificationRepeat.none,  // daily / weekly / monthly
    subtitle: 'Bills',
    silent: false,
    ongoing: false,
  ),
));
```

`hub.entriesForDisplay()` is the pending list for an in-app "upcoming" view.
Reference consumer: `apps/portal_finance/lib/core/bill_reminders.dart`.
