import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);

void main() {
  testWidgets('tappable bars are buttons carrying their own label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final taps = <int>[];
    await tester.pumpWidget(
      _host(
        PortalBarChart(
          semanticLabel: 'Spending by month',
          highlight: 1,
          onBarTap: taps.add,
          bars: const [
            PortalBar('Jul', 120, semanticLabel: 'July £120'),
            PortalBar('Aug', 240, valueLabel: '£240'),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('July £120'), findsOneWidget);
    expect(find.bySemanticsLabel('Aug £240'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('July £120'));
    expect(taps, [0]);
    handle.dispose();
  });

  testWidgets('a bar chart without taps announces its summary alone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const PortalBarChart(
          semanticLabel: 'Spending by month',
          bars: [PortalBar('Jul', 120), PortalBar('Aug', 240)],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Spending by month'), findsOneWidget);
    expect(find.bySemanticsLabel('Jul'), findsNothing);
    handle.dispose();
  });

  testWidgets('minBarHeight floors a zero bar', (tester) async {
    await tester.pumpWidget(
      _host(
        const PortalBarChart(
          semanticLabel: 'band',
          plotHeight: 56,
          minBarHeight: 3,
          bars: [PortalBar('Jul', 0), PortalBar('Aug', 100)],
        ),
      ),
    );

    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.constraints?.maxWidth == 56)
        .toList();
    expect(bars.length, 2);
    expect(tester.getSize(find.byWidget(bars.first)).height, 3);
    expect(tester.getSize(find.byWidget(bars.last)).height, 56);
  });

  testWidgets('a sparkline paints above two points and reserves its height '
      'below', (tester) async {
    await tester.pumpWidget(
      _host(const PortalSparkline(points: [80.4, 80.1, 79.6])),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(PortalSparkline)).height, 28);

    await tester.pumpWidget(_host(const PortalSparkline(points: [80.4])));
    expect(tester.getSize(find.byType(PortalSparkline)).height, 28);
  });
}
