import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> ext = const []}) {
    final base = buildPortalTheme(brightness: Brightness.light);
    return MaterialApp(
      theme: base.copyWith(extensions: [...base.extensions.values, ...ext]),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('badge takes a widget leading tinted by the tone', (t) async {
    await t.pumpWidget(host(const PortalBadge(
      label: 'Paid',
      tone: PortalBadgeTone.success,
      outlined: true,
      leading: Text('G'),
    )));
    expect(find.text('G'), findsOneWidget);
    final iconTheme = t.widget<IconTheme>(find
        .ancestor(of: find.text('G'), matching: find.byType(IconTheme))
        .first);
    expect(iconTheme.data.color,
        PortalSemanticColors.of(t.element(find.text('G'))).success);
  });

  testWidgets('chip theme sets colours; widget argument still wins', (t) async {
    const theme = PortalFilterChipTheme(
      selectedColor: Colors.amber,
      unselectedColor: Colors.teal,
    );
    Color? fillOf() =>
        (t.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
                as BoxDecoration)
            .color;
    await t.pumpWidget(host(
      const PortalFilterChip(label: 'A', selected: true),
      ext: [theme],
    ));
    expect(fillOf(), Colors.amber);
    await t.pumpWidget(host(
      const PortalFilterChip(label: 'A', selected: false),
      ext: [theme],
    ));
    await t.pumpAndSettle();
    expect(fillOf(), Colors.teal);
    await t.pumpWidget(host(
      const PortalFilterChip(
          label: 'A', selected: false, unselectedColor: Colors.pink),
      ext: [theme],
    ));
    await t.pumpAndSettle();
    expect(fillOf(), Colors.pink);
  });

  testWidgets('compact paints 32 but keeps a minTapTarget hit area', (t) async {
    var taps = 0;
    await t.pumpWidget(host(PortalFilterChip(
      label: 'A',
      selected: false,
      compact: true,
      onTap: () => taps++,
    )));
    expect(t.getSize(find.byType(AnimatedContainer)).height, 32);
    expect(t.getSize(find.byType(PortalPressable)).height, 48);
    // a tap 19 dp above centre is outside the 32 dp paint but inside the 48 dp target.
    final c = t.getCenter(find.byType(AnimatedContainer));
    await t.tapAt(c - const Offset(0, 19));
    expect(taps, 1);
  });

  testWidgets('theme minHeight sets the painted height', (t) async {
    await t.pumpWidget(host(
      const PortalFilterChip(label: 'A', selected: false),
      ext: [const PortalFilterChipTheme(minHeight: 36)],
    ));
    expect(t.getSize(find.byType(AnimatedContainer)).height, 36);
  });

  testWidgets('onDeleted adds a named delete target apart from the chip',
      (t) async {
    final h = t.ensureSemantics();
    var taps = 0, deletes = 0;
    await t.pumpWidget(host(PortalFilterChip(
      label: 'Vegan',
      selected: true,
      compact: true,
      onTap: () => taps++,
      onDeleted: () => deletes++,
      deleteTooltip: 'Remove vegan',
    )));
    expect(find.byTooltip('Remove vegan'), findsOneWidget);
    final del = t.getRect(find.byTooltip('Remove vegan'));
    expect(del.width, greaterThanOrEqualTo(44));
    expect(del.height, greaterThanOrEqualTo(44));

    // Above the 32 dp paint, inside the 44+ target, at the close glyph.
    await t.tapAt(Offset(del.center.dx, del.top + 3));
    expect(deletes, 1);
    expect(taps, 0);

    await t.tap(find.text('Vegan'));
    expect(taps, 1);
    expect(deletes, 1);
    expect(
        t.getSemantics(find.byTooltip('Remove vegan')),
        isSemantics(
            tooltip: 'Remove vegan', isButton: true, hasTapAction: true));
    h.dispose();
  });

  testWidgets('a compact chip hugs its label in a Wrap', (t) async {
    await t.pumpWidget(host(const SizedBox(
      width: 300,
      child: Wrap(children: [
        PortalFilterChip(label: 'A', selected: false, compact: true),
      ]),
    )));
    expect(t.getSize(find.byType(PortalPressable)).width, lessThan(100));
  });

  testWidgets('compact beats a theme minHeight', (t) async {
    await t.pumpWidget(host(
      const PortalFilterChip(label: 'A', selected: false, compact: true),
      ext: [const PortalFilterChipTheme(minHeight: 40)],
    ));
    expect(t.getSize(find.byType(AnimatedContainer)).height, 32);
  });

  testWidgets('tapping the label end of a deletable chip does not delete',
      (t) async {
    var taps = 0, deletes = 0;
    await t.pumpWidget(host(PortalFilterChip(
      label: 'Vegan',
      selected: true,
      onTap: () => taps++,
      onDeleted: () => deletes++,
      deleteTooltip: 'Remove vegan',
    )));
    final label = t.getRect(find.text('Vegan'));
    await t.tapAt(Offset(label.right - 2, label.center.dy));
    expect(deletes, 0);
    expect(taps, 1);
  });

  group('PortalFilterChipRow edge fade', () {
    Widget row(int n) => host(SizedBox(
          width: 300,
          child: PortalFilterChipRow(
            children: [
              for (var i = 0; i < n; i++) PortalFilterChip(label: 'Chip $i', selected: false)
            ],
          ),
        ));

    testWidgets('nothing fades while every chip fits', (t) async {
      await t.pumpWidget(row(2));
      await t.pump();
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('fades once chips run past the edge, and keeps the offset',
        (t) async {
      await t.pumpWidget(row(12));
      await t.pump();
      expect(find.byType(ShaderMask), findsOneWidget);

      await t.drag(find.byType(SingleChildScrollView), const Offset(-120, 0));
      await t.pump();
      expect(find.byType(ShaderMask), findsOneWidget);
      final scroll = t.state<ScrollableState>(find.byType(Scrollable));
      expect(scroll.position.pixels, greaterThan(0));

      await t.drag(find.byType(SingleChildScrollView), const Offset(-5000, 0));
      await t.pump();
      // Scrolled to the end: the start edge fades now, not the end.
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(scroll.position.pixels, scroll.position.maxScrollExtent);
    });
  });

  group('selected chip check', () {
    testWidgets('a selected chip with no glyph of its own gets a check',
        (t) async {
      await t.pumpWidget(host(const PortalFilterChip(label: 'A', selected: true)));
      expect(find.byIcon(PortalIcons.check_rounded), findsOneWidget);
    });

    testWidgets('unselected, action, menu and own-icon chips do not',
        (t) async {
      await t.pumpWidget(host(const Column(children: [
        PortalFilterChip(label: 'A', selected: false),
        PortalFilterChip.action(label: 'B'),
        PortalFilterChip(label: 'C', selected: true, menu: true),
        PortalFilterChip(label: 'D', selected: true, icon: Icons.star),
      ])));
      expect(find.byIcon(PortalIcons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('a chosen selected colour gets a readable ink', (t) async {
      await t.pumpWidget(host(const PortalFilterChip(
        label: 'A',
        selected: true,
        selectedColor: Color(0xFFFFCA28),
      )));
      expect(t.widget<Text>(find.text('A')).style?.color, Colors.black);
    });
  });
}
