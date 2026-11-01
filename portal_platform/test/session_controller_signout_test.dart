import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingNav implements PortalNavigation {
  String? lastGo;
  @override
  String? get currentPath => lastGo;
  @override
  void go(String path, {Object? extra}) => lastGo = path;
  @override
  Future<void> push(String path, {Object? extra}) async {}
  @override
  void replace(String path, {Object? extra}) {}
  @override
  void pop({Object? result}) {}
}

/// Never reaches the real biometric plugin (no handler under flutter_test).
class _FakeDeviceSecurityService extends DeviceSecurityService {
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // GetStorage reaches for path_provider, which has no implementation here.
    final tempDir = Directory.systemTemp.createTempSync('session_signout_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  late _RecordingNav nav;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await GetStorage.init();
    nav = _RecordingNav();
    PortalNavigation.register(nav);

    Get.put<ApiClient>(
      await ApiClient().init(baseUrl: 'https://cloud.example/api'),
    );
    Get.put(
      const AppConfig(
        apiBaseUrl: '',
        routeLoggedIn: '/home',
        routeLoggedOut: '/login',
      ),
    );
    Get.put(DeepLinkService());
    Get.put(
      DeviceSecurityController(
        preferences: DeviceSecurityPreferences(GetStorage()),
        service: _FakeDeviceSecurityService(),
      )..enabled.value = true,
    );
    Get.put(SessionController());
  });

  tearDown(PortalNavigation.unregister);

  test('signing out a local-only session turns off the device lock', () async {
    final api = Get.find<ApiClient>();
    await api.startLocalOnlySession({'id': 'device-1'});
    final session = Get.find<SessionController>();
    await session.reloadFromStorage();
    expect(session.isLocalOnly, isTrue);

    await session.signOut();

    // The lock was the offline session's only credential — gone with it, so
    // the next guarded route shows login instead of a PIN/biometric prompt.
    expect(Get.find<DeviceSecurityController>().enabled.value, isFalse);
    expect(nav.lastGo, '/login');
    expect(await api.isLoggedIn(), isFalse);
  });

  test('signing out a cloud session leaves the app lock enabled', () async {
    await TokenStorage().saveTokens(accessToken: 'jwt', refreshToken: 'r');
    await TokenStorage().saveUser({'id': 'u', 'name': 'Pat'});
    final session = Get.find<SessionController>();
    await session.reloadFromStorage();
    expect(session.isLocalOnly, isFalse);

    await session.signOut();

    // A deliberately-enabled app lock is the user's own device setting, not a
    // credential the offline flow created, so sign-out must not clear it.
    expect(Get.find<DeviceSecurityController>().enabled.value, isTrue);
    expect(nav.lastGo, '/login');
  });
}
