import 'package:intl/intl.dart';

final _gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');

String formatGbp(double amount) => _gbp.format(amount);

String formatGbpCompact(double amount) {
  if (amount >= 1000) {
    return _gbp.format(amount);
  }
  return _gbp.format(amount);
}

/// Human-readable countdown to [payoff] (exclusive of time-of-day).
String formatTimeLeftTo(DateTime? payoff) {
  if (payoff == null) return '';
  final now = DateTime.now();
  if (payoff.isBefore(now)) return 'Paid off';
  var days = payoff.difference(now).inDays;
  final years = days ~/ 365;
  days -= years * 365;
  final months = days ~/ 30;
  days -= months * 30;
  final parts = <String>[];
  if (years > 0) parts.add(years == 1 ? '1 year' : '$years years');
  if (months > 0) parts.add(months == 1 ? '1 month' : '$months months');
  if (days > 0) parts.add(days == 1 ? '1 day' : '$days days');
  if (parts.isEmpty) return 'Less than a day left';
  return '${parts.join(', ')} left';
}

double? parseMoneyInput(String s) {
  final t = s.replaceAll(RegExp(r'[£,\s]'), '').trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

double? parsePercentInput(String s) {
  final t = s.replaceAll(RegExp(r'[%\s]'), '').trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
