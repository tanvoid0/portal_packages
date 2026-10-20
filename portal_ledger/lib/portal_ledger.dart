/// Money, expense splitting, and a shared/personal ledger core for Portal apps.
///
/// Pure Dart — no persistence, no auth. See the package README.
library;

export 'src/currency.dart' show currencyExponent, pow10;
export 'src/money.dart';
export 'src/split.dart';
export 'src/ledger.dart';
export 'src/personal_ledger.dart';
export 'src/shared_ledger.dart';
