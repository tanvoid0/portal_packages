import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Wraps [child] with a Material tooltip (shadcn Tooltip).
class PortalTooltip extends StatelessWidget {
  const PortalTooltip({
    required this.message,
    required this.child,
    super.key,
    this.waitDuration = const Duration(milliseconds: 400),
  });

  final String message;
  final Widget child;
  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
      margin: EdgeInsets.all(t.spacing.sm),
      decoration: BoxDecoration(
        color: portal.onSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(t.radii.sm),
      ),
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: portal.surface,
          ),
      child: child,
    );
  }
}
