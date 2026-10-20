# portal_ledger

The shared money core for Portal apps. Pure Dart — **maths and model only, no
persistence and no auth**, so a single base can be reused by both the private
(personal) and multi-tenant (shared) worlds without ever merging their security
boundaries. Mirrored by a TypeScript ledger-core on the server, which recomputes
balances authoritatively; this Dart copy powers optimistic client preview.

## What's in it

- **`Money`** — `{ int minorUnits, String currency }`. Exact integer storage;
  all arithmetic that can lose precision (percentages, FX) runs through
  `package:decimal` and rounds back with a largest-remainder method so parts sum
  to the total exactly.
- **Split engine** — `EqualSplit`, `ExactSplit`, `SharesSplit`, `PercentSplit`
  (basis points), all via `allocateByWeights` (largest-remainder). Expenses
  support **multiple payers**.
- **Ledger hierarchy** — `Ledger` (base) → `PersonalLedger` (one party) and
  `SharedLedger` (members, expenses, settlements). Solo = a `SharedLedger` with
  one member; `sharedLedger.viewFor(member)` projects a member's slice as a
  `PersonalLedger`.
- **Multi-currency** — balances are tracked per currency (you can be owed USD
  *and* owe EUR); conversion is explicit (`Money.convertTo`) with an overridable
  rate, never forced on the owed truth.
- **`simplifyDebts()`** — greedy min-cash-flow heuristic, per currency.

```dart
final ledger = SharedLedger(memberIds: ['alice', 'bob', 'carol'], entries: [
  Expense(
    id: 'e1',
    amount: const Money(9000, 'THB'),           // ฿90.00
    payers: const [Payment('alice', Money(9000, 'THB'))],
    split: const EqualSplit(['alice', 'bob', 'carol']),
  ),
]);
ledger.balanceOf('alice');   // {THB: 6000}
ledger.simplifyDebts();      // bob→alice ฿30.00, carol→alice ฿30.00
```
