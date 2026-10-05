import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('sizes the tile and glyph, and takes colours', (t) async {
    await t.pumpWidget(host(const PortalIconTile(
      Icons.home,
      size: 60,
      backgroundColor: Colors.amber,
      foregroundColor: Colors.indigo,
    )));
    expect(t.getSize(find.byType(Container)), const Size(60, 60));
    final icon = t.widget<Icon>(find.byIcon(Icons.home));
    expect(icon.size, 36);
    expect(icon.color, Colors.indigo);
    final box = t.widget<Container>(find.byType(Container)).decoration!
        as BoxDecoration;
    expect(box.color, Colors.amber);
  });

  testWidgets('builder gets the tone ink; label makes it a named image',
      (t) async {
    final h = t.ensureSemantics();
    Color? got;
    await t.pumpWidget(host(PortalIconTile.builder(
      (c, color) {
        got = color;
        return const Text('G');
      },
      tone: PortalListTone.error,
      semanticLabel: 'Alert',
    )));
    expect(
        got, Theme.of(t.element(find.text('G'))).colorScheme.onErrorContainer);
    expect(t.getSemantics(find.byType(PortalIconTile)).label, 'Alert');
    h.dispose();
  });

  testWidgets('decorative by default', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(const PortalIconTile(Icons.home)));
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    h.dispose();
  });

  testWidgets('circle shape, also through PortalListLeading.tile', (t) async {
    BoxDecoration deco() =>
        t.widget<Container>(find.byType(Container).first).decoration!
            as BoxDecoration;
    await t.pumpWidget(host(const PortalIconTile(Icons.home)));
    expect(deco().shape, BoxShape.rectangle);
    expect(deco().borderRadius, isNotNull);

    await t.pumpWidget(host(const PortalIconTile(Icons.home,
        shape: PortalIconTileShape.circle)));
    expect(deco().shape, BoxShape.circle);
    expect(deco().borderRadius, isNull);

    await t.pumpWidget(host(PortalListItem(
      title: 'Row',
      leading: PortalListLeading.tile(Icons.home,
          shape: PortalIconTileShape.circle),
    )));
    final tile = t.widget<PortalIconTile>(find.byType(PortalIconTile));
    expect(tile.shape, PortalIconTileShape.circle);
  });
}
