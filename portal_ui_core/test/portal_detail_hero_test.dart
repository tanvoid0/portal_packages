import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  testWidgets('caption, amount and meta all render', (t) async {
    await t.pumpWidget(host(const PortalDetailHero(
      caption: 'Pages read',
      amount: Text('212'),
      meta: 'Started 2 Aug',
    )));

    expect(find.text('Pages read'), findsOneWidget);
    expect(find.text('212'), findsOneWidget);
    expect(find.text('Started 2 Aug'), findsOneWidget);
  });
}
