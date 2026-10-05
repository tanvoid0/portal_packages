import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('colour override beats the variant', (t) async {
    await t.pumpWidget(host(PortalButton(
      label: 'Go',
      onPressed: () {},
      backgroundColor: Colors.amber,
      foregroundColor: Colors.indigo,
    )));
    final ink = t.widget<Ink>(find.byType(Ink));
    expect((ink.decoration! as BoxDecoration).color, Colors.amber);
    expect(t.widget<Text>(find.text('Go')).style!.color, Colors.indigo);
  });

  testWidgets('icon button is a circle with a tooltip and a tap target',
      (t) async {
    var taps = 0;
    await t.pumpWidget(host(PortalButton.icon(
      icon: Icons.add,
      tooltip: 'Add item',
      size: PortalButtonSize.sm,
      onPressed: () => taps++,
    )));
    expect(find.byTooltip('Add item'), findsOneWidget);
    expect(t.getSize(find.byType(Ink)), const Size(36, 36));
    expect(
        t.getSize(find.byType(PortalButton)).width, greaterThanOrEqualTo(44));
    await t.tap(find.byIcon(Icons.add));
    expect(taps, 1);
  });

  testWidgets('dock grid takes per-action flex', (t) async {
    await t.pumpWidget(host(PortalButtonDock.grid(
      columns: 2,
      flexes: const [1, 3],
      showRule: false,
      actions: [
        PortalButton(label: 'A', expand: true, onPressed: () {}),
        PortalButton(label: 'B', expand: true, onPressed: () {}),
      ],
    )));
    final a = t.getSize(find.widgetWithText(PortalButton, 'A')).width;
    final b = t.getSize(find.widgetWithText(PortalButton, 'B')).width;
    expect(b / a, closeTo(3, .1));
  });

  testWidgets('dock grid scrolls sideways', (t) async {
    t.view.physicalSize = const Size(300, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(PortalButtonDock.grid(
      scrollable: true,
      showRule: false,
      actions: [
        for (var i = 0; i < 6; i++)
          PortalButton(label: 'Action $i', onPressed: () {}),
      ],
    )));
    expect(find.text('Action 5').hitTestable(), findsNothing);
    await t.drag(find.byType(SingleChildScrollView), const Offset(-900, 0));
    await t.pump();
    expect(find.text('Action 5').hitTestable(), findsOneWidget);
  });

  testWidgets('icon button takes a widget glyph and a selected state',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalButton.icon(
      iconWidget: const Text('FA', key: Key('g')),
      tooltip: 'Favourite',
      onPressed: () {},
    )));
    expect(find.byKey(const Key('g')), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    Future<void> toggle(bool on) => t.pumpWidget(host(PortalButton.icon(
          icon: Icons.favorite,
          tooltip: 'Favourite',
          selected: on,
          onPressed: () {},
        )));
    await toggle(false);
    final off = (t.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration)
        .color;
    expect(t.widget<Icon>(find.byIcon(Icons.favorite)).fill, 0);

    await toggle(true);
    final on = (t.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration)
        .color;
    expect(on, isNot(off));
    expect(t.widget<Icon>(find.byIcon(Icons.favorite)).fill, 1);
    expect(find.byTooltip('Favourite'), findsOneWidget);
    expect(
        t.getSemantics(find.byTooltip('Favourite')),
        isSemantics(
            tooltip: 'Favourite',
            isSelected: true,
            hasSelectedState: true,
            isButton: true));
    h.dispose();
  });

  testWidgets('icon button hit area is the tap target, not the paint',
      (t) async {
    var taps = 0;
    await t.pumpWidget(host(PortalButton.icon(
      icon: Icons.add,
      tooltip: 'Add item',
      size: PortalButtonSize.sm,
      onPressed: () => taps++,
    )));
    // Paint is 36; 21 dp off centre is in the margin of the 48 target.
    await t.tapAt(t.getCenter(find.byType(Ink)) + const Offset(0, 21));
    expect(taps, 1);
    await t.tap(find.byIcon(Icons.add));
    expect(taps, 2);
  });

  testWidgets('a button with no handler is still a disabled button',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalButton.icon(
      icon: Icons.remove,
      tooltip: 'Decrease',
    )));
    expect(t.getSemantics(find.byType(PortalPressable)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false));
    h.dispose();
  });
}
