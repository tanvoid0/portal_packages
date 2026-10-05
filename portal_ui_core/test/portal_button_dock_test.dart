import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget page({bool long = true}) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: PortalScrollPage(
          title: 'Edit',
          bottom: PortalButtonDock(
            primary: PortalButton(label: 'Save', onPressed: () {}),
          ),
          children: [
            for (var i = 0; i < (long ? 40 : 1); i++) Text('row $i'),
          ],
        ),
      );

  Color rule(WidgetTester t) {
    final box = t.widget<DecoratedBox>(find
        .descendant(
          of: find.byType(PortalButtonDock),
          matching: find.byType(DecoratedBox),
        )
        .first);
    return ((box.decoration as BoxDecoration).border as Border).top.color;
  }

  testWidgets('the rule shows only while content scrolls beneath', (t) async {
    await t.pumpWidget(page());
    await t.pumpAndSettle();
    expect(rule(t), isNot(Colors.transparent));
    await t.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await t.pumpAndSettle();
    expect(rule(t), Colors.transparent);
  });

  testWidgets('a page that fits has no rule', (t) async {
    await t.pumpWidget(page(long: false));
    await t.pumpAndSettle();
    expect(rule(t), Colors.transparent);
  });

  testWidgets('grid: N actions in rows, a short last row keeps cell width',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        bottomNavigationBar: PortalButtonDock.grid(
          columns: 2,
          actions: [
            for (final l in ['A', 'B', 'C'])
              PortalButton(label: l, onPressed: () {}),
          ],
        ),
      ),
    ));
    final a = t.getRect(find.widgetWithText(PortalButton, 'A'));
    final b = t.getRect(find.widgetWithText(PortalButton, 'B'));
    final c = t.getRect(find.widgetWithText(PortalButton, 'C'));
    expect(a.top, b.top);
    expect(c.top, greaterThan(a.bottom));
    expect(c.left, a.left);
    expect(c.width, a.width);

    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        bottomNavigationBar: PortalButtonDock.grid(actions: [
          for (final l in ['A', 'B', 'C', 'D'])
            PortalButton(label: l, onPressed: () {}),
        ]),
      ),
    ));
    expect(t.getRect(find.widgetWithText(PortalButton, 'A')).top,
        t.getRect(find.widgetWithText(PortalButton, 'D')).top);
  });
}
