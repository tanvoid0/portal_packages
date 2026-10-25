import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  test('flag emoji derives from the code country prefix', () {
    expect(portalCurrencyOf('GBP')!.flag, '🇬🇧');
    expect(portalCurrencyOf('USD')!.flag, '🇺🇸');
    expect(portalCurrencyOf('EUR')!.flag, '🇪🇺');
    expect(portalCurrencyOf('JPY')!.flag, '🇯🇵');
  });

  test('lookup is case-insensitive and null for unknown', () {
    expect(portalCurrencyOf('gbp')?.code, 'GBP');
    expect(portalCurrencyOf('ZZZ'), isNull);
  });

  test('list is broad and free of duplicate codes', () {
    expect(kPortalCurrencies.length, greaterThan(40));
    final codes = kPortalCurrencies.map((c) => c.code).toSet();
    expect(codes.length, kPortalCurrencies.length);
  });

  test('exponent matches the currency', () {
    expect(portalCurrencyOf('USD')!.exponent, 2);
    expect(portalCurrencyOf('JPY')!.exponent, 0);
    expect(portalCurrencyOf('ISK')!.exponent, 0);
  });

  group('PortalMoney.parse', () {
    test('exact minor units via string math, no float drift', () {
      expect(PortalMoney.parse('19.99', 'GBP')!.minorUnits, 1999);
      expect(PortalMoney.parse('0.1', 'USD')!.minorUnits, 10);
      expect(PortalMoney.parse('1234.5', 'EUR')!.minorUnits, 123450);
    });

    test('zero-decimal currency ignores a typed fraction', () {
      expect(PortalMoney.parse('500', 'JPY')!.minorUnits, 500);
      expect(PortalMoney.parse('500.7', 'JPY')!.minorUnits, 500);
    });

    test('tolerates symbols, commas, spaces and sign', () {
      expect(PortalMoney.parse(r' £1,250.50 ', 'GBP')!.minorUnits, 125050);
      expect(PortalMoney.parse('-5', 'USD')!.minorUnits, -500);
    });

    test('over-long fraction truncates to the currency exponent', () {
      expect(PortalMoney.parse('1.239', 'USD')!.minorUnits, 123);
    });

    test('null when there is no number', () {
      expect(PortalMoney.parse('', 'USD'), isNull);
      expect(PortalMoney.parse('abc', 'USD'), isNull);
      expect(PortalMoney.parse('.', 'USD'), isNull);
    });
  });
}
