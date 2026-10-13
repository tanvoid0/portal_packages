import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget stepper(double? value, ValueChanged<double> on,
          {double step = 0.5, double max = 12, double initial = 7}) =>
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Center(
            child: PortalDecimalStepper(
              value: value,
              onChanged: on,
              step: step,
              max: max,
              initial: initial,
              unit: 'h',
              semanticLabel: 'Sleep',
              decreaseTooltip: 'Less',
              increaseTooltip: 'More',
            ),
          ),
        ),
      );

  testWidgets('steps by a half, no trailing .0, exact at 8', (t) async {
    double? got;
    await t.pumpWidget(stepper(7.5, (v) => got = v));
    expect(find.textContaining('7.5 h', findRichText: true), findsOneWidget);
    await t.tap(find.byTooltip('More'));
    expect(got, 8.0);
    await t.tap(find.byTooltip('Less'));
    expect(got, 7.0);
    await t.pumpWidget(stepper(8, (v) => got = v));
    expect(find.textContaining('8 h', findRichText: true), findsOneWidget);
  });

  testWidgets('no drift on a 0.1 step; disabled at the bounds', (t) async {
    double? got;
    await t.pumpWidget(stepper(0.2, (v) => got = v, step: 0.1));
    await t.tap(find.byTooltip('More'));
    expect(got, 0.3);

    got = null;
    await t.pumpWidget(stepper(12, (v) => got = v));
    await t.tap(find.byTooltip('More'));
    expect(got, isNull, reason: 'at max, plus is disabled');
    await t.pumpWidget(stepper(0, (v) => got = v));
    await t.tap(find.byTooltip('Less'));
    expect(got, isNull, reason: 'at min, minus is disabled');
  });

  testWidgets('unset shows a dash and the first tap lands on initial', (t) async {
    double? got;
    await t.pumpWidget(stepper(null, (v) => got = v));
    expect(find.text('–'), findsOneWidget);
    await t.tap(find.byTooltip('More'));
    expect(got, 7.0);
    got = null;
    await t.tap(find.byTooltip('Less'));
    expect(got, 7.0);
  });

  testWidgets('one adjustable node speaks value and next values', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(stepper(7.5, (_) {}));
    final n = t.getSemantics(find.bySemanticsLabel('Sleep'));
    expect(n.value, '7.5 h');
    expect(n.increasedValue, '8 h');
    expect(n.decreasedValue, '7 h');
    h.dispose();
  });
}
