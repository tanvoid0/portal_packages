import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('a switch row toggles from anywhere on the row', (t) async {
    var on = false;
    await t.pumpWidget(host(PortalListSection(
      header: 'Privacy',
      children: [
        PortalListItem(
          title: 'Lock app',
          leading: PortalListLeading.icon(Icons.lock_outline),
          trailing: PortalListAccessory.switchControl(
            checked: on,
            onChanged: (v) => on = v,
          ),
        ),
      ],
    )));
    await t.tap(find.text('Lock app'));
    expect(on, isTrue);
  });

  testWidgets('dividers sit between rows only, inset to the text column',
      (t) async {
    await t.pumpWidget(host(PortalListSection(
      children: [
        PortalListItem(
          title: 'A',
          leading: PortalListLeading.tile(Icons.home),
        ),
        const PortalListItem(title: 'B'),
        const PortalListItem(title: 'C'),
      ],
    )));
    final dividers = t.widgetList<Divider>(find.byType(Divider)).toList();
    expect(dividers.length, 2);
    // 16 padding + 40 tile + 16 gap = 72 from the first row's leading.
    expect(dividers.first.indent, 16 + 40 + 16);
  });

  testWidgets('a disabled row refuses taps and says why', (t) async {
    var taps = 0;
    await t.pumpWidget(host(PortalListSection(children: [
      PortalListItem(
        title: 'Sync',
        disabledReason: 'Sign in first',
        trailing: const PortalListAccessory.navigate(),
        onTap: () => taps++,
      ),
    ])));
    await t.tap(find.text('Sync'));
    expect(taps, 0);
    expect(find.text('Sign in first'), findsOneWidget);
  });

  testWidgets('skeleton row builds without a label', (t) async {
    await t.pumpWidget(host(const PortalListSection(
      children: [PortalListItem.skeleton()],
    )));
    expect(find.byType(PortalSkeleton), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });
}
