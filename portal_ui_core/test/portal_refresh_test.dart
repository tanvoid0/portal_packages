import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
    PortalHaptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  /// A pull past the threshold, released, and the spinner's settle.
  Future<void> pull(WidgetTester t) async {
    await t.fling(find.text('row 0'), const Offset(0, 300), 1000);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  testWidgets('pull calls onRefresh once, with one light haptic', (t) async {
    var refreshes = 0;
    await t.pumpWidget(host(PortalRefresh(
      onRefresh: () async => refreshes++,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(20, (i) => ListTile(title: Text('row $i'))),
      ),
    )));

    await pull(t);
    expect(refreshes, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    final indicator = t.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    expect(indicator.elevation, 0);
    expect(indicator.strokeWidth, 2.5);
  });

  testWidgets('PortalScrollPage drops the disc under its large header',
      (t) async {
    await t.pumpWidget(host(PortalScrollPage(
      header: const PortalHeader.large(title: 'Library'),
      onRefresh: () async {},
      children: List.generate(20, (i) => ListTile(title: Text('row $i'))),
    )));

    final indicator = t.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    expect(indicator.edgeOffset, PortalHeader.expandedHeight);
  });
}
