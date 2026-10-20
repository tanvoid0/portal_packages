import 'package:meta/meta.dart';

import 'ledger.dart';
import 'money.dart';
import 'personal_ledger.dart';
import 'split.dart';

/// Money a single party paid toward an expense. An expense may have several.
@immutable
class Payment {
  final String partyId;
  final Money amount;

  const Payment(this.partyId, this.amount);
}

/// How an expense's total is owed across its beneficiaries. `resolve` returns
/// `partyId -> owed minor units`, summing to the total exactly.
sealed class Split {
  const Split();

  Map<String, int> resolve(int total);
}

/// Everyone named owes an equal share (largest-remainder for the odd cents).
class EqualSplit extends Split {
  final List<String> among;

  const EqualSplit(this.among);

  @override
  Map<String, int> resolve(int total) {
    final parts = allocateByWeights(total, List<int>.filled(among.length, 1));
    return {for (var i = 0; i < among.length; i++) among[i]: parts[i]};
  }
}

/// Owed in proportion to integer weights (e.g. 2 adults : 1 child).
class SharesSplit extends Split {
  final Map<String, int> shares;

  const SharesSplit(this.shares);

  @override
  Map<String, int> resolve(int total) {
    final ids = shares.keys.toList();
    final parts = allocateByWeights(total, ids.map((k) => shares[k]!).toList());
    return {for (var i = 0; i < ids.length; i++) ids[i]: parts[i]};
  }
}

/// Owed by percentage, given in basis points (hundredths of a percent) that
/// must sum to 10000. Largest-remainder handles the rounding.
class PercentSplit extends Split {
  final Map<String, int> basisPoints;

  const PercentSplit(this.basisPoints);

  @override
  Map<String, int> resolve(int total) {
    final ids = basisPoints.keys.toList();
    final bps = ids.map((k) => basisPoints[k]!).toList();
    final sum = bps.fold<int>(0, (a, b) => a + b);
    if (sum != 10000) {
      throw ArgumentError('basis points must sum to 10000, got $sum');
    }
    final parts = allocateByWeights(total, bps);
    return {for (var i = 0; i < ids.length; i++) ids[i]: parts[i]};
  }
}

/// Explicit owed amounts per party; must sum to the total.
class ExactSplit extends Split {
  final Map<String, int> amounts;

  const ExactSplit(this.amounts);

  @override
  Map<String, int> resolve(int total) {
    final sum = amounts.values.fold<int>(0, (a, b) => a + b);
    if (sum != total) {
      throw ArgumentError('exact amounts must sum to $total, got $sum');
    }
    return Map<String, int>.from(amounts);
  }
}

/// A cost paid by one or more parties and owed across beneficiaries, all in a
/// single currency. Payers' total must equal [amount].
@immutable
class Expense implements LedgerEntry {
  final String id;
  final Money amount;
  final List<Payment> payers;
  final Split split;

  const Expense({
    required this.id,
    required this.amount,
    required this.payers,
    required this.split,
  });

  @override
  List<LedgerDelta> deltas() {
    var paid = 0;
    for (final p in payers) {
      if (p.amount.currency != amount.currency) {
        throw ArgumentError('payer currency ${p.amount.currency} != ${amount.currency}');
      }
      paid += p.amount.minorUnits;
    }
    if (paid != amount.minorUnits) {
      throw ArgumentError('payers sum to $paid, expected ${amount.minorUnits}');
    }
    final owed = split.resolve(amount.minorUnits);
    final out = <LedgerDelta>[];
    for (final p in payers) {
      out.add(LedgerDelta(p.partyId, p.amount));
    }
    owed.forEach((party, share) {
      out.add(LedgerDelta(party, Money(-share, amount.currency)));
    });
    return out;
  }
}

/// A repayment from one party to another. [received] may differ in amount or
/// currency from [sent] — that captures a real transfer whose landing amount
/// is cut by an FX spread or bank fee. Defaults to [sent].
@immutable
class Settlement implements LedgerEntry {
  final String id;
  final String fromParty;
  final String toParty;
  final Money sent;
  final Money? received;

  const Settlement({
    required this.id,
    required this.fromParty,
    required this.toParty,
    required this.sent,
    this.received,
  });

  @override
  List<LedgerDelta> deltas() {
    final landed = received ?? sent;
    return [
      // The debtor paying out moves their balance up toward zero.
      LedgerDelta(fromParty, sent),
      // The creditor being paid moves their balance down toward zero.
      LedgerDelta(toParty, Money(-landed.minorUnits, landed.currency)),
    ];
  }
}

/// A suggested payment that reduces outstanding balances.
@immutable
class Transfer {
  final String from;
  final String to;
  final Money amount;

  const Transfer(this.from, this.to, this.amount);

  @override
  String toString() => '$from -> $to ${amount.format()}';
}

/// A multi-member ledger of shared [Expense]s and [Settlement]s.
class SharedLedger extends Ledger {
  SharedLedger({required List<String> memberIds, List<LedgerEntry> entries = const []})
      : super(memberIds, entries);

  List<String> get memberIds => partyIds;

  /// Minimal-ish set of payments that clears all balances, computed per
  /// currency (cross-currency debts settle within their own currency).
  ///
  // ponytail: greedy largest-creditor/largest-debtor matching — not provably
  // minimal (optimal min-cash-flow is NP-hard). Fine for trip-sized groups;
  // revisit with a subset-sum pass only if transfer counts ever matter.
  List<Transfer> simplifyDebts() {
    final result = <Transfer>[];
    final balances = this.balances();

    final currencies = <String>{};
    for (final byCurrency in balances.values) {
      currencies.addAll(byCurrency.keys);
    }

    for (final currency in currencies.toList()..sort()) {
      final creditors = <_Bucket>[];
      final debtors = <_Bucket>[];
      balances.forEach((party, byCurrency) {
        final net = byCurrency[currency] ?? 0;
        if (net > 0) creditors.add(_Bucket(party, net));
        if (net < 0) debtors.add(_Bucket(party, -net));
      });
      creditors.sort((a, b) => b.amount.compareTo(a.amount));
      debtors.sort((a, b) => b.amount.compareTo(a.amount));

      var i = 0;
      var j = 0;
      while (i < debtors.length && j < creditors.length) {
        final pay = debtors[i].amount < creditors[j].amount
            ? debtors[i].amount
            : creditors[j].amount;
        if (pay > 0) {
          result.add(Transfer(debtors[i].id, creditors[j].id, Money(pay, currency)));
        }
        debtors[i].amount -= pay;
        creditors[j].amount -= pay;
        if (debtors[i].amount == 0) i++;
        if (creditors[j].amount == 0) j++;
      }
    }
    return result;
  }

  /// Project one member's slice as a [PersonalLedger] — the same base, now with
  /// only this member's deltas. This is how "a personal ledger is part of a
  /// shared ledger" is expressed, without merging storage.
  PersonalLedger viewFor(String memberId) {
    final own = <LedgerEntry>[];
    for (final entry in entries) {
      final mine = entry.deltas().where((d) => d.partyId == memberId).toList();
      if (mine.isNotEmpty) own.add(RawLedgerEntry(mine));
    }
    return PersonalLedger(ownerId: memberId, entries: own);
  }
}

class _Bucket {
  final String id;
  int amount;

  _Bucket(this.id, this.amount);
}
