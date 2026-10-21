/// A selectable world currency: ISO-4217 [code], its [symbol] and English
/// [name]. [flag] is the Unicode flag emoji derived from the code's country
/// prefix (renders on mobile; may fall back to letters on desktop/web fonts).
///
/// One list for the whole fleet so finance and travel offer the same set
/// instead of each hard-coding a handful. Add rows as they come up.
class PortalCurrency {
  const PortalCurrency(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;

  /// Flag emoji from the first two letters of [code] (GBP → GB → 🇬🇧). Blank
  /// when the prefix is not a region (the supranational XAF/XOF codes).
  String get flag {
    final region = code.substring(0, 2);
    if (region.codeUnits.any((c) => c < 0x41 || c > 0x5A)) return '';
    return String.fromCharCodes(
      region.codeUnits.map((c) => 0x1F1E6 + c - 0x41),
    );
  }

  /// Minor-unit decimal places (2 for USD, 0 for JPY, 3 for KWD). Matches
  /// portal_ledger's table; the default is 2.
  int get exponent => _currencyExponent(code);

  @override
  String toString() => code;
}

/// ISO-4217 minor-unit exponents that differ from the default of 2. Kept in
/// step with portal_ledger's own table (this package cannot depend on it).
const Set<String> _zeroDecimal = {
  'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'PYG', 'RWF', 'UGX', 'VUV', 'XAF',
  'XOF', 'XPF', 'BIF', 'DJF', 'GNF', 'KMF',
};
const Set<String> _threeDecimal = {
  'BHD', 'KWD', 'OMR', 'TND', 'IQD', 'JOD', 'LYD',
};

int _currencyExponent(String code) {
  final c = code.toUpperCase();
  if (_zeroDecimal.contains(c)) return 0;
  if (_threeDecimal.contains(c)) return 3;
  return 2;
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// A parsed amount: the [amount] as a double, the ISO [currency], and the exact
/// [minorUnits] (what storage and wire use). This is ui_core's neutral money
/// value — an app maps it to its own domain type (e.g. travel's ledger Money).
class PortalMoney {
  const PortalMoney(this.amount, this.currency, this.minorUnits);

  final double amount;
  final String currency;
  final int minorUnits;

  /// Parses user-typed [raw] (symbols, commas and spaces tolerated) into exact
  /// [minorUnits] for [currency]'s exponent. Null when there is no number.
  /// String math, not `double * 100`, so 19.99 GBP is 1999, never 1998.
  static PortalMoney? parse(String raw, String currency) {
    final cur = currency.toUpperCase();
    final exp = _currencyExponent(cur);
    var s = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final neg = s.startsWith('-');
    if (neg) s = s.substring(1);
    s = s.replaceAll('-', '');
    if (s.isEmpty || s == '.') return null;
    final dot = s.indexOf('.');
    final intPart = (dot < 0 ? s : s.substring(0, dot));
    final fracRaw = dot < 0 ? '' : s.substring(dot + 1).replaceAll('.', '');
    final frac = fracRaw.padRight(exp, '0').substring(0, exp);
    final minor = int.tryParse((intPart.isEmpty ? '0' : intPart) + frac);
    if (minor == null) return null;
    final signed = neg ? -minor : minor;
    final amount = exp == 0 ? signed.toDouble() : signed / _pow10(exp);
    return PortalMoney(amount, cur, signed);
  }

  @override
  String toString() => 'PortalMoney($minorUnits, $currency)';
}

/// Every currency the pickers offer, common ones first. Not exhaustive ISO —
/// the long tail (XAF, SDG, …) is added on request rather than padding the
/// list with codes no one picks.
const List<PortalCurrency> kPortalCurrencies = [
  PortalCurrency('USD', r'$', 'US Dollar'),
  PortalCurrency('EUR', '€', 'Euro'),
  PortalCurrency('GBP', '£', 'British Pound'),
  PortalCurrency('JPY', '¥', 'Japanese Yen'),
  PortalCurrency('CNY', '¥', 'Chinese Yuan'),
  PortalCurrency('INR', '₹', 'Indian Rupee'),
  PortalCurrency('AUD', r'A$', 'Australian Dollar'),
  PortalCurrency('CAD', r'C$', 'Canadian Dollar'),
  PortalCurrency('CHF', 'Fr', 'Swiss Franc'),
  PortalCurrency('HKD', r'HK$', 'Hong Kong Dollar'),
  PortalCurrency('SGD', r'S$', 'Singapore Dollar'),
  PortalCurrency('NZD', r'NZ$', 'New Zealand Dollar'),
  PortalCurrency('SEK', 'kr', 'Swedish Krona'),
  PortalCurrency('NOK', 'kr', 'Norwegian Krone'),
  PortalCurrency('DKK', 'kr', 'Danish Krone'),
  PortalCurrency('KRW', '₩', 'South Korean Won'),
  PortalCurrency('THB', '฿', 'Thai Baht'),
  PortalCurrency('IDR', 'Rp', 'Indonesian Rupiah'),
  PortalCurrency('MYR', 'RM', 'Malaysian Ringgit'),
  PortalCurrency('PHP', '₱', 'Philippine Peso'),
  PortalCurrency('VND', '₫', 'Vietnamese Dong'),
  PortalCurrency('AED', 'د.إ', 'UAE Dirham'),
  PortalCurrency('SAR', '﷼', 'Saudi Riyal'),
  PortalCurrency('QAR', '﷼', 'Qatari Riyal'),
  PortalCurrency('ILS', '₪', 'Israeli Shekel'),
  PortalCurrency('TRY', '₺', 'Turkish Lira'),
  PortalCurrency('ZAR', 'R', 'South African Rand'),
  PortalCurrency('EGP', 'E£', 'Egyptian Pound'),
  PortalCurrency('NGN', '₦', 'Nigerian Naira'),
  PortalCurrency('KES', 'KSh', 'Kenyan Shilling'),
  PortalCurrency('GHS', '₵', 'Ghanaian Cedi'),
  PortalCurrency('MAD', 'DH', 'Moroccan Dirham'),
  PortalCurrency('BRL', r'R$', 'Brazilian Real'),
  PortalCurrency('MXN', r'$', 'Mexican Peso'),
  PortalCurrency('ARS', r'$', 'Argentine Peso'),
  PortalCurrency('CLP', r'$', 'Chilean Peso'),
  PortalCurrency('COP', r'$', 'Colombian Peso'),
  PortalCurrency('PEN', 'S/', 'Peruvian Sol'),
  PortalCurrency('PLN', 'zł', 'Polish Zloty'),
  PortalCurrency('CZK', 'Kč', 'Czech Koruna'),
  PortalCurrency('HUF', 'Ft', 'Hungarian Forint'),
  PortalCurrency('RON', 'lei', 'Romanian Leu'),
  PortalCurrency('BGN', 'лв', 'Bulgarian Lev'),
  PortalCurrency('RUB', '₽', 'Russian Ruble'),
  PortalCurrency('UAH', '₴', 'Ukrainian Hryvnia'),
  PortalCurrency('PKR', '₨', 'Pakistani Rupee'),
  PortalCurrency('BDT', '৳', 'Bangladeshi Taka'),
  PortalCurrency('LKR', 'Rs', 'Sri Lankan Rupee'),
  PortalCurrency('NPR', 'Rs', 'Nepalese Rupee'),
  PortalCurrency('TWD', r'NT$', 'Taiwan Dollar'),
  PortalCurrency('ISK', 'kr', 'Icelandic Krona'),
];

final Map<String, PortalCurrency> _byCode = {
  for (final c in kPortalCurrencies) c.code: c,
};

/// The currency for [code] (case-insensitive), or null when unknown.
PortalCurrency? portalCurrencyOf(String code) => _byCode[code.toUpperCase()];

/// The last currency the user picked in a Portal currency/money field this
/// session. Set by the picker; null until the first pick. Seed a new field's
/// default with it so money inputs remember the last choice:
///
/// ```dart
/// late String _currency = portalLastUsedCurrency ?? userDefaultCurrency;
/// ```
///
/// Session-only (not persisted) — a cross-launch default belongs to the app's
/// own stored preference.
String? portalLastUsedCurrency;
