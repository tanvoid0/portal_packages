import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Finance's `MoneyText` format, restated: symbol + abs body at fixed
/// decimals, `+` only when signed and positive, `-` for a negative (the kit's
/// hyphen-minus; finance draws U+2212).
String _reference(double v, {bool signed = false, bool decimals = true}) {
  final body = NumberFormat.currency(symbol: '£', decimalDigits: decimals ? 2 : 0)
      .format(v.abs());
  if (v < 0) return '-$body';
  return signed && v > 0 ? '+$body' : body;
}

void main() {
  Future<Text> pump(WidgetTester t, PortalAmount a) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(body: a),
    ));
    return t.widget<Text>(find.byType(Text).first);
  }

  String textOf(Text w) => w.textSpan!.toPlainText();

  testWidgets('text matches the ledger format: sign, currency, rounding',
      (t) async {
    for (final v in [0.0, 1.0, 12.5, 12.6, 1234.567, -9.99, -1200.0]) {
      for (final signed in [false, true]) {
        for (final decimals in [true, false]) {
          final w = await pump(
            t,
            PortalAmount(v, 'GBP', signed: signed, decimals: decimals),
          );
          expect(
            textOf(w),
            _reference(v, signed: signed, decimals: decimals),
            reason: 'v=$v signed=$signed decimals=$decimals',
          );
        }
      }
    }
  });

  testWidgets('tone, colour override, size and weight', (t) async {
    var w = await pump(t, const PortalAmount(5, 'GBP'));
    final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
    expect(w.style!.color, cs.onSurface);

    w = await pump(
      t,
      const PortalAmount(5, 'GBP', tone: PortalAmountTone.alert),
    );
    expect(w.style!.color, cs.error);

    w = await pump(
      t,
      const PortalAmount(
        5,
        'GBP',
        tone: PortalAmountTone.alert,
        foregroundColor: Color(0xFF123456),
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
    expect(w.style!.color, const Color(0xFF123456));
    expect(w.style!.fontSize, 22);
    expect(w.style!.fontWeight, FontWeight.w900);
  });

  testWidgets('compact', (t) async {
    expect(textOf(await pump(t, const PortalAmount(12400, 'GBP', compact: true))),
        '£12.4K');
    expect(
        textOf(await pump(
            t, const PortalAmount(12400, 'GBP', compact: true, signed: true))),
        '+£12.4K');
    expect(textOf(await pump(t, const PortalAmount(-412, 'GBP', compact: true))),
        '-£412');
  });

  testWidgets('a sub-penny value is neither signed nor success-coloured',
      (t) async {
    final w = await pump(t, const PortalAmount(5.5e-17, 'GBP', signed: true));
    final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
    expect(textOf(w), '£0.00');
    expect(w.style!.color, cs.onSurface);
  });
}
