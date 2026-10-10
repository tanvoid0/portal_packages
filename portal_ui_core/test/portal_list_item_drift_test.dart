import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('overline draws uppercase above the title, chips under it',
      (t) async {
    await t.pumpWidget(host(const PortalListItem(
      title: 'Leg day',
      subtitle: 'Gym',
      overline: 'Up next',
      chips: [Text('Due today')],
    )));
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(t.getTopLeft(find.text('UP NEXT')).dy,
        lessThan(t.getTopLeft(find.text('Leg day')).dy));
  });

  testWidgets('checklist toggle strikes the title through', (t) async {
    var done = false;
    await t.pumpWidget(host(StatefulBuilder(
      builder: (context, set) => PortalListItem.checklist(
        title: 'Buy milk',
        done: done,
        onChanged: (v) => set(() => done = v),
      ),
    )));
    TextDecoration? line() =>
        t.widget<Text>(find.text('Buy milk')).style!.decoration;
    expect(line(), isNull);
    await t.tap(find.text('Buy milk'));
    await t.pump();
    expect(done, isTrue);
    expect(line(), TextDecoration.lineThrough);
  });

  testWidgets('a tonal icon-button accessory builds and stays named',
      (t) async {
    await t.pumpWidget(host(PortalListItem(
      title: 'Water',
      trailing: PortalListAccessory.iconButton(
        icon: Icons.add,
        tooltip: 'Add a glass',
        onPressed: () {},
        tonal: true,
      ),
    )));
    expect(find.byTooltip('Add a glass'), findsOneWidget);
  });
}
