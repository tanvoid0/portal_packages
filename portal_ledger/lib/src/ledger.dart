import 'package:meta/meta.dart';

import 'money.dart';

/// A signed effect of an entry on one party's balance, in one currency.
/// Positive means the party is owed (a net creditor) by that amount.
@immutable
class LedgerDelta {
  final String partyId;
  final Money amount;

  const LedgerDelta(this.partyId, this.amount);
}

/// Anything that moves money between parties. An entry resolves to the set of
/// per-party deltas it produces.
abstract class LedgerEntry {
  List<LedgerDelta> deltas();
}

/// An entry built directly from deltas — used to project a member's slice of a
/// shared ledger (see `SharedLedger.viewFor`).
@immutable
class RawLedgerEntry implements LedgerEntry {
  final List<LedgerDelta> _deltas;

  const RawLedgerEntry(this._deltas);

  @override
  List<LedgerDelta> deltas() => _deltas;
}

/// The common base: a set of parties and the entries over them. Balances are
/// tracked **per currency** — a party can be owed in one currency and owe in
/// another at the same time. Pure computation; no persistence, no auth.
abstract class Ledger {
  final List<String> partyIds;
  final List<LedgerEntry> entries;

  const Ledger(this.partyIds, this.entries);

  /// `partyId -> (currency -> net minor units)`. A currency with a net of zero
  /// is omitted. Positive means the party is a net creditor in that currency.
  Map<String, Map<String, int>> balances() {
    final out = <String, Map<String, int>>{};
    for (final p in partyIds) {
      out[p] = <String, int>{};
    }
    for (final entry in entries) {
      for (final d in entry.deltas()) {
        final byCurrency = out.putIfAbsent(d.partyId, () => <String, int>{});
        byCurrency[d.amount.currency] =
            (byCurrency[d.amount.currency] ?? 0) + d.amount.minorUnits;
      }
    }
    for (final byCurrency in out.values) {
      byCurrency.removeWhere((_, v) => v == 0);
    }
    return out;
  }

  /// Net balance for one party as `currency -> minor units` (zeros omitted).
  Map<String, int> balanceOf(String partyId) =>
      Map<String, int>.from(balances()[partyId] ?? const {});
}
