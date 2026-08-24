import 'package:get/get.dart';

import 'connectivity_service.dart';

/// Shared sync observables and connectivity guard for entity sync services.
abstract class BaseEntitySyncService extends GetxService {
  final isSyncing = false.obs;
  final lastSyncAt = Rxn<DateTime>();
  final lastError = RxnString();
  final pendingPushCount = 0.obs;

  /// Returns false when device is offline and push should be deferred.
  bool get isOnlineForPush {
    if (!Get.isRegistered<ConnectivityService>()) return true;
    return Get.find<ConnectivityService>().isOnline;
  }

  void clearLastError() => lastError.value = null;

  void setSyncError(Object error) => lastError.value = error.toString();
}
