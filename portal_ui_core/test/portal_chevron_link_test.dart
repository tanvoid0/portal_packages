import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('renders its label and fires onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: PortalChevronLink(
          label: 'Export data',
          semanticLabel: 'Export data',
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Export data'), findsOneWidget);
    await t.tap(find.byType(PortalChevronLink));
    expect(tapped, isTrue);
  });
}
