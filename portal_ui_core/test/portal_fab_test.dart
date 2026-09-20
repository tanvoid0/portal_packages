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

  Widget host(Widget fab) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: const SizedBox.expand(), floatingActionButton: fab),
      );

  testWidgets('PortalFab carries its tooltip and taps with one medium haptic',
      (t) async {
    var taps = 0;
    await t.pumpWidget(host(PortalFab(
      icon: Icons.add,
      tooltip: 'Add',
      onPressed: () => taps++,
    )));
    expect(find.byTooltip('Add'), findsOneWidget);
    expect(t.getSize(find.byType(Ink)), const Size.square(PortalFab.size));

    await t.tap(find.byType(PortalFab));
    await t.pump();
    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('PortalFab is 56 square under the fleet theme (22 dp icons)',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: const PortalThemeConfig().light(),
      home: Scaffold(
        floatingActionButton:
            PortalFab(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
      ),
    ));
    expect(t.getSize(find.byType(Ink)), const Size.square(PortalFab.size));
  });

  testWidgets('extended collapses on a scroll down and re-extends on the way up',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: PortalScrollPage(
        title: 'Items',
        floatingActionButton: PortalFab.extended(
          icon: Icons.add,
          label: 'Add item',
          onPressed: () {},
        ),
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('$i')),
        ],
      ),
    ));
    final tooltip = find.descendant(
        of: find.byType(PortalFab), matching: find.byType(Tooltip));
    expect(find.text('Add item'), findsOneWidget);
    // The visible label names it; the tooltip stays out of semantics.
    expect(t.widget<Tooltip>(tooltip).excludeFromSemantics, isTrue);
    final extendedWidth = t.getSize(find.byType(Ink)).width;
    expect(extendedWidth, greaterThan(PortalFab.size));

    await t.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await t.pumpAndSettle();
    expect(find.text('Add item'), findsNothing);
    expect(t.getSize(find.byType(Ink)).width, PortalFab.size);
    // The label is gone, so the tooltip carries the name.
    expect(t.widget<Tooltip>(tooltip).excludeFromSemantics, isFalse);

    await t.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await t.pumpAndSettle();
    expect(find.text('Add item'), findsOneWidget);
    expect(t.getSize(find.byType(Ink)).width, extendedWidth);

    // A programmatic return to the top (tab re-tap, refresh reset) has no
    // user direction; it must still re-extend.
    await t.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await t.pumpAndSettle();
    expect(find.text('Add item'), findsNothing);
    t.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
    await t.pumpAndSettle();
    expect(find.text('Add item'), findsOneWidget);
  });

  testWidgets('PortalToolbar gives every action a tooltip and fires it',
      (t) async {
    var shared = 0;
    await t.pumpWidget(host(PortalToolbar(
      actions: [
        PortalAction(
          icon: Icons.share,
          label: 'Share',
          onPressed: () => shared++,
        ),
        PortalAction(icon: Icons.delete, label: 'Delete', onPressed: () {}),
      ],
    )));
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await t.tap(find.byTooltip('Share'));
    expect(shared, 1);
  });
}
