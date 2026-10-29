import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';

/// Counts onInit so the test can prove a re-put after the switch does not
/// re-initialize the kept instance. init() is never called, so no plugin runs.
class _CountingConnectivity extends ConnectivityService {
  int inits = 0;
  @override
  void onInit() {
    inits++;
    super.onInit();
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('resetForModuleSwitch keeps shared, drops per-module, closes SyncManager',
      () async {
    final conn = Get.put<ConnectivityService>(
      _CountingConnectivity(),
      permanent: true,
    );
    final mgr = SyncManager();
    await Get.putAsync<SyncManager>(() => mgr.init()); // listener + online→syncAll
    await Future<void>.delayed(Duration.zero); // let the fire-and-forget land
    final stamp = mgr.lastSyncAt.value;
    // Per-module state that must NOT survive the switch.
    Get.put<AppConfig>(
      const AppConfig(apiBaseUrl: 'https://x/api', googleSignInServerClientId: 'x'),
      permanent: true,
    );

    PortalBootstrap.resetForModuleSwitch();

    // Shared service: same instance, not re-constructed, not re-inited.
    expect(identical(Get.find<ConnectivityService>(), conn), isTrue);
    expect((conn as _CountingConnectivity).inits, 1);
    // SyncManager force-deleted → onClose ran → its reconnect listener is gone.
    expect(Get.isRegistered<SyncManager>(), isFalse);
    conn.reportReachable(false);
    conn.reportReachable(true); // offline→online edge
    await Future<void>.delayed(Duration.zero);
    expect(mgr.lastSyncAt.value, stamp,
        reason: 'closed SyncManager must not react to the reconnect');
    // Per-module state cleared by the reset.
    expect(Get.isRegistered<AppConfig>(), isFalse);
  });
}
