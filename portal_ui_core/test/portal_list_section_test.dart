import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  testWidgets('a section holds foreign widgets with matching dividers',
      (t) async {
    await t.pumpWidget(host(SingleChildScrollView(
      child: PortalListSection(children: [
        PortalListItem(
          title: 'A',
          leading: PortalListLeading.custom(const SizedBox(width: 40)),
        ),
        const ListTile(title: Text('Foreign')),
        const PortalListItem(title: 'C'),
      ]),
    )));
    expect(find.text('Foreign'), findsOneWidget);
    final dividers = t.widgetList<Divider>(find.byType(Divider)).toList();
    expect(dividers.map((d) => d.indent), [16 + 40 + 16, 16]);
  });

  testWidgets('the sliver section builds only the rows in view', (t) async {
    final built = <int>{};
    await t.pumpWidget(host(CustomScrollView(slivers: [
      PortalSliverListSection(
        header: 'Long',
        itemCount: 500,
        itemBuilder: (c, i) {
          built.add(i);
          return PortalListItem(title: 'Row $i');
        },
      ),
    ])));
    expect(find.text('Long'), findsOneWidget);
    expect(find.text('Row 0'), findsOneWidget);
    expect(built.length, lessThan(30));
    await t.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await t.pump();
    expect(find.text('Row 0'), findsNothing);
    expect(find.byType(Divider), findsWidgets);
  });
}
