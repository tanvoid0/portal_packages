import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(ValueChanged<DateTime?> onPicked, {DateTime? initial}) =>
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final picked = await showPortalDatePicker(
                  context: context,
                  initialDate: initial ?? DateTime(2026, 2, 10),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                onPicked(picked);
              },
              child: const Text('pick'),
            ),
          ),
        ),
      );

  testWidgets('opens the native date picker and returns the confirmed date',
      (t) async {
    DateTime? result;
    await t.pumpWidget(host((d) => result = d));
    await t.tap(find.text('pick'));
    await t.pumpAndSettle();

    expect(find.text('OK'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    expect(result, DateTime(2026, 2, 10));
  });

  testWidgets(
      'clamps an initialDate outside first/last instead of asserting',
      (t) async {
    DateTime? result;
    // Outside the 2020..2035 range passed to the picker — asserting here
    // instead of clamping would throw before the dialog ever opens.
    await t.pumpWidget(host((d) => result = d, initial: DateTime(2040, 1, 1)));
    await t.tap(find.text('pick'));
    await t.pumpAndSettle();

    expect(find.text('OK'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();

    expect(result, DateTime(2035));
  });
}
