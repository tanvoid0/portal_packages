import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';

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
  String? message,
  String confirmLabel = 'Confirm',
  String? cancelLabel = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => PortalConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      onConfirm: () => Navigator.pop(ctx, true),
      onCancel: () => Navigator.pop(ctx, false),
    ),
  );
  return confirmed ?? false;
}

/// [portalConfirm]'s dialog body, extracted so a design-review book (or any
/// other screen) can show the same chrome without pushing a route. Unlike
/// [portalConfirm] there is no `Navigator` to pop by default, so [onConfirm]
/// is required and [onCancel] is whatever the caller wants Cancel to do.
class PortalConfirmDialog extends StatelessWidget {
  const PortalConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final msg = message;
    return AlertDialog(
      title: Text(title),
      content: msg == null ? null : Text(msg),
      actions: [
        if (cancelLabel != null)
          TextButton(onPressed: onCancel, child: Text(cancelLabel!)),
        TextButton(
          onPressed: () {
            PortalHaptics.medium();
            onConfirm();
          },
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: scheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
