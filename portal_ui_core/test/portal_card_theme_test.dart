import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> skin = const []}) =>
      MaterialApp(
        theme: PortalThemeConfig(extensionsBuilder: (_) => skin).light(),
        home: Scaffold(body: Center(child: child)),
      );

  Material card(WidgetTester t) => t.widget<Material>(find
      .descendant(of: find.byType(PortalCard), matching: find.byType(Material))
      .first);

  const skin = PortalCardTheme(
    padding: EdgeInsets.all(40),
    borderRadius: BorderRadius.all(Radius.circular(3)),
    backgroundColor: Colors.teal,
    border: BorderSide(color: Colors.red, width: 2),
    elevation: PortalCardElevation.card,
  );

  testWidgets('theme sets padding, radius, fill, border and shadow',
      (t) async {
    await t.pumpWidget(
        host(const PortalCard(child: SizedBox(key: Key('c'))), skin: [skin]));
    await t.pumpAndSettle();
    final m = card(t);
    expect(m.color, Colors.teal);
    final shape = m.shape! as OutlinedBorder;
    expect(shape.side.color, Colors.red);
    final inner = t.getRect(find.byKey(const Key('c')));
    final outer = t.getRect(find.byType(PortalCard));
    expect(outer.width - inner.width, 80);
    final deco = t.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(PortalCard), matching: find.byType(DecoratedBox))
        .first);
    expect((deco.decoration as ShapeDecoration).shadows, isNotEmpty);
  });

  testWidgets('a widget argument beats the theme', (t) async {
    await t.pumpWidget(host(
      const PortalCard(
        backgroundColor: Colors.amber,
        elevation: PortalCardElevation.flat,
        child: SizedBox(),
      ),
      skin: [skin],
    ));
    await t.pumpAndSettle();
    expect(card(t).color, Colors.amber);
    final deco = t.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(PortalCard), matching: find.byType(DecoratedBox))
        .first);
    expect((deco.decoration as ShapeDecoration).shadows, isEmpty);
  });

  testWidgets('no theme leaves the default card', (t) async {
    await t.pumpWidget(host(const PortalCard(child: SizedBox())));
    final m = card(t);
    expect(m.color, isNot(Colors.teal));
  });
}
