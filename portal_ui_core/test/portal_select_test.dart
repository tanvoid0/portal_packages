import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  const items = [
    PortalSelectItem(value: 1, label: 'Weekly', icon: Icons.repeat),
    PortalSelectItem(value: 2, label: 'Monthly'),
  ];

  Widget host({
    int? value,
    ValueChanged<int?>? onChanged,
    String? error,
  }) =>
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Center(
            child: PortalSelect<int>(
              label: 'Repeats',
              hint: 'Choose one',
              helper: 'How often',
              errorText: error,
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      );

  testWidgets('shows label and hint, picks an item, shows it', (t) async {
    int? picked;
    await t.pumpWidget(host(onChanged: (v) => picked = v));
    expect(find.text('Repeats'), findsOneWidget);
    expect(find.text('Choose one'), findsOneWidget);
    expect(find.text('How often'), findsOneWidget);
    expect(t.getSize(find.byType(DropdownButtonFormField<int>)).height,
        greaterThanOrEqualTo(44));

    await t.tap(find.byType(DropdownButtonFormField<int>));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    await t.tap(find.text('Monthly').last);
    await t.pumpAndSettle();
    expect(picked, 2);

    await t.pumpWidget(host(value: 2, onChanged: (_) {}));
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Choose one'), findsNothing);
  });

  testWidgets('error replaces helper; null onChanged disables', (t) async {
    await t.pumpWidget(host(error: 'Pick one'));
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('How often'), findsNothing);

    await t.tap(find.byType(DropdownButtonFormField<int>),
        warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('Weekly'), findsNothing);
  });

  testWidgets('the label reaches a screen reader on the control', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(value: 1, onChanged: (_) {}));
    expect(find.bySemanticsLabel(RegExp('Repeats')), findsWidgets);
    h.dispose();
  });
}
