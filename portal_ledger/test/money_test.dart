import 'package:decimal/decimal.dart';
import 'package:portal_ledger/portal_ledger.dart';
import 'package:test/test.dart';

void main() {
  group('currency exponent', () {
    test('defaults to 2, zero- and three-decimal overrides', () {
      expect(currencyExponent('USD'), 2);
      expect(currencyExponent('eur'), 2); // case-insensitive
      expect(currencyExponent('JPY'), 0);
      expect(currencyExponent('KWD'), 3);
      expect(currencyExponent('ZZZ'), 2); // unknown -> default
    });
  });

  group('Money arithmetic', () {
    test('add and subtract within a currency', () {
      expect(const Money(100, 'USD') + const Money(50, 'USD'), const Money(150, 'USD'));
      expect(const Money(100, 'USD') - const Money(150, 'USD'), const Money(-50, 'USD'));
      expect(-const Money(100, 'USD'), const Money(-100, 'USD'));
      expect(const Money(100, 'USD').timesInt(3), const Money(300, 'USD'));
    });

    test('currency mismatch throws', () {
      expect(() => const Money(1, 'USD') + const Money(1, 'EUR'), throwsArgumentError);
    });
  });

  group('Money.convertTo', () {
    test('USD -> JPY drops to zero decimals exactly', () {
      // $1.00 at ¥150 per $1 = ¥150.
      expect(
        const Money(100, 'USD').convertTo('JPY', Decimal.fromInt(150)),
        const Money(150, 'JPY'),
      );
    });

    test('JPY -> USD rounds to cents', () {
      // ¥150 at ~0.0066667 $/¥ = $1.0000 -> 100 cents.
      expect(
        const Money(150, 'JPY').convertTo('USD', Decimal.parse('0.0066667')),
        const Money(100, 'USD'),
      );
    });

    test('a manual (fee-inclusive) rate is honoured as given', () {
      // €100.00 at a worse-than-mid 36 THB/€ = ฿3600.00.
      expect(
        const Money(10000, 'EUR').convertTo('THB', Decimal.fromInt(36)),
        const Money(360000, 'THB'),
      );
    });
  });

  group('Money.format', () {
    test('renders by currency exponent and sign', () {
      expect(const Money(12345, 'EUR').format(), '123.45 EUR');
      expect(const Money(-12345, 'EUR').format(), '-123.45 EUR');
      expect(const Money(5, 'USD').format(), '0.05 USD');
      expect(const Money(500, 'JPY').format(), '500 JPY');
    });
  });

  test('json round-trip', () {
    const m = Money(12345, 'GBP');
    expect(Money.fromJson(m.toJson()), m);
  });
}
