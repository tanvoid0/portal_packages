import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends ApiClient {
  _Api(this.failure);
  final ApiException failure;
  String? switchedTo = 'untouched';

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async => throw failure;

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async => throw failure;

  @override
  Future<void> switchServer(String? url) async => switchedTo = url;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});

  Future<_Api> pump(
    WidgetTester tester,
    ApiException failure, {
    PortalAuthConfig? config,
  }) async {
    Get.reset();
    final api = _Api(failure);
    try {
      await api.init(baseUrl: 'https://cloud.example/api');
    } catch (_) {
      // storage-less target: the base URL is set before the token store opens
    }
    Get.put<ApiClient>(api);
    Get.put<AppConfig>(const AppConfig(apiBaseUrl: 'https://cloud.example'));
    Get.put(PortalAuthController());
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: PortalAuthView(
          config:
              config ??
              const PortalAuthConfig(
                appIcon: Icons.lock,
                appTitle: 'Portal',
                allowLocalOnlyLogin: false,
              ),
        ),
      ),
    );
    return api;
  }

  tearDown(Get.reset);

  testWidgets('a refused sign-in is the password field\'s own error', (
    tester,
  ) async {
    await pump(tester, ApiException('Wrong email or password.', 401));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(Get.find<PortalAuthController>().errorMessage.value, isEmpty);

    // Editing the field clears it.
    await tester.enterText(find.byType(TextFormField).last, 'hunter23');
    await tester.pump();
    expect(find.text('Wrong email or password.'), findsNothing);
  });

  testWidgets('no connection stays on the banner, not on a field', (
    tester,
  ) async {
    await pump(tester, ApiException('No connection.', 0));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(Get.find<PortalAuthController>().passwordError.value, isNull);
    expect(find.text('No connection.'), findsOneWidget);
  });

  testWidgets('the test-server switch points the app at the URL and back', (
    tester,
  ) async {
    final api = await pump(
      tester,
      ApiException('x', 500),
      config: const PortalAuthConfig(
        appIcon: Icons.lock,
        appTitle: 'Portal',
        allowLocalOnlyLogin: false,
        showTestServer: true,
        testServerUrl: 'http://10.0.2.2:3001/api',
      ),
    );
    expect(find.text('Use test server'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(api.switchedTo, 'http://10.0.2.2:3001/api');
    expect(Get.find<PortalAuthController>().usingTestServer.value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(api.switchedTo, isNull);
  });

  testWidgets('no switch without a testServerUrl', (tester) async {
    await pump(
      tester,
      ApiException('x', 500),
      config: const PortalAuthConfig(
        appIcon: Icons.lock,
        appTitle: 'Portal',
        allowLocalOnlyLogin: false,
        showTestServer: true,
      ),
    );
    expect(find.text('Use test server'), findsNothing);
  });
}
