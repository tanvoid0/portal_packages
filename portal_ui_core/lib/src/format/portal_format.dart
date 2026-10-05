import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A named date pattern for [PortalFormat.dateAs].
enum PortalDateStyle {
  /// `05 Sep`.
  dayMonth('dd MMM'),

  /// `05 Sep 2026`.
  dayMonthYear('dd MMM yyyy'),

  /// `05/09/2026`.
  numeric('dd/MM/yyyy'),

  /// `05/09`.
  numericDayMonth('dd/MM'),

  /// `5 Sep`: the day unpadded.
  dayMonthUnpadded('d MMM'),

  /// `5 Sep 2026`.
  dayMonthYearUnpadded('d MMM yyyy'),

  /// `Oct 5`: month first, the order en-US reads.
  monthDay('MMM d'),

  /// `Monday, Oct 5`.
  weekdayMonthDay('EEEE, MMM d');

  const PortalDateStyle(this.pattern);
  final String pattern;
}

/// How [PortalFormat.duration] spells a length of time.
enum PortalDurationStyle {
  /// `1 h 5 min`, `1 min 52 s`, `42 s`: the kit's rule, and the default.
  spelled,

  /// `1h 5m`, `1m 52s`, `42s`: for a dense value column.
  compact,

  /// `1h 30m`, `2h 0m`, `45m`: hours and minutes, the minutes always shown
  /// once there are hours. Seconds are dropped.
  hoursMinutes,

  /// `5m 0s`, `75m 30s`: total minutes and the seconds, both always shown.
  minutesSeconds,

  /// `45 min`, `90 min`: total minutes, spelled, seconds dropped.
  minutesSpelled,
}

/// The one set of rules for money, numbers, dates and time (G2).
///
/// Locale comes from the context ([PortalFormat.of]), `intl` underneath.
/// The rules, each a decision rather than a default:
///
/// * The currency symbol is always there: `£0`, never "Free".
/// * No `.00` in a sentence ([money]); padded decimals in lists and receipts
///   (`padded: true`) so columns line up.
/// * Negative is a hyphen-minus before the symbol: `-$25`, never `$-25` or
///   `($25)`.
/// * A space before a unit (`586 MB`, `1 h 5 min`); ranges take an en dash.
class PortalFormat {
  /// [now] is injectable so relative dates are testable.
  PortalFormat(this.locale, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  factory PortalFormat.of(BuildContext context) =>
      PortalFormat(Localizations.localeOf(context).toString());

  final String locale;
  final DateTime Function() _now;

  /// `£1,200`, or with [padded] `£1,200.00`. A non-whole amount always keeps
  /// its two decimals (`£24.60`): only a whole one drops them in prose.
  String money(num amount, String currency, {bool padded = false}) {
    amount = _round(amount, 2);
    final whole = amount == amount.roundToDouble();
    final f = NumberFormat.simpleCurrency(
      locale: locale,
      name: currency,
      decimalDigits: whole && !padded ? 0 : 2,
    );
    final body = f.format(amount.abs());
    return amount < 0 ? '-$body' : body;
  }

  /// A change: `+£12.30`, `-£24.60`. With [percent], [value] is a fraction and
  /// the result a whole number, one decimal only under 1%: `+6%`, `+0.4%`.
  /// Zero carries no sign.
  String signed(num value, [String? currency, bool percent = false]) {
    // Round to the shown precision first: -0.004 reads `£0.00`, not `-£0.00`.
    final digits = percent
        ? (value.abs() * 100 < 1 ? 1 : 0)
        : (currency == null ? 3 : 2);
    final v = _round(percent ? value * 100 : value, digits);
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    final abs = v.abs();
    if (percent) {
      final f = NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: digits,
      );
      return '$sign${f.format(abs)}%';
    }
    final body = currency == null
        ? NumberFormat.decimalPattern(locale).format(abs)
        : money(abs, currency, padded: true);
    return '$sign$body';
  }

