import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('tile takes custom colours and a widget glyph', (t) async {
    await t.pumpWidget(host(PortalListItem(
      title: 'Bank',
      leading: PortalListLeading.tileBuilder(
        (c, color) => Text('G', style: TextStyle(color: color)),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.indigo,
      ),
    )));
    final tile = t.widget<Container>(find
        .ancestor(of: find.text('G'), matching: find.byType(Container))
        .first);
    expect((tile.decoration! as BoxDecoration).color, Colors.amber);
    expect(t.widget<Text>(find.text('G')).style!.color, Colors.indigo);
  });

  testWidgets('custom leading sets the divider inset by its extent', (t) async {
    await t.pumpWidget(host(PortalListSection(children: [
      PortalListItem(
        title: 'A',
        leading: PortalListLeading.custom(const SizedBox(width: 56), extent: 56),
      ),
      const PortalListItem(title: 'B'),
    ])));
    expect(t.widget<Divider>(find.byType(Divider)).indent, 16 + 56 + 16);
  });

  testWidgets('widget slots, progress, long press and several actions',
      (t) async {
    var pressed = '';
    var long = 0;
    await t.pumpWidget(host(PortalListItem(
      title: 'Rent',
      subtitleWidget: const Text('sub-widget'),
      metaWidget: const Text('meta-widget'),
      progress: .4,
      progressLabel: const Text('40% paid'),
      onLongPress: () => long++,
      trailing: PortalListAccessory.iconButtons([
        PortalListIconAction(
          icon: Icons.edit,
          tooltip: 'Edit rent',
          onPressed: () => pressed = 'edit',
        ),
        PortalListIconAction(
          icon: Icons.delete,
          tooltip: 'Delete rent',
          onPressed: () => pressed = 'delete',
        ),
      ]),
    )));
    expect(find.text('sub-widget'), findsOneWidget);
    expect(find.text('meta-widget'), findsOneWidget);
    expect(find.text('40% paid'), findsOneWidget);
    expect(find.byType(PortalProgress), findsOneWidget);
    await t.tap(find.byTooltip('Delete rent'));
    expect(pressed, 'delete');
    await t.longPress(find.text('Rent'));
    expect(long, 1);
  });

  testWidgets('a widget accessory is read through its semanticLabel',
      (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(host(const PortalListItem(
      title: 'Salary',
      trailing: PortalListAccessory.widget(
        Text('£2,000'),
        semanticLabel: '£2,000 received',
      ),
    )));
    expect(find.text('£2,000'), findsOneWidget);
    expect(
      t.getSemantics(find.byType(PortalListItem)).label,
      contains('£2,000 received'),
    );
    handle.dispose();
  });

  testWidgets('empty state takes a widget icon', (t) async {
    await t.pumpWidget(host(
      const PortalEmptyState(iconWidget: Text('FA'), title: 'None'),
    ));
    expect(find.text('FA'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
