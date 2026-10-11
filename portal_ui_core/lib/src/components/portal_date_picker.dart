import 'package:flutter/material.dart';

/// Thin wrapper around [showDatePicker] for the common "pick one date" flow
/// repeated across the fleet (finance, gym, task): same ~10-year default
/// window, and [initialDate] clamped into [firstDate]..[lastDate] so a stale
/// value from state (a goal date already in the past, a controller default)
/// cannot trip `showDatePicker`'s initialDate-in-range assertion.
///
/// Theming (colors, shape, elevation) comes from the ambient
/// `ThemeData.datePickerTheme` set by `PortalUiTheme` — this wrapper adds no
/// styling of its own, only the defaulting/clamping every call site repeated.
Future<DateTime?> showPortalDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  final now = DateTime.now();
  final first = firstDate ?? DateTime(now.year - 10);
  final last = lastDate ?? DateTime(now.year + 10);
  var initial = initialDate;
  if (initial.isBefore(first)) {
    initial = first;
  } else if (initial.isAfter(last)) {
    initial = last;
  }
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    helpText: helpText,
  );
}
