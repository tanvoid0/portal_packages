import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed in, so the Account row/group actually renders.
class _FakeSession extends SessionController {
  _FakeSession() {
    user.value = {'name': 'Ada Lovelace', 'email': 'ada@example.com'};
  }

  @override
  Future<void> reloadFromStorage() async {}
}

/// Readiness is never asked here -- nothing in these tests taps Mode.
class _FakeApi extends ApiClient {
  @override
  Future<BackendReadinessResult> checkBackendReadiness({
    Duration timeout = const Duration(seconds: 12),
    String? baseUrl,
  }) => Completer<BackendReadinessResult>().future;
}

/// The shape a batch app builds: its own root, a settings node under it, and
/// [portalSettingsChildren]'s own pages nested under that.
List<GetPage> _tree(Widget Function() settingsPage) => [
  GetPage(
    name: '/x',
    page: () => const SizedBox(),
    children: [
      GetPage(
        name: '/settings',
        page: settingsPage,
        children: portalSettingsChildren(
          include: const [PortalSettingsGroup.about],
        ),
      ),
    ],
  ),
];

void main() {
  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Portal Test',
      packageName: 'uk.aipairs.portal.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await PortalAppVersion.load();
    final api = _FakeApi();
    await api.init(baseUrl: 'https://cloud.example/api');
    Get.put<ApiClient>(api);
    Get.put<SessionController>(_FakeSession());
  });

  testWidgets('the nested GetPage tree resolves full paths', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        initialRoute: '/x/settings',
        getPages: _tree(() => const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed('/x/settings/account');
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/x/settings/account');

    Get.toNamed('/x/settings/account/change-password');
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/x/settings/account/change-password');
  });

  testWidgets('settingsRoute makes the change-password row navigate by name', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        initialRoute: '/x/settings',
        getPages: _tree(
          () => const PortalSettingsPage(
            settingsRoute: '/x/settings',
            include: [PortalSettingsGroup.about],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    // Lands on the named route -- an unnamed MaterialPageRoute push would
    // leave Get.currentRoute at '/x/settings'.
    expect(Get.currentRoute, '/x/settings/account/change-password');
  });
}
