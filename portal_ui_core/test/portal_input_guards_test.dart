import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

TextEditingValue _v(String t) => TextEditingValue(text: t);

void main() {
  const f = PortalBoundedNumberFormatter(max: 500);

  test('refuses out-of-range and negative values, keeps partial input', () {
    expect(f.formatEditUpdate(_v('50'), _v('999999')).text, '50');
    expect(f.formatEditUpdate(_v(''), _v('-')).text, '');
    expect(f.formatEditUpdate(_v('12'), _v('12.')).text, '12.');
    expect(f.formatEditUpdate(_v('12'), _v('')).text, '');
    expect(f.formatEditUpdate(_v('499'), _v('500')).text, '500');
  });

  test('single flight drops a second call while running', () async {
    var calls = 0;
    final tap = portalSingleFlight(() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    tap();
    tap();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    tap();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 2);
  });
}
