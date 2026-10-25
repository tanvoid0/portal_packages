import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Never reaches the real biometric plugin: [scheduleAutoUnlock] fires on
/// every lock, and the platform channel it would otherwise hit has no
/// handler under `flutter_test` (and on some hosts not even a
/// `MissingPluginException` — it can hang waiting on a real OS prompt).
class _FakeDeviceSecurityService extends DeviceSecurityService {
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

/// [PortalAppRoot.shouldGuardRoute] wires [PortalDeviceSecurityGate] to the
/// current route without a mid-build write to the guard [RxBool] — the
/// hazard finance's hand-rolled root used to guard against by hand.
void main() {
  setUpAll(() {
    // GetStorage reaches for path_provider, which has no implementation
    // under flutter_test.
    final tempDir = Directory.systemTemp.createTempSync(
      'portal_app_root_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await GetStorage.init();
    Get.put(
      const AppConfig(
        apiBaseUrl: '',
        routeLoggedIn: '/home',
        routeLoggedOut: '/login',
      ),
    );
    Get.put(PortalThemeController());
    Get.put(
      DeviceSecurityController(
        preferences:
            DeviceSecurityPreferences(GetStorageKeyValueStore(GetStorage())),
        service: _FakeDeviceSecurityService(),
      ),
    )
      ..enabled.value = true
      ..lock();
  });

  Widget buildRoot({bool Function(String route)? shouldGuardRoute}) {
    return PortalAppRoot(
      title: 'Test',
      lightTheme: (_) => ThemeData.light(),
      darkTheme: (_) => ThemeData.dark(),
      getPages: [
        GetPage(name: '/login', page: () => const Text('login')),
        GetPage(name: '/home', page: () => const Text('home')),
      ],
      shouldGuardRoute: shouldGuardRoute,
    );
  }

  testWidgets('guard follows the route with no mid-build write', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildRoot(shouldGuardRoute: (route) => route != '/login'),
    );
    await tester.pumpAndSettle();

    // The persistentCallbacks-phase write from the very first route would
    // throw "setState() called during build" here if the scheduler guard
    // regressed.
    expect(tester.takeException(), isNull);
    expect(find.byType(PortalDeviceSecurityLockView), findsNothing);

    Get.toNamed('/home');
    await tester.pumpAndSettle();
    expect(find.byType(PortalDeviceSecurityLockView), findsOneWidget);

    Get.offAllNamed('/login');
    await tester.pumpAndSettle();
    expect(find.byType(PortalDeviceSecurityLockView), findsNothing);
  });

  testWidgets('null shouldGuardRoute defaults to guarding all but login', (
    tester,
  ) async {
    await tester.pumpWidget(buildRoot());
    await tester.pumpAndSettle();
    expect(find.byType(PortalDeviceSecurityGate), findsOneWidget);
    expect(find.byType(PortalDeviceSecurityLockView), findsNothing);

    Get.toNamed('/home');
    await tester.pumpAndSettle();
    expect(find.byType(PortalDeviceSecurityLockView), findsOneWidget);
  });

  testWidgets('no controller registered mounts no gate at all', (tester) async {
    Get.delete<DeviceSecurityController>(force: true);
    await tester.pumpWidget(buildRoot());
    await tester.pumpAndSettle();

    expect(find.byType(PortalDeviceSecurityGate), findsNothing);
  });
}
