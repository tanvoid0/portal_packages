import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends ApiClient {
  bool up = true;

  @override
  Future<BackendReadinessResult> checkBackendReadiness({
    Duration timeout = const Duration(seconds: 12),
    String? baseUrl,
  }) async => up
      ? const BackendReadinessResult(isReady: true)
      : const BackendReadinessResult(isReady: false, errorMessage: 'down');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(envString: 'UNUSED=1');
    Get.reset();
    api = _FakeApi();
    await api.init(baseUrl: 'https://cloud.example/api');
    Get.put<ApiClient>(api);
  });

  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const PortalServerPage(),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('healthy server shows the online badge', (t) async {
    await open(t);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('unreachable server shows the problem with a retry', (t) async {
    api.up = false;
    await open(t);
    expect(find.text('Unreachable'), findsOneWidget);
    expect(find.text('down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a public host is refused before any ping', (t) async {
    await open(t);
    await t.enterText(find.byType(EditableText), 'example.com');
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.textContaining('local-network'), findsOneWidget);
  });

  testWidgets('a tested local host offers the switch', (t) async {
    await open(t);
    await t.tap(find.text('Check'));
    await t.pumpAndSettle();
    expect(find.textContaining('Online ·'), findsOneWidget);
    expect(find.text('Switch and sign out'), findsOneWidget);
  });
}