  // ponytail: K / M / B suffixes only (English); a locale with its own short
  // forms needs NumberFormat.compact and gives up the 12.4K rule.
  /// `12.4K`, `£1.2M`: one decimal, a trailing `.0` dropped.
  String compact(num value, {String? currency}) {
    final abs = value.abs();
    var (div, suffix) = abs >= 1e9
        ? (1e9, 'B')
        : abs >= 1e6
            ? (1e6, 'M')
            : abs >= 1e3
                ? (1e3, 'K')
                : (1.0, '');
    // 999,960 scales to 999.96 -> `1,000K`: step up a unit once it rounds there.
    if (_round(abs / div, 1) >= 1000 && suffix != 'B') {
      (div, suffix) = suffix == 'M'
          ? (1e9, 'B')
          : suffix == 'K'
              ? (1e6, 'M')
              : (1e3, 'K');
    }
    final scaled = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    ).format(abs / div);
    final symbol = currency == null
        ? ''
        : NumberFormat.simpleCurrency(locale: locale, name: currency)
            .currencySymbol;
    return '${value < 0 ? '-' : ''}$symbol${_trimZero(scaled)}$suffix';
  }

  /// `6.4%` from `0.064`; `6%` from `0.06`.
  String percent(num fraction) {
    final f = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: 1,
    )..minimumFractionDigits = 0;
    return f.format(fraction);
  }

  /// Today / Yesterday / `Wednesday` within a week / `14 Sep` / `14 Sep 2025`.
  /// With [short] (a row's value column): the time today, `Wed` for a
  /// weekday, otherwise as above. Never `5m`, which reads as a duration.
  String date(DateTime d, {bool short = false}) {
    d = d.toLocal();
    final now = _now();
    // UTC midnights: two local ones either side of a DST change are 23h apart
    // and `inDays` would truncate that to a day short.
    final diff = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return short ? time(d) : 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) {
      return (short ? DateFormat.E(locale) : DateFormat.EEEE(locale)).format(d);
    }
    final f = d.year == now.year ? DateFormat.MMMd(locale) : DateFormat.yMMMd(locale);
    return f.format(d);
  }

  /// A date in a fixed shape, never relative: see [PortalDateStyle]. Zero
  /// padded; the month name follows the locale (en-GB reads `Sept`).
  String dateAs(DateTime d, PortalDateStyle style) =>
      DateFormat(style.pattern, locale).format(d);

  /// `18:42` or `6:42 PM`, by locale. Never seconds.
  String time(DateTime t) => DateFormat.jm(locale).format(t.toLocal());

  /// `1 h 5 min`, `1 min 52 s`, `42 s`. Never `65 min` or `1:05:00`.
  /// [style] `compact` drops the spaces and spells the units `h`, `m`, `s`.
  String duration(Duration d,
      {PortalDurationStyle style = PortalDurationStyle.spelled}) {
    if (d.isNegative) {
      return '-${duration(-d, style: style)}';
    }
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    switch (style) {
      case PortalDurationStyle.hoursMinutes:
        return h > 0 ? '${h}h ${m}m' : '${m}m';
      case PortalDurationStyle.minutesSeconds:
        return '${d.inMinutes}m ${s}s';
      case PortalDurationStyle.minutesSpelled:
        return '${d.inMinutes} min';
      case PortalDurationStyle.spelled || PortalDurationStyle.compact:
        break;
    }
    if (style == PortalDurationStyle.compact) {
      if (h > 0) return m == 0 ? '${h}h' : '${h}h ${m}m';
      if (d.inMinutes > 0) return s == 0 ? '${m}m' : '${m}m ${s}s';
      return '${s}s';
    }
    if (h > 0) return m == 0 ? '$h h' : '$h h $m min';
    if (d.inMinutes > 0) return s == 0 ? '$m min' : '$m min $s s';
    return '$s s';
  }

  /// `£20–£40` from two numbers with a [currency], or any two formatted ends
  /// (`Mon–Fri`, `09:00–17:30`). Never a hyphen or "to".
  String range(Object from, Object to, {String? currency}) {
    String one(Object o) =>
        o is num && currency != null ? money(o, currency) : '$o';
    return '${one(from)}–${one(to)}';
  }

  /// Decimal units: `586 MB`, `1.6 GB`.
  String bytes(num value) {
    const units = ['B', 'kB', 'MB', 'GB', 'TB'];
    var v = value.toDouble().abs();
    var i = 0;
    while (v >= 1000 && i < units.length - 1) {
      v /= 1000;
      i++;
    }
    final f = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: v < 10 && i > 0 ? 1 : 0,
    );
    return '${value < 0 ? '-' : ''}${_trimZero(f.format(v))} ${units[i]}';
  }

  static double _round(num v, int digits) {
    final k = pow(10, digits);
    final r = (v * k).round() / k;
    return r == 0 ? 0 : r; // no negative zero
  }

  static String _trimZero(String s) =>
      s.endsWith('.0') || s.endsWith(',0') ? s.substring(0, s.length - 2) : s;
}
