import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// [HapticFeedback] is a platform call; record what reaches the channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];

  setUp(() {
    calls.clear();
    PortalHaptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
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

  testWidgets('tapping a segment sends one selectionClick', (t) async {
    await t.pumpWidget(host(PortalSegmentedTabs(
      labels: const ['A', 'B'],
      index: 0,
      onChanged: (_) {},
    )));
    await t.tap(find.text('B'));
    expect(calls, ['HapticFeedbackType.selectionClick']);

    // Re-tapping the selected segment changes nothing, so it says nothing.
    await t.tap(find.text('A'));
    expect(calls, hasLength(1));
  });

  testWidgets('enabled = false sends none', (t) async {
    PortalHaptics.enabled = false;
    await t.pumpWidget(host(PortalSegmentedTabs(
      labels: const ['A', 'B'],
      index: 0,
      onChanged: (_) {},
    )));
    await t.tap(find.text('B'));
    expect(calls, isEmpty);
  });

  testWidgets('a success toast plays success once, as it appears', (t) async {
    await t.pumpWidget(host(const PortalToastHost()));
    AppToast.success('Saved');
    await t.pump();
    await t.pump(PortalHaptics.gap);
    expect(calls, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
    // Rebuilding the host is not a new toast: the card is keyed by toast id,
    // so initState must not run again.
    await t.pumpWidget(host(const PortalToastHost()));
    await t.pump(const Duration(milliseconds: 300));
    expect(calls, hasLength(2));
    AppToast.clear();
    await t.pump(const Duration(milliseconds: 300));
  });

  test('PortalThemeConfig.haptics drives the switch when given', () {
    const PortalThemeConfig(haptics: false).light();
    expect(PortalHaptics.enabled, isFalse);
    // Left null (the default), a rebuild must not stomp a user's own
    // haptics setting back on.
    const PortalThemeConfig().light();
    expect(PortalHaptics.enabled, isFalse);

    const PortalThemeConfig(haptics: true).light();
    expect(PortalHaptics.enabled, isTrue);
  });

  test('success is light then medium', () async {
    await PortalHaptics.success();
    expect(calls, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });
}
