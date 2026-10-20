import 'package:portal_ledger/portal_ledger.dart';
import 'package:test/test.dart';

/// Unordered comparison of suggested transfers.
Set<String> _asSet(List<Transfer> ts) =>
    ts.map((t) => '${t.from}->${t.to}:${t.amount.minorUnits}${t.amount.currency}').toSet();

void main() {
  group('Expense', () {
    test('single payer, equal split nets correctly', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob', 'carol'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(9000, 'THB'),
          payers: [Payment('alice', Money(9000, 'THB'))],
          split: EqualSplit(['alice', 'bob', 'carol']),
        ),
      ]);
      expect(ledger.balanceOf('alice'), {'THB': 6000});
      expect(ledger.balanceOf('bob'), {'THB': -3000});
      expect(ledger.balanceOf('carol'), {'THB': -3000});
    });

    test('multiple payers', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(100, 'USD'),
          payers: [Payment('alice', Money(60, 'USD')), Payment('bob', Money(40, 'USD'))],
          split: EqualSplit(['alice', 'bob']),
        ),
      ]);
      expect(ledger.balanceOf('alice'), {'USD': 10});
      expect(ledger.balanceOf('bob'), {'USD': -10});
    });

    test('payers that do not sum to the total throw', () {
      const bad = Expense(
        id: 'e1',
        amount: Money(100, 'USD'),
        payers: [Payment('alice', Money(60, 'USD'))],
        split: EqualSplit(['alice', 'bob']),
      );
      expect(bad.deltas, throwsArgumentError);
    });
  });

  group('splits', () {
    test('percent split in basis points, odd cent to largest remainder', () {
      expect(
        const PercentSplit({'a': 3333, 'b': 3333, 'c': 3334}).resolve(100),
        {'a': 33, 'b': 33, 'c': 34},
      );
    });

    test('percent that does not sum to 10000 throws', () {
      expect(() => const PercentSplit({'a': 5000, 'b': 4000}).resolve(100), throwsArgumentError);
    });

    test('exact split must match the total', () {
      expect(const ExactSplit({'a': 70, 'b': 30}).resolve(100), {'a': 70, 'b': 30});
      expect(() => const ExactSplit({'a': 70, 'b': 40}).resolve(100), throwsArgumentError);
    });
  });

  group('settlement', () {
    test('repayment clears a debtor', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob', 'carol'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(9000, 'THB'),
          payers: [Payment('alice', Money(9000, 'THB'))],
          split: EqualSplit(['alice', 'bob', 'carol']),
        ),
        Settlement(id: 's1', fromParty: 'bob', toParty: 'alice', sent: Money(3000, 'THB')),
      ]);
      expect(ledger.balanceOf('bob'), isEmpty); // net zero -> no currencies
      expect(ledger.balanceOf('alice'), {'THB': 3000});
      expect(ledger.balanceOf('carol'), {'THB': -3000});
    });

    test('cross-currency settlement adjusts each side in its own currency', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob'], entries: const [
        Settlement(
          id: 's1',
          fromParty: 'bob',
          toParty: 'alice',
          sent: Money(5000, 'USD'),
          received: Money(4500, 'EUR'),
        ),
      ]);
      expect(ledger.balanceOf('bob'), {'USD': 5000});
      expect(ledger.balanceOf('alice'), {'EUR': -4500});
    });
  });

  group('multi-currency and simplifyDebts', () {
    test('balances track each currency independently', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(100, 'USD'),
          payers: [Payment('alice', Money(100, 'USD'))],
          split: EqualSplit(['alice', 'bob']),
        ),
        Expense(
          id: 'e2',
          amount: Money(200, 'EUR'),
          payers: [Payment('bob', Money(200, 'EUR'))],
          split: EqualSplit(['alice', 'bob']),
        ),
      ]);
      expect(ledger.balanceOf('alice'), {'USD': 50, 'EUR': -100});
      expect(ledger.balanceOf('bob'), {'USD': -50, 'EUR': 100});
    });

    test('greedy simplification clears everyone, per currency', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob', 'carol'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(9000, 'THB'),
          payers: [Payment('alice', Money(9000, 'THB'))],
          split: EqualSplit(['alice', 'bob', 'carol']),
        ),
      ]);
      final transfers = ledger.simplifyDebts();
      expect(transfers.length, 2);
      expect(_asSet(transfers), {'bob->alice:3000THB', 'carol->alice:3000THB'});
    });
  });

  group('personal ledger', () {
    test('solo spend nets across entries', () {
      final me = PersonalLedger(ownerId: 'me', entries: const [
        PersonalEntry(id: 'p1', ownerId: 'me', amount: Money(-5000, 'USD')),
        PersonalEntry(id: 'p2', ownerId: 'me', amount: Money(1000, 'USD')),
      ]);
      expect(me.balance(), {'USD': -4000});
    });

    test('a member view of a shared ledger is a personal ledger', () {
      final ledger = SharedLedger(memberIds: ['alice', 'bob', 'carol'], entries: const [
        Expense(
          id: 'e1',
          amount: Money(9000, 'THB'),
          payers: [Payment('alice', Money(9000, 'THB'))],
          split: EqualSplit(['alice', 'bob', 'carol']),
        ),
      ]);
      final bobView = ledger.viewFor('bob');
      expect(bobView, isA<PersonalLedger>());
      expect(bobView.balance(), ledger.balanceOf('bob'));
      expect(bobView.balance(), {'THB': -3000});
    });
  });
}
