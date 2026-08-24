import 'dart:async';

import 'package:get/get.dart';

import 'connectivity_service.dart';
import 'sync_mutation.dart';

/// Enqueues a mutation and triggers an online push when sync is enabled.
abstract final class SyncAfterWrite {
  static Future<void> run<M extends SyncMutation>({
    required M mutation,
    required Future<void> Function(M) enqueue,
    required bool shouldSync,
    required bool Function() isSyncServiceRegistered,
    required Future<void> Function() pushToServer,
  }) async {
    if (!shouldSync) return;
    await enqueue(mutation);
    if (isSyncServiceRegistered() &&
        Get.isRegistered<ConnectivityService>() &&
        Get.find<ConnectivityService>().isOnline) {
      unawaited(pushToServer());
    }
  }
}
