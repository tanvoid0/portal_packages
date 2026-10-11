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

  testWidgets('headerValue reads with the title as one header, no title text',
      (t) async {
    await t.pumpWidget(host(
      const PortalSectionHeader(title: 'Today', headerValue: '-£42.10'),
    ));
    expect(find.bySemanticsLabel('Today, -£42.10'), findsOneWidget);
  });

  testWidgets('skeleton draws no title text, as one excluded group',
      (t) async {
    await t.pumpWidget(host(const PortalSectionHeader.skeleton()));
    expect(find.text('Today'), findsNothing);
    expect(find.byType(PortalSkeleton), findsOneWidget);
  });
}
