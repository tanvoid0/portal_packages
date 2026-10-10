import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: child),
      );

  testWidgets('a caption renders under the title', (t) async {
    await t.pumpWidget(host(
      const PortalSectionHeader(title: 'Today', caption: '3 transactions'),
    ));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('3 transactions'), findsOneWidget);
  });

  testWidgets('the action label is tappable and fires onAction', (t) async {
    var taps = 0;
    await t.pumpWidget(host(
      PortalSectionHeader(
        title: 'Recent',
        actionLabel: 'See all',
        onAction: () => taps++,
      ),
    ));
    await t.tap(find.text('See all'));
    expect(taps, 1);
  });
}
