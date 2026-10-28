import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

const _destinations = [
  PortalNavDestination(icon: Symbols.home_rounded, label: 'Home'),
  PortalNavDestination(icon: Symbols.bar_chart_rounded, label: 'Stats'),
];

Widget _host(int selected) => MaterialApp(
      theme: const PortalThemeConfig().light(),
      home: Scaffold(
        bottomNavigationBar: PortalBottomNavBar(
          selectedIndex: selected,
          onDestinationSelected: (_) {},
          destinations: _destinations,
        ),
      ),
    );

Icon _icon(WidgetTester t, IconData glyph) => t.widget<Icon>(find.byIcon(glyph));

void main() {
  test('theme carries one Symbols voice: rounded 400, opsz 24, unfilled', () {
    for (final theme in [
      buildPortalTheme(brightness: Brightness.dark),
      const PortalThemeConfig().light(),
    ]) {
      for (final icons in [theme.iconTheme, theme.primaryIconTheme]) {
        expect(icons.fill, 0);
        expect(icons.weight, 400);
        expect(icons.grade, 0);
        expect(icons.opticalSize, 24);
        expect(icons.color, isNotNull);
      }
    }
  });

  testWidgets('selecting a destination animates its glyph fill 0 -> 1',
      (t) async {
    await t.pumpWidget(_host(0));
    expect(_icon(t, Symbols.home_rounded).fill, 1);
    expect(_icon(t, Symbols.bar_chart_rounded).fill, 0);

    await t.pumpWidget(_host(1));
    await t.pump(const Duration(milliseconds: 80));
    final mid = _icon(t, Symbols.bar_chart_rounded).fill!;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));

    await t.pumpAndSettle();
    expect(_icon(t, Symbols.bar_chart_rounded).fill, 1);
    expect(_icon(t, Symbols.home_rounded).fill, 0);
  });

  testWidgets('filter chip fills its glyph when selected', (t) async {
    Widget chip(bool selected) => MaterialApp(
          theme: const PortalThemeConfig().light(),
          home: Scaffold(
            body: PortalFilterChip(
              label: 'Pinned',
              icon: Symbols.push_pin_rounded,
              selected: selected,
              onTap: () {},
            ),
          ),
        );
    await t.pumpWidget(chip(false));
    expect(_icon(t, Symbols.push_pin_rounded).fill, 0);
    await t.pumpWidget(chip(true));
    await t.pumpAndSettle();
    expect(_icon(t, Symbols.push_pin_rounded).fill, 1);
  });

  testWidgets('PortalNavBarTheme colours the bar; a widget argument wins',
      (t) async {
    Widget bar({Color? well}) => MaterialApp(
          theme: PortalThemeConfig(
            extensionsBuilder: (_) => const [
              PortalNavBarTheme(
                selectedWellColor: Colors.orange,
                selectedMarkColor: Colors.teal,
              ),
            ],
          ).light(),
          home: Scaffold(
            bottomNavigationBar: PortalBottomNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: _destinations,
              selectedWellColor: well,
            ),
          ),
        );
    Iterable<Color?> wells(WidgetTester t) => t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((c) => (c.decoration as BoxDecoration?)?.color);

    await t.pumpWidget(bar());
    await t.pumpAndSettle();
    expect(wells(t), contains(Colors.orange));
    expect(_icon(t, Symbols.home_rounded).color, Colors.teal);

    await t.pumpWidget(bar(well: Colors.pink));
    await t.pumpAndSettle();
    expect(wells(t), contains(Colors.pink));
    expect(wells(t), isNot(contains(Colors.orange)));
  });
}
