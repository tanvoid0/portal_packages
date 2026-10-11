import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

const _destinations = [
  PortalNavDestination(icon: Symbols.home_rounded, label: 'Home'),
  PortalNavDestination(icon: Symbols.bar_chart_rounded, label: 'Stats'),
];

Widget _host({
  required int index,
  required ValueChanged<int> onSelect,
  Widget? Function(int)? fab,
}) =>
    MaterialApp(
      theme: const PortalThemeConfig().light(),
      home: PortalTabShell(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: _destinations,
        floatingActionButtonBuilder: fab,
        children: const [
          Text('home body'),
          Text('stats body'),
        ],
      ),
    );

void main() {
  testWidgets('keeps every tab alive in an IndexedStack', (t) async {
    await t.pumpWidget(_host(index: 0, onSelect: (_) {}));
    expect(find.text('home body'), findsOneWidget);
    // Both children exist in the tree, just offstage — hence skipOffstage: false.
    expect(find.text('stats body', skipOffstage: false), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);
  });

  testWidgets('tapping a destination calls onDestinationSelected', (t) async {
    var selected = -1;
    await t.pumpWidget(_host(index: 0, onSelect: (i) => selected = i));
    await t.tap(find.text('Stats'));
    expect(selected, 1);
  });

  testWidgets('back pops only on tab 0; elsewhere it returns to tab 0',
      (t) async {
    var index = 1;
    await t.pumpWidget(_host(
      index: index,
      onSelect: (i) => index = i,
    ));
    final shell = t.widget<PortalTabShell>(find.byType(PortalTabShell));
    expect(shell.selectedIndex, 1);

    // PopScope is generic (PopScope<Object>), so byType must match `is
    // PopScope` rather than the exact instantiated type.
    final popScope =
        t.widget(find.byWidgetPredicate((w) => w is PopScope)) as PopScope;
    expect(popScope.canPop, false);
    popScope.onPopInvokedWithResult!(false, null);
    expect(index, 0);
  });

  testWidgets('floatingActionButtonBuilder is index-aware', (t) async {
    await t.pumpWidget(_host(
      index: 0,
      onSelect: (_) {},
      fab: (i) => i == 0 ? const Icon(Icons.add) : null,
    ));
    expect(find.byIcon(Icons.add), findsOneWidget);

    await t.pumpWidget(_host(
      index: 1,
      onSelect: (_) {},
      fab: (i) => i == 0 ? const Icon(Icons.add) : null,
    ));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
