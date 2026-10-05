import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  Widget stepper(int value, ValueChanged<int> on,
          {int min = 0, int max = 5, int step = 1, String? label, String? unit}) =>
      host(PortalStepper(
        value: value,
        onChanged: on,
        min: min,
        max: max,
        step: step,
        label: label,
        unit: unit,
        decreaseTooltip: 'Remove one',
        increaseTooltip: 'Add one',
      ));

  testWidgets('steps, clamps to the bounds and disables at them', (t) async {
    var got = -1;
    await t.pumpWidget(stepper(3, (v) => got = v, step: 2));
    await t.tap(find.byTooltip('Add one'));
    expect(got, 5);
    await t.tap(find.byTooltip('Remove one'));
    expect(got, 1);

    await t.pumpWidget(stepper(4, (v) => got = v, step: 3));
    await t.tap(find.byTooltip('Add one'));
    expect(got, 5, reason: 'clamped to max');

    got = -1;
    await t.pumpWidget(stepper(5, (v) => got = v));
    await t.tap(find.byTooltip('Add one'));
    expect(got, -1, reason: 'at max, plus is disabled');
    await t.pumpWidget(stepper(0, (v) => got = v));
    await t.tap(find.byTooltip('Remove one'));
    expect(got, -1, reason: 'at min, minus is disabled');
  });

  testWidgets('shows number and unit, or a label; 48 dp targets', (t) async {
    await t.pumpWidget(stepper(2, (_) {}, unit: 'pcs'));
    expect(find.textContaining('2 pcs', findRichText: true), findsOneWidget);
    for (final tip in ['Remove one', 'Add one']) {
      final size = t.getSize(find.byTooltip(tip));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }

    await t.pumpWidget(stepper(2, (_) {}, label: '2/4', unit: 'pcs'));
    expect(find.text('2/4', findRichText: true), findsOneWidget);
    expect(find.textContaining('pcs', findRichText: true), findsNothing);
  });
}
