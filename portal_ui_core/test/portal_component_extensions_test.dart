import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child, {List<ThemeExtension<dynamic>> skin = const []}) {
    final config = PortalThemeConfig(extensionsBuilder: (_) => skin);
    return MaterialApp(
      theme: config.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  Color tintOf(WidgetTester t) {
    final well = t.widget<Container>(find
        .ancestor(of: find.byIcon(Icons.bolt), matching: find.byType(Container))
        .first);
    return (well.decoration! as BoxDecoration).color!.withValues(alpha: 1);
  }

  testWidgets('stat card: config extension re-skins, widget arg wins',
      (t) async {
    const skin = PortalStatCardTheme(accentColor: Colors.teal, wellAlpha: 1);
    await t.pumpWidget(host(
      const PortalStatCard(value: '1', label: 'A', icon: Icons.bolt),
      skin: const [skin],
    ));
    expect(tintOf(t), Colors.teal.withValues(alpha: 1));

    await t.pumpWidget(host(
      const PortalStatCard(
          value: '1', label: 'A', icon: Icons.bolt, accentColor: Colors.red),
      skin: const [skin],
    ));
    expect(tintOf(t), Colors.red.withValues(alpha: 1));
  });

  testWidgets('empty state: icon colour and size come from the extension',
      (t) async {
    await t.pumpWidget(host(
      const PortalEmptyState(icon: Icons.bolt, title: 'None'),
      skin: const [
        PortalEmptyStateTheme(iconColor: Colors.teal, iconSize: 80),
      ],
    ));
    final icon = t.widget<Icon>(find.byIcon(Icons.bolt));
    expect(icon.color, Colors.teal);
    expect(icon.size, 80);
  });

  test('lerp and copyWith keep unset fields null', () {
    const a = PortalStatCardTheme(accentColor: Colors.black);
    final mid = a.lerp(const PortalStatCardTheme(accentColor: Colors.white), .5);
    expect(mid.accentColor, isNot(Colors.black));
    expect(mid.valueColor, isNull);
    expect(a.copyWith(wellAlpha: .5).accentColor, Colors.black);
  });

  test('lerp snaps at the midpoint when one side leaves a field unset', () {
    const a = PortalFilterChipTheme(selectedColor: Colors.red, minHeight: 40);
    const b = PortalFilterChipTheme();
    final early = a.lerp(b, .25);
    expect(early.selectedColor, Colors.red);
    expect(early.minHeight, 40);
    final late = a.lerp(b, .75);
    expect(late.selectedColor, isNull);
    expect(late.minHeight, isNull);
    final both = a.lerp(const PortalFilterChipTheme(minHeight: 20), .5);
    expect(both.minHeight, 30);
  });
}
