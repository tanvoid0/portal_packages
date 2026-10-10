import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const labels = AiBackendLabels();

  late AiBackendStore store;
  AiRoutingMode? applied;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AiBackendStore(
      prefs: await SharedPreferences.getInstance(),
      keyPrefix: 'test',
    );
    applied = null;
  });

  Future<void> open(WidgetTester tester, {bool cloudEligible = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => applied = await AiRoutingSheet.show(
                context,
                store: store,
                cloudEligible: cloudEligible,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  VoidCallback? applyHandler(WidgetTester tester) =>
      tester.widget<PortalButton>(find.byType(PortalButton)).onPressed;

  testWidgets('Apply is off until the pick changes', (tester) async {
    await open(tester);
    expect(applyHandler(tester), isNull);

    await tester.tap(find.text(labels.routingLocalOnly));
    await tester.pump();
    expect(applyHandler(tester), isNotNull);

    // Back to what is stored: nothing to apply.
    await tester.tap(find.text(labels.routingServerFirst));
    await tester.pump();
    expect(applyHandler(tester), isNull);
  });

  testWidgets('Apply persists the pick and closes with it', (tester) async {
    await open(tester);

    await tester.tap(find.text(labels.routingLocalOnly));
    await tester.pump();
    await tester.tap(find.text(labels.apply));
    await tester.pumpAndSettle();

    expect(store.routingMode, AiRoutingMode.localOnly);
    expect(applied, AiRoutingMode.localOnly);
    expect(find.byType(AiRoutingSheet), findsNothing);
  });

  testWidgets('dismissing without Apply changes nothing', (tester) async {
    await open(tester);

    await tester.tap(find.text(labels.routingLocalOnly));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(store.routingMode, AiRoutingMode.serverFirst);
    expect(applied, isNull);
  });

  testWidgets('Server only is out of reach without a cloud account', (
    tester,
  ) async {
    await open(tester, cloudEligible: false);
    expect(find.text(labels.cloudNote), findsOneWidget);

    await tester.tap(find.text(labels.routingServerOnly));
    await tester.pump();

    expect(applyHandler(tester), isNull);
  });
}
