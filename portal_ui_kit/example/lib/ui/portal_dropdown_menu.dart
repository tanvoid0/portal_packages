import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalMenuAction {
  const PortalMenuAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool destructive;
}

/// Anchored menu with [MenuAnchor] (shadcn Dropdown Menu).
class PortalDropdownMenu extends StatelessWidget {
  const PortalDropdownMenu({
    required this.actions,
    required this.trigger,
    super.key,
    this.alignmentOffset = Offset.zero,
  });

  final List<PortalMenuAction> actions;
  final Widget trigger;
  final Offset alignmentOffset;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return MenuAnchor(
      alignmentOffset: alignmentOffset,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(portal.popover),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radii.md),
            side: portal.borderSide(),
          ),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: t.spacing.xs)),
      ),
      menuChildren: [
        for (final a in actions)
          MenuItemButton(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                a.destructive ? portal.destructive : portal.onSurface,
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: t.spacing.lg, vertical: t.spacing.sm),
              ),
            ),
            onPressed: a.onPressed,
            leadingIcon: a.icon == null ? null : Icon(a.icon, size: 20),
            child: Text(a.label),
          ),
      ],
      builder: (context, controller, _) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(t.radii.sm),
          child: trigger,
        );
      },
    );
  }
}
