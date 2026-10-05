import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> skin = const []}) =>
      MaterialApp(
        theme: PortalThemeConfig(extensionsBuilder: (_) => skin).light(),
        home: Scaffold(body: Center(child: child)),
      );

  Color? fill(WidgetTester t) => t
      .widget<Material>(find
          .descendant(
              of: find.byType(PortalCard), matching: find.byType(Material))
          .first)
      .color;

  testWidgets('value colour and background: widget beats theme beats default',
      (t) async {
    await t.pumpWidget(host(const PortalStatCard(value: '9', label: 'A')));
    final plain = fill(t);
    final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
    expect(t.widget<Text>(find.text('9')).style!.color, cs.onSurface);

    await t.pumpWidget(host(
      const PortalStatCard(value: '9', label: 'A'),
      skin: const [
        PortalStatCardTheme(backgroundColor: Colors.teal, valueColor: Colors.red),
      ],
    ));
    await t.pumpAndSettle();
    expect(fill(t), Colors.teal);
    expect(t.widget<Text>(find.text('9')).style!.color, Colors.red);

    await t.pumpWidget(host(
      const PortalStatCard(
        value: '9',
        label: 'A',
        valueColor: Colors.green,
        backgroundColor: Colors.amber,
      ),
      skin: const [
        PortalStatCardTheme(backgroundColor: Colors.teal, valueColor: Colors.red),
      ],
    ));
    await t.pumpAndSettle();
    expect(fill(t), Colors.amber);
    expect(t.widget<Text>(find.text('9')).style!.color, Colors.green);
    expect(plain, isNot(Colors.amber));
  });
}
