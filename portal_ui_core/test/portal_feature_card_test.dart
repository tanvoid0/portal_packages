import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  testWidgets('renders overline, title and detail; action fires onAction',
      (t) async {
    var tapped = false;
    await t.pumpWidget(host(PortalFeatureCard(
      overline: 'Now reading',
      title: 'Middlemarch',
      detail: '212 / 528 pages',
      chips: const ['Active'],
      actionLabel: 'Open',
      onAction: () => tapped = true,
    )));

    expect(find.text('NOW READING'), findsOneWidget);
    expect(find.text('Middlemarch'), findsOneWidget);
    expect(find.text('212 / 528 pages'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await t.tap(find.text('Open'));
    expect(tapped, isTrue);
  });
}
