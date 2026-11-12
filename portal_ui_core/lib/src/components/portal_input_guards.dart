import 'package:flutter/services.dart';

/// Rejects keystrokes that would leave a number outside [min]..[max].
///
/// Partial input stays typeable ("", "12.", "-" when negatives are allowed);
/// only a complete value out of range is refused, so the field never holds
/// 999999 kg or -5 minutes. Use with a numeric keyboard.
class PortalBoundedNumberFormatter extends TextInputFormatter {
  const PortalBoundedNumberFormatter({this.min = 0, required this.max});

  final double min;
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '.' || (text == '-' && min < 0)) {
      return newValue;
    }
    final v = double.tryParse(text);
    if (v == null || v < min || v > max) return oldValue;
    return newValue;
  }
}

/// Wraps [action] so a second call while the first is still running is
/// dropped. Pass the result as `onPressed`; a synchronous [action] is guarded
/// for the duration of its call only, so make it return its Future.
///
/// A tap handler that mints ids or posts must not run twice from a double tap.
VoidCallback portalSingleFlight(Future<void> Function() action) {
  var running = false;
  return () async {
    if (running) return;
    running = true;
    try {
      await action();
    } finally {
      running = false;
    }
  };
}
