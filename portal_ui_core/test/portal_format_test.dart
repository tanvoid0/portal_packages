import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The kit's G2 rules table (en-GB), one assertion per row.
void main() {
  setUpAll(() => initializeDateFormatting('en_GB'));

  final f = PortalFormat('en_GB', now: () => DateTime(2026, 9, 16, 19));

  test('money: symbol always, .00 only when padded, negative is -\$25', () {
    expect(f.money(1200, 'GBP'), '£1,200');
    expect(f.money(24.6, 'GBP', padded: true), '£24.60');
    expect(f.money(1200, 'GBP', padded: true), '£1,200.00');
    expect(f.money(0, 'GBP'), '£0');
    expect(PortalFormat('en_US').money(-25, 'USD'), '-\$25');
  });

  test('signed: money in +, money out -, percent whole above 1%', () {
    expect(f.signed(12.3, 'GBP'), '+£12.30');
    expect(f.signed(-24.6, 'GBP'), '-£24.60');
    expect(f.signed(0.064, null, true), '+6%');
    expect(f.signed(0.004, null, true), '+0.4%');
  });

  test('compact and percent', () {
    expect(f.compact(12400), '12.4K');
    expect(f.compact(1.2e6, currency: 'GBP'), '£1.2M');
    expect(f.compact(12000), '12K');
    expect(f.percent(0.064), '6.4%');
    expect(f.percent(0.06), '6%');
  });

  test('dates: relative within a week, then calendar', () {
    expect(f.date(DateTime(2026, 9, 16, 8)), 'Today');
    expect(f.date(DateTime(2026, 9, 15)), 'Yesterday');
    expect(f.date(DateTime(2026, 9, 14)), 'Monday');
    expect(f.date(DateTime(2026, 9, 14), short: true), 'Mon');
    expect(f.date(DateTime(2026, 9, 16, 18, 40), short: true), '18:40');
    // CLDR spells September "Sept" in en-GB; the kit's table says "Sep".
    expect(f.date(DateTime(2026, 9, 1)), '1 Sept');
    expect(f.date(DateTime(2025, 9, 14)), '14 Sept 2025');
    expect(f.time(DateTime(2026, 1, 1, 18, 42)), '18:42');
  });

  test('relative days are calendar days across a spring-forward', () {
    // 2026-03-29 is the UK clock change: local midnights either side are 23h
    // apart, which a Duration-based count reads as Today.
    final g = PortalFormat('en_GB', now: () => DateTime(2026, 3, 30, 10));
    expect(g.date(DateTime(2026, 3, 29, 23)), 'Yesterday');
    expect(g.date(DateTime(2026, 3, 29)), 'Yesterday');
    expect(g.date(DateTime(2026, 3, 30)), 'Today');
    expect(g.date(DateTime(2026, 3, 27)), 'Friday');
  });

  test('duration, range, bytes', () {
    expect(f.duration(const Duration(minutes: 65)), '1 h 5 min');
    expect(f.duration(const Duration(minutes: 1, seconds: 52)), '1 min 52 s');
    expect(f.duration(const Duration(seconds: 42)), '42 s');
    expect(f.range(20, 40, currency: 'GBP'), '£20–£40');
    expect(f.range('Mon', 'Fri'), 'Mon–Fri');
    expect(f.bytes(586e6), '586 MB');
    expect(f.bytes(1.6e9), '1.6 GB');
  });

  testWidgets('PortalAmount scales a long value to fit, never wraps',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: SizedBox(
          width: 120,
          child: PortalAmount(
            1284390.75,
            'GBP',
            size: PortalAmountSize.hero,
          ),
        ),
      ),
    ));
    expect(find.text('£1,284,390.75'), findsOneWidget);
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(FittedBox)).width, lessThanOrEqualTo(120));
  });

  test('dateAs: named day-month and numeric shapes, zero padded', () {
    final us = PortalFormat('en_US');
    final d = DateTime(2026, 9, 5);
    expect(us.dateAs(d, PortalDateStyle.dayMonth), '05 Sep');
    expect(us.dateAs(d, PortalDateStyle.dayMonthYear), '05 Sep 2026');
    expect(us.dateAs(d, PortalDateStyle.numeric), '05/09/2026');
    expect(us.dateAs(d, PortalDateStyle.numericDayMonth), '05/09');
  });

  test('duration: spelled stays the default, compact drops the spaces', () {
    const d = Duration(minutes: 1, seconds: 5);
    expect(f.duration(d), '1 min 5 s');
    expect(f.duration(d, style: PortalDurationStyle.compact), '1m 5s');
    expect(
        f.duration(const Duration(hours: 1, minutes: 5),
            style: PortalDurationStyle.compact),
        '1h 5m');
    expect(
        f.duration(const Duration(seconds: 42),
            style: PortalDurationStyle.compact),
        '42s');
    expect(
        f.duration(const Duration(minutes: 2),
            style: PortalDurationStyle.compact),
        '2m');
  });

  test('dateAs: unpadded, month-first and weekday shapes', () {
    final us = PortalFormat('en_US');
    final d = DateTime(2026, 10, 5);
    expect(us.dateAs(d, PortalDateStyle.dayMonthUnpadded), '5 Oct');
    expect(us.dateAs(d, PortalDateStyle.dayMonthYearUnpadded), '5 Oct 2026');
    expect(us.dateAs(d, PortalDateStyle.monthDay), 'Oct 5');
    expect(us.dateAs(d, PortalDateStyle.weekdayMonthDay), 'Monday, Oct 5');
    expect(us.dateAs(d, PortalDateStyle.dayMonth), '05 Oct');
  });

  test('duration: hoursMinutes, minutesSeconds, minutesSpelled', () {
    String of(Duration d, PortalDurationStyle s) => f.duration(d, style: s);
    const ninety = Duration(minutes: 90, seconds: 20);
    expect(of(ninety, PortalDurationStyle.hoursMinutes), '1h 30m');
    expect(of(const Duration(hours: 2), PortalDurationStyle.hoursMinutes),
        '2h 0m');
    expect(of(const Duration(minutes: 45), PortalDurationStyle.hoursMinutes),
        '45m');
    expect(of(const Duration(minutes: 5), PortalDurationStyle.minutesSeconds),
        '5m 0s');
    expect(of(ninety, PortalDurationStyle.minutesSeconds), '90m 20s');
    expect(of(const Duration(minutes: 45), PortalDurationStyle.minutesSpelled),
        '45 min');
    expect(of(ninety, PortalDurationStyle.minutesSpelled), '90 min');
    expect(f.duration(const Duration(minutes: 1, seconds: 5)), '1 min 5 s');
  });
}
