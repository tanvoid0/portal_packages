import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import 'connectivity_service.dart';
import 'sync_queue.dart';
import 'syncable_repository.dart';

// The toasts [portalInstallSyncFeedback] raises, as plain data. Public so the
// design kit previews the real copy and variant instead of a hand-kept twin
// that drifts the first time the wording changes.

/// First queued write of an offline stretch. The banner carries every one
/// after it, so editing ten things on a train is one toast, not ten.
/// [offline] false means the device is online but the server failed: saying
/// "you're offline" then is false, and sends the user to check their wifi.
PortalToastData syncQueuedToast({bool offline = true}) => PortalToastData(
      title: 'Saved on this device',
      description: offline
          ? "You're offline. It syncs as soon as you reconnect."
          : "The server couldn't take it just now. It retries automatically.",
    );

/// [pushed] queued changes reached the server.
PortalToastData syncPushedToast(int pushed) => PortalToastData(
      title: pushed == 1 ? 'Synced 1 change' : 'Synced $pushed changes',
      variant: PortalToastVariant.success,
    );

/// The server refused [dropped] changes outright, so they will not sync. The
/// only path that gives up on a local change gets the loud variant and a
/// longer read. [what] is the user-facing word for the entity ('recipe').
PortalToastData syncRejectedToast(int dropped, String what) => PortalToastData(
      title: dropped == 1
          ? "1 $what change couldn't be saved"
          : "$dropped $what changes couldn't be saved",
      description: 'The server refused it. It is still on this device, but it '
          'will not sync.',
      variant: PortalToastVariant.destructive,
      duration: const Duration(seconds: 6),
    );

/// [dropped] unsynced changes were evicted for [reason]. Eviction also
/// destroys local changes, and unlike a rejection the user had no signal at
/// all that it was coming.
PortalToastData syncEvictedToast(int dropped, String reason) => PortalToastData(
      title: dropped == 1
          ? '1 unsynced change was discarded'
          : '$dropped unsynced changes were discarded',
      description: 'They were dropped because $reason.',
      variant: PortalToastVariant.destructive,
      duration: const Duration(seconds: 6),
    );

/// Give the offline-first data layer a voice, in one call.
///
/// [SyncableRepository] queues a write it cannot push and returns normally.
/// That is the right behaviour and the wrong experience: with nothing on
/// screen saying so, working with no network is indistinguishable from an app
/// that ignored you. [SyncStatusBanner] shows the standing state; these
/// toasts mark the transitions worth interrupting for.
///
/// Call once during startup, after [SyncQueue] is registered. Pair it with a
/// [SyncStatusBanner] in the app shell and a `PortalToastHost` above it.
///
/// [entityLabel] maps a repository's `entityType` to a word for the user
/// ('recipe' → 'recipes'); the raw type is used when it returns null.
void portalInstallSyncFeedback({String? Function(String entityType)? entityLabel}) {
  SyncFeedback.onQueued = (_, pendingCount) {
    if (pendingCount != 1) return;
    final online = Get.isRegistered<ConnectivityService>() &&
        Get.find<ConnectivityService>().isOnline;
    AppToast.present(syncQueuedToast(offline: !online));
  };

  SyncFeedback.onPushed = (pushed) => AppToast.present(syncPushedToast(pushed));

  SyncFeedback.onRejected = (entityType, dropped) => AppToast.present(
        syncRejectedToast(dropped, entityLabel?.call(entityType) ?? entityType),
      );

  SyncQueue.onEvicted =
      (dropped, reason) => AppToast.present(syncEvictedToast(dropped, reason));
}
