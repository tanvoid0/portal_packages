import 'package:meta/meta.dart';

import 'ledger.dart';
import 'money.dart';

/// One signed movement for a single owner: a spend (negative) or an income /
/// refund (positive). The building block of a solo traveller's own tracking.
@immutable
class PersonalEntry implements LedgerEntry {
  final String id;
  final String ownerId;
  final Money amount;

  const PersonalEntry({required this.id, required this.ownerId, required this.amount});

  @override
  List<LedgerDelta> deltas() => [LedgerDelta(ownerId, amount)];
}

/// A ledger with a single party. Used for a solo traveller and as the shape a
/// member's slice of a [SharedLedger] projects to (`viewFor`). A solo trip is a
/// `SharedLedger` with one member, which *is* a personal ledger — one base, both
/// cases.
class PersonalLedger extends Ledger {
  final String ownerId;

  PersonalLedger({required this.ownerId, List<LedgerEntry> entries = const []})
      : super([ownerId], entries);

  /// The owner's net position as `currency -> minor units` (zeros omitted).
  Map<String, int> balance() => balanceOf(ownerId);
}
