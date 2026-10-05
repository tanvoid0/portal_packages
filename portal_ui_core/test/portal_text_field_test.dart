import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      );

  testWidgets('plain: label, error text, validator in a Form, disabled',
      (t) async {
    final key = GlobalKey<FormState>();
    await t.pumpWidget(host(Form(
      key: key,
      child: PortalTextField(
        label: 'Name',
        required: true,
        errorText: 'Taken',
        validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
      ),
    )));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Required'), findsOneWidget);

    await t.pumpWidget(host(const PortalTextField(enabled: false)));
    expect(t.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('filled: borderless with a fill; field meets the tap target',
      (t) async {
    await t.pumpWidget(host(const PortalTextField(filled: true, hint: 'Note')));
    final d = t.widget<TextField>(find.byType(TextField)).decoration!;
    expect(d.filled, isTrue);
    expect((d.border! as OutlineInputBorder).borderSide, BorderSide.none);
    expect(t.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(DesignTokens.defaults.minTapTarget));
  });

  testWidgets('amount: stops a 2nd dot / 3rd decimal, selects all on focus',
      (t) async {
    final c = TextEditingController(text: PortalTextField.formatAmount(12));
    await t.pumpWidget(host(PortalTextField.amount(
      controller: c,
      currencySymbol: r'$',
    )));
    expect(c.text, '12');

    await t.tap(find.byType(TextField));
    await t.pump();
    expect(c.selection, const TextSelection(baseOffset: 0, extentOffset: 2));

    await t.enterText(find.byType(TextField), '1.234');
    expect(c.text, '1.23');
    await t.enterText(find.byType(TextField), '1.2.');
    expect(c.text, '1.2');
  });

  test('amount format and parse', () {
    expect(PortalTextField.formatAmount(12.5), '12.50');
    expect(PortalTextField.formatAmount(12.0), '12');
    expect(PortalTextField.formatAmount(0), '');
    expect(PortalTextField.parseAmount('1,5'), 1.5);
    expect(PortalTextField.parseAmount('x'), 0);
  });
}
