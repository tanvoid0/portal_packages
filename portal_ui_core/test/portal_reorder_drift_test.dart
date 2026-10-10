import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Widget row(String name, int i) => PortalListItem(
        key: ValueKey(name),
        title: name,
        trailing: PortalListAccessory.widget(
          PortalReorderHandle(index: i),
          interactive: true,
        ),
      );

  testWidgets('a section with onReorder renders a handle per row', (t) async {
    await t.pumpWidget(host(PortalListSection(
      onReorder: (from, to) {},
      children: [row('A', 0), row('B', 1), row('C', 2)],
    )));
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byType(PortalReorderHandle), findsNWidgets(3));
    expect(find.byTooltip('Reorder'), findsNWidgets(3));
    // The dividers survive the regrouping: one between each pair of rows.
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('a bare section still builds as a plain column', (t) async {
    await t.pumpWidget(host(const PortalListSection(children: [
      PortalListItem(title: 'A'),
      PortalListItem(title: 'B'),
    ])));
    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byType(PortalReorderHandle), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });
}
