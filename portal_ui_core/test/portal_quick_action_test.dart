import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: SizedBox(width: 96, child: child))),
      );

  testWidgets('taps, reads as a named button, meets the tap target', (t) async {
    final h = t.ensureSemantics();
    var taps = 0;
    await t.pumpWidget(host(PortalQuickAction(
      icon: Icons.add,
      label: 'Add expense',
      onTap: () => taps++,
    )));
    final node = t.getSemantics(find.byType(PortalQuickAction));
    expect(node.label, 'Add expense');
    expect(node.flagsCollection.isButton, isTrue);
    expect(t.getSize(find.byType(PortalQuickAction)).height,
        greaterThanOrEqualTo(48));
    await t.tap(find.text('Add expense'));
    expect(taps, 1);
    h.dispose();
  });

  testWidgets('tooltip and colours; builder glyph gets the ink', (t) async {
    Color? got;
    await t.pumpWidget(host(PortalQuickAction.builder(
      builder: (c, color) {
        got = color;
        return const Text('G');
      },
      label: 'Scan',
      tooltip: 'Scan a receipt',
      backgroundColor: Colors.amber,
      foregroundColor: Colors.indigo,
      onTap: () {},
    )));
    expect(find.byTooltip('Scan a receipt'), findsOneWidget);
    expect(got, Colors.indigo);
    final box = t
        .widget<Container>(find
            .descendant(
                of: find.byType(PortalQuickAction),
                matching: find.byType(Container))
            .first)
        .decoration! as BoxDecoration;
    expect(box.color, Colors.amber);
  });
}
