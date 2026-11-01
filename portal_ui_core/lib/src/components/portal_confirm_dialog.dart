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
/// is the caller's and [onCancel] is whatever the caller wants Cancel to do.
///
/// [otherLabel] adds a third, error-styled escape beside Cancel/Confirm — the
/// "Discard" way out of a dialog whose Confirm keeps the state (e.g. "Workout
/// already in progress": Resume / Discard / Cancel). A null [onConfirm] (or
/// [onOther]) renders that action disabled, for a static book preview of a
/// dialog that cannot act.
class PortalConfirmDialog extends StatelessWidget {
  const PortalConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
    this.otherLabel,
    this.onOther,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// The third, error-styled action's label ("Discard"); null hides it.
  final String? otherLabel;
  final VoidCallback? onOther;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final msg = message;
    final onConfirm = this.onConfirm;
    return AlertDialog(
      title: Text(title),
      content: msg == null ? null : Text(msg),
      actions: [
        if (cancelLabel != null)
          TextButton(onPressed: onCancel, child: Text(cancelLabel!)),
        if (otherLabel case final other?)
          TextButton(
            onPressed: onOther,
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(other),
          ),
        TextButton(
          onPressed: onConfirm == null
              ? null
              : () {
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
