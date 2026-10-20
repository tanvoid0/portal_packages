/// ISO-4217 minor-unit exponents that differ from the default of 2.
///
/// The default is 2 (cents). Extend either map as currencies come up; an
/// unknown code falls back to 2, which is correct for the large majority.
const Map<String, int> _exponents = {
  // Zero-decimal currencies.
  'JPY': 0, 'KRW': 0, 'VND': 0, 'CLP': 0, 'ISK': 0, 'PYG': 0, 'RWF': 0,
  'UGX': 0, 'VUV': 0, 'XAF': 0, 'XOF': 0, 'XPF': 0, 'BIF': 0, 'DJF': 0,
  'GNF': 0, 'KMF': 0,
  // Three-decimal currencies.
  'BHD': 3, 'KWD': 3, 'OMR': 3, 'TND': 3, 'IQD': 3, 'JOD': 3, 'LYD': 3,
};

/// Number of minor-unit decimal places for [code] (e.g. 2 for USD, 0 for JPY).
int currencyExponent(String code) => _exponents[code.toUpperCase()] ?? 2;

/// 10^[n] for small non-negative [n]. Minor-unit exponents are 0..3.
int pow10(int n) {
  assert(n >= 0, 'exponent must be non-negative');
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
