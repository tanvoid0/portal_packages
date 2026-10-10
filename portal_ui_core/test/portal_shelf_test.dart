import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: const PortalThemeConfig().light(),
        home: Scaffold(body: child),
      );

  testWidgets('header, horizontal list, children and trailing all render',
      (t) async {
    await t.pumpWidget(host(PortalShelf(
      header: 'Picks',
      itemWidth: 120,
      height: 80,
      trailing: const SizedBox(key: ValueKey('end'), width: 40),
      children: [
        for (var i = 0; i < 3; i++)
          SizedBox.expand(key: ValueKey('card$i')),
      ],
    )));

    expect(find.text('Picks'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal),
      findsOneWidget,
    );
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('card$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('end')), findsOneWidget);
    // Children are held to itemWidth and the row height.
    expect(t.getSize(find.byKey(const ValueKey('card0'))), const Size(120, 80));
  });
}
