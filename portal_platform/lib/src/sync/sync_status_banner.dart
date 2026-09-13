import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'connectivity_service.dart';
import 'sync_manager.dart';
import 'sync_queue.dart';

/// Bottom strip that says what the offline-first data layer is doing.
///
/// The app already worked offline — reads fell back to the cache and writes
/// landed in [SyncQueue] — but it did so completely silently, so a session
/// with no network was indistinguishable from a broken app. This is the only
/// place that state is visible.
///
/// Three states, in priority order:
///  * **offline** — cloud_off, plus the pending count when there is one.
///  * **online with a queue** — syncing, tappable to retry now.
///  * **online and empty** — hidden.
///
/// Mount it once, above the app's content and below any toast host — see
/// [portalInstallSyncFeedback] for the toasts that go with it.
// Matches the shared spacing/radius scale. Held as literals rather than
// imported so the banner stays usable from an app with its own token set.
const double _spacingS = 8;
const double _spacingM = 12;
const double _spacingL = 16;
const double _radiusFull = 999;

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, this.bottomInset = 0});

  /// Space to leave under the strip, e.g. for a bottom nav bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>() ||
        !Get.isRegistered<SyncQueue>()) {
      return const SizedBox.shrink();
    }
    final connectivity = Get.find<ConnectivityService>();
    final queue = Get.find<SyncQueue>();

    return Obx(() {
      final online = connectivity.isOnlineRx.value;
      final pending = queue.pendingCount.value;
      if (online && pending == 0) return const SizedBox.shrink();

      final syncing = Get.isRegistered<SyncManager>() &&
          Get.find<SyncManager>().isSyncing.value;

      return _Strip(
        online: online,
        pending: pending,
        syncing: syncing,
        bottomInset: bottomInset,
      );
    });
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.online,
    required this.pending,
    required this.syncing,
    required this.bottomInset,
  });

  final bool online;
  final int pending;
  final bool syncing;
  final double bottomInset;

  static String _changes(int n) => n == 1 ? '1 change' : '$n changes';

  String get _label {
    if (!online) {
      return pending == 0
          ? "You're offline — showing saved data"
          : "You're offline — ${_changes(pending)} waiting to sync";
    }
    return syncing
        ? 'Syncing ${_changes(pending)}…'
        : '${_changes(pending)} waiting to sync';
  }

  /// Only a stalled queue is worth a manual retry: offline there is nothing to
  /// retry against, and a running sync is already doing it.
  bool get _canRetry => online && !syncing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Offline is a state to be aware of, not an error — the app still works —
    // so it reads as neutral chrome rather than the error red a failure gets.
    final background = online ? cs.secondaryContainer : cs.surfaceContainerHigh;
    final foreground = online ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _spacingM,
          0,
          _spacingM,
          bottomInset + _spacingM,
        ),
        child: Semantics(
          liveRegion: true,
          button: _canRetry,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(_radiusFull),
            child: InkWell(
              borderRadius: BorderRadius.circular(_radiusFull),
              onTap: _canRetry ? () => Get.find<SyncManager>().syncAll() : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _spacingL,
                  vertical: _spacingS + 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Leading(
                      online: online,
                      syncing: syncing,
                      color: foreground,
                    ),
                    const SizedBox(width: _spacingS),
                    Flexible(
                      child: Text(
                        _label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: foreground),
                      ),
                    ),
                    if (_canRetry) ...[
                      const SizedBox(width: _spacingS),
                      Text(
                        'Retry',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.online,
    required this.syncing,
    required this.color,
  });

  final bool online;
  final bool syncing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (online && syncing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Icon(
      online ? Icons.cloud_upload_outlined : Icons.cloud_off,
      size: 16,
      color: color,
    );
  }
}
