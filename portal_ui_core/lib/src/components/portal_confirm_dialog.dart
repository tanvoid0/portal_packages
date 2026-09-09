import 'package:flutter/material.dart';

/// Asks the user to confirm an action. Resolves to true only if they did —
/// dismissing by tapping outside or pressing back counts as a cancel.
///
/// Replaces six near-identical copies that were living in the apps (two of
/// them byte-identical), which had already drifted on destructive styling.
/// Deliberately a function over a widget: every one of those copies was used
/// through its static `show()`, and none used the `onConfirm`/`onCancel`
/// callbacks the widget carried.
Future<bool> portalConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: scheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
