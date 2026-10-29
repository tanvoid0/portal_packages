import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';

void main() {
  // SessionController's ctor resolves ApiClient from Get, so register a fake
  // one first (exactly as PortalBootstrap does in PORTAL_FAKE mode).
  setUp(() {
    Get.testMode = true;
    Get.put<ApiClient>(FakeApi());
  });
  tearDown(Get.reset);

  test('FakeSession seeds the demo user and does no storage I/O', () async {
    final s = FakeSession(kPortalFakeUser);
    expect(s.user.value, kPortalFakeUser);
    await s.reloadFromStorage(); // must not reach storage or clear the user
    expect(s.user.value, kPortalFakeUser);
  });

  test('FakeSession(null) is signed out', () {
    expect(FakeSession(null).user.value, isNull);
  });

  test('FakeApi reports the backend ready (down) without a network probe',
      () async {
    expect((await FakeApi().checkBackendReadiness()).isReady, isTrue);
    expect((await FakeApi(up: false).checkBackendReadiness()).isReady, isFalse);
  });
}
