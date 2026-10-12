import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('tapping a row toggles it', (t) async {
    var toggled = -1;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: portalOptionSection(
          options: const [PortalOption('Backlog'), PortalOption('Active')],
          selected: const {0},
          onToggle: (i) => toggled = i,
        ),
      ),
    ));

    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    await t.tap(find.text('Active'));
    expect(toggled, 1);
  });
}
