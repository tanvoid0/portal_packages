import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 120">'
      '<rect fill="{{primary}}" stroke="{{surface}}" width="40" height="40"/>'
      '<circle fill="#6FAE7D" r="5"/></svg>';

  testWidgets('roles resolve from the theme, literals stay', (t) async {
    late String out;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(builder: (c) {
        out = PortalArt.resolve(c, svg);
        return const SizedBox();
      }),
    ));
    expect(out, isNot(contains('{{')));
    expect(out, contains('#6FAE7D'));
  });

  testWidgets('an unknown role fails loudly, not as a black shape', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(builder: (c) {
        expect(
          () => PortalArt.resolve(c, '<svg>{{nope}}</svg>'),
          throwsArgumentError,
        );
        return const SizedBox();
      }),
    ));
  });

  testWidgets('decorative unless a label is given', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const PortalArt(svg, semanticLabel: 'Empty wardrobe'),
    ));
    expect(find.bySemanticsLabel('Empty wardrobe'), findsOneWidget);
  });
}
