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
}
