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

  testWidgets('selectedIndices outlines every selected row, not just one',
      (t) async {
    await t.pumpWidget(host(const PortalListSection.selectable(
      selectedIndices: {0, 2},
      children: [
        PortalListItem(title: 'A'),
        PortalListItem(title: 'B'),
        PortalListItem(title: 'C'),
      ],
    )));
    final boxes = t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((d) => d.position == DecorationPosition.foreground);
    expect(boxes.length, 2);
  });

  testWidgets('skeleton draws rows shaped like the data, inset', (t) async {
    await t.pumpWidget(host(PortalListSection.skeleton(rows: 2)));
    expect(find.byType(PortalListItem), findsNWidgets(2));
    expect(find.byType(PortalSectionHeader), findsNothing);
  });

  testWidgets('skeleton hasHeader draws a PortalSectionHeader.skeleton',
      (t) async {
    await t.pumpWidget(host(PortalListSection.skeleton(hasHeader: true)));
    expect(find.byType(PortalSectionHeader), findsOneWidget);
  });
}
