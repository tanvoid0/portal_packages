import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Pressable control with an on/off visual (shadcn Toggle).
class PortalToggle extends StatelessWidget {
  const PortalToggle({
    required this.pressed,
    required this.onPressed,
    required this.child,
    super.key,
  });

  final bool pressed;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Material(
      color: pressed ? portal.muted : Colors.transparent,
      borderRadius: BorderRadius.circular(t.radii.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(t.radii.md),
        child: Padding(
          padding: EdgeInsets.all(t.spacing.sm),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: portal.onSurface,
                ),
            child: IconTheme.merge(
              data: IconThemeData(color: portal.onSurface, size: 20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
