import 'package:decimal/decimal.dart';
import 'package:meta/meta.dart';

import 'currency.dart';

/// An exact amount of money: an integer count of a currency's minor units
/// (cents, satang, …) plus its ISO-4217 code.
///
/// Storage and wire are always integers. Arithmetic that could lose precision
/// — percentages, FX conversion — goes through [package:decimal] and rounds
/// back to minor units, so results stay exact and reconcilable.
@immutable
class Money {
  final int minorUnits;
  final String currency;

  const Money(this.minorUnits, this.currency);

  factory Money.zero(String currency) => Money(0, currency);

  /// Minor-unit decimal places for this currency (2 for USD, 0 for JPY, …).
  int get exponent => currencyExponent(currency);

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  /// Exact multiplication by a whole number (e.g. nights × nightly rate).
  Money timesInt(int factor) => Money(minorUnits * factor, currency);

  /// Convert to [targetCurrency] using [rate] = units of target per 1 unit of
  /// source (e.g. 37 for EUR→THB). The rate is the caller's to choose, so a
  /// manual, fee-inclusive rate overrides any mid-market one. Rounds half away
  /// from zero to the target currency's minor unit.
  Money convertTo(String targetCurrency, Decimal rate) {
    final target = targetCurrency.toUpperCase();
    final frac = rate.toRational();
    // targetMinor = minorUnits * rate * 10^targetExp / 10^sourceExp, rounded.
    final numerator = BigInt.from(minorUnits) *
        frac.numerator *
        BigInt.from(pow10(currencyExponent(target)));
    final denominator = frac.denominator * BigInt.from(pow10(exponent));
    return Money(_roundDiv(numerator, denominator).toInt(), target);
  }

  /// Integer division rounded half away from zero. [b] must be positive.
  static BigInt _roundDiv(BigInt a, BigInt b) {
    final negative = a.isNegative;
    final abs = a.abs();
    final q = abs ~/ b;
    final r = abs - q * b;
    final rounded = (r * BigInt.two >= b) ? q + BigInt.one : q;
    return negative ? -rounded : rounded;
  }

  /// A plain decimal rendering with the currency code, e.g. `123.45 EUR`.
  /// For UI prefer `PortalFormat.money`; this is for debugging and tests.
  String format() {
    final exp = exponent;
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    if (exp == 0) return '$sign$abs $currency';
    final digits = abs.toString().padLeft(exp + 1, '0');
    final whole = digits.substring(0, digits.length - exp);
    final frac = digits.substring(digits.length - exp);
    return '$sign$whole.$frac $currency';
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'currency mismatch: $currency vs ${other.currency} — convert first',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits, $currency)';

  Map<String, dynamic> toJson() => {'minorUnits': minorUnits, 'currency': currency};

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money(json['minorUnits'] as int, json['currency'] as String);
}
