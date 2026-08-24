import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Shows a themed modal bottom sheet (shadcn Sheet).
Future<T?> showPortalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool useSafeArea = true,
}) {
  final portal = PortalUiTheme.of(context);
  final t = portal.tokens;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final sheet = DecoratedBox(
        decoration: BoxDecoration(
          color: portal.popover,
          borderRadius: BorderRadius.vertical(top: Radius.circular(t.radii.lg)),
          border: Border.fromBorderSide(portal.borderSide()),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: t.spacing.lg,
            right: t.spacing.lg,
            top: t.spacing.md,
            bottom: t.spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: portal.border,
                  borderRadius: BorderRadius.circular(t.radii.full),
                ),
              ),
              SizedBox(height: t.spacing.md),
              builder(ctx),
            ],
          ),
        ),
      );

      if (!useSafeArea) return sheet;
      return SafeArea(child: sheet);
    },
  );
}
