import 'package:portal_ui_core/portal_ui_core.dart';

import 'sync_queue.dart';
import 'syncable_repository.dart';

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
  // Only the first queued write of an offline stretch. The banner carries
  // every one after it, so editing ten things on a train is one toast, not
  // ten.
  SyncFeedback.onQueued = (_, pendingCount) {
    if (pendingCount != 1) return;
    AppToast.show(
      'Saved on this device',
      description: "You're offline. It syncs as soon as you reconnect.",
    );
  };

  SyncFeedback.onPushed = (pushed) {
    AppToast.success(
      pushed == 1 ? 'Synced 1 change' : 'Synced $pushed changes',
    );
  };

  // The server refused these outright, so they are gone. The only path that
  // loses a local change gets the loud variant and a longer read.
  SyncFeedback.onRejected = (entityType, dropped) {
    final what = entityLabel?.call(entityType) ?? entityType;
    AppToast.error(
      dropped == 1
          ? "1 $what change couldn't be saved"
          : "$dropped $what changes couldn't be saved",
      description: 'The server refused it. It is still on this device, but it '
          'will not sync.',
      duration: const Duration(seconds: 6),
    );
  };

  // Eviction also destroys local changes, and unlike a rejection the user had
  // no signal at all that it was coming.
  SyncQueue.onEvicted = (dropped, reason) {
    AppToast.error(
      dropped == 1
          ? '1 unsynced change was discarded'
          : '$dropped unsynced changes were discarded',
      description: 'They were dropped because $reason.',
      duration: const Duration(seconds: 6),
    );
  };
}
