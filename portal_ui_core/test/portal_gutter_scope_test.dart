import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget body) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: body,
      );

  PortalListSection section() => const PortalListSection(
        header: 'Group',
        children: [PortalListItem(title: 'Row')],
      );

  testWidgets('a list section on a scroll page sits on the page gutter',
      (t) async {
    await t.pumpWidget(host(PortalScrollPage(
      title: 'Page',
      children: [const PortalSectionHeader(title: 'Bare'), section()],
    )));
    // The bare header and the section's own header share a left edge.
    expect(t.getTopLeft(find.text('Bare')).dx,
        t.getTopLeft(find.text('Group')).dx);
  });

  testWidgets('off a scroll page it keeps its own 16dp gutter', (t) async {
    await t.pumpWidget(host(Scaffold(body: ListView(children: [section()]))));
    expect(t.getTopLeft(find.text('Group')).dx, 16);
  });

  testWidgets('a page with its own padding does not publish the gutter',
      (t) async {
    await t.pumpWidget(host(PortalScrollPage(
      title: 'Page',
      padding: EdgeInsets.zero,
      children: [section()],
    )));
    expect(t.getTopLeft(find.text('Group')).dx, 16);
  });
}
