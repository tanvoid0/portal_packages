import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(Widget child) => MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('figure strip: one semantics node per cell', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const PortalFigureStrip(
          figures: [
            PortalFigure('Sets', '18'),
            PortalFigure('Volume', '8,420', unit: 'kg'),
            PortalFigure('Reps', '96', spoken: 'Total reps'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Sets, 18'), findsOneWidget);
    expect(find.bySemanticsLabel('Volume, 8,420, kg'), findsOneWidget);
    expect(find.bySemanticsLabel('Total reps, 96'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('row size: the figure is heavy, the unit muted', (tester) async {
    await tester.pumpWidget(
      _host(
        const PortalFigureStrip(
          figures: [PortalFigure('Volume', '8,420', unit: 'kg')],
        ),
      ),
    );
    final span = tester
        .widget<RichText>(find.text('8,420 kg', findRichText: true))
        .text as TextSpan;
    final parts =
        (span.children!.single as TextSpan).children!.cast<TextSpan>();
    expect(parts.first.text, '8,420');
    expect(parts.first.style!.fontWeight, FontWeight.w700);
    expect(parts.last.text, ' kg');
    expect(parts.last.style!.fontSize, 13);
  });

  testWidgets('figure size: 34 display figure, wraps in 150 cells',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const PortalFigureStrip(
          size: PortalFigureSize.figure,
          figures: [
            PortalFigure('Short value', '£24.60'),
            PortalFigure('Long value', '£1,284,390.75'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final text = tester.widget<RichText>(
      find.text('£24.60', findRichText: true),
    );
    expect(text.text.style!.fontSize, 34);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('skeleton builds, with a cell count', (tester) async {
    await tester.pumpWidget(_host(const PortalFigureStrip.skeleton()));
    expect(tester.takeException(), isNull);
    expect(find.byType(PortalSkeleton), findsNWidgets(6));
    await tester.pumpWidget(
      _host(const PortalFigureStrip.skeleton(cells: 2)),
    );
    expect(find.byType(PortalSkeleton), findsNWidgets(4));
  });
}
