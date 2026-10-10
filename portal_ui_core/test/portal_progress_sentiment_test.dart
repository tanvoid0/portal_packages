import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: const PortalThemeConfig().light(),
        home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
      );

  testWidgets('sentiment: budget bands, tinted fill, over-limit, skeleton',
      (t) async {
    expect(portalBudgetSentiment(1.2), PortalSentiment.negative);
    expect(portalBudgetSentiment(0.8), PortalSentiment.warning);
    expect(portalBudgetSentiment(0.5), PortalSentiment.positive);

    await t.pumpWidget(host(const PortalProgress(
      value: 0.8,
      sentiment: PortalSentiment.warning,
      startLabel: 'Spent',
      endLabel: '£20 left',
    )));
    await t.pumpAndSettle();
    expect(find.byType(PortalProgress), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);

    // Over the limit: the bar rescales instead of clamping.
    await t.pumpWidget(host(const PortalProgress(
      value: 1.2,
      sentiment: PortalSentiment.negative,
    )));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PortalProgress),
        matching: find.byType(OverflowBox),
      ),
      findsOneWidget,
    );

    // The skeleton pulses forever, so a single frame.
    await t.pumpWidget(host(const PortalProgress.skeleton()));
    await t.pump();
    expect(find.byType(PortalSkeleton), findsNWidgets(3));
  });
}
