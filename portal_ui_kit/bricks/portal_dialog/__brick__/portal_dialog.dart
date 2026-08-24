import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Shows a themed alert dialog (shadcn Alert Dialog).
///
/// Returns `true` when the user confirms, `false` when they cancel (if
/// [cancelLabel] is set), or `null` when dismissed via the barrier.
Future<bool?> showPortalAlertDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Continue',
  String? cancelLabel,
  bool barrierDismissible = true,
  bool destructive = false,
}) {
  final portal = PortalUiTheme.of(context);
  final t = portal.tokens;

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: portal.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radii.lg),
          side: portal.borderSide(),
        ),
        title: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
        content: message == null
            ? null
            : Text(
                message,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: portal.onSurfaceVariant,
                    ),
              ),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? portal.destructive : portal.primary,
              foregroundColor: destructive ? portal.onDestructive : portal.onPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
